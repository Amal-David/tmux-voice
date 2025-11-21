import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/notification_provider.dart';
import '../../ssh/state/ssh_providers.dart';
import '../services/log_viewer_service.dart';
import '../services/uptime_monitor_service.dart';

final uptimeMonitorProvider = Provider<UptimeMonitorService>((ref) {
  final notifications = ref.watch(localNotificationServiceProvider);
  final service = UptimeMonitorService(notifications);
  return service;
});

final logViewerServiceProvider = Provider<LogViewerService>((ref) {
  final repo = ref.watch(sshRepositoryProvider);
  return LogViewerService(repo);
});
