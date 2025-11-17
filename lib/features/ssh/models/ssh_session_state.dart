import 'package:xterm/xterm.dart';

import 'ssh_profile.dart';

enum SshSessionStatus { connecting, connected, disconnected, error }

class SshSessionState {
  const SshSessionState({
    required this.id,
    required this.profile,
    required this.terminal,
    required this.status,
    required this.connectedAt,
    this.lastCommand,
    this.errorMessage,
  });

  final String id;
  final SshProfile profile;
  final Terminal terminal;
  final SshSessionStatus status;
  final DateTime connectedAt;
  final String? lastCommand;
  final String? errorMessage;

  SshSessionState copyWith({
    SshSessionStatus? status,
    Terminal? terminal,
    DateTime? connectedAt,
    String? lastCommand,
    String? errorMessage,
  }) {
    return SshSessionState(
      id: id,
      profile: profile,
      terminal: terminal ?? this.terminal,
      status: status ?? this.status,
      connectedAt: connectedAt ?? this.connectedAt,
      lastCommand: lastCommand ?? this.lastCommand,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
