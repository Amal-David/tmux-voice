import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../app_theme.dart';

// Custom Believe-style text field (no Material Design)
class BelieveTextField extends StatefulWidget {
  const BelieveTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<BelieveTextField> createState() => _BelieveTextFieldState();
}

class _BelieveTextFieldState extends State<BelieveTextField> {
  bool _isFocused = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Focus(
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppTheme.surfaceFilled,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _errorText != null
                    ? AppTheme.errorRed
                    : _isFocused
                        ? AppTheme.primaryPurple
                        : Colors.transparent,
                width: _isFocused || _errorText != null ? 1.5 : 0,
              ),
            ),
            child: Row(
              children: [
                if (widget.prefixIcon != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: IconTheme(
                      data: const IconThemeData(
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                      child: widget.prefixIcon!,
                    ),
                  ),
                ],
                Expanded(
                  child: CupertinoTextField(
                    controller: widget.controller,
                    placeholder: widget.hint,
                    obscureText: widget.obscureText,
                    keyboardType: widget.keyboardType,
                    maxLines: widget.maxLines,
                    minLines: widget.minLines,
                    readOnly: widget.readOnly,
                    onTap: widget.onTap,
                    onChanged: (value) {
                      if (widget.validator != null) {
                        setState(() {
                          _errorText = widget.validator!(value);
                        });
                      }
                      widget.onChanged?.call(value);
                    },
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.prefixIcon == null ? 16 : 0,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      border: null,
                    ),
                    placeholderStyle: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                if (widget.suffixIcon != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 16, left: 8),
                    child: IconTheme(
                      data: const IconThemeData(
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                      child: widget.suffixIcon!,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            _errorText!,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.errorRed,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}
