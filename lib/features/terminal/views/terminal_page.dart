import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../ssh/models/ssh_session_state.dart';
import '../../ssh/state/ssh_providers.dart';
import '../../voice/models/voice_command_state.dart';
import '../../voice/state/voice_command_controller.dart';

class TerminalPage extends ConsumerStatefulWidget {
  const TerminalPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends ConsumerState<TerminalPage> {
  late final TerminalController _terminalController;
  final TextEditingController _commandController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _terminalController = TerminalController();
  }

  @override
  void dispose() {
    _terminalController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sshSessionsProvider);
    SshSessionState? session;
    for (final candidate in sessions) {
      if (candidate.id == widget.sessionId) {
        session = candidate;
        break;
      }
    }

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Terminal')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Session not found. It may have been closed.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to sessions'),
              ),
            ],
          ),
        ),
      );
    }

    final voiceState = ref.watch(voiceCommandControllerProvider);
    final voiceBanner = _voiceStatusWidget(context, voiceState);

    return Scaffold(
      appBar: AppBar(
        title: Text(session.profile.label),
        actions: [
          IconButton(
            tooltip: 'Disconnect',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(sshSessionsProvider.notifier).disconnect(session.id);
              if (mounted) Navigator.of(context).pop();
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TerminalView(
                terminal: session.terminal,
                controller: _terminalController,
                autofocus: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    decoration: const InputDecoration(
                      labelText: 'Send command',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _sendCommand,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => _sendCommand(_commandController.text),
                  child: const Text('Send'),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  tooltip: voiceState.isRecording ? 'Stop and process voice command' : 'Record voice command',
                  onPressed: voiceState.isProcessing ? null : () => _handleVoiceButton(session.id, voiceState),
                  icon: Icon(voiceState.isRecording ? Icons.stop : Icons.mic),
                ),
              ],
            ),
            if (voiceBanner != null) ...[
              const SizedBox(height: 12),
              voiceBanner,
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendCommand(String? command) async {
    final trimmed = command?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    try {
      await ref.read(sshSessionsProvider.notifier).sendCommand(widget.sessionId, trimmed);
      _commandController.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $error')));
      }
    }
  }

  Future<void> _handleVoiceButton(String sessionId, VoiceCommandState voiceState) async {
    final controller = ref.read(voiceCommandControllerProvider.notifier);
    if (voiceState.isRecording) {
      final command = await controller.stopAndProcess();
      if (command == null) {
        final error = ref.read(voiceCommandControllerProvider).errorMessage ?? 'Unable to generate command.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
        return;
      }

      try {
        await ref.read(sshSessionsProvider.notifier).sendCommand(sessionId, command);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ran voice command: $command')),
          );
        }
        _commandController.clear();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to run command: $error')),
          );
        }
      }
    } else {
      await controller.startRecording();
    }
  }

  Widget? _voiceStatusWidget(BuildContext context, VoiceCommandState state) {
    switch (state.status) {
      case VoiceCommandStatus.idle:
        return null;
      case VoiceCommandStatus.recording:
        return _VoiceStatusBanner(
          icon: Icons.mic,
          text: 'Recording… tap stop when ready.',
        );
      case VoiceCommandStatus.processing:
        return const _VoiceProcessingBanner();
      case VoiceCommandStatus.success:
        if (state.command == null) return null;
        return _VoiceStatusBanner(
          icon: Icons.check_circle,
          text: 'Sent: ${state.command}',
        );
      case VoiceCommandStatus.error:
        return _VoiceStatusBanner(
          icon: Icons.error_outline,
          text: state.errorMessage ?? 'Voice command failed.',
          isError: true,
        );
    }
  }
}

class _VoiceStatusBanner extends StatelessWidget {
  const _VoiceStatusBanner({required this.icon, required this.text, this.isError = false});

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.redAccent : Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceProcessingBanner extends StatelessWidget {
  const _VoiceProcessingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Expanded(child: Text('Processing voice command...', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
