import 'package:speech_to_text/speech_to_text.dart' as stt;

class DeviceSpeechService {
  DeviceSpeechService() : _speech = stt.SpeechToText();

  final stt.SpeechToText _speech;
  String _latestTranscript = '';

  Future<bool> startListening({void Function(String transcript)? onPartial}) async {
    final available = await _speech.initialize(
      onError: (error) {},
      onStatus: (_) {},
    );
    if (!available) return false;

    _latestTranscript = '';

    final started = await _speech.listen(
      onResult: (result) {
        _latestTranscript = result.recognizedWords;
        if (onPartial != null) {
          onPartial(_latestTranscript);
        }
      },
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
    );
    return started ?? false;
  }

  Future<String> stopListening() async {
    await _speech.stop();
    return _latestTranscript.trim();
  }

  Future<void> cancel() async {
    await _speech.cancel();
  }

  bool get isListening => _speech.isListening;

  void dispose() {
    _speech.stop();
  }
}
