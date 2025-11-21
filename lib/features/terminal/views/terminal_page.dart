import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../ssh/models/ssh_session_state.dart';
import '../../ssh/state/ssh_providers.dart';
import '../constants/common_commands.dart';
import '../models/command_history_state.dart';
import '../models/terminal_theme.dart';
import '../state/command_history_provider.dart';
import '../state/terminal_settings_provider.dart';
import '../state/uptime_monitor_provider.dart';
import '../widgets/input_accessory_bar.dart';
import '../widgets/quick_commands_bar.dart';
import '../widgets/resource_monitor_view.dart';
import 'terminal_settings_page.dart';

class TerminalPage extends ConsumerStatefulWidget {
  const TerminalPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends ConsumerState<TerminalPage> {
  late final TerminalController _terminalController;
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _commandFocusNode = FocusNode();
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _terminalController = TerminalController();
    _commandController.addListener(_onCommandChanged);
  }

  @override
  void dispose() {
    _terminalController.dispose();
    _commandController.removeListener(_onCommandChanged);
    _commandController.dispose();
    _commandFocusNode.dispose();
    super.dispose();
  }

  void _onCommandChanged() {
    setState(() {
      _suggestions = getCommandSuggestions(_commandController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sshSessionsProvider);
    final session = _findSession(sessions);
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

    final commandHistory = ref.watch(commandHistoryProvider);
    final terminalSettings = ref.watch(terminalSettingsProvider);
    final theme = AppTerminalThemes.getById(terminalSettings.themeId) ?? AppTerminalThemes.dracula;

    return Scaffold(
      appBar: AppBar(
        title: Text(session.profile.label),
        actions: [
          IconButton(
            tooltip: 'Terminal settings',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => _showTerminalSettings(context),
          ),
          IconButton(
            tooltip: 'View logs',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => _showLogsSheet(session.id),
          ),
          IconButton(
            tooltip: 'Server metrics',
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => _showMetrics(context, session.id),
          ),
          IconButton(
            tooltip: 'Disconnect',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(sshSessionsProvider.notifier).disconnect(session.id);
              if (!mounted) return;
              Navigator.of(context).pop();
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(terminalSettings.terminalPadding.toDouble()),
                child: TerminalView(
                  session.terminal,
                  controller: _terminalController,
                  autofocus: true,
                  theme: theme.toXTermTheme(),
                  textStyle: TerminalStyle(
                    fontSize: terminalSettings.fontSize,
                    fontFamily: terminalSettings.fontFamily,
                    height: terminalSettings.lineHeight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_suggestions.isNotEmpty) ...[
                    _CommandSuggestions(
                      suggestions: _suggestions,
                      onSelected: (cmd) {
                        _commandController.text = cmd;
                        _commandController.selection = TextSelection.fromPosition(
                          TextPosition(offset: cmd.length),
                        );
                        setState(() => _suggestions = []);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Command history',
                        onPressed: () => _showHistorySheet(commandHistory),
                        icon: const Icon(Icons.history),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(
                            maxHeight: 150,
                          ),
                          child: TextField(
                            controller: _commandController,
                            focusNode: _commandFocusNode,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              hintText: 'Type command...',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              suffixIcon: _commandController.text.isNotEmpty
                                  ? IconButton(
                                      tooltip: 'Clear',
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _commandController.clear();
                                        _commandFocusNode.requestFocus();
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Send command',
                        onPressed: _commandController.text.isEmpty
                            ? null
                            : () => _sendCommand(_commandController.text),
                        icon: const Icon(Icons.send),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            QuickCommandsBar(
              onCommandTap: (command) => _sendCommand(command),
            ),
            InputAccessoryBar(
              onKeyTap: (key) => session.terminal.textInput(key),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showTerminalSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TerminalSettingsPage(),
      ),
    );
  }

  Future<void> _sendCommand(String? command) async {
    final trimmed = command?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    try {
      await ref.read(sshSessionsProvider.notifier).sendCommand(widget.sessionId, trimmed);
      _commandController.clear();
      setState(() => _suggestions = []);
      await ref.read(commandHistoryProvider.notifier).recordCommand(trimmed);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $error')));
      }
    }
  }

  SshSessionState? _findSession(List<SshSessionState> sessions) {
    for (final candidate in sessions) {
      if (candidate.id == widget.sessionId) {
        return candidate;
      }
    }
    return null;
  }

  void _showMetrics(BuildContext context, String sessionId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => SizedBox(
        height: 520,
        child: ResourceMonitorView(sessionId: sessionId),
      ),
    );
  }

  void _showHistorySheet(CommandHistoryState history) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final frequentEntries = history.frequency.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Command history', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      Text('Recent', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (history.recent.isEmpty)
                        const Text('No commands yet.'),
                      ...history.recent.map(
                        (command) => ListTile(
                          title: Text(command),
                          trailing: const Icon(Icons.north_west, size: 16),
                          onTap: () {
                            Navigator.of(context).pop();
                            _commandController.text = command;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Frequently used', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (frequentEntries.isEmpty)
                        const Text('No data yet.'),
                      ...frequentEntries.take(10).map(
                        (entry) => ListTile(
                          title: Text(entry.key),
                          subtitle: Text('${entry.value} times'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _commandController.text = entry.key;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogsSheet(String sessionId) {
    final parentContext = context;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.dns),
              title: const Text('Docker container logs'),
              subtitle: const Text('tail docker logs --tail 200'),
              onTap: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                final container = await _pickDockerContainer(parentContext, sessionId);
                if (container == null || container.trim().isEmpty) return;
                final command = 'docker logs --tail 200 ${container.trim()}';
                _fetchAndShowLogs(sessionId, 'Docker: ${container.trim()}', command);
              },
            ),
            ListTile(
              leading: const Icon(Icons.web),
              title: const Text('Nginx access log'),
              subtitle: const Text('/var/log/nginx/access.log'),
              onTap: () {
                Navigator.of(context).pop();
                _fetchAndShowLogs(sessionId, 'Nginx access log', 'sudo tail -n 200 /var/log/nginx/access.log');
              },
            ),
            ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Nginx error log'),
              subtitle: const Text('/var/log/nginx/error.log'),
              onTap: () {
                Navigator.of(context).pop();
                _fetchAndShowLogs(sessionId, 'Nginx error log', 'sudo tail -n 200 /var/log/nginx/error.log');
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Systemd service (Node/Python)'),
              subtitle: const Text('journalctl -u service -n 200'),
              onTap: () async {
                final navigator = Navigator.of(context);
                final service = await _promptForText('Service name', 'e.g. myapp.service');
                if (service == null || service.trim().isEmpty) return;
                navigator.pop();
                final command =
                    'sudo journalctl -u ${service.trim()} -n 200 --no-pager --since "-30 min"';
                _fetchAndShowLogs(sessionId, 'Service: ${service.trim()}', command);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Log file path'),
              subtitle: const Text('tail -n 200 <path>'),
              onTap: () async {
                final navigator = Navigator.of(context);
                final path = await _promptForText('Log file path', '/var/log/app.log');
                if (path == null || path.trim().isEmpty) return;
                navigator.pop();
                final command = 'sudo tail -n 200 ${path.trim()}';
                _fetchAndShowLogs(sessionId, path.trim(), command);
              },
            ),
            ListTile(
              leading: const Icon(Icons.terminal),
              title: const Text('Custom command'),
              subtitle: const Text('Run any log command'),
              onTap: () async {
                final navigator = Navigator.of(context);
                final command = await _promptForText('Command to run', 'e.g. tail -n 200 /tmp/log.txt');
                if (command == null || command.trim().isEmpty) return;
                navigator.pop();
                _fetchAndShowLogs(sessionId, command.trim(), command.trim());
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchAndShowLogs(String sessionId, String title, String command) async {
    if (!mounted) return;
    final service = ref.read(logViewerServiceProvider);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(12),
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<String>(
              future: service.fetchLogs(sessionId: sessionId, command: command),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 200,
                    child: SingleChildScrollView(
                      child: Text(
                        'Failed to fetch logs:\n${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  );
                }
                return SizedBox(
                  height: 300,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      snapshot.data ?? '',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _promptForText(String title, String hint) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickDockerContainer(BuildContext parentContext, String sessionId) async {
    final service = ref.read(logViewerServiceProvider);
    return showModalBottomSheet<String>(
      context: parentContext,
      showDragHandle: true,
      builder: (context) {
        return FutureBuilder<List<String>>(
          future: service.dockerContainers(sessionId),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final containers = snapshot.data ?? [];
            if (containers.isEmpty) {
              return SizedBox(
                height: 220,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No running containers detected.'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Enter container name manually'),
                      onTap: () async {
                        final name = await _promptForText('Container name', 'e.g. web');
                        if (name == null) return;
                        Navigator.of(context).pop(name);
                      },
                    ),
                  ],
                ),
              );
            }
            return SizedBox(
              height: 320,
              child: ListView(
                children: [
                  ...containers.map(
                    (name) => ListTile(
                      title: Text(name),
                      onTap: () => Navigator.of(context).pop(name),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Enter name manually'),
                    onTap: () async {
                      final manual = await _promptForText('Container name', 'e.g. web');
                      if (manual == null) return;
                      Navigator.of(context).pop(manual);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CommandSuggestions extends StatelessWidget {
  const _CommandSuggestions({
    required this.suggestions,
    required this.onSelected,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.terminal, size: 18),
            title: Text(
              suggestion,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            onTap: () => onSelected(suggestion),
          );
        },
      ),
    );
  }
}
