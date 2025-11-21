import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum NotificationCategory {
  critical,
  warning,
  info,
  success,
}

class LocalNotificationService {
  LocalNotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  // Notification channel IDs
  static const _criticalChannel = 'critical_alerts';
  static const _warningChannel = 'warning_alerts';
  static const _infoChannel = 'info_alerts';
  static const _uptimeChannel = 'uptime_channel';

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestCriticalPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      
      // Create notification channels
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _criticalChannel,
          'Critical Alerts',
          description: 'Urgent server issues requiring immediate attention',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _warningChannel,
          'Warning Alerts',
          description: 'Server warnings and non-critical issues',
          importance: Importance.high,
          playSound: true,
        ),
      );
      
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _infoChannel,
          'Info & Success',
          description: 'Informational updates and success notifications',
          importance: Importance.defaultImportance,
        ),
      );
      
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _uptimeChannel,
          'Uptime Monitor',
          description: 'Server uptime status changes',
          importance: Importance.high,
        ),
      );
    }
    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap and action buttons
    final payload = response.payload;
    final actionId = response.actionId;
    
    print('[Notification] Tapped: action=$actionId, payload=$payload');
    
    // TODO: Handle action execution (restart service, view logs, etc.)
    // This will be connected to the SSH service to execute commands
  }

  Future<void> showAlert({
    required int id,
    required String title,
    required String body,
    required NotificationCategory category,
    String? payload,
    List<NotificationAction>? actions,
  }) async {
    final channelId = _getChannelId(category);
    final importance = _getImportance(category);
    final priority = _getPriority(category);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(category),
      channelDescription: _getChannelDescription(category),
      importance: importance,
      priority: priority,
      styleInformation: const BigTextStyleInformation(''),
      actions: actions
              ?.map((a) => AndroidNotificationAction(
                    a.id,
                    a.label,
                  ))
              .toList() ??
          [],
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: category == NotificationCategory.critical,
      interruptionLevel: category == NotificationCategory.critical
          ? InterruptionLevel.critical
          : category == NotificationCategory.warning
              ? InterruptionLevel.timeSensitive
              : InterruptionLevel.active,
      categoryIdentifier: category.name,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> showUptimeAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    await showAlert(
      id: id,
      title: title,
      body: body,
      category: NotificationCategory.warning,
    );
  }

  String _getChannelId(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.critical:
        return _criticalChannel;
      case NotificationCategory.warning:
        return _warningChannel;
      case NotificationCategory.info:
      case NotificationCategory.success:
        return _infoChannel;
    }
  }

  String _getChannelName(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.critical:
        return 'Critical Alerts';
      case NotificationCategory.warning:
        return 'Warning Alerts';
      case NotificationCategory.info:
        return 'Info & Success';
      case NotificationCategory.success:
        return 'Info & Success';
    }
  }

  String _getChannelDescription(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.critical:
        return 'Urgent server issues';
      case NotificationCategory.warning:
        return 'Server warnings';
      case NotificationCategory.info:
        return 'Informational updates';
      case NotificationCategory.success:
        return 'Success notifications';
    }
  }

  Importance _getImportance(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.critical:
        return Importance.max;
      case NotificationCategory.warning:
        return Importance.high;
      case NotificationCategory.info:
      case NotificationCategory.success:
        return Importance.defaultImportance;
    }
  }

  Priority _getPriority(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.critical:
        return Priority.max;
      case NotificationCategory.warning:
        return Priority.high;
      case NotificationCategory.info:
      case NotificationCategory.success:
        return Priority.defaultPriority;
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}

class NotificationAction {
  final String id;
  final String label;
  final bool destructive;

  const NotificationAction({
    required this.id,
    required this.label,
    this.destructive = false,
  });
}
