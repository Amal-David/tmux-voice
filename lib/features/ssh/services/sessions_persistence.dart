import 'dart:convert';

import '../../../core/services/secure_storage_service.dart';
import '../models/ssh_profile.dart';

class SessionsPersistence {
  SessionsPersistence(this._storage);

  final SecureStorageService _storage;
  static const _key = 'active_sessions';

  Future<void> saveActiveProfiles(List<SshProfile> profiles) async {
    final payload = profiles.map((profile) => profile.toJson()).toList(growable: false);
    await _storage.write(_key, jsonEncode(payload));
  }

  Future<List<SshProfile>> loadActiveProfiles() async {
    final raw = await _storage.read(_key);
    if (raw == null || raw.isEmpty) return const [];
    final data = jsonDecode(raw) as List<dynamic>;
    return data
        .map((entry) => SshProfile.fromJson((entry as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }
}
