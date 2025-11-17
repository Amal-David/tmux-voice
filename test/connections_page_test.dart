import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tmux_voice/app.dart';
import 'package:tmux_voice/core/providers/secure_storage_provider.dart';
import 'package:tmux_voice/core/services/secure_storage_service.dart';
import 'package:tmux_voice/features/settings/state/voice_settings_notifier.dart';
import 'package:tmux_voice/features/ssh/models/ssh_profile.dart';
import 'package:tmux_voice/features/ssh/services/profiles_storage.dart';
import 'package:tmux_voice/features/ssh/services/sessions_persistence.dart';
import 'package:tmux_voice/features/ssh/state/ssh_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders persisted profiles and loads UI', (tester) async {
    final secureStorage = _InMemorySecureStorage();
    await secureStorage.write(
      'profiles',
      jsonEncode([
        const SshProfile(
          label: 'Staging Server',
          host: 'staging.example.com',
          port: 22,
          username: 'deploy',
        ).toJson()
      ]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(secureStorage),
        child: const TmuxVoiceApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Connections'), findsOneWidget);
    expect(find.text('Staging Server'), findsOneWidget);
  });

  testWidgets('can add a new profile via the sheet', (tester) async {
    final secureStorage = _InMemorySecureStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(secureStorage),
        child: const TmuxVoiceApp(),
      ),
    );

    final profilesBefore = await secureStorage.read('profiles');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add profile'));
    await tester.pumpAndSettle();

    expect(find.text('New Connection'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Label'), 'Prod');
    await tester.enterText(find.widgetWithText(TextFormField, 'Host'), 'prod.example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Port'), '22');
    await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'root');

    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(find.text('Prod'), findsOneWidget);
    final stored = await secureStorage.read('profiles');
    expect(stored, isNotNull);
    expect(stored, isNot(equals(profilesBefore)));
  });
}

List<Override> _overrides(_InMemorySecureStorage storage) {
  return [
    secureStorageProvider.overrideWithValue(storage),
    profilesStorageProvider.overrideWith((ref) => ProfilesStorage(storage)),
    sessionsPersistenceProvider.overrideWithValue(SessionsPersistence(storage)),
    voiceSettingsProvider.overrideWith((ref) => VoiceSettingsNotifier(storage)),
  ];
}

class _InMemorySecureStorage extends SecureStorageService {
  _InMemorySecureStorage() : super();

  final Map<String, String> _store = {};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null || value.isEmpty) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }
}
