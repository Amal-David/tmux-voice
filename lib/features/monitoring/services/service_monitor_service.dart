import 'package:uuid/uuid.dart';

import '../../ssh/services/ssh_repository.dart';
import '../models/monitor_config.dart';

class ServiceMonitorService {
  final SshRepository _sshRepository;
  final _uuid = const Uuid();

  ServiceMonitorService(this._sshRepository);

  Future<List<MonitorAlert>> checkServicesHealth(
    String sessionId,
    ServiceMonitorSettings settings,
    String monitorId,
  ) async {
    final alerts = <MonitorAlert>[];

    if (settings.serviceNames.isEmpty) {
      return alerts;
    }

    try {
      for (final serviceName in settings.serviceNames) {
        final serviceAlerts = await _checkService(
          sessionId,
          serviceName,
          settings,
          monitorId,
        );
        alerts.addAll(serviceAlerts);
      }
    } catch (e) {
      print('[ServiceMonitor] Error: $e');
    }

    return alerts;
  }

  Future<List<MonitorAlert>> _checkService(
    String sessionId,
    String serviceName,
    ServiceMonitorSettings settings,
    String monitorId,
  ) async {
    final alerts = <MonitorAlert>[];

    try {
      // Check service status
      final command = 'systemctl is-active $serviceName';
      final output = await _sshRepository.runCommand(sessionId, command);
      final status = output.trim().toLowerCase();

      if (settings.alertOnStopped && status == 'inactive') {
        alerts.add(MonitorAlert(
          id: _uuid.v4(),
          monitorId: monitorId,
          sessionId: sessionId,
          title: 'Service Stopped',
          message: 'Service "$serviceName" is inactive',
          severity: AlertSeverity.warning,
          timestamp: DateTime.now(),
          data: {
            'service': serviceName,
            'status': status,
          },
          actions: [
            AlertAction(
              id: 'start',
              label: 'Start Service',
              command: 'sudo systemctl start $serviceName',
            ),
            AlertAction(
              id: 'status',
              label: 'Check Status',
              command: 'systemctl status $serviceName',
              requiresConfirmation: false,
            ),
            AlertAction(
              id: 'logs',
              label: 'View Logs',
              command: 'sudo journalctl -u $serviceName -n 50 --no-pager',
              requiresConfirmation: false,
            ),
          ],
        ));
      }

      if (settings.alertOnFailed && status == 'failed') {
        alerts.add(MonitorAlert(
          id: _uuid.v4(),
          monitorId: monitorId,
          sessionId: sessionId,
          title: 'Service Failed',
          message: 'Service "$serviceName" has failed',
          severity: AlertSeverity.critical,
          timestamp: DateTime.now(),
          data: {
            'service': serviceName,
            'status': status,
          },
          actions: [
            AlertAction(
              id: 'restart',
              label: 'Restart Service',
              command: 'sudo systemctl restart $serviceName',
            ),
            AlertAction(
              id: 'status',
              label: 'Check Status',
              command: 'systemctl status $serviceName',
              requiresConfirmation: false,
            ),
            AlertAction(
              id: 'logs',
              label: 'View Error Logs',
              command: 'sudo journalctl -u $serviceName -n 50 --no-pager -p err',
              requiresConfirmation: false,
            ),
          ],
        ));
      }

      // Check for restart loops (service restarted multiple times recently)
      if (status == 'active') {
        final restartAlerts = await _checkForRestartLoop(
          sessionId,
          serviceName,
          monitorId,
        );
        alerts.addAll(restartAlerts);
      }
    } catch (e) {
      print('[ServiceMonitor] Service $serviceName error: $e');
    }

    return alerts;
  }

  Future<List<MonitorAlert>> _checkForRestartLoop(
    String sessionId,
    String serviceName,
    String monitorId,
  ) async {
    final alerts = <MonitorAlert>[];

    try {
      // Check for restarts in the last hour
      final command = 'sudo journalctl -u $serviceName --since "1 hour ago" --no-pager | grep -c "Started\\|Stopped" || echo 0';
      final output = await _sshRepository.runCommand(sessionId, command);
      final restartCount = int.tryParse(output.trim()) ?? 0;

      // If restarted more than 3 times in an hour, that's suspicious
      if (restartCount > 6) { // 6 because each restart logs both Started and Stopped
        alerts.add(MonitorAlert(
          id: _uuid.v4(),
          monitorId: monitorId,
          sessionId: sessionId,
          title: 'Service Restart Loop',
          message: 'Service "$serviceName" restarted ${(restartCount / 2).floor()} times in last hour',
          severity: AlertSeverity.warning,
          timestamp: DateTime.now(),
          data: {
            'service': serviceName,
            'restartCount': (restartCount / 2).floor(),
          },
          actions: [
            AlertAction(
              id: 'status',
              label: 'Check Status',
              command: 'systemctl status $serviceName',
              requiresConfirmation: false,
            ),
            AlertAction(
              id: 'logs',
              label: 'View Recent Logs',
              command: 'sudo journalctl -u $serviceName --since "1 hour ago" --no-pager',
              requiresConfirmation: false,
            ),
            AlertAction(
              id: 'stop',
              label: 'Stop Service',
              command: 'sudo systemctl stop $serviceName',
            ),
          ],
        ));
      }
    } catch (e) {
      print('[ServiceMonitor] Restart loop check error: $e');
    }

    return alerts;
  }

  /// Check common web services (nginx, apache, etc.)
  Future<List<MonitorAlert>> checkWebServers(
    String sessionId,
    String monitorId,
  ) async {
    final commonServices = ['nginx', 'apache2', 'httpd'];
    final alerts = <MonitorAlert>[];

    for (final service in commonServices) {
      try {
        final command = 'systemctl is-active $service 2>/dev/null || echo "not-found"';
        final output = await _sshRepository.runCommand(sessionId, command);
        final status = output.trim().toLowerCase();

        if (status != 'not-found' && status != 'active') {
          alerts.add(MonitorAlert(
            id: _uuid.v4(),
            monitorId: monitorId,
            sessionId: sessionId,
            title: 'Web Server Down',
            message: 'Web server "$service" is $status',
            severity: AlertSeverity.critical,
            timestamp: DateTime.now(),
            data: {
              'service': service,
              'status': status,
            },
            actions: [
              AlertAction(
                id: 'restart',
                label: 'Restart',
                command: 'sudo systemctl restart $service',
              ),
              AlertAction(
                id: 'logs',
                label: 'Error Log',
                command: service == 'nginx'
                    ? 'sudo tail -50 /var/log/nginx/error.log'
                    : 'sudo journalctl -u $service -n 50 --no-pager',
                requiresConfirmation: false,
              ),
            ],
          ));
        }
      } catch (e) {
        // Service doesn't exist, skip
      }
    }

    return alerts;
  }
}
