import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ssh_profile.dart';
import '../services/profiles_storage.dart';

class ProfilesNotifier extends StateNotifier<AsyncValue<List<SshProfile>>> {
  ProfilesNotifier(this._storage) : super(const AsyncValue.loading()) {
    _loadProfiles();
  }

  final ProfilesStorage _storage;

  Future<void> _loadProfiles() async {
    try {
      final profiles = await _storage.loadProfiles();
      state = AsyncValue.data(profiles);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> addProfile(SshProfile profile) async {
    print('[ProfilesNotifier Debug] === ADD PROFILE ===');
    print('[ProfilesNotifier Debug] Profile password length: ${profile.password?.length ?? 0}');
    print('[ProfilesNotifier Debug] Profile private key length: ${profile.privateKey?.length ?? 0}');
    
    final current = _requireProfiles();
    final updated = [...current, profile];
    await _persist(updated);
    
    print('[ProfilesNotifier Debug] Persisted ${updated.length} profiles total');
  }

  Future<void> updateProfile(int index, SshProfile profile) async {
    final current = _requireProfiles();
    if (index < 0 || index >= current.length) {
      throw RangeError.index(index, current, 'index');
    }
    final updated = [...current]..[index] = profile;
    await _persist(updated);
  }

  Future<void> deleteProfile(int index) async {
    final current = _requireProfiles();
    if (index < 0 || index >= current.length) {
      throw RangeError.index(index, current, 'index');
    }
    final updated = [...current]..removeAt(index);
    await _persist(updated);
  }

  List<SshProfile> _requireProfiles() {
    return state.maybeWhen(data: (profiles) => profiles, orElse: () => throw StateError('Profiles not loaded yet'));
  }

  Future<void> _persist(List<SshProfile> profiles) async {
    state = AsyncValue.data(profiles);
    try {
      await _storage.saveProfiles(profiles);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}
