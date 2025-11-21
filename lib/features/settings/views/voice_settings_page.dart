import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/gradient_card.dart';
import '../../../core/widgets/believe_text_field.dart';
import '../../../core/widgets/believe_button.dart';
import '../models/voice_settings.dart';
import '../state/env_vars_provider.dart';
import '../state/voice_settings_notifier.dart';
import 'ssh_keys_page.dart';

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

  Future<void> _showEnvVarDialog({String? existingKey, String? existingValue}) async {
    final keyController = TextEditingController(text: existingKey ?? '');
    final valueController = TextEditingController(text: existingValue ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingKey == null ? 'Add variable' : 'Edit ${existingKey}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(labelText: 'Key', hintText: 'e.g. API_URL'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(labelText: 'Value', hintText: 'https://...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
        ],
      ),
    );
    if (result == true) {
      final key = keyController.text.trim();
      final value = valueController.text.trim();
      if (key.isEmpty || value.isEmpty) return;
      await ref.read(envVarsProvider.notifier).upsert(key, value);
    }
  }

  Future<void> _confirmDeleteEnvVar(String key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete variable?'),
        content: Text('Remove $key from saved variables?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(envVarsProvider.notifier).delete(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(voiceSettingsProvider);
    final envVarsAsync = ref.watch(envVarsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceFilled,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
            padding: const EdgeInsets.all(20),
            children: [
              GradientCard(
                gradient: AppTheme.purpleSoftGradient,
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voice Commands',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            settings.voiceEnabled ? 'Enabled' : 'Disabled',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                      value: settings.voiceEnabled,
                      onChanged: (value) => ref.read(voiceSettingsProvider.notifier).setVoiceEnabled(value),
                      activeColor: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      gradient: AppTheme.tealGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Voice Configuration',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BelieveCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Speech-to-Text Provider',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<SttProvider>(
                      value: settings.sttProvider,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.record_voice_over, color: AppTheme.accentTeal),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: SttProvider.groqWhisper,
                          child: Text('Groq Whisper Large V3'),
                        ),
                        DropdownMenuItem(
                          value: SttProvider.device,
                          child: Text('On-device (Apple/Android)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(voiceSettingsProvider.notifier).updateProviders(stt: value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'On-device mode uses the system speech recognizer so you can try voice commands without API keys.',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BelieveCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LLM Provider',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<LlmProvider>(
                      value: settings.llmProvider,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.psychology, color: AppTheme.primaryPurple),
                      ),
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
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      gradient: AppTheme.purpleSoftGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.key, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'API Keys',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BelieveCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.security, color: AppTheme.accentTeal, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Groq API Key',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    BelieveTextField(
                      controller: _groqController,
                      hint: 'sk-live-••••••••••••••••',
                      prefixIcon: const Icon(CupertinoIcons.lock_shield),
                      suffixIcon: const Icon(CupertinoIcons.eye_slash),
                      obscureText: true,
                      onChanged: (value) => ref.read(voiceSettingsProvider.notifier).updateKeys(groqKey: value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BelieveCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.security, color: AppTheme.primaryPurple, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Gemini API Key',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    BelieveTextField(
                      controller: _geminiController,
                      hint: 'AIza••••••••••••••••',
                      prefixIcon: const Icon(CupertinoIcons.lock_shield),
                      suffixIcon: const Icon(CupertinoIcons.eye_slash),
                      obscureText: true,
                      onChanged: (value) => ref.read(voiceSettingsProvider.notifier).updateKeys(geminiKey: value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // SSH Keys Section
              BelieveCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SshKeysPage()),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(CupertinoIcons.lock_shield, color: AppTheme.accentTeal, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'SSH Keys',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Generate and manage SSH keys',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(CupertinoIcons.chevron_right, color: AppTheme.textTertiary, size: 20),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceFilled.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accentTeal.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.accentTeal, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'API keys are stored securely on-device using the system keychain.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceFilled,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.code, size: 20, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Environment Variables',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Add variable',
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _showEnvVarDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              envVarsAsync.when(
                data: (vars) {
                  if (vars.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceFilled.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'No environment variables saved yet.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
                  }
                  final entries = vars.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
                  return Column(
                    children: [
                      for (final entry in entries)
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(entry.key, style: Theme.of(context).textTheme.titleSmall),
                            subtitle: Text(entry.value, style: Theme.of(context).textTheme.bodySmall),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => _showEnvVarDialog(existingKey: entry.key, existingValue: entry.value),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                  onPressed: () => _confirmDeleteEnvVar(entry.key),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Failed to load vars: $error'),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryPurple),
              const SizedBox(height: 16),
              Text('Loading settings...', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              ),
              const SizedBox(height: 20),
              Text(
                'Failed to load settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
