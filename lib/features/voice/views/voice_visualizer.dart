import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../models/voice_command_state.dart';

class VoiceVisualizer extends StatefulWidget {
  const VoiceVisualizer({
    super.key,
    required this.status,
  });

  final VoiceCommandStatus status;

  @override
  State<VoiceVisualizer> createState() => _VoiceVisualizerState();
}

class _VoiceVisualizerState extends State<VoiceVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.5, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status == VoiceCommandStatus.idle) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildVisualIndicator(),
          const SizedBox(width: 16),
          Expanded(child: _buildStatusText()),
        ],
      ),
    );
  }

  Widget _buildVisualIndicator() {
    switch (widget.status) {
      case VoiceCommandStatus.recording:
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryPurple.withOpacity(0.2),
              ),
              child: Center(
                child: Container(
                  width: 40 * _scaleAnimation.value * 0.8,
                  height: 40 * _scaleAnimation.value * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryPurple.withOpacity(_opacityAnimation.value),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPurple.withOpacity(0.4),
                        blurRadius: 10 * _scaleAnimation.value,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 20),
                ),
              ),
            );
          },
        );
      case VoiceCommandStatus.processing:
        return Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.accentTeal.withOpacity(0.1),
          ),
          child: const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentTeal),
          ),
        );
      case VoiceCommandStatus.success:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.successGreen.withOpacity(0.1),
          ),
          child: const Icon(Icons.check, color: AppTheme.successGreen),
        );
      case VoiceCommandStatus.error:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.errorRed.withOpacity(0.1),
          ),
          child: const Icon(Icons.priority_high, color: AppTheme.errorRed),
        );
      default:
        return const SizedBox(width: 40, height: 40);
    }
  }

  Widget _buildStatusText() {
    String text;
    TextStyle style = const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: AppTheme.textPrimary,
    );

    switch (widget.status) {
      case VoiceCommandStatus.recording:
        text = "Listening...";
        break;
      case VoiceCommandStatus.processing:
        text = "Thinking...";
        break;
      case VoiceCommandStatus.success:
        text = "Command sent!";
        style = style.copyWith(color: AppTheme.successGreen);
        break;
      case VoiceCommandStatus.error:
        text = "Something went wrong.";
        style = style.copyWith(color: AppTheme.errorRed);
        break;
      default:
        text = "";
    }

    return Text(text, style: style);
  }
}
