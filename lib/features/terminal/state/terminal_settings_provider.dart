import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/terminal_settings.dart';

class TerminalSettingsNotifier extends StateNotifier<TerminalSettings> {
  TerminalSettingsNotifier(this._prefs) : super(TerminalSettings.defaults) {
    _loadSettings();
  }

  final SharedPreferences _prefs;
  static const _key = 'terminal_settings';

  Future<void> _loadSettings() async {
    final json = _prefs.getString(_key);
    if (json != null) {
      try {
        state = TerminalSettings.fromJson(jsonDecode(json));
      } catch (_) {
        // If parsing fails, keep defaults
      }
    }
  }

  Future<void> _saveSettings() async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> updateTheme(String themeId) async {
    state = state.copyWith(themeId: themeId);
    await _saveSettings();
  }

  Future<void> updateFontSize(double fontSize) async {
    state = state.copyWith(fontSize: fontSize);
    await _saveSettings();
  }

  Future<void> updateFontFamily(String fontFamily) async {
    state = state.copyWith(fontFamily: fontFamily);
    await _saveSettings();
  }

  Future<void> updateCursorStyle(CursorStyle style) async {
    state = state.copyWith(cursorStyle: style);
    await _saveSettings();
  }

  Future<void> updateCursorBlink(bool blink) async {
    state = state.copyWith(cursorBlink: blink);
    await _saveSettings();
  }

  Future<void> updatePadding(int padding) async {
    state = state.copyWith(terminalPadding: padding);
    await _saveSettings();
  }

  Future<void> updateLineHeight(double lineHeight) async {
    state = state.copyWith(lineHeight: lineHeight);
    await _saveSettings();
  }
}

final terminalSettingsProvider =
    StateNotifierProvider<TerminalSettingsNotifier, TerminalSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TerminalSettingsNotifier(prefs);
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});
