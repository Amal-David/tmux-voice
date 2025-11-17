enum VoiceCommandStatus { idle, recording, processing, success, error }

class VoiceCommandState {
  const VoiceCommandState({
    required this.status,
    this.transcript,
    this.command,
    this.errorMessage,
  });

  const VoiceCommandState.idle() : this(status: VoiceCommandStatus.idle);

  final VoiceCommandStatus status;
  final String? transcript;
  final String? command;
  final String? errorMessage;

  bool get isRecording => status == VoiceCommandStatus.recording;
  bool get isProcessing => status == VoiceCommandStatus.processing;

  VoiceCommandState copyWith({
    VoiceCommandStatus? status,
    String? transcript,
    String? command,
    String? errorMessage,
  }) {
    return VoiceCommandState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      command: command ?? this.command,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
