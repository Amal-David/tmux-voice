class CommandHistoryEntry {
  const CommandHistoryEntry({
    required this.command,
    required this.timestamp,
    required this.sessionId,
  });

  final String command;
  final DateTime timestamp;
  final String sessionId;

  Map<String, dynamic> toJson() => {
        'command': command,
        'timestamp': timestamp.toIso8601String(),
        'sessionId': sessionId,
      };

  factory CommandHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CommandHistoryEntry(
      command: json['command'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      sessionId: json['sessionId'] as String,
    );
  }
}
