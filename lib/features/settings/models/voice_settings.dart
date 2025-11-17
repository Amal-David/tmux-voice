enum SttProvider { groqWhisper }

enum LlmProvider { geminiFlash, geminiPro }

class VoiceSettings {
  const VoiceSettings({
    required this.sttProvider,
    required this.llmProvider,
    this.groqApiKey,
    this.geminiApiKey,
  });

  final SttProvider sttProvider;
  final LlmProvider llmProvider;
  final String? groqApiKey;
  final String? geminiApiKey;

  VoiceSettings copyWith({
    SttProvider? sttProvider,
    LlmProvider? llmProvider,
    String? groqApiKey,
    String? geminiApiKey,
  }) {
    return VoiceSettings(
      sttProvider: sttProvider ?? this.sttProvider,
      llmProvider: llmProvider ?? this.llmProvider,
      groqApiKey: groqApiKey ?? this.groqApiKey,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'sttProvider': sttProvider.name,
        'llmProvider': llmProvider.name,
        'groqApiKey': groqApiKey,
        'geminiApiKey': geminiApiKey,
      };

  factory VoiceSettings.fromJson(Map<String, dynamic> json) {
    return VoiceSettings(
      sttProvider: SttProvider.values.firstWhere(
        (value) => value.name == json['sttProvider'],
        orElse: () => SttProvider.groqWhisper,
      ),
      llmProvider: LlmProvider.values.firstWhere(
        (value) => value.name == json['llmProvider'],
        orElse: () => LlmProvider.geminiFlash,
      ),
      groqApiKey: json['groqApiKey'] as String?,
      geminiApiKey: json['geminiApiKey'] as String?,
    );
  }

  static const defaults = VoiceSettings(
    sttProvider: SttProvider.groqWhisper,
    llmProvider: LlmProvider.geminiFlash,
  );
}
