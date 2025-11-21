import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_theme.dart';
import 'features/home/views/connections_page.dart';
import 'features/ssh/models/ssh_profile.dart';
import 'features/ssh/state/ssh_providers.dart';
import 'features/terminal/state/uptime_monitor_provider.dart';

class TmuxVoiceApp extends ConsumerStatefulWidget {
  const TmuxVoiceApp({super.key});

  @override
  ConsumerState<TmuxVoiceApp> createState() => _TmuxVoiceAppState();
}

class _TmuxVoiceAppState extends ConsumerState<TmuxVoiceApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(uptimeMonitorProvider).ensureInitialized();
      final initial = ref.read(profilesProvider);
      initial.whenData((profiles) {
        ref.read(uptimeMonitorProvider).updateWatchlist(profiles);
      });
      ref.listen<AsyncValue<List<SshProfile>>>(
        profilesProvider,
        (_, next) {
          next.whenData((profiles) {
            ref.read(uptimeMonitorProvider).updateWatchlist(profiles);
          });
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tmux-voice',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ConnectionsPage(),
    );
  }
}
