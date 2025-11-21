
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ssh/models/ssh_session_state.dart';
import '../../../core/app_theme.dart';

class StackedSessionDeck extends StatelessWidget {
  const StackedSessionDeck({
    super.key,
    required this.sessions,
    required this.isRestoring,
    required this.selectedSessionId,
    required this.onSelect,
    required this.onOpen,
    required this.onDisconnect,
    this.onRetry,
  });

  final List<SshSessionState> sessions;
  final bool isRestoring;
  final String? selectedSessionId;
  final ValueChanged<SshSessionState> onSelect;
  final ValueChanged<SshSessionState> onOpen;
  final ValueChanged<SshSessionState> onDisconnect;
  final ValueChanged<SshSessionState>? onRetry;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      if (isRestoring) {
        return const _DeckLoadingPlaceholder();
      }
      return const _DeckEmptyState();
    }

    final sorted = [...sessions]
      ..sort((a, b) => b.connectedAt.compareTo(a.connectedAt));
    final visible = sorted.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 280,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = visible.length - 1; i >= 0; i--)
                _DeckCard(
                  key: ValueKey('deck-card-${visible[i].id}'),
                  session: visible[i],
                  index: i,
                  isNow: i == 0,
                  isSelected: visible[i].id == selectedSessionId,
                  onTap: () {
                    onSelect(visible[i]);
                    onOpen(visible[i]);
                  },
                  onOpen: () {
                    onSelect(visible[i]);
                    onOpen(visible[i]);
                  },
                  onDisconnect: () => onDisconnect(visible[i]),
                  onRetry: visible[i].status == SshSessionStatus.error && onRetry != null
                      ? () => onRetry!(visible[i])
                      : null,
                ),
            ],
          ),
        ),
        if (sorted.length > 3) ...[
          const SizedBox(height: 24),
          Text(
            'Earlier Sessions',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          ...sorted.skip(3).map(
                (session) => _HistoryChip(
                  session: session,
                  onTap: () {
                    onSelect(session);
                    onOpen(session);
                  },
                ),
              ),
        ],
      ],
    );
  }
}

class _DeckCard extends StatefulWidget {
  const _DeckCard({
    super.key,
    required this.session,
    required this.index,
    required this.isNow,
    required this.isSelected,
    required this.onTap,
    required this.onOpen,
    required this.onDisconnect,
    this.onRetry,
  });

  final SshSessionState session;
  final int index;
  final bool isNow;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onOpen;
  final VoidCallback onDisconnect;
  final VoidCallback? onRetry;

  @override
  State<_DeckCard> createState() => _DeckCardState();
}

class _DeckCardState extends State<_DeckCard> {
  static const _baseHeight = 230.0;
  bool _isPressed = false;
  double _dragExtent = 0;

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _handleTapDown(_) => setState(() => _isPressed = true);

  void _handleTapEnd(_) => setState(() => _isPressed = false);

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragExtent += -details.delta.dy;
    if (_dragExtent < 0) _dragExtent = 0;
    if (_dragExtent > 160) _dragExtent = 160;
    setState(() {});
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragExtent > 80 || velocity < -400) {
      widget.onOpen();
    }
    setState(() => _dragExtent = 0);
  }

  @override
  Widget build(BuildContext context) {
    final offset = 12.0 * widget.index - _dragExtent * 0.4;
    final scale = (1 - 0.02 * widget.index) + (_dragExtent / 400);
    final opacity = 1 - 0.08 * widget.index;

    final card = Transform.translate(
      offset: Offset(0, offset),
      child: Transform.scale(
        scale: _isPressed ? scale * 0.98 : scale,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: opacity,
          child: _CardSurface(
            session: widget.session,
            isNow: widget.isNow,
            isSelected: widget.isSelected,
            onDisconnect: widget.onDisconnect,
            onRetry: widget.onRetry,
            onOpen: widget.onOpen,
          ),
        ),
      ),
    );

    if (!widget.isNow) {
      return card;
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapEnd,
      onTapCancel: () => _handleTapEnd(null),
      onTap: _handleTap,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: card,
    );
  }
}

class _CardSurface extends StatelessWidget {
  const _CardSurface({
    required this.session,
    required this.isNow,
    required this.isSelected,
    required this.onDisconnect,
    required this.onOpen,
    this.onRetry,
  });

  final SshSessionState session;
  final bool isNow;
  final bool isSelected;
  final VoidCallback onDisconnect;
  final VoidCallback onOpen;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    final radius = BorderRadius.circular(isNow ? 22 : 18);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: _DeckCardState._baseHeight,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: Colors.white.withOpacity(0.85),
            border: Border.all(
              color: Colors.white.withOpacity(isNow ? 0.6 : 0.4),
              width: 1,
            ),
            boxShadow: AppTheme.elevation1,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isNow)
                          Text(
                            'Now',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                            ),
                          ),
                        Text(
                          session.profile.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
              _StatusPill(status: session.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${session.profile.username}@${session.profile.host}:${session.profile.port}',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          if (session.lastCommand != null)
            Text(
              'Last: ${session.lastCommand}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
            )
          else
            Text(
              'Connected ${_timeString(session.connectedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
            ),
          const Spacer(),
          Row(
            children: [
              _DeckActionButton(
                icon: Icons.terminal,
                label: 'Open',
                onTap: onOpen,
              ),
              const SizedBox(width: 12),
              if (onRetry != null)
                _DeckActionButton(
                  icon: Icons.refresh,
                  label: 'Retry',
                  onTap: onRetry!,
                )
              else
                _DeckActionButton(
                  icon: Icons.logout,
                  label: 'Close',
                  onTap: onDisconnect,
                ),
              const Spacer(),
              if (isSelected)
                Icon(Icons.check_circle, color: Colors.white70)
              else
                const SizedBox.shrink(),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }

  static String _timeString(DateTime timestamp) {
    final minutes = timestamp.minute.toString().padLeft(2, '0');
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final suffix = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minutes $suffix';
  }
}

class _DeckActionButton extends StatelessWidget {
  const _DeckActionButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppTheme.textPrimary),
      label: Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        backgroundColor: AppTheme.surfaceFilled,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final SshSessionStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = {
      SshSessionStatus.connected: AppTheme.successGreen,
      SshSessionStatus.connecting: AppTheme.warningYellow,
      SshSessionStatus.disconnected: AppTheme.textTertiary,
      SshSessionStatus.error: AppTheme.errorRed,
    };
    final color = colors[status] ?? Colors.white70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.name,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({required this.session, required this.onTap});

  final SshSessionState session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
            color: const Color(0x11101520),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.profile.label, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${session.profile.username}@${session.profile.host}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckEmptyState extends StatelessWidget {
  const _DeckEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0x33101220), Color(0x22080A12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No sessions yet',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a profile and connect to spin up your first tmux session.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _DeckLoadingPlaceholder extends StatefulWidget {
  const _DeckLoadingPlaceholder();

  @override
  State<_DeckLoadingPlaceholder> createState() => _DeckLoadingPlaceholderState();
}

class _DeckLoadingPlaceholderState extends State<_DeckLoadingPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final alignment = Alignment(-1 + 2 * _controller.value, 0);
        return Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF111527), Color(0xFF090B14)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                colors: const [Colors.white10, Colors.white24, Colors.white10],
                stops: const [0.2, 0.5, 0.8],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                transform: GradientRotation(math.pi / 12),
                tileMode: TileMode.clamp,
              ).createShader(rect);
            },
            blendMode: BlendMode.srcATop,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: alignment,
                  end: alignment * -1,
                  colors: const [Colors.white10, Colors.white30, Colors.white10],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
