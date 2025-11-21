import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/secure_storage_provider.dart';
import '../../../core/services/secure_storage_service.dart';
import '../models/voice_settings.dart';

class VoiceSettingsNotifier extends StateNotifier<AsyncValue<VoiceSettings>> {
  VoiceSettingsNotifier(this._storage) : super(const AsyncValue.loading()) {
    _load();
  }

  final SecureStorageService _storage;
  static const _settingsKey = 'voice_settings';

  Future<void> _load() async {
    try {
      final raw = await _storage.read(_settingsKey);
      if (raw == null || raw.isEmpty) {
        state = const AsyncValue.data(VoiceSettings.defaults);
        return;
      }
      final json = jsonDecode(raw) as Map<String, dynamic>;
      state = AsyncValue.data(VoiceSettings.fromJson(json));
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> updateSettings(VoiceSettings settings) async {
    state = AsyncValue.data(settings);
    await _storage.write(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> updateKeys({String? groqKey, String? geminiKey}) async {
    final current = _requireSettings();
    final updated = current.copyWith(
      groqApiKey: groqKey ?? current.groqApiKey,
      geminiApiKey: geminiKey ?? current.geminiApiKey,
    );
    await updateSettings(updated);
  }

  Future<void> updateProviders({SttProvider? stt, LlmProvider? llm}) async {
    final current = _requireSettings();
    final updated = current.copyWith(
      sttProvider: stt ?? current.sttProvider,
      llmProvider: llm ?? current.llmProvider,
    );
    await updateSettings(updated);
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    final current = _requireSettings();
    final updated = current.copyWith(voiceEnabled: enabled);
    await updateSettings(updated);
  }

  VoiceSettings _requireSettings() {
    return state.maybeWhen(data: (settings) => settings, orElse: () => VoiceSettings.defaults);
  }
}

final voiceSettingsProvider = StateNotifierProvider<VoiceSettingsNotifier, AsyncValue<VoiceSettings>>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return VoiceSettingsNotifier(storage);
});
