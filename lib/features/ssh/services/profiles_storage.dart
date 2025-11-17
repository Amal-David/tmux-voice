import 'dart:convert';

import '../../../core/services/secure_storage_service.dart';
import '../models/ssh_profile.dart';

class ProfilesStorage {
  ProfilesStorage(this._storage);

  final SecureStorageService _storage;
  static const _profilesKey = 'profiles';

  Future<List<SshProfile>> loadProfiles() async {
    final raw = await _storage.read(_profilesKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final data = jsonDecode(raw) as List<dynamic>;
    return data
        .map((entry) {
          final map = (entry as Map).cast<String, dynamic>();
          return SshProfile.fromJson(map);
        })
        .toList(growable: false);
  }

  Future<void> saveProfiles(List<SshProfile> profiles) async {
    final payload = profiles.map((p) => p.toJson()).toList(growable: false);
    await _storage.write(_profilesKey, jsonEncode(payload));
  }
}
