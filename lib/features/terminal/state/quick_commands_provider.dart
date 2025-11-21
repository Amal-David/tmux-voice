import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/terminal_settings.dart';
import 'terminal_settings_provider.dart';

class QuickCommandsNotifier extends StateNotifier<List<QuickCommand>> {
  QuickCommandsNotifier(this._prefs) : super([]) {
    _loadCommands();
  }

  final SharedPreferences _prefs;
  static const _key = 'quick_commands';
  final _uuid = const Uuid();

  Future<void> _loadCommands() async {
    final json = _prefs.getString(_key);
    if (json != null) {
      try {
        final List<dynamic> list = jsonDecode(json);
        state = list.map((item) => QuickCommand.fromJson(item)).toList();
      } catch (_) {
        // Load defaults if parsing fails
        state = DefaultQuickCommands.defaults;
        await _saveCommands();
      }
    } else {
      // First time - load defaults
      state = DefaultQuickCommands.defaults;
      await _saveCommands();
    }
  }

  Future<void> _saveCommands() async {
    final json = jsonEncode(state.map((cmd) => cmd.toJson()).toList());
    await _prefs.setString(_key, json);
  }

  Future<void> addCommand(String label, String command) async {
    final newCommand = QuickCommand(
      id: _uuid.v4(),
      label: label,
      command: command,
      order: state.length,
    );
    state = [...state, newCommand];
    await _saveCommands();
  }

  Future<void> updateCommand(String id, String label, String command) async {
    state = [
      for (final cmd in state)
        if (cmd.id == id) cmd.copyWith(label: label, command: command) else cmd,
    ];
    await _saveCommands();
  }

  Future<void> deleteCommand(String id) async {
    state = state.where((cmd) => cmd.id != id).toList();
    await _saveCommands();
  }

  Future<void> reorderCommands(int oldIndex, int newIndex) async {
    final items = [...state];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    // Update order values
    state = [
      for (var i = 0; i < items.length; i++) items[i].copyWith(order: i),
    ];
    await _saveCommands();
  }

  Future<void> resetToDefaults() async {
    state = DefaultQuickCommands.defaults;
    await _saveCommands();
  }
}

final quickCommandsProvider =
    StateNotifierProvider<QuickCommandsNotifier, List<QuickCommand>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return QuickCommandsNotifier(prefs);
});
