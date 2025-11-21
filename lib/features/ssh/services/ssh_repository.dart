import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';

import '../models/ssh_profile.dart';
import '../../../core/utils/pem_validator.dart';

class SshRepository {
  final _connections = <String, _SshConnection>{};

  Future<Terminal> createSession({
    required String sessionId,
    required SshProfile profile,
  }) async {
    final logs = StringBuffer();
    void log(String msg) {
      print('[SSH Debug] $msg');
      logs.writeln('${DateTime.now().toIso8601String().split('T')[1].substring(0, 8)} $msg');
    }

    log('Starting connection to ${profile.host}:${profile.port}');

    final hasPassword = profile.password?.trim().isNotEmpty ?? false;
    final hasPrivateKey = profile.privateKey?.trim().isNotEmpty ?? false;
    if (!hasPassword && !hasPrivateKey) {
      log('No password or private key configured for ${profile.username}@${profile.host}');
      throw SshConnectionException(
        'No authentication methods configured. Add a password or private key to the profile.',
        logs.toString(),
      );
    }
    
    try {
      log('Resolving and connecting socket...');
      final socket = await SSHSocket.connect(
        profile.host, 
        profile.port, 
        timeout: const Duration(seconds: 10),
      ).catchError((e) {
        throw 'Socket connection failed: $e';
      });
      log('Socket connected successfully.');

      List<SSHKeyPair>? keyPairs;
      if (profile.privateKey != null && profile.privateKey!.trim().isNotEmpty) {
        log('Processing private key...');
        final validation = PemValidator.validatePrivateKey(profile.privateKey!);
        final keyToUse = validation.cleanedKey ?? profile.privateKey!.trim().replaceAll('\\n', '\n');
        
        try {
          // Try to parse. If password is provided, try using it as passphrase
          if (profile.password != null && profile.password!.isNotEmpty) {
             log('Attempting to parse key with provided password as passphrase...');
             keyPairs = SSHKeyPair.fromPem(keyToUse, profile.password!);
          } else {
             log('Parsing unencrypted key...');
             keyPairs = SSHKeyPair.fromPem(keyToUse);
          }
          log('Key parsed successfully. Loaded ${keyPairs.length} keys.');
        } catch (keyError) {
          log('Key parsing failed: $keyError');
          log('Continuing without private key (will try password auth if available)...');
        }
      }

      String? Function()? passwordCallback;
      if (profile.password != null && profile.password!.trim().isNotEmpty) {
        final pwd = profile.password!.trim();
        passwordCallback = () {
          log('Server requested password/passphrase. Sending...');
          return pwd;
        };
      }

      log('Initializing SSH Client...');
      log('User: ${profile.username}');
      log('Auth methods: ${keyPairs != null ? "PublicKey" : ""} ${passwordCallback != null ? "Password" : ""}');

      final client = SSHClient(
        socket,
        username: profile.username,
        identities: keyPairs,
        onPasswordRequest: passwordCallback,
        onVerifyHostKey: (type, fingerprint) {
          final fingerprintHex = fingerprint.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
          log('Host key received ($type): $fingerprintHex');
          return true;
        },
        printDebug: (message) {
          final shouldLog = !(message?.contains('keep-alive') ?? false);
          if (shouldLog) log('Protocol: $message');
        },
      );

      log('Waiting for authentication...');
      await client.authenticated.timeout(const Duration(seconds: 15), onTimeout: () {
        throw 'Authentication timed out after 15s';
      });
      log('Authentication successful!');

      log('Opening shell...');
      final session = await client.shell();
      log('Shell opened.');
      
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
        log('Auto-attaching tmux...');
        final name = profile.tmuxSession?.trim().isEmpty ?? true
            ? 'vomo_$sessionId'
            : profile.tmuxSession!.trim();
        session.write(const Utf8Encoder().convert(
          'tmux new-session -A -s $name\r',
        ));
      }

      return terminal;

    } catch (e, stack) {
      log('ERROR: $e');
      log('Stack trace: $stack');
      throw SshConnectionException(e.toString(), logs.toString());
    }
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
    connection.session.close();
    connection.client.close();
  }

  Future<String> runCommand(String sessionId, String command) async {
    final connection = _connections[sessionId];
    if (connection == null) {
      throw SshConnectionException('Session not found', '');
    }
    final exec = await connection.client.execute(command);
    final output = await utf8.decoder.bind(exec.stdout).join();
    final error = await utf8.decoder.bind(exec.stderr).join();
    exec.close();
    if (output.trim().isNotEmpty) {
      return output;
    }
    return error;
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

class SshConnectionException implements Exception {
  final String message;
  final String logs;

  SshConnectionException(this.message, this.logs);

  @override
  String toString() => message;
}
