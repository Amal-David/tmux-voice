import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ssh/state/ssh_providers.dart';
import '../services/resource_monitor_service.dart';
import '../models/resource_stats.dart';

final resourceMonitorServiceProvider = Provider<ResourceMonitorService>((ref) {
  final sshRepo = ref.watch(sshRepositoryProvider);
  final service = ResourceMonitorService(sshRepo);
  ref.onDispose(service.dispose);
  return service;
});

final resourceStatsProvider = StreamProvider.family<ResourceStats?, String>((ref, sessionId) {
  final service = ref.watch(resourceMonitorServiceProvider);
  return service.startMonitoring(sessionId);
});

class ResourceHistoryNotifier extends StateNotifier<Map<String, List<ResourceStats>>> {
  ResourceHistoryNotifier() : super({});

  void addStats(String sessionId, ResourceStats stats) {
    final history = state[sessionId] ?? [];
    final updated = [...history, stats];
    
    // Keep only last 20 data points for charts
    final trimmed = updated.length > 20 ? updated.sublist(updated.length - 20) : updated;
    
    state = {...state, sessionId: trimmed};
  }

  List<ResourceStats> getHistory(String sessionId) {
    return state[sessionId] ?? [];
  }

  void clearHistory(String sessionId) {
    final newState = Map<String, List<ResourceStats>>.from(state);
    newState.remove(sessionId);
    state = newState;
  }
}

final resourceHistoryProvider = StateNotifierProvider<ResourceHistoryNotifier, Map<String, List<ResourceStats>>>((ref) {
  return ResourceHistoryNotifier();
});
