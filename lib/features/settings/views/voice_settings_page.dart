import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/voice_settings.dart';
import '../state/voice_settings_notifier.dart';

class VoiceSettingsPage extends ConsumerStatefulWidget {
  const VoiceSettingsPage({super.key});

  @override
  ConsumerState<VoiceSettingsPage> createState() => _VoiceSettingsPageState();
}

class _VoiceSettingsPageState extends ConsumerState<VoiceSettingsPage> {
  final _groqController = TextEditingController();
  final _geminiController = TextEditingController();

  @override
  void dispose() {
    _groqController.dispose();
    _geminiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(voiceSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Settings')),
      body: settingsAsync.when(
        data: (settings) {
          final groqValue = settings.groqApiKey ?? '';
          final geminiValue = settings.geminiApiKey ?? '';
          if (_groqController.text != groqValue) {
            _groqController.text = groqValue;
          }
          if (_geminiController.text != geminiValue) {
            _geminiController.text = geminiValue;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Speech-to-text provider'),
              const SizedBox(height: 8),
              DropdownButtonFormField<SttProvider>(
                value: settings.sttProvider,
                items: const [
                  DropdownMenuItem(
                    value: SttProvider.groqWhisper,
                    child: Text('Groq Whisper Large V3'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(voiceSettingsProvider.notifier).updateProviders(stt: value);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('LLM provider'),
              const SizedBox(height: 8),
              DropdownButtonFormField<LlmProvider>(
                value: settings.llmProvider,
                items: const [
                  DropdownMenuItem(value: LlmProvider.geminiFlash, child: Text('Gemini 2.0 Flash')),
                  DropdownMenuItem(value: LlmProvider.geminiPro, child: Text('Gemini 1.5 Pro')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(voiceSettingsProvider.notifier).updateProviders(llm: value);
                  }
                },
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _groqController,
                decoration: const InputDecoration(
                  labelText: 'Groq API Key',
                  hintText: 'sk-live-…',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onChanged: (value) => ref.read(voiceSettingsProvider.notifier).updateKeys(groqKey: value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _geminiController,
                decoration: const InputDecoration(
                  labelText: 'Gemini API Key',
                  hintText: 'AIza…',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onChanged: (value) => ref.read(voiceSettingsProvider.notifier).updateKeys(geminiKey: value),
              ),
              const SizedBox(height: 32),
              Text(
                'Keys are stored securely on-device using the system keychain.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load settings: $error')),
      ),
    );
  }
}
