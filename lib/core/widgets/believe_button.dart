import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../app_theme.dart';

// Custom Believe-style primary button (no Material Design)
class BelieveButton extends StatefulWidget {
  const BelieveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isFullWidth = false,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isFullWidth;
  final bool isLoading;

  @override
  State<BelieveButton> createState() => _BelieveButtonState();
}

class _BelieveButtonState extends State<BelieveButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: widget.isFullWidth ? double.infinity : null,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: widget.onPressed == null 
                ? AppTheme.textTertiary 
                : AppTheme.primaryPurple,
            borderRadius: BorderRadius.circular(26),
            boxShadow: widget.onPressed != null && !_isPressed
                ? [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: widget.isLoading
                ? const CupertinoActivityIndicator(color: Colors.white)
                : DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                    child: widget.child,
                  ),
          ),
        ),
      ),
    );
  }
}

// Custom Believe-style secondary button
class BelieveSecondaryButton extends StatefulWidget {
  const BelieveSecondaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isFullWidth = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isFullWidth;

  @override
  State<BelieveSecondaryButton> createState() => _BelieveSecondaryButtonState();
}

class _BelieveSecondaryButtonState extends State<BelieveSecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: widget.isFullWidth ? double.infinity : null,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: widget.onPressed == null
                  ? AppTheme.textTertiary
                  : AppTheme.primaryPurple.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: DefaultTextStyle(
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.onPressed == null 
                    ? AppTheme.textTertiary 
                    : AppTheme.primaryPurple,
                letterSpacing: 0,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Believe-style text button
class BelieveTextButton extends StatelessWidget {
  const BelieveTextButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: onPressed == null 
                ? AppTheme.textTertiary 
                : AppTheme.primaryPurple,
          ),
          child: child,
        ),
      ),
    );
  }
}
