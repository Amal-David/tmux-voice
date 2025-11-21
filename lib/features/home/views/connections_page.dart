import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/gradient_card.dart';
import '../../../core/widgets/believe_button.dart';
import '../../../core/widgets/believe_text_field.dart';
import '../../../core/widgets/believe_dialog.dart';
import '../../../core/widgets/believe_loading_dialog.dart';
import '../../../core/utils/ssh_url_parser.dart';
import '../../../core/utils/ppk_converter.dart';
import '../../../core/utils/pem_validator.dart';
import '../../settings/views/voice_settings_page.dart';
import '../../ssh/models/ssh_profile.dart';
import '../../ssh/models/ssh_session_state.dart';
import '../../ssh/services/ssh_repository.dart';
import '../../ssh/services/sessions_persistence.dart';
import '../../ssh/services/profiles_storage.dart';
import '../../ssh/state/ssh_providers.dart';
import '../../monitoring/views/monitoring_page.dart';
import '../../terminal/views/terminal_loading_page.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('tmux-voice'),
        actions: [
          IconButton(
            tooltip: 'Monitoring',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceFilled,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.monitor_heart_outlined, size: 20),
            ),
            onPressed: () => _showMonitoring(context),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceFilled,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.settings_outlined, size: 20),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VoiceSettingsPage()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundBase,
              AppTheme.primaryPurple.withOpacity(0.03),
              AppTheme.backgroundBase,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
            children: [
              const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: AppTheme.purpleSoftGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.terminal, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                'Terminal Sessions',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          StackedSessionDeck(
            sessions: sessions,
            isRestoring: isRestoringSessions,
            selectedSessionId: selectedSessionId,
            onSelect: (session) => ref.read(selectedSessionIdProvider.notifier).state = session.id,
            onOpen: (session) => _openTerminal(context, ref, session.id),
            onDisconnect: (session) => _disconnect(context, ref, session.id),
            onRetry: (session) => ref.read(sshSessionsProvider.notifier).reconnect(session.id),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: AppTheme.tealGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud_outlined, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                'Saved Profiles',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
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
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 300 + (i * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: _ProfileCard(
                        profile: profiles[i],
                        onConnect: () => _connect(context, ref, profiles[i]),
                        onDelete: () => _deleteProfile(context, ref, i),
                        onEdit: () => _editProfile(context, ref, profiles[i], i),
                        onUptime: () => _showUptimeQuickSheet(context, ref, profiles[i], i),
                      ),
                    ),
                ],
              );
            },
            loading: () => const _SectionLoading(),
            error: (error, _) => _ErrorState(message: 'Failed to load profiles ($error)'),
          ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.purpleSoftGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPurple.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: canModifyProfiles ? () => _openProfileSheet(context, ref) : null,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text('New Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
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

    print('[Profile Debug] Saving profile:');
    print('[Profile Debug] - Label: ${profile.label}');
    print('[Profile Debug] - Host: ${profile.host}');
    print('[Profile Debug] - Username: ${profile.username}');
    print('[Profile Debug] - Password length: ${profile.password?.length ?? 0}');
    print('[Profile Debug] - Private key length: ${profile.privateKey?.length ?? 0}');
    print('[Profile Debug] - Private key starts with: ${profile.privateKey?.substring(0, 30) ?? "null"}');

    await notifier.addProfile(profile);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    }
  }

  Future<void> _connect(BuildContext context, WidgetRef ref, SshProfile profile) async {
    final notifier = ref.read(sshSessionsProvider.notifier);
    
    print('[Connect Debug] Connecting with profile:');
    print('[Connect Debug] - Label: ${profile.label}');
    print('[Connect Debug] - Host: ${profile.host}');
    print('[Connect Debug] - Username: ${profile.username}');
    print('[Connect Debug] - Password length: ${profile.password?.length ?? 0}');
    print('[Connect Debug] - Private key length: ${profile.privateKey?.length ?? 0}');
    print('[Connect Debug] - Private key starts with: ${profile.privateKey?.substring(0, 30) ?? "null"}');
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BelieveLoadingDialog(
        message: 'Connecting...',
      ),
    );
    
    try {
      final sessionId = await notifier.connect(profile);
      ref.read(selectedSessionIdProvider.notifier).state = sessionId;
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${profile.label}'), backgroundColor: AppTheme.successGreen),
        );
        _openTerminal(context, ref, sessionId);
      }
    } catch (error) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        
        String errorMsg = error.toString().replaceAll('Exception: ', '');
        String? debugLogs;
        
        if (error is SshConnectionException) {
          errorMsg = error.message;
          debugLogs = error.logs;
        }
        
        showDialog(
          context: context,
          builder: (context) => BelieveDialog(
            title: 'Connection Failed',
            icon: CupertinoIcons.xmark_circle,
            iconColor: AppTheme.errorRed,
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(errorMsg, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  if (debugLogs != null) ...[
                    const Text('Debug Logs:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          debugLogs,
                          style: const TextStyle(
                            fontSize: 11, 
                            fontFamily: 'Courier', 
                            color: Colors.greenAccent,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Common fixes:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          Text(
                            '• Verify username and password\n'
                            '• Check private key format (PEM)\n'
                            '• Ensure host and port are correct\n'
                            '• Check server SSH config allows key auth',
                            style: TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              BelieveButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }

  void _showMonitoring(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MonitoringPage(),
      ),
    );
  }

  void _openTerminal(BuildContext context, WidgetRef ref, String sessionId) {
    // Find session to get the label
    final sessions = ref.read(sshSessionsProvider);
    final session = sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => sessions.first,
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TerminalLoadingPage(
          sessionId: sessionId,
          sessionLabel: session.profile.label,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
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

  Future<void> _showUptimeQuickSheet(
    BuildContext context,
    WidgetRef ref,
    SshProfile profile,
    int index,
  ) async {
    bool enabled = profile.monitorUptime;
    int minutes = profile.uptimeIntervalMinutes;

    final result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Uptime monitor', style: Theme.of(context).textTheme.titleLarge),
                    CupertinoSwitch(
                      value: enabled,
                      onChanged: (value) => setState(() => enabled = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (enabled)
                  SizedBox(
                    height: 200,
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      minuteInterval: 5,
                      initialTimerDuration: Duration(minutes: minutes.clamp(15, 240)),
                      onTimerDurationChanged: (duration) =>
                          setState(() => minutes = duration.inMinutes.clamp(15, 240)),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Monitoring disabled', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (result == true) {
      final updated = profile.copyWith(
        monitorUptime: enabled,
        uptimeIntervalMinutes: minutes,
      );
      await ref.read(profilesProvider.notifier).updateProfile(index, updated);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Monitoring every $minutes minutes'
                  : 'Uptime monitor disabled for ${profile.label}',
            ),
          ),
        );
      }
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onConnect,
    required this.onDelete,
    required this.onEdit,
    required this.onUptime,
  });

  final SshProfile profile;
  final VoidCallback onConnect;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onUptime;

  @override
  Widget build(BuildContext context) {
    return BelieveCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.purpleSoftGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.dns_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.label,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.username}@${profile.host}:${profile.port}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Uptime monitor',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: profile.monitorUptime ? AppTheme.successGreen.withOpacity(0.15) : AppTheme.surfaceFilled,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    profile.monitorUptime ? Icons.monitor_heart : Icons.monitor_heart_outlined,
                    size: 18,
                    color: profile.monitorUptime ? AppTheme.successGreen : AppTheme.textSecondary,
                  ),
                ),
                onPressed: onUptime,
              ),
              IconButton(
                tooltip: 'Edit',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceFilled,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_outlined, size: 18),
                ),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Delete',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                ),
                onPressed: onDelete,
              ),
            ],
          ),
          if (profile.tmuxSession != null && profile.tmuxSession!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.accentTeal.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.view_compact_alt_outlined, size: 16, color: AppTheme.accentTeal),
                  const SizedBox(width: 6),
                  Text(
                    'tmux: ${profile.tmuxSession}',
                    style: TextStyle(color: AppTheme.accentTeal, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.purpleSoftGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: BelieveButton(
                onPressed: onConnect,
                isFullWidth: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(CupertinoIcons.play_fill, size: 18),
                    SizedBox(width: 8),
                    Text('Connect Now'),
                  ],
                ),
              ),
            ),
          ),
        ],
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
  bool _monitorUptime = false;
  int _uptimeIntervalMinutes = 15;

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
    _monitorUptime = initial?.monitorUptime ?? false;
    _uptimeIntervalMinutes = initial?.uptimeIntervalMinutes ?? 15;
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
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
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      icon: const Icon(CupertinoIcons.back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.initialProfile == null ? 'New Connection' : 'Edit Connection',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(CupertinoIcons.clear_thick),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // SSH URL Quick Connect
                BelieveTextField(
                  label: 'Quick Connect (Optional)',
                  hint: 'ssh://user@host:port or user@host',
                  prefixIcon: const Icon(CupertinoIcons.link),
                  onChanged: (url) {
                    final parsed = SshUrlParser.parse(url);
                    if (parsed != null) {
                      if (parsed.username != null) {
                        _usernameController.text = parsed.username!;
                      }
                      _hostController.text = parsed.host;
                      _portController.text = parsed.port.toString();
                    }
                  },
                ),
                const SizedBox(height: 20),
                
                BelieveTextField(
                  controller: _labelController,
                  label: 'Label',
                  hint: 'My Server',
                  prefixIcon: const Icon(CupertinoIcons.tag),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                // Host + Port Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: BelieveTextField(
                        controller: _hostController,
                        label: 'Host',
                        hint: 'server.example.com',
                        prefixIcon: const Icon(CupertinoIcons.globe),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: BelieveTextField(
                        controller: _portController,
                        label: 'Port',
                        hint: '22',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final port = int.tryParse(value ?? '');
                          if (port == null || port <= 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Username + Password Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: BelieveTextField(
                        controller: _usernameController,
                        label: 'Username',
                        hint: 'admin',
                        prefixIcon: const Icon(CupertinoIcons.person),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BelieveTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Optional',
                        prefixIcon: const Icon(CupertinoIcons.lock),
                        obscureText: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Private Key Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceFilled.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(CupertinoIcons.lock_shield, size: 18, color: AppTheme.primaryPurple),
                          SizedBox(width: 8),
                          Text(
                            'Private Key Authentication',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                BelieveTextField(
                  controller: _privateKeyController,
                  hint: 'Paste PEM key or select file below',
                  minLines: 3,
                  maxLines: 5,
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _privateKeyController,
                  builder: (context, value, _) {
                    final text = value.text.trim();
                    if (text.isEmpty) return const SizedBox.shrink();
                    final preview = text.length > 80 ? '${text.substring(0, 80)}…' : text;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        preview,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                BelieveSecondaryButton(
                  onPressed: _pickPrivateKeyFile,
                  child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(CupertinoIcons.folder, size: 18),
                            SizedBox(width: 8),
                            Text('Choose Key File (PEM/PPK)'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Tmux Settings
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceFilled.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(CupertinoIcons.square_split_2x1, size: 18, color: AppTheme.accentTeal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Auto attach to tmux',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CupertinoSwitch(
                                value: _autoAttachTmux,
                                activeColor: AppTheme.accentTeal,
                                onChanged: (value) => setState(() => _autoAttachTmux = value),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Monitor uptime', style: TextStyle(color: AppTheme.textSecondary)),
                                  const SizedBox(width: 8),
                                  CupertinoSwitch(
                                    value: _monitorUptime,
                                    activeColor: AppTheme.successGreen,
                                    onChanged: (value) => _onToggleUptime(value),
                                  ),
                                ],
                              ),
                              if (_monitorUptime) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Checks every $_uptimeIntervalMinutes min',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      if (_autoAttachTmux) ...[
                        const SizedBox(height: 16),
                        BelieveTextField(
                          controller: _tmuxController,
                          hint: 'session-name (optional)',
                          prefixIcon: const Icon(CupertinoIcons.textformat),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                BelieveButton(
                  onPressed: _submit,
                  isFullWidth: true,
                  child: Text(widget.initialProfile == null ? 'Save Profile' : 'Save Changes'),
                )
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPrivateKeyFile() async {
    print('[FilePicker Debug] === FILE PICKER OPENED ===');
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pem', 'ppk', 'key', 'cer', 'crt'],
        withData: true,
        allowMultiple: false,
      );

      print('[FilePicker Debug] Result: ${result != null ? "Got file" : "Cancelled"}');

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('[FilePicker Debug] File name: ${file.name}');
        print('[FilePicker Debug] File size: ${file.size} bytes');
        if (file.bytes != null && file.bytes!.isNotEmpty) {
          String content = utf8.decode(file.bytes!);
          print('[FilePicker Debug] Content length: ${content.length} chars');
          print('[FilePicker Debug] Content starts: ${content.substring(0, 30)}');
          
          // Auto-convert PPK to PEM
          if (PpkConverter.isPpkFile(content)) {
            final converted = PpkConverter.convertPpkToPem(content);
            if (converted != null) {
              content = converted;
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ PPK file converted to PEM format'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            }
          }
          
          // Validate PEM format
          final validation = PemValidator.validatePrivateKey(content);
          
          if (!validation.isValid) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    children: const [
                      Icon(CupertinoIcons.xmark_circle, color: AppTheme.errorRed, size: 24),
                      SizedBox(width: 12),
                      Text('Invalid Key'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(validation.error ?? 'Unknown error', style: const TextStyle(fontSize: 15)),
                      if (validation.suggestion != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            validation.suggestion!,
                            style: const TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    BelieveButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                  ],
                ),
              );
            }
            return;
          }
          
          final finalKey = validation.cleanedKey ?? content;
          print('[FilePicker Debug] Setting text field to ${finalKey.length} chars');
          
          setState(() {
            _privateKeyController.text = finalKey;
          });
          
          print('[FilePicker Debug] Text field now contains: ${_privateKeyController.text.length} chars');
          print('[FilePicker Debug] Text field preview: ${_privateKeyController.text.isEmpty ? "EMPTY!" : _privateKeyController.text.substring(0, 30)}');
          
          if (mounted && validation.keyType != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ ${validation.keyType} key loaded successfully'),
                backgroundColor: AppTheme.successGreen,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading file: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _onToggleUptime(bool value) async {
    if (!value) {
      setState(() {
        _monitorUptime = false;
      });
      return;
    }

    final interval = await _pickUptimeInterval();
    if (interval == null) return;
    setState(() {
      _monitorUptime = true;
      _uptimeIntervalMinutes = interval;
    });
  }

  Future<int?> _pickUptimeInterval() async {
    int tempMinutes = _uptimeIntervalMinutes;
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: 320,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const Text('Check every', style: TextStyle(fontWeight: FontWeight.w600)),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(tempMinutes),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      minuteInterval: 5,
                      initialTimerDuration: Duration(minutes: tempMinutes.clamp(15, 240)),
                      onTimerDurationChanged: (duration) {
                        setModalState(() {
                          tempMinutes = duration.inMinutes.clamp(15, 240);
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Current: $tempMinutes minutes',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _submit() {
    print('[Form Debug] === FORM SUBMIT CALLED ===');
    print('[Form Debug] Label controller: "${_labelController.text}"');
    print('[Form Debug] Host controller: "${_hostController.text}"');
    print('[Form Debug] Username controller: "${_usernameController.text}"');
    print('[Form Debug] Password controller length: ${_passwordController.text.length}');
    print('[Form Debug] Private key controller length: ${_privateKeyController.text.length}');
    print('[Form Debug] Private key starts: ${_privateKeyController.text.isEmpty ? "EMPTY" : _privateKeyController.text.substring(0, 30)}');
    
    if (!_formKey.currentState!.validate()) return;
    
    // Validate private key if provided
    final privateKeyText = _privateKeyController.text.trim();
    final passwordText = _passwordController.text.trim();
    print('[Form Debug] After trim, private key length: ${privateKeyText.length}');
    if (privateKeyText.isNotEmpty) {
      final validation = PemValidator.validatePrivateKey(privateKeyText);
      if (!validation.isValid) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(CupertinoIcons.xmark_circle, color: AppTheme.errorRed, size: 24),
                SizedBox(width: 12),
                Text('Invalid Private Key'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(validation.error ?? 'Unknown error', style: const TextStyle(fontSize: 15)),
                if (validation.suggestion != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      validation.suggestion!,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              BelieveButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          ),
        );
        return;
      }
    }

    if (passwordText.isEmpty && privateKeyText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Provide a password or a private key to connect.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
      return;
    }
    
    // Dismiss keyboard before closing (iOS fix)
    FocusScope.of(context).unfocus();
    
    final profile = SshProfile(
      label: _labelController.text.trim(),
      host: _hostController.text.trim(),
      port: int.parse(_portController.text.trim()),
      username: _usernameController.text.trim(),
      password: passwordText.isEmpty ? null : passwordText,
      privateKey: privateKeyText.isEmpty ? null : privateKeyText,
      tmuxSession: _tmuxController.text.trim().isEmpty ? null : _tmuxController.text.trim(),
      autoAttachTmux: _autoAttachTmux,
      monitorUptime: _monitorUptime,
      uptimeIntervalMinutes: _uptimeIntervalMinutes,
    );
    
    print('[Form Debug] === PROFILE CREATED ===');
    print('[Form Debug] Profile password length: ${profile.password?.length ?? 0}');
    print('[Form Debug] Profile private key length: ${profile.privateKey?.length ?? 0}');
    print('[Form Debug] Profile private key preview: ${profile.privateKey?.substring(0, 30) ?? "NULL"}');
    
    Navigator.of(context).pop(profile);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.elevation1,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryPurple.withOpacity(0.05),
            ),
            child: Icon(Icons.dns_outlined, size: 48, color: AppTheme.primaryPurple.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.1),
            ),
            child: const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
          ),
        ],
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
