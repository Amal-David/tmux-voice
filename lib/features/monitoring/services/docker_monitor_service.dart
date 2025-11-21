import 'package:uuid/uuid.dart';

import '../../ssh/services/ssh_repository.dart';
import '../models/monitor_config.dart';

class DockerMonitorService {
  final SshRepository _sshRepository;
  final _uuid = const Uuid();

  DockerMonitorService(this._sshRepository);

  Future<List<MonitorAlert>> checkDockerHealth(
    String sessionId,
    DockerMonitorSettings settings,
    String monitorId,
  ) async {
    final alerts = <MonitorAlert>[];

    try {
      // Get all containers or specific ones
      final containerFilter = settings.containerNames.isEmpty
          ? ''
          : settings.containerNames.map((n) => '--filter name=$n').join(' ');

      final command = 'docker ps -a $containerFilter --format "{{.Names}}|{{.Status}}|{{.State}}"';
      final output = await _sshRepository.runCommand(sessionId, command);

      if (output.isEmpty) {
        return alerts;
      }

      final lines = output.split('\n').where((line) => line.trim().isNotEmpty);

      for (final line in lines) {
        final parts = line.split('|');
        if (parts.length < 3) continue;

        final name = parts[0];
        final status = parts[1];
        final state = parts[2];

        // Check if container is stopped
        if (settings.alertOnStopped && state.toLowerCase() == 'exited') {
          alerts.add(MonitorAlert(
            id: _uuid.v4(),
            monitorId: monitorId,
            sessionId: sessionId,
            title: 'Container Stopped',
            message: 'Docker container "$name" has stopped',
            severity: AlertSeverity.critical,
            timestamp: DateTime.now(),
            data: {
              'container': name,
              'status': status,
              'state': state,
            },
            actions: [
              AlertAction(
                id: 'restart',
                label: 'Restart Container',
                command: 'docker start $name',
              ),
              AlertAction(
                id: 'logs',
                label: 'View Logs',
                command: 'docker logs --tail 50 $name',
                requiresConfirmation: false,
              ),
            ],
          ));
        }

        // Check if container is unhealthy
        if (settings.alertOnUnhealthy && status.toLowerCase().contains('unhealthy')) {
          alerts.add(MonitorAlert(
            id: _uuid.v4(),
            monitorId: monitorId,
            sessionId: sessionId,
            title: 'Container Unhealthy',
            message: 'Docker container "$name" is unhealthy',
            severity: AlertSeverity.warning,
            timestamp: DateTime.now(),
            data: {
              'container': name,
              'status': status,
            },
            actions: [
              AlertAction(
                id: 'restart',
                label: 'Restart Container',
                command: 'docker restart $name',
              ),
              AlertAction(
                id: 'logs',
                label: 'View Logs',
                command: 'docker logs --tail 50 $name',
                requiresConfirmation: false,
              ),
              AlertAction(
                id: 'inspect',
                label: 'Inspect',
                command: 'docker inspect $name',
                requiresConfirmation: false,
              ),
            ],
          ));
        }
      }

      // Check resource usage for running containers
      if (settings.memoryThresholdMB > 0 || settings.cpuThresholdPercent > 0) {
        final statsAlerts = await _checkContainerStats(
          sessionId,
          settings,
          monitorId,
        );
        alerts.addAll(statsAlerts);
      }
    } catch (e) {
      // Log error but don't throw - monitoring should be non-blocking
      print('[DockerMonitor] Error: $e');
    }

    return alerts;
  }

  Future<List<MonitorAlert>> _checkContainerStats(
    String sessionId,
    DockerMonitorSettings settings,
    String monitorId,
  ) async {
    final alerts = <MonitorAlert>[];

    try {
      final command = 'docker stats --no-stream --format "{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}"';
      final output = await _sshRepository.runCommand(sessionId, command);

      if (output.isEmpty) return alerts;

      final lines = output.split('\n').where((line) => line.trim().isNotEmpty);

      for (final line in lines) {
        final parts = line.split('|');
        if (parts.length < 3) continue;

        final name = parts[0];
        final cpuStr = parts[1].replaceAll('%', '').trim();
        final memStr = parts[2]; // e.g., "123.4MiB / 1.5GiB"

        // Parse CPU percentage
        final cpuPercent = double.tryParse(cpuStr) ?? 0;
        if (settings.cpuThresholdPercent > 0 && cpuPercent > settings.cpuThresholdPercent) {
          alerts.add(MonitorAlert(
            id: _uuid.v4(),
            monitorId: monitorId,
            sessionId: sessionId,
            title: 'High Container CPU',
            message: 'Container "$name" CPU: ${cpuPercent.toStringAsFixed(1)}%',
            severity: AlertSeverity.warning,
            timestamp: DateTime.now(),
            data: {
              'container': name,
              'cpu': cpuPercent,
            },
            actions: [
              AlertAction(
                id: 'top',
                label: 'View Processes',
                command: 'docker top $name',
                requiresConfirmation: false,
              ),
              AlertAction(
                id: 'restart',
                label: 'Restart Container',
                command: 'docker restart $name',
              ),
            ],
          ));
        }

        // Parse memory usage
        if (settings.memoryThresholdMB > 0 && memStr.contains('/')) {
          final memParts = memStr.split('/');
          if (memParts.isNotEmpty) {
            final usageStr = memParts[0].trim();
            final memMB = _parseMemoryToMB(usageStr);
            
            if (memMB > settings.memoryThresholdMB) {
              alerts.add(MonitorAlert(
                id: _uuid.v4(),
                monitorId: monitorId,
                sessionId: sessionId,
                title: 'High Container Memory',
                message: 'Container "$name" using ${memMB.toStringAsFixed(0)}MB',
                severity: AlertSeverity.warning,
                timestamp: DateTime.now(),
                data: {
                  'container': name,
                  'memoryMB': memMB,
                },
                actions: [
                  AlertAction(
                    id: 'stats',
                    label: 'View Stats',
                    command: 'docker stats $name --no-stream',
                    requiresConfirmation: false,
                  ),
                  AlertAction(
                    id: 'restart',
                    label: 'Restart Container',
                    command: 'docker restart $name',
                  ),
                ],
              ));
            }
          }
        }
      }
    } catch (e) {
      print('[DockerMonitor] Stats error: $e');
    }

    return alerts;
  }

  double _parseMemoryToMB(String memStr) {
    final value = double.tryParse(memStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    
    if (memStr.contains('GiB') || memStr.contains('GB')) {
      return value * 1024;
    } else if (memStr.contains('MiB') || memStr.contains('MB')) {
      return value;
    } else if (memStr.contains('KiB') || memStr.contains('KB')) {
      return value / 1024;
    }
    
    return value;
  }
}
