import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/local_notification_service.dart';
import '../../ssh/services/ssh_repository.dart';
import '../models/monitor_config.dart';
import 'docker_monitor_service.dart';
import 'gpu_monitor_service.dart';
import 'resource_monitor_service.dart';
import 'service_monitor_service.dart';

/// Orchestrates all monitoring services and handles alert notifications
class MonitoringOrchestrator {
  final SshRepository _sshRepository;
  final LocalNotificationService _notificationService;
  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  late final DockerMonitorService _dockerMonitor;
  late final GpuMonitorService _gpuMonitor;
  late final ServiceMonitorService _serviceMonitor;
  late final ResourceMonitorService _resourceMonitor;

  static const _monitorsKey = 'active_monitors';
  static const _alertsKey = 'recent_alerts';

  MonitoringOrchestrator(
    this._sshRepository,
    this._notificationService,
    this._prefs,
  ) {
    _dockerMonitor = DockerMonitorService(_sshRepository);
    _gpuMonitor = GpuMonitorService(_sshRepository);
    _serviceMonitor = ServiceMonitorService(_sshRepository);
    _resourceMonitor = ResourceMonitorService(_sshRepository);
  }

  /// Run all active monitors for all sessions
  Future<void> runMonitors() async {
    print('[MonitorOrchestrator] Running monitors...');
    
    final monitors = await getActiveMonitors();
    if (monitors.isEmpty) {
      print('[MonitorOrchestrator] No active monitors');
      return;
    }

    final allAlerts = <MonitorAlert>[];

    for (final monitor in monitors) {
      if (!monitor.enabled) continue;

      try {
        final alerts = await _runMonitor(monitor);
        allAlerts.addAll(alerts);
      } catch (e) {
        print('[MonitorOrchestrator] Error running monitor ${monitor.name}: $e');
      }
    }

    // Send notifications for new alerts
    for (final alert in allAlerts) {
      await _sendAlertNotification(alert);
    }

    // Save alerts for history
    await _saveAlerts(allAlerts);

    print('[MonitorOrchestrator] Completed. ${allAlerts.length} alerts generated');
  }

  Future<List<MonitorAlert>> _runMonitor(MonitorConfig monitor) async {
    switch (monitor.type) {
      case MonitorType.docker:
        final settings = DockerMonitorSettings.fromJson(monitor.settings);
        return await _dockerMonitor.checkDockerHealth(
          monitor.sessionId,
          settings,
          monitor.id,
        );

      case MonitorType.gpu:
        final settings = GpuMonitorSettings.fromJson(monitor.settings);
        return await _gpuMonitor.checkGpuHealth(
          monitor.sessionId,
          settings,
          monitor.id,
        );

      case MonitorType.service:
        final settings = ServiceMonitorSettings.fromJson(monitor.settings);
        return await _serviceMonitor.checkServicesHealth(
          monitor.sessionId,
          settings,
          monitor.id,
        );

      case MonitorType.resource:
        final settings = ResourceMonitorSettings.fromJson(monitor.settings);
        final alerts = await _resourceMonitor.checkResourceUsage(
          monitor.sessionId,
          settings,
          monitor.id,
        );
        // Also check for patterns
        final patternAlerts = await _resourceMonitor.checkResourcePatterns(
          monitor.sessionId,
          monitor.id,
        );
        return [...alerts, ...patternAlerts];

      case MonitorType.uptime:
        // Uptime is handled by existing uptime_monitor_service
        return [];

      case MonitorType.logPattern:
        // TODO: Implement log pattern monitoring
        return [];
    }
  }

  Future<void> _sendAlertNotification(MonitorAlert alert) async {
    final category = _mapSeverityToCategory(alert.severity);
    
    // Convert alert actions to notification actions
    final notifActions = alert.actions.take(3).map((action) {
      return NotificationAction(
        id: action.id,
        label: action.label,
        destructive: action.label.toLowerCase().contains('stop') ||
            action.label.toLowerCase().contains('kill'),
      );
    }).toList();

    await _notificationService.showAlert(
      id: alert.id.hashCode,
      title: alert.title,
      body: alert.message,
      category: category,
      payload: jsonEncode({
        'alertId': alert.id,
        'monitorId': alert.monitorId,
        'sessionId': alert.sessionId,
        'actions': alert.actions.map((a) => a.toJson()).toList(),
      }),
      actions: notifActions,
    );
  }

  NotificationCategory _mapSeverityToCategory(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return NotificationCategory.critical;
      case AlertSeverity.warning:
        return NotificationCategory.warning;
      case AlertSeverity.info:
        return NotificationCategory.info;
    }
  }

  /// Add a new monitor
  Future<void> addMonitor(MonitorConfig monitor) async {
    final monitors = await getActiveMonitors();
    monitors.add(monitor);
    await _saveMonitors(monitors);
  }

  /// Update an existing monitor
  Future<void> updateMonitor(MonitorConfig monitor) async {
    final monitors = await getActiveMonitors();
    final index = monitors.indexWhere((m) => m.id == monitor.id);
    if (index != -1) {
      monitors[index] = monitor;
      await _saveMonitors(monitors);
    }
  }

  /// Remove a monitor
  Future<void> removeMonitor(String monitorId) async {
    final monitors = await getActiveMonitors();
    monitors.removeWhere((m) => m.id == monitorId);
    await _saveMonitors(monitors);
  }

  /// Get all active monitors
  Future<List<MonitorConfig>> getActiveMonitors() async {
    final json = _prefs.getString(_monitorsKey);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((item) => MonitorConfig.fromJson(item)).toList();
    } catch (e) {
      print('[MonitorOrchestrator] Error loading monitors: $e');
      return [];
    }
  }

  /// Get monitors for a specific session
  Future<List<MonitorConfig>> getMonitorsForSession(String sessionId) async {
    final all = await getActiveMonitors();
    return all.where((m) => m.sessionId == sessionId).toList();
  }

  Future<void> _saveMonitors(List<MonitorConfig> monitors) async {
    final json = jsonEncode(monitors.map((m) => m.toJson()).toList());
    await _prefs.setString(_monitorsKey, json);
  }

  /// Get recent alerts (last 100)
  Future<List<MonitorAlert>> getRecentAlerts() async {
    final json = _prefs.getString(_alertsKey);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((item) => MonitorAlert.fromJson(item)).toList();
    } catch (e) {
      print('[MonitorOrchestrator] Error loading alerts: $e');
      return [];
    }
  }

  Future<void> _saveAlerts(List<MonitorAlert> newAlerts) async {
    if (newAlerts.isEmpty) return;

    final existing = await getRecentAlerts();
    final combined = [...newAlerts, ...existing];
    
    // Keep only last 100 alerts
    final toSave = combined.take(100).toList();
    
    final json = jsonEncode(toSave.map((a) => a.toJson()).toList());
    await _prefs.setString(_alertsKey, json);
  }

  /// Clear all alerts
  Future<void> clearAlerts() async {
    await _prefs.remove(_alertsKey);
  }

  /// Create default monitors for a session
  Future<void> createDefaultMonitors(String sessionId) async {
    final monitors = [
      // Docker monitoring
      MonitorConfig(
        id: _uuid.v4(),
        sessionId: sessionId,
        name: 'Docker Containers',
        type: MonitorType.docker,
        enabled: true,
        checkIntervalMinutes: 15,
        settings: const DockerMonitorSettings(
          containerNames: [], // Monitor all
          alertOnStopped: true,
          alertOnUnhealthy: true,
          memoryThresholdMB: 1024,
          cpuThresholdPercent: 80,
        ).toJson(),
      ),
      
      // Resource monitoring
      MonitorConfig(
        id: _uuid.v4(),
        sessionId: sessionId,
        name: 'System Resources',
        type: MonitorType.resource,
        enabled: true,
        checkIntervalMinutes: 10,
        settings: const ResourceMonitorSettings(
          cpuThresholdPercent: 85,
          memoryThresholdPercent: 90,
          diskThresholdPercent: 90,
          durationMinutes: 5,
        ).toJson(),
      ),
      
      // GPU monitoring (will auto-detect if available)
      MonitorConfig(
        id: _uuid.v4(),
        sessionId: sessionId,
        name: 'GPU Monitoring',
        type: MonitorType.gpu,
        enabled: false, // Disabled by default, user can enable if they have GPU
        checkIntervalMinutes: 15,
        settings: const GpuMonitorSettings(
          temperatureThresholdC: 80,
          utilizationThresholdPercent: 95,
          memoryThresholdPercent: 95,
          alertOnHighTemp: true,
          alertOnHighUtilization: true,
        ).toJson(),
      ),
    ];

    for (final monitor in monitors) {
      await addMonitor(monitor);
    }
  }
}
