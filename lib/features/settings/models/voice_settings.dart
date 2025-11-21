enum SttProvider { groqWhisper, device }

enum LlmProvider { geminiFlash, geminiPro }

class VoiceSettings {
  const VoiceSettings({
    required this.sttProvider,
    required this.llmProvider,
    this.groqApiKey,
    this.geminiApiKey,
    this.voiceEnabled = false,
  });

  final SttProvider sttProvider;
  final LlmProvider llmProvider;
  final String? groqApiKey;
  final String? geminiApiKey;
  final bool voiceEnabled;

  VoiceSettings copyWith({
    SttProvider? sttProvider,
    LlmProvider? llmProvider,
    String? groqApiKey,
    String? geminiApiKey,
    bool? voiceEnabled,
  }) {
    return VoiceSettings(
      sttProvider: sttProvider ?? this.sttProvider,
      llmProvider: llmProvider ?? this.llmProvider,
      groqApiKey: groqApiKey ?? this.groqApiKey,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'sttProvider': sttProvider.name,
        'llmProvider': llmProvider.name,
        'groqApiKey': groqApiKey,
        'geminiApiKey': geminiApiKey,
        'voiceEnabled': voiceEnabled,
      };

  factory VoiceSettings.fromJson(Map<String, dynamic> json) {
    return VoiceSettings(
      sttProvider: SttProvider.values.firstWhere(
        (value) => value.name == json['sttProvider'],
        orElse: () => SttProvider.device,
      ),
      llmProvider: LlmProvider.values.firstWhere(
        (value) => value.name == json['llmProvider'],
        orElse: () => LlmProvider.geminiFlash,
      ),
      groqApiKey: json['groqApiKey'] as String?,
      geminiApiKey: json['geminiApiKey'] as String?,
      voiceEnabled: json['voiceEnabled'] as bool? ?? false,
    );
  }

  static const defaults = VoiceSettings(
    sttProvider: SttProvider.device,
    llmProvider: LlmProvider.geminiFlash,
  );
}
