import 'package:flutter/material.dart';

class InputAccessoryBar extends StatelessWidget {
  const InputAccessoryBar({
    super.key,
    required this.onKeyTap,
  });

  final ValueChanged<String> onKeyTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _KeyButton(label: 'Esc', onTap: () => onKeyTap('\x1b')),
          _KeyButton(label: 'Tab', onTap: () => onKeyTap('\t')),
          _KeyButton(label: 'Ctrl+C', onTap: () => onKeyTap('\x03')),
          _KeyButton(label: 'Ctrl+D', onTap: () => onKeyTap('\x04')),
          _KeyButton(label: 'Ctrl+Z', onTap: () => onKeyTap('\x1a')),
          _KeyButton(label: 'Ctrl+L', onTap: () => onKeyTap('\x0c')),
          const SizedBox(width: 8),
          _KeyButton(icon: Icons.arrow_upward, onTap: () => onKeyTap('\x1b[A')),
          _KeyButton(icon: Icons.arrow_downward, onTap: () => onKeyTap('\x1b[B')),
          _KeyButton(icon: Icons.arrow_forward, onTap: () => onKeyTap('\x1b[C')),
          _KeyButton(icon: Icons.arrow_back, onTap: () => onKeyTap('\x1b[D')),
          const SizedBox(width: 8),
          _KeyButton(label: '/', onTap: () => onKeyTap('/')),
          _KeyButton(label: '~', onTap: () => onKeyTap('~')),
          _KeyButton(label: '|', onTap: () => onKeyTap('|')),
          _KeyButton(label: '-', onTap: () => onKeyTap('-')),
          _KeyButton(label: '`', onTap: () => onKeyTap('`')),
          _KeyButton(label: '=', onTap: () => onKeyTap('=')),
          _KeyButton(label: '<', onTap: () => onKeyTap('<')),
          _KeyButton(label: '>', onTap: () => onKeyTap('>')),
          _KeyButton(label: '&', onTap: () => onKeyTap('&')),
          _KeyButton(label: '!', onTap: () => onKeyTap('!')),
          _KeyButton(label: r'$', onTap: () => onKeyTap(r'$')),
        ],
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    this.label,
    this.icon,
    required this.onTap,
  }) : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Material(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: icon != null
                ? Icon(icon, size: 18, color: Colors.white)
                : Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
