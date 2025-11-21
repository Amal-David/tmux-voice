import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme.dart';
import '../../ssh/models/ssh_session_state.dart';
import '../../ssh/state/ssh_providers.dart';
import 'terminal_page.dart';

class TerminalLoadingPage extends ConsumerStatefulWidget {
  const TerminalLoadingPage({
    super.key,
    required this.sessionId,
    required this.sessionLabel,
  });

  final String sessionId;
  final String sessionLabel;

  @override
  ConsumerState<TerminalLoadingPage> createState() => _TerminalLoadingPageState();
}

class _TerminalLoadingPageState extends ConsumerState<TerminalLoadingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _hasNavigated = false;
  bool _minDelayComplete = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    // Minimum delay to show loading animation (user feedback)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _minDelayComplete = true);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sshSessionsProvider);
    final session = _findSession(sessions);

    // Auto-navigate when connected AND minimum delay is complete (for user feedback)
    if (session != null &&
        session.status == SshSessionStatus.connected &&
        _minDelayComplete &&
        !_hasNavigated) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  TerminalPage(sessionId: widget.sessionId),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
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
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      });
    }

    // Show error if connection failed
    if (session != null && session.status == SshSessionStatus.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                session.errorMessage ?? 'Connection failed',
              ),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AnimatedConnectingIcon(animation: _animationController),
              const SizedBox(height: 40),
              Text(
                'Connecting to',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.sessionLabel,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 40),
              _LoadingDots(animation: _animationController),
              const SizedBox(height: 20),
              Text(
                _getLoadingMessage(session),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SshSessionState? _findSession(List<SshSessionState> sessions) {
    for (final session in sessions) {
      if (session.id == widget.sessionId) {
        return session;
      }
    }
    return null;
  }

  String _getLoadingMessage(SshSessionState? session) {
    if (session == null) {
      return 'Initializing session...';
    }

    switch (session.status) {
      case SshSessionStatus.connecting:
        return 'Establishing secure connection...';
      case SshSessionStatus.connected:
        return 'Opening terminal...';
      case SshSessionStatus.disconnected:
        return 'Reconnecting...';
      case SshSessionStatus.error:
        return 'Connection failed';
    }
  }
}

class _AnimatedConnectingIcon extends StatelessWidget {
  const _AnimatedConnectingIcon({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulsing circle
            Transform.scale(
              scale: 1.0 + (math.sin(animation.value * math.pi * 2) * 0.15),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryPurple.withOpacity(0.3),
                      AppTheme.primaryPurple.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Middle rotating circle
            Transform.rotate(
              angle: animation.value * math.pi * 2,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
            ),
            // Inner icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.purpleSoftGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.terminal,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (animation.value + delay) % 1.0;
            final scale = math.sin(value * math.pi);
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: 0.5 + (scale * 0.5),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.5 + (scale * 0.5)),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
