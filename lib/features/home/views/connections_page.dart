import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/views/voice_settings_page.dart';
import '../../ssh/models/ssh_profile.dart';
import '../../ssh/state/ssh_providers.dart';
import '../../terminal/views/terminal_page.dart';
import 'session_deck.dart';

class ConnectionsPage extends ConsumerWidget {
  const ConnectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final sessions = ref.watch(sshSessionsProvider);
    final selectedSessionId = ref.watch(selectedSessionIdProvider);
    final isRestoringSessions = ref.watch(sessionRestorationProvider);
    final canModifyProfiles = profilesAsync.hasValue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connections'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VoiceSettingsPage()),
            ),
          ),
          IconButton(
            tooltip: 'Add profile',
            icon: const Icon(Icons.add),
            onPressed: canModifyProfiles ? () => _openProfileSheet(context, ref) : null,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          const Text(
            'Terminal Sessions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          StackedSessionDeck(
            sessions: sessions,
            isRestoring: isRestoringSessions,
            selectedSessionId: selectedSessionId,
            onSelect: (session) => ref.read(selectedSessionIdProvider.notifier).state = session.id,
            onOpen: (session) => _openTerminal(context, session.id),
            onDisconnect: (session) => _disconnect(context, ref, session.id),
            onRetry: (session) => ref.read(sshSessionsProvider.notifier).reconnect(session.id),
          ),
          const SizedBox(height: 32),
          const Text(
            'Saved Profiles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          profilesAsync.when(
            data: (profiles) {
              if (profiles.isEmpty) {
                return const _EmptyState(message: 'No saved profiles yet. Tap + to create one.');
              }
              return Column(
                children: [
                  for (var i = 0; i < profiles.length; i++)
                    _ProfileCard(
                      profile: profiles[i],
                      onConnect: () => _connect(context, ref, profiles[i]),
                      onDelete: () => _deleteProfile(context, ref, i),
                      onEdit: () => _editProfile(context, ref, profiles[i], i),
                    ),
                ],
              );
            },
            loading: () => const _SectionLoading(),
            error: (error, _) => _ErrorState(message: 'Failed to load profiles ($error)'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: canModifyProfiles ? () => _openProfileSheet(context, ref) : null,
        icon: const Icon(Icons.add),
        label: const Text('New profile'),
      ),
    );
  }

  Future<void> _openProfileSheet(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(profilesProvider.notifier);
    final profile = await showModalBottomSheet<SshProfile>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ProfileFormSheet(),
    );

    if (profile == null) {
      return;
    }

    await notifier.addProfile(profile);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    }
  }

  Future<void> _connect(BuildContext context, WidgetRef ref, SshProfile profile) async {
    final notifier = ref.read(sshSessionsProvider.notifier);
    try {
      final sessionId = await notifier.connect(profile);
      ref.read(selectedSessionIdProvider.notifier).state = sessionId;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${profile.label}')),
        );
        _openTerminal(context, sessionId);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $error')),
        );
      }
    }
  }

  void _openTerminal(BuildContext context, String sessionId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TerminalPage(sessionId: sessionId),
      ),
    );
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref, String sessionId) async {
    final notifier = ref.read(sshSessionsProvider.notifier);
    try {
      await notifier.disconnect(sessionId);
      if (ref.read(selectedSessionIdProvider) == sessionId) {
        ref.read(selectedSessionIdProvider.notifier).state = null;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session disconnected')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disconnect: $error')),
        );
      }
    }
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    SshProfile profile,
    int index,
  ) async {
    final notifier = ref.read(profilesProvider.notifier);
    final updated = await showModalBottomSheet<SshProfile>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProfileFormSheet(initialProfile: profile),
    );

    if (updated == null) return;

    await notifier.updateProfile(index, updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    }
  }

  Future<void> _deleteProfile(BuildContext context, WidgetRef ref, int index) async {
    final notifier = ref.read(profilesProvider.notifier);
    await notifier.deleteProfile(index);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile removed')),
      );
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onConnect,
    required this.onDelete,
    required this.onEdit,
  });

  final SshProfile profile;
  final VoidCallback onConnect;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    profile.label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Edit profile',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: 'Delete profile',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${profile.username}@${profile.host}:${profile.port}'),
            if (profile.tmuxSession != null && profile.tmuxSession!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('tmux: ${profile.tmuxSession}'),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onConnect,
                icon: const Icon(Icons.login),
                label: const Text('Connect'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileFormSheet extends StatefulWidget {
  const _ProfileFormSheet({this.initialProfile});

  final SshProfile? initialProfile;

  @override
  State<_ProfileFormSheet> createState() => _ProfileFormSheetState();
}

class _ProfileFormSheetState extends State<_ProfileFormSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _privateKeyController;
  late final TextEditingController _tmuxController;
  bool _autoAttachTmux = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialProfile;
    _labelController = TextEditingController(text: initial?.label ?? '');
    _hostController = TextEditingController(text: initial?.host ?? '');
    _portController = TextEditingController(text: (initial?.port ?? 22).toString());
    _usernameController = TextEditingController(text: initial?.username ?? '');
    _passwordController = TextEditingController(text: initial?.password ?? '');
    _privateKeyController = TextEditingController(text: initial?.privateKey ?? '');
    _tmuxController = TextEditingController(text: initial?.tmuxSession ?? '');
    _autoAttachTmux = initial?.autoAttachTmux ?? true;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _privateKeyController.dispose();
    _tmuxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.initialProfile == null ? 'New Connection' : 'Edit Connection',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(labelText: 'Label'),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hostController,
                  decoration: const InputDecoration(labelText: 'Host'),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _portController,
                  decoration: const InputDecoration(labelText: 'Port'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final port = int.tryParse(value ?? '');
                    if (port == null || port <= 0) {
                      return 'Enter a valid port';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password (optional)'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _privateKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Private key (PEM)',
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 6,
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: _autoAttachTmux,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) => setState(() => _autoAttachTmux = value),
                  title: const Text('Auto attach to tmux'),
                ),
                TextFormField(
                  controller: _tmuxController,
                  decoration: const InputDecoration(labelText: 'tmux session name (optional)'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: Text(widget.initialProfile == null ? 'Save profile' : 'Save changes'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      SshProfile(
        label: _labelController.text.trim(),
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim().isEmpty ? null : _passwordController.text,
        privateKey: _privateKeyController.text.trim().isEmpty ? null : _privateKeyController.text,
        tmuxSession: _tmuxController.text.trim().isEmpty ? null : _tmuxController.text.trim(),
        autoAttachTmux: _autoAttachTmux,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
