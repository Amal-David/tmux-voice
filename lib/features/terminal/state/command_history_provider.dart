import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/command_history_state.dart';

class CommandHistoryNotifier extends StateNotifier<CommandHistoryState> {
  CommandHistoryNotifier() : super(CommandHistoryState.empty) {
    _load();
  }

  static const _historyKey = 'command_history';
  static const _frequencyKey = 'command_frequency';

  SharedPreferences? _prefs;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final recent = prefs.getStringList(_historyKey) ?? <String>[];
    final frequencyRaw = prefs.getString(_frequencyKey);
    final frequency = <String, int>{};
    if (frequencyRaw != null) {
      final decoded = jsonDecode(frequencyRaw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        frequency[entry.key] = (entry.value as num).toInt();
      }
    }
    state = CommandHistoryState(recent: recent, frequency: frequency);
  }

  Future<void> recordCommand(String command) async {
    final trimmed = command.trim();
    if (trimmed.isEmpty) return;

    final updatedRecent = [
      trimmed,
      ...state.recent.where((existing) => existing != trimmed),
    ];
    final limitedRecent = updatedRecent.length > 20 ? updatedRecent.sublist(0, 20) : updatedRecent;
    final updatedFrequency = {...state.frequency};
    updatedFrequency[trimmed] = (updatedFrequency[trimmed] ?? 0) + 1;

    state = CommandHistoryState(recent: limitedRecent, frequency: updatedFrequency);
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, limitedRecent);
    await prefs.setString(_frequencyKey, jsonEncode(updatedFrequency));
  }
}

final commandHistoryProvider =
    StateNotifierProvider<CommandHistoryNotifier, CommandHistoryState>((ref) {
  return CommandHistoryNotifier();
});
