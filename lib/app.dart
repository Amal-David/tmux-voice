import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'features/home/views/connections_page.dart';

class TmuxVoiceApp extends StatelessWidget {
  const TmuxVoiceApp({super.key});

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
