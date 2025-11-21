import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/local_notification_service.dart';
import '../../ssh/state/ssh_providers.dart';
import '../../terminal/state/terminal_settings_provider.dart';
import '../models/monitor_config.dart';
import '../services/monitoring_orchestrator.dart';

final notificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});

final monitoringOrchestratorProvider = Provider<MonitoringOrchestrator>((ref) {
  final sshRepository = ref.watch(sshRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  return MonitoringOrchestrator(sshRepository, notificationService, prefs);
});

final activeMonitorsProvider = FutureProvider<List<MonitorConfig>>((ref) async {
  final orchestrator = ref.watch(monitoringOrchestratorProvider);
  return await orchestrator.getActiveMonitors();
});

final sessionMonitorsProvider = FutureProvider.family<List<MonitorConfig>, String>(
  (ref, sessionId) async {
    final orchestrator = ref.watch(monitoringOrchestratorProvider);
    return await orchestrator.getMonitorsForSession(sessionId);
  },
);

final recentAlertsProvider = FutureProvider<List<MonitorAlert>>((ref) async {
  final orchestrator = ref.watch(monitoringOrchestratorProvider);
  return await orchestrator.getRecentAlerts();
});

/// Extension to trigger monitoring from background
extension MonitoringBackground on WidgetRef {
  Future<void> runBackgroundMonitoring() async {
    final orchestrator = read(monitoringOrchestratorProvider);
    await orchestrator.runMonitors();
  }
}
