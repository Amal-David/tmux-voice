import 'dart:convert';

import '../../../core/services/secure_storage_service.dart';
import '../models/ssh_profile.dart';

class ProfilesStorage {
  ProfilesStorage(this._storage);

  final SecureStorageService _storage;
  static const _profilesKey = 'profiles';

  Future<List<SshProfile>> loadProfiles() async {
    print('[Storage Debug] === LOADING PROFILES ===');
    final raw = await _storage.read(_profilesKey);
    if (raw == null || raw.trim().isEmpty) {
      print('[Storage Debug] No profiles found in storage');
      return const [];
    }

    print('[Storage Debug] Raw JSON length: ${raw.length} chars');
    final data = jsonDecode(raw) as List<dynamic>;
    print('[Storage Debug] Decoded ${data.length} profiles');
    
    final profiles = data
        .map((entry) {
          final map = (entry as Map).cast<String, dynamic>();
          return SshProfile.fromJson(map);
        })
        .toList(growable: false);
    
    for (var i = 0; i < profiles.length; i++) {
      final p = profiles[i];
      print('[Storage Debug] Loaded profile $i: ${p.label}');
      print('[Storage Debug]   - Password length: ${p.password?.length ?? 0}');
      print('[Storage Debug]   - Private key length: ${p.privateKey?.length ?? 0}');
    }
    
    return profiles;
  }

  Future<void> saveProfiles(List<SshProfile> profiles) async {
    print('[Storage Debug] === SAVING ${profiles.length} PROFILES ===');
    for (var i = 0; i < profiles.length; i++) {
      final p = profiles[i];
      print('[Storage Debug] Profile $i: ${p.label}');
      print('[Storage Debug]   - Password length: ${p.password?.length ?? 0}');
      print('[Storage Debug]   - Private key length: ${p.privateKey?.length ?? 0}');
    }
    
    final payload = profiles.map((p) => p.toJson()).toList(growable: false);
    final jsonStr = jsonEncode(payload);
    print('[Storage Debug] JSON length: ${jsonStr.length} chars');
    
    await _storage.write(_profilesKey, jsonStr);
    print('[Storage Debug] Write complete!');
  }
}
