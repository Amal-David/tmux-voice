import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/ssh_profile.dart';
import '../models/ssh_session_state.dart';
import '../services/sessions_persistence.dart';
import '../services/ssh_repository.dart';

class SshSessionsNotifier extends StateNotifier<List<SshSessionState>> {
  SshSessionsNotifier(
    this._repository,
    this._uuid,
    this._persistence,
    this._onRestorationChanged,
  ) : super(const []) {
    _onRestorationChanged(true);
    unawaited(_restoreSessions());
  }

  final SshRepository _repository;
  final Uuid _uuid;
  final SessionsPersistence _persistence;
  final void Function(bool) _onRestorationChanged;

  Future<String> connect(SshProfile profile, {bool persist = true}) async {
    final sessionId = _uuid.v4();
    final terminal = await _repository.createSession(
      sessionId: sessionId,
      profile: profile,
    );

    final session = SshSessionState(
      id: sessionId,
      profile: profile,
      terminal: terminal,
      status: SshSessionStatus.connected,
      connectedAt: DateTime.now(),
    );

    state = [...state, session];
    if (persist) {
      await _persistActiveProfiles();
    }
    return sessionId;
  }

  Future<void> reconnect(String sessionId) async {
    final existing = state.firstWhere((s) => s.id == sessionId, orElse: () => throw StateError('Session not found'));
    await disconnect(sessionId, persist: false);
    await connect(existing.profile);
  }

  Future<void> disconnect(String sessionId, {bool persist = true}) async {
    final session = state.firstWhere((s) => s.id == sessionId, orElse: () => throw StateError('Session not found'));
    state = state.where((s) => s.id != sessionId).toList();
    await _repository.disposeSession(sessionId);
    session.terminal.write('\r\n[Session closed]\r\n');
    if (persist) {
      await _persistActiveProfiles();
    }
  }

  Future<void> sendCommand(String sessionId, String command) async {
    try {
      await _repository.sendRaw(sessionId, '$command\r');
      state = [
        for (final session in state)
          if (session.id == sessionId)
            session.copyWith(lastCommand: command, status: SshSessionStatus.connected, errorMessage: null)
          else
            session,
      ];
    } catch (error) {
      state = [
        for (final session in state)
          if (session.id == sessionId)
            session.copyWith(status: SshSessionStatus.error, errorMessage: error.toString())
          else
            session,
      ];
      rethrow;
    }
  }

  SshSessionState? sessionById(String sessionId) {
    return state.where((s) => s.id == sessionId).firstOrNull;
  }

  Future<void> _persistActiveProfiles() async {
    await _persistence.saveActiveProfiles([for (final session in state) session.profile]);
  }

  Future<void> _restoreSessions() async {
    try {
      final profiles = await _persistence.loadActiveProfiles();
      for (final profile in profiles) {
        try {
          await connect(profile, persist: false);
        } catch (_) {
          // Ignore failure; user can manually reconnect.
        }
      }
    } finally {
      _onRestorationChanged(false);
    }
  }
}

extension _IterableFirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
