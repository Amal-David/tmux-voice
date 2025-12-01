import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme.dart';
import '../models/terminal_settings.dart';
import '../models/terminal_theme.dart';
import '../state/snippets_provider.dart';
import '../state/terminal_settings_provider.dart';

class TerminalSettingsPage extends ConsumerWidget {
  const TerminalSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(terminalSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminal Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Theme',
            icon: Icons.palette,
            child: _ThemeSelector(currentThemeId: settings.themeId),
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'Font',
            icon: Icons.text_fields,
            child: Column(
              children: [
                _FontSizeSlider(currentSize: settings.fontSize),
                const SizedBox(height: 16),
                _FontFamilyPicker(currentFont: settings.fontFamily),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'Cursor',
            icon: Icons.text_rotation_none,
            child: Column(
              children: [
                _CursorStylePicker(currentStyle: settings.cursorStyle),
                const SizedBox(height: 12),
                _CursorBlinkToggle(enabled: settings.cursorBlink),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'Visual',
            icon: Icons.tune,
            child: Column(
              children: [
                _PaddingSlider(currentPadding: settings.terminalPadding),
                const SizedBox(height: 16),
                _LineHeightSlider(currentHeight: settings.lineHeight),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryPurple),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector({required this.currentThemeId});

  final String currentThemeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: AppTerminalThemes.all.length,
      itemBuilder: (context, index) {
        final theme = AppTerminalThemes.all[index];
        final isSelected = theme.id == currentThemeId;

        return GestureDetector(
          onTap: () => ref.read(terminalSettingsProvider.notifier).updateTheme(theme.id),
          child: Container(
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppTheme.primaryPurple : Colors.white24,
                width: isSelected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                if (isSelected) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    theme.name,
                    style: TextStyle(
                      color: theme.foreground,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FontSizeSlider extends ConsumerWidget {
  const _FontSizeSlider({required this.currentSize});

  final double currentSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Size'),
            Text(
              '${currentSize.toStringAsFixed(0)}pt',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Slider(
          value: currentSize,
          min: 10,
          max: 24,
          divisions: 14,
          onChanged: (value) => ref.read(terminalSettingsProvider.notifier).updateFontSize(value),
        ),
      ],
    );
  }
}

class _FontFamilyPicker extends ConsumerWidget {
  const _FontFamilyPicker({required this.currentFont});

  final String currentFont;

  static const fonts = [
    'Courier',
    'Courier New',
    'Menlo',
    'Monaco',
    'Consolas',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Font Family'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: fonts.map((font) {
            final isSelected = font == currentFont;
            return ChoiceChip(
              label: Text(font),
              selected: isSelected,
              onSelected: (_) => ref.read(terminalSettingsProvider.notifier).updateFontFamily(font),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CursorStylePicker extends ConsumerWidget {
  const _CursorStylePicker({required this.currentStyle});

  final CursorStyle currentStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Style'),
        const SizedBox(height: 8),
        SegmentedButton<CursorStyle>(
          segments: const [
            ButtonSegment(value: CursorStyle.block, label: Text('Block')),
            ButtonSegment(value: CursorStyle.underline, label: Text('Underline')),
            ButtonSegment(value: CursorStyle.bar, label: Text('Bar')),
          ],
          selected: {currentStyle},
          onSelectionChanged: (Set<CursorStyle> selection) {
            ref.read(terminalSettingsProvider.notifier).updateCursorStyle(selection.first);
          },
        ),
      ],
    );
  }
}

class _CursorBlinkToggle extends ConsumerWidget {
  const _CursorBlinkToggle({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      title: const Text('Blinking'),
      value: enabled,
      onChanged: (value) => ref.read(terminalSettingsProvider.notifier).updateCursorBlink(value),
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _PaddingSlider extends ConsumerWidget {
  const _PaddingSlider({required this.currentPadding});

  final int currentPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Padding'),
            Text(
              '${currentPadding}px',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Slider(
          value: currentPadding.toDouble(),
          min: 0,
          max: 24,
          divisions: 24,
          onChanged: (value) => ref.read(terminalSettingsProvider.notifier).updatePadding(value.toInt()),
        ),
      ],
    );
  }
}

class _LineHeightSlider extends ConsumerWidget {
  const _LineHeightSlider({required this.currentHeight});

  final double currentHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Line Height'),
            Text(
              currentHeight.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Slider(
          value: currentHeight,
          min: 1.0,
          max: 2.0,
          divisions: 10,
          onChanged: (value) => ref.read(terminalSettingsProvider.notifier).updateLineHeight(value),
        ),
      ],
    );
  }
}

class _SnippetsManager extends ConsumerWidget {
  const _SnippetsManager();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snippets = ref.watch(snippetsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Reusable command templates with variables'),
            ),
            TextButton.icon(
              onPressed: () => _showAddSnippetDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (snippets.isEmpty)
          const Text('No snippets yet. Add one to get started!')
        else
          ...snippets.map((snippet) => _SnippetTile(snippet: snippet)),
      ],
    );
  }

  void _showAddSnippetDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final templateController = TextEditingController();
    final descController = TextEditingController();
    final variablesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Snippet'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., SSH to server',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: templateController,
                decoration: const InputDecoration(
                  labelText: 'Template',
                  hintText: 'e.g., ssh \${user}@\${host}',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: variablesController,
                decoration: const InputDecoration(
                  labelText: 'Variables (comma-separated)',
                  hintText: 'e.g., user,host',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && templateController.text.isNotEmpty) {
                final variables = variablesController.text
                    .split(',')
                    .map((v) => v.trim())
                    .where((v) => v.isNotEmpty)
                    .toList();

                ref.read(snippetsProvider.notifier).addSnippet(
                      name: nameController.text,
                      template: templateController.text,
                      variables: variables,
                      description: descController.text.isEmpty ? null : descController.text,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _SnippetTile extends ConsumerWidget {
  const _SnippetTile({required this.snippet});

  final CommandSnippet snippet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(snippet.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              snippet.template,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            if (snippet.description != null) ...[
              const SizedBox(height: 4),
              Text(
                snippet.description!,
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
            if (snippet.variables.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: snippet.variables
                    .map((v) => Chip(
                          label: Text('\$$v', style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, size: 20),
          onPressed: () => ref.read(snippetsProvider.notifier).deleteSnippet(snippet.id),
        ),
        onTap: () => _useSnippet(context, snippet),
      ),
    );
  }

  void _useSnippet(BuildContext context, CommandSnippet snippet) {
    if (snippet.variables.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final controllers = <String, TextEditingController>{};
    for (final variable in snippet.variables) {
      controllers[variable] = TextEditingController();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(snippet.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: snippet.variables.map((variable) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: controllers[variable],
                decoration: InputDecoration(
                  labelText: variable,
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final values = <String, String>{};
              for (final entry in controllers.entries) {
                values[entry.key] = entry.value.text;
              }
              final command = snippet.fillVariables(values);
              Navigator.pop(context);
              // TODO: Send command to terminal
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Command: $command')),
              );
            },
            child: const Text('Use'),
          ),
        ],
      ),
    );
  }
}
