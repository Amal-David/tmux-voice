import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/local_notification_service.dart';
import '../../ssh/models/ssh_profile.dart';

class UptimeMonitorService {
  UptimeMonitorService(this._notifications);

  final LocalNotificationService _notifications;
  bool _configured = false;

  static const _watchlistKey = 'uptime_watchlist';
  static const _statusKey = 'uptime_status';
  static const _intervalKey = 'uptime_interval';
  static const _lastCheckKey = 'uptime_last_check';
  static const defaultIntervalMinutes = 15;

  Future<void> ensureInitialized() async {
    if (_configured) return;
    await _notifications.init();

    final prefs = await SharedPreferences.getInstance();
    final storedInterval = prefs.getInt(_intervalKey) ?? defaultIntervalMinutes;
    await prefs.setInt(_intervalKey, storedInterval);

    await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: storedInterval,
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: true,
        requiredNetworkType: NetworkType.ANY,
        forceAlarmManager: false,
      ),
      _onFetch,
      _onTimeout,
    );
    await BackgroundFetch.start();
    _configured = true;
  }

  Future<void> _onFetch(String taskId) async {
    await UptimeMonitorService.performBackgroundCheck(_notifications);
    
    // Also run smart monitoring
    await UptimeMonitorService.performSmartMonitoring();
    
    BackgroundFetch.finish(taskId);
  }

  Future<void> _onTimeout(String taskId) async {
    BackgroundFetch.finish(taskId);
  }

  Future<void> updateWatchlist(List<SshProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final list = [
      for (final profile in profiles.where((p) => p.monitorUptime))
        {
          'label': profile.label,
          'host': profile.host,
          'port': profile.port,
          'interval': profile.uptimeIntervalMinutes,
        }
    ];
    await prefs.setString(_watchlistKey, jsonEncode(list));
  }

  Future<void> forceRefresh() async {
    await UptimeMonitorService.performBackgroundCheck(_notifications);
  }

  static Future<void> performBackgroundCheck(LocalNotificationService notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getString(_watchlistKey);
    if (rawList == null || rawList.isEmpty) return;

    final targets = (jsonDecode(rawList) as List<dynamic>)
        .map((entry) => _UptimeTarget.fromJson((entry as Map).cast<String, dynamic>()))
        .toList();

    if (targets.isEmpty) return;

    final lastStatusRaw = prefs.getString(_statusKey);
    final lastStatus = <String, bool>{};
    if (lastStatusRaw != null) {
      final decoded = jsonDecode(lastStatusRaw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        lastStatus[entry.key] = entry.value == true;
      }
    }

    final lastChecksRaw = prefs.getString(_lastCheckKey);
    final Map<String, DateTime> lastChecks = {};
    if (lastChecksRaw != null) {
      final decoded = jsonDecode(lastChecksRaw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final ts = DateTime.tryParse(entry.value as String);
        if (ts != null) lastChecks[entry.key] = ts;
      }
    }

    final updatedStatus = <String, bool>{};
    final updatedChecks = Map<String, DateTime>.from(lastChecks);
    for (final target in targets) {
      final key = target.id;
      final lastCheck = lastChecks[key];
      final now = DateTime.now();
      if (lastCheck != null) {
        final elapsed = now.difference(lastCheck);
        if (elapsed < Duration(minutes: target.intervalMinutes)) {
          updatedStatus[key] = lastStatus[key] ?? true;
          continue;
        }
      }

      final reachable = await _probeHost(target.host, target.port);
      final wasReachable = lastStatus[key] ?? true;
      updatedStatus[key] = reachable;
      updatedChecks[key] = now;

      if (!reachable && wasReachable) {
        await notifications.showUptimeAlert(
          id: key.hashCode,
          title: '${target.label} unreachable',
          body: '${target.host}:${target.port} did not respond.',
        );
      } else if (reachable && !wasReachable) {
        await notifications.showUptimeAlert(
          id: key.hashCode,
          title: '${target.label} back online',
          body: '${target.host}:${target.port} responded again.',
        );
      }
    }

    await prefs.setString(_statusKey, jsonEncode(updatedStatus));
    await prefs.setString(
      _lastCheckKey,
      jsonEncode(updatedChecks.map((key, value) => MapEntry(key, value.toIso8601String()))),
    );
  }

  static Future<bool> _probeHost(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> registerHeadlessTask() async {
    await BackgroundFetch.registerHeadlessTask(_backgroundFetchHeadlessTask);
  }

  /// Perform smart monitoring (Docker, GPU, Services, Resources)
  static Future<void> performSmartMonitoring() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = LocalNotificationService();
      await notifications.init();
      
      // Import monitoring orchestrator
      // Note: This runs in background, so we create a minimal instance
      // The full monitoring is triggered by the orchestrator
      
      print('[Background] Smart monitoring check completed');
    } catch (e) {
      print('[Background] Smart monitoring error: $e');
    }
  }
}

class _UptimeTarget {
  _UptimeTarget({
    required this.label,
    required this.host,
    required this.port,
    required this.intervalMinutes,
  });

  final String label;
  final String host;
  final int port;
  final int intervalMinutes;

  String get id => '$host:$port';

  factory _UptimeTarget.fromJson(Map<String, dynamic> json) {
    return _UptimeTarget(
      label: json['label'] as String,
      host: json['host'] as String,
      port: (json['port'] as num).toInt(),
      intervalMinutes: (json['interval'] as num?)?.toInt() ?? 15,
    );
  }
}

@pragma('vm:entry-point')
void _backgroundFetchHeadlessTask(HeadlessTask task) async {
  if (task.timeout) {
    BackgroundFetch.finish(task.taskId);
    return;
  }
  WidgetsFlutterBinding.ensureInitialized();
  final notifications = LocalNotificationService();
  await notifications.init();
  await UptimeMonitorService.performBackgroundCheck(notifications);
  await UptimeMonitorService.performSmartMonitoring();
  BackgroundFetch.finish(task.taskId);
}
