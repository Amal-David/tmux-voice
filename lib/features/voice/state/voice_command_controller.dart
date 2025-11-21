import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../core/constants.dart';
import '../../../core/providers/http_client_provider.dart';
import '../../settings/models/voice_settings.dart';
import '../../settings/state/voice_settings_notifier.dart';
import '../models/voice_command_state.dart';
import '../services/command_generation_service.dart';
import '../services/device_speech_service.dart';
import '../services/speech_to_text_service.dart';

final recordProvider = Provider<AudioRecorder>((ref) {
  final recorder = AudioRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
});

final speechToTextServiceProvider = Provider<SpeechToTextService>((ref) {
  final client = ref.watch(httpClientProvider);
  return SpeechToTextService(client);
});

final commandGenerationServiceProvider = Provider<CommandGenerationService>((ref) {
  final client = ref.watch(httpClientProvider);
  return CommandGenerationService(client);
});

final deviceSpeechServiceProvider = Provider<DeviceSpeechService>((ref) {
  final service = DeviceSpeechService();
  ref.onDispose(service.dispose);
  return service;
});

final voiceCommandControllerProvider =
    StateNotifierProvider<VoiceCommandController, VoiceCommandState>((ref) {
  final recorder = ref.watch(recordProvider);
  final stt = ref.watch(speechToTextServiceProvider);
  final generator = ref.watch(commandGenerationServiceProvider);
  final deviceSpeech = ref.watch(deviceSpeechServiceProvider);
  return VoiceCommandController(ref, recorder, stt, generator, deviceSpeech);
});

class VoiceCommandController extends StateNotifier<VoiceCommandState> {
  VoiceCommandController(
    this._ref,
    this._recorder,
    this._speechToText,
    this._commandGenerator,
    this._deviceSpeech,
  ) : super(const VoiceCommandState.idle());

  final Ref _ref;
  final AudioRecorder _recorder;
  final SpeechToTextService _speechToText;
  final CommandGenerationService _commandGenerator;
  final DeviceSpeechService _deviceSpeech;
  String? _currentRecordingPath;
  String _deviceTranscript = '';

  Future<void> startRecording() async {
    if (state.isRecording || state.isProcessing) return;
    final granted = await _ensurePermission();
    if (!granted) {
      state = const VoiceCommandState(
        status: VoiceCommandStatus.error,
        errorMessage: 'Microphone permission is required.',
      );
      return;
    }

    if (_useDeviceStt()) {
      final started = await _deviceSpeech.startListening(onPartial: (partial) {
        state = state.copyWith(transcript: partial);
      });
      if (!started) {
        state = const VoiceCommandState(
          status: VoiceCommandStatus.error,
          errorMessage: 'Device speech recognition is unavailable.',
        );
        return;
      }
      _deviceTranscript = '';
      state = const VoiceCommandState(status: VoiceCommandStatus.recording);
      return;
    }

    final dir = await getTemporaryDirectory();
    _currentRecordingPath =
        '${dir.path}/tmux_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _currentRecordingPath!,
    );

    state = const VoiceCommandState(status: VoiceCommandStatus.recording);
  }

  Future<String?> stopAndProcess({String? contextString}) async {
    if (_useDeviceStt()) {
      if (!state.isRecording) return null;
      state = const VoiceCommandState(status: VoiceCommandStatus.processing);
      try {
        _deviceTranscript = await _deviceSpeech.stopListening();
      } catch (_) {
        await _deviceSpeech.cancel();
        state = const VoiceCommandState(
          status: VoiceCommandStatus.error,
          errorMessage: 'Unable to capture voice input.',
        );
        return null;
      }

      if (_deviceTranscript.isEmpty) {
        state = const VoiceCommandState(
          status: VoiceCommandStatus.error,
          errorMessage: 'Heard silence. Please try again.',
        );
        return null;
      }

      try {
        final command = await _generateCommandFromTranscript(
          transcript: _deviceTranscript,
          contextString: contextString,
        );
        state = VoiceCommandState(
          status: VoiceCommandStatus.success,
          transcript: _deviceTranscript,
          command: command,
        );
        return command;
      } catch (error) {
        state = VoiceCommandState(
          status: VoiceCommandStatus.error,
          errorMessage: error.toString(),
        );
        return null;
      }
    }

    if (_currentRecordingPath == null) {
      return null;
    }
    final path = _currentRecordingPath;
    _currentRecordingPath = null;

    await _recorder.stop();

    final file = File(path!);
    if (!await file.exists()) {
      state = const VoiceCommandState(
        status: VoiceCommandStatus.error,
        errorMessage: 'Recording failed, try again.',
      );
      return null;
    }

    state = const VoiceCommandState(status: VoiceCommandStatus.processing);

    try {
      final transcript = await _transcribeRemote(file);
      final command = await _generateCommandFromTranscript(
        transcript: transcript,
        contextString: contextString,
      );

      state = VoiceCommandState(
        status: VoiceCommandStatus.success,
        transcript: transcript,
        command: command,
      );
      return command;
    } catch (error) {
      state = VoiceCommandState(
        status: VoiceCommandStatus.error,
        errorMessage: error.toString(),
      );
      return null;
    } finally {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<bool> _ensurePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  String _requireEnvKey(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('Missing $key in .env');
    }
    return value;
  }

  VoiceSettings? _currentSettings() {
    return _ref.read(voiceSettingsProvider).maybeWhen(
          data: (settings) => settings,
          orElse: () => null,
        );
  }

  String _sttModel(SttProvider provider) {
    switch (provider) {
      case SttProvider.groqWhisper:
        return VoiceModels.groqStt;
      case SttProvider.device:
        return '';
    }
  }

  String _llmModel(LlmProvider provider) {
    switch (provider) {
      case LlmProvider.geminiFlash:
        return VoiceModels.geminiFlash;
      case LlmProvider.geminiPro:
        return VoiceModels.geminiPro;
    }
  }

  bool _useDeviceStt() {
    final settings = _currentSettings();
    return (settings?.sttProvider ?? SttProvider.groqWhisper) == SttProvider.device;
  }

  Future<String> _transcribeRemote(File file) async {
    final settings = _currentSettings();
    final groqKey = settings?.groqApiKey?.isNotEmpty == true
        ? settings!.groqApiKey!
        : _requireEnvKey(EnvKeys.groqApiKey);
    final sttModel = _sttModel(settings?.sttProvider ?? SttProvider.groqWhisper);
    return _speechToText.transcribe(
      audioFile: file,
      apiKey: groqKey,
      model: sttModel,
    );
  }

  Future<String> _generateCommandFromTranscript({
    required String transcript,
    String? contextString,
  }) async {
    final settings = _currentSettings();
    final geminiKey = settings?.geminiApiKey?.isNotEmpty == true
        ? settings!.geminiApiKey!
        : _requireEnvKey(EnvKeys.geminiApiKey);
    final llmModel = _llmModel(settings?.llmProvider ?? LlmProvider.geminiFlash);
    final prompt = await rootBundle.loadString(Assets.commandPrompt);
    return _commandGenerator.generateCommand(
      transcript: transcript,
      prompt: prompt,
      apiKey: geminiKey,
      model: llmModel,
      context: contextString,
    );
  }
}
