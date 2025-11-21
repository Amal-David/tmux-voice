import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../ssh/models/ssh_session_state.dart';
import '../monitoring/models/monitor_config.dart';

/// Service to share data with home screen widgets
class WidgetDataService {
  static const _widgetName = 'ServerStatusWidget';

  /// Update widget with current server status
  static Future<void> updateServerStatus({
    required List<SshSessionState> sessions,
    required List<MonitorAlert> recentAlerts,
  }) async {
    try {
      final connectedCount = sessions.where((s) => s.status == SshSessionStatus.connected).length;
      final totalCount = sessions.length;
      final criticalAlerts = recentAlerts.where((a) => a.severity == AlertSeverity.critical).length;
      final warningAlerts = recentAlerts.where((a) => a.severity == AlertSeverity.warning).length;

      // Save data for widget
      await HomeWidget.saveWidgetData<int>('server_count', totalCount);
      await HomeWidget.saveWidgetData<int>('connected_count', connectedCount);
      await HomeWidget.saveWidgetData<int>('critical_alerts', criticalAlerts);
      await HomeWidget.saveWidgetData<int>('warning_alerts', warningAlerts);
      await HomeWidget.saveWidgetData<String>('last_update', DateTime.now().toIso8601String());

      // Save server list (compact JSON)
      final serverData = sessions.take(5).map((s) => {
        'label': s.profile.label,
        'status': s.status.name,
      }).toList();
      await HomeWidget.saveWidgetData<String>('servers', jsonEncode(serverData));

      // Update widget
      await HomeWidget.updateWidget(
        name: _widgetName,
        iOSName: _widgetName,
        androidName: _widgetName,
      );
    } catch (e) {
      print('[WidgetData] Error updating: $e');
    }
  }

  /// Update widget with quick stats
  static Future<void> updateQuickStats({
    required int serverCount,
    required int healthyCount,
    required int alertCount,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('server_count', serverCount);
      await HomeWidget.saveWidgetData<int>('healthy_count', healthyCount);
      await HomeWidget.saveWidgetData<int>('alert_count', alertCount);
      await HomeWidget.saveWidgetData<String>('last_update', DateTime.now().toIso8601String());

      await HomeWidget.updateWidget(
        name: _widgetName,
        iOSName: _widgetName,
        androidName: _widgetName,
      );
    } catch (e) {
      print('[WidgetData] Error: $e');
    }
  }

  /// Handle widget tap (opens app)
  static Future<Uri?> getWidgetLaunchUri() async {
    return await HomeWidget.getWidgetData<String>('launch_uri').then(
      (value) => value != null ? Uri.tryParse(value) : null,
    );
  }

  /// Set URL to open when widget is tapped
  static Future<void> setLaunchUri(String uri) async {
    await HomeWidget.saveWidgetData<String>('launch_uri', uri);
  }
}
