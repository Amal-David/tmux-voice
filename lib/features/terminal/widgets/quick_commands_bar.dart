import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_theme.dart';

import '../models/terminal_settings.dart';
import '../state/quick_commands_provider.dart';

class QuickCommandsBar extends ConsumerWidget {
  const QuickCommandsBar({
    super.key,
    required this.onCommandTap,
  });

  final ValueChanged<String> onCommandTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commands = ref.watch(quickCommandsProvider);

    if (commands.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.textTertiary.withOpacity(0.1)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: commands.length + 1, // +1 for settings button
        itemBuilder: (context, index) {
          if (index == commands.length) {
            return _SettingsButton(
              onTap: () => _showQuickCommandsSettings(context, ref),
            );
          }

          final command = commands[index];
          return _CommandChip(
            label: command.label,
            onTap: () => onCommandTap(command.command),
          );
        },
      ),
    );
  }

  void _showQuickCommandsSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => const _QuickCommandsSheet(),
    );
  }
}

class _CommandChip extends StatelessWidget {
  const _CommandChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: AppTheme.accentPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
                color: AppTheme.activePurple,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        icon: const Icon(Icons.settings, size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        color: AppTheme.textSecondary,
      ),
    );
  }
}

class _QuickCommandsSheet extends ConsumerStatefulWidget {
  const _QuickCommandsSheet();

  @override
  ConsumerState<_QuickCommandsSheet> createState() => _QuickCommandsSheetState();
}

class _QuickCommandsSheetState extends ConsumerState<_QuickCommandsSheet> {
  @override
  Widget build(BuildContext context) {
    final commands = ref.watch(quickCommandsProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Quick Commands',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: commands.length,
                onReorder: (oldIndex, newIndex) {
                  ref.read(quickCommandsProvider.notifier).reorderCommands(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final command = commands[index];
                  return ListTile(
                    key: ValueKey(command.id),
                    leading: const Icon(Icons.drag_handle),
                    title: Text(command.label),
                    subtitle: Text(
                      command.command,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditDialog(context, command),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () =>
                              ref.read(quickCommandsProvider.notifier).deleteCommand(command.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final labelController = TextEditingController();
    final commandController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Quick Command'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'e.g., List Files',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commandController,
              decoration: const InputDecoration(
                labelText: 'Command',
                hintText: 'e.g., ls -la',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (labelController.text.isNotEmpty && commandController.text.isNotEmpty) {
                ref.read(quickCommandsProvider.notifier).addCommand(
                      labelController.text,
                      commandController.text,
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

  void _showEditDialog(BuildContext context, QuickCommand command) {
    final labelController = TextEditingController(text: command.label);
    final commandController = TextEditingController(text: command.command);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Quick Command'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commandController,
              decoration: const InputDecoration(labelText: 'Command'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (labelController.text.isNotEmpty && commandController.text.isNotEmpty) {
                ref.read(quickCommandsProvider.notifier).updateCommand(
                      command.id,
                      labelController.text,
                      commandController.text,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
