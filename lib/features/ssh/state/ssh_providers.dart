import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/secure_storage_provider.dart';
import '../models/ssh_profile.dart';
import '../models/ssh_session_state.dart';
import '../services/profiles_storage.dart';
import '../services/sessions_persistence.dart';
import '../services/ssh_repository.dart';
import 'profiles_notifier.dart';
import 'ssh_sessions_notifier.dart';

final sshRepositoryProvider = Provider<SshRepository>((ref) {
  return SshRepository();
});

final sessionRestorationProvider = StateProvider<bool>((ref) => true);

final sessionsPersistenceProvider = Provider<SessionsPersistence>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return SessionsPersistence(storage);
});

final sshSessionsProvider =
    StateNotifierProvider<SshSessionsNotifier, List<SshSessionState>>((ref) {
  final repo = ref.watch(sshRepositoryProvider);
  final persistence = ref.watch(sessionsPersistenceProvider);
  final restoration = ref.read(sessionRestorationProvider.notifier);
  return SshSessionsNotifier(
    repo,
    const Uuid(),
    persistence,
    (value) => restoration.state = value,
  );
});

final selectedSessionIdProvider = StateProvider<String?>((ref) => null);

final profilesStorageProvider = Provider<ProfilesStorage>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ProfilesStorage(storage);
});

final profilesProvider =
    StateNotifierProvider<ProfilesNotifier, AsyncValue<List<SshProfile>>>((ref) {
  final storage = ref.watch(profilesStorageProvider);
  return ProfilesNotifier(storage);
});
