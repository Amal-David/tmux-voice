import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/secure_storage_provider.dart';
import '../../../core/services/secure_storage_service.dart';

class EnvVarsNotifier extends StateNotifier<AsyncValue<Map<String, String>>> {
  EnvVarsNotifier(this._storage) : super(const AsyncValue.loading()) {
    _load();
  }

  final SecureStorageService _storage;
  static const _storageKey = 'user_env_vars';

  Future<void> _load() async {
    try {
      final raw = await _storage.read(_storageKey);
      if (raw == null || raw.isEmpty) {
        state = const AsyncValue.data({});
        return;
      }
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      state = AsyncValue.data(decoded.map((key, value) => MapEntry(key, value.toString())));
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> upsert(String key, String value) async {
    final current = state.value ?? {};
    final updated = {...current, key: value};
    state = AsyncValue.data(updated);
    await _storage.write(_storageKey, jsonEncode(updated));
  }

  Future<void> delete(String key) async {
    final current = state.value ?? {};
    final updated = {...current}..remove(key);
    state = AsyncValue.data(updated);
    await _storage.write(_storageKey, jsonEncode(updated));
  }
}

final envVarsProvider = StateNotifierProvider<EnvVarsNotifier, AsyncValue<Map<String, String>>>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return EnvVarsNotifier(storage);
});
