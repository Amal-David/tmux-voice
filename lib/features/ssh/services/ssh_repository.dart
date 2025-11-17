import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';

import '../models/ssh_profile.dart';

class SshRepository {
  final _connections = <String, _SshConnection>{};

  Future<Terminal> createSession({
    required String sessionId,
    required SshProfile profile,
  }) async {
    final socket = await SSHSocket.connect(profile.host, profile.port);

    SSHKeyPair? keyPair;
    if (profile.privateKey != null && profile.privateKey!.trim().isNotEmpty) {
      keyPair = SSHKeyPair.fromPem(profile.privateKey!.trim());
    }

    final client = SSHClient(
      socket,
      username: profile.username,
      identities: keyPair != null ? [keyPair] : null,
      onPasswordRequest: profile.password != null
          ? () => profile.password
          : () async => null,
      printDebug: (message) {},
    );

    final session = await client.shell();
    final terminal = Terminal(maxLines: 2000);

    final stdoutSub = session.stdout.listen((data) {
      terminal.write(String.fromCharCodes(data));
    });

    final stderrSub = session.stderr.listen((data) {
      terminal.write(String.fromCharCodes(data));
    });

    terminal.write('Connected to ${profile.host}\r\n');

    terminal.onOutput = (data) {
      session.write(const Utf8Encoder().convert(data));
    };

    terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      session.resizeTerminal(width, height, pixelWidth, pixelHeight);
    };

    final connection = _SshConnection(
      client: client,
      session: session,
      stdoutSub: stdoutSub,
      stderrSub: stderrSub,
      terminal: terminal,
    );
    _connections[sessionId] = connection;

    if (profile.autoAttachTmux) {
      final name = profile.tmuxSession?.trim().isEmpty ?? true
          ? 'vomo_$sessionId'
          : profile.tmuxSession!.trim();
      session.write(const Utf8Encoder().convert(
        'tmux new-session -A -s $name\r',
      ));
    }

    return terminal;
  }

  Future<void> sendRaw(String sessionId, String data) async {
    final connection = _connections[sessionId];
    connection?.session.write(const Utf8Encoder().convert(data));
  }

  Future<void> disposeSession(String sessionId) async {
    final connection = _connections.remove(sessionId);
    if (connection == null) return;
    await connection.stdoutSub.cancel();
    await connection.stderrSub.cancel();
    await connection.session.close();
    await connection.client.close();
  }
}

class _SshConnection {
  _SshConnection({
    required this.client,
    required this.session,
    required this.stdoutSub,
    required this.stderrSub,
    required this.terminal,
  });

  final SSHClient client;
  final SSHSession session;
  final StreamSubscription<List<int>> stdoutSub;
  final StreamSubscription<List<int>> stderrSub;
  final Terminal terminal;
}
