import 'dart:convert';

import 'package:flutter/services.dart';

/// iOS Shortcuts and Siri Integration
/// 
/// To enable:
/// 1. Add NSUserActivityTypes to Info.plist
/// 2. Create Intents.intentdefinition in Xcode
/// 3. Register intent handlers
class IOSShortcutsService {
  static const _channel = MethodChannel('com.voice.terminal/shortcuts');

  /// Available shortcut actions
  static const actionCheckServers = 'check_servers';
  static const actionRestartService = 'restart_service';
  static const actionViewLogs = 'view_logs';
  static const actionConnectServer = 'connect_server';

  /// Initialize shortcuts
  static Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initialize');
      
      // Donate common activities for Siri suggestions
      await donateActivity(
        actionCheckServers,
        title: 'Check Server Status',
        description: 'View the status of all your servers',
      );
      
      await donateActivity(
        actionViewLogs,
        title: 'View Recent Logs',
        description: 'Check recent error logs from your servers',
      );
    } catch (e) {
      print('[Shortcuts] Not available on this platform: $e');
    }
  }

  /// Donate an activity for Siri suggestions
  static Future<void> donateActivity(
    String action, {
    required String title,
    required String description,
    Map<String, dynamic>? userInfo,
  }) async {
    try {
      await _channel.invokeMethod('donateActivity', {
        'action': action,
        'title': title,
        'description': description,
        'userInfo': userInfo != null ? jsonEncode(userInfo) : null,
      });
    } catch (e) {
      print('[Shortcuts] Donate failed: $e');
    }
  }

  /// Handle shortcut intent
  static Future<Map<String, dynamic>?> handleIntent(String intentName) async {
    try {
      final result = await _channel.invokeMethod('handleIntent', {
        'intentName': intentName,
      });
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      print('[Shortcuts] Handle intent failed: $e');
      return null;
    }
  }

  /// Create quick action (3D Touch / Long Press on app icon)
  static Future<void> setQuickActions(List<QuickAction> actions) async {
    try {
      await _channel.invokeMethod('setQuickActions', {
        'actions': actions.map((a) => a.toJson()).toList(),
      });
    } catch (e) {
      print('[Shortcuts] Set quick actions failed: $e');
    }
  }

  /// Get pending shortcut action (when app is launched from shortcut)
  static Future<String?> getPendingAction() async {
    try {
      return await _channel.invokeMethod<String>('getPendingAction');
    } catch (e) {
      print('[Shortcuts] Get pending action failed: $e');
      return null;
    }
  }
}

class QuickAction {
  final String action;
  final String title;
  final String? subtitle;
  final String? icon;

  const QuickAction({
    required this.action,
    required this.title,
    this.subtitle,
    this.icon,
  });

  Map<String, dynamic> toJson() => {
        'action': action,
        'title': title,
        'subtitle': subtitle,
        'icon': icon,
      };
}

/// Siri response builder
class SiriResponse {
  final String title;
  final String message;
  final Map<String, dynamic>? data;

  const SiriResponse({
    required this.title,
    required this.message,
    this.data,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'message': message,
        'data': data,
      };
}
