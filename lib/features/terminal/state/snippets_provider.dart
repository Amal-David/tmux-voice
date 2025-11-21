import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/terminal_settings.dart';
import 'terminal_settings_provider.dart';

class SnippetsNotifier extends StateNotifier<List<CommandSnippet>> {
  SnippetsNotifier(this._prefs) : super([]) {
    _loadSnippets();
  }

  final SharedPreferences _prefs;
  static const _key = 'command_snippets';
  final _uuid = const Uuid();

  Future<void> _loadSnippets() async {
    final json = _prefs.getString(_key);
    if (json != null) {
      try {
        final List<dynamic> list = jsonDecode(json);
        state = list.map((item) => CommandSnippet.fromJson(item)).toList();
      } catch (_) {
        // Load defaults if parsing fails
        state = DefaultSnippets.defaults;
        await _saveSnippets();
      }
    } else {
      // First time - load defaults
      state = DefaultSnippets.defaults;
      await _saveSnippets();
    }
  }

  Future<void> _saveSnippets() async {
    final json = jsonEncode(state.map((snippet) => snippet.toJson()).toList());
    await _prefs.setString(_key, json);
  }

  Future<void> addSnippet({
    required String name,
    required String template,
    required List<String> variables,
    String? description,
  }) async {
    final newSnippet = CommandSnippet(
      id: _uuid.v4(),
      name: name,
      template: template,
      variables: variables,
      description: description,
    );
    state = [...state, newSnippet];
    await _saveSnippets();
  }

  Future<void> deleteSnippet(String id) async {
    state = state.where((snippet) => snippet.id != id).toList();
    await _saveSnippets();
  }

  Future<void> resetToDefaults() async {
    state = DefaultSnippets.defaults;
    await _saveSnippets();
  }
}

final snippetsProvider =
    StateNotifierProvider<SnippetsNotifier, List<CommandSnippet>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SnippetsNotifier(prefs);
});
