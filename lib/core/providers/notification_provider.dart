import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_notification_service.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  final service = LocalNotificationService();
  return service;
});
