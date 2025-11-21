class CommandHistoryState {
  const CommandHistoryState({
    required this.recent,
    required this.frequency,
  });

  final List<String> recent;
  final Map<String, int> frequency;

  static const empty = CommandHistoryState(recent: [], frequency: {});
}
