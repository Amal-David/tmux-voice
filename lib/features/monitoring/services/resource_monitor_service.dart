import 'package:uuid/uuid.dart';

import '../../ssh/services/ssh_repository.dart';
import '../models/monitor_config.dart';

class ResourceMonitorService {
  final SshRepository _sshRepository;
  final _uuid = const Uuid();

  // Track sustained high usage
  final Map<String, List<DateTime>> _highCpuEvents = {};
  final Map<String, List<DateTime>> _highMemoryEvents = {};

  ResourceMonitorService(this._sshRepository);

  Future<List<MonitorAlert>> checkResourceUsage(
    String sessionId,
    ResourceMonitorSettings settings,
    String monitorId,
  ) async {
    final alerts = <MonitorAlert>[];

    try {
      // Check CPU
      final cpuAlerts = await _checkCpu(sessionId, settings, monitorId);
      alerts.addAll(cpuAlerts);

      // Check Memory
      final memAlerts = await _checkMemory(sessionId, settings, monitorId);
      alerts.addAll(memAlerts);

      // Check Disk
      final diskAlerts = await _checkDisk(sessionId, settings, monitorId);
      alerts.addAll(diskAlerts);
    } catch (e) {
      print('[ResourceMonitor] Error: $e');
    }

    return alerts;
  }

  Future<List<MonitorAlert>> _checkCpu(
    String sessionId,
    ResourceMonitorSettings settings,
    String monitorId,
  ) async {
    final alerts = <MonitorAlert>[];

    try {
      // Get CPU usage using top
      final command = "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | cut -d'%' -f1";
      final output = await _sshRepository.runCommand(sessionId, command);
      final cpuUsage = double.tryParse(output.trim()) ?? 0;

      if (cpuUsage > settings.cpuThresholdPercent) {
        // Track this event
        final key = '$sessionId-cpu';
        _highCpuEvents.putIfAbsent(key, () => []);
        _highCpuEvents[key]!.add(DateTime.now());

        // Remove events older than duration window
        final cutoff = DateTime.now().subtract(
          Duration(minutes: settings.durationMinutes),
        );
        _highCpuEvents[key]!.removeWhere((time) => time.isBefore(cutoff));

        // Alert only if sustained for duration
        if (_highCpuEvents[key]!.length >= (settings.durationMinutes ~/ 2)) {
          alerts.add(MonitorAlert(
            id: _uuid.v4(),
            monitorId: monitorId,
            sessionId: sessionId,
            title: 'High CPU Usage',
            message: 'CPU at ${cpuUsage.toStringAsFixed(1)}% for ${settings.durationMinutes}+ minutes',
            severity: cpuUsage > 95 ? AlertSeverity.critical : AlertSeverity.warning,
            timestamp: DateTime.now(),
            data: {
              'cpu': cpuUsage,
              'threshold': settings.cpuThresholdPercent,
            },
            actions: [
              AlertAction(
                id: 'top',
                label: 'View Top Processes',
                command: 'top -bn1 | head -20',
                requiresConfirmation: false,
              ),
              AlertAction(
                id: 'ps',
                label: 'CPU Hogs',
                command: 'ps aux --sort=-%cpu | head -10',
                requiresConfirmation: false,
              ),
            ],
          ));

          // Clear events after alert
          _highCpuEvents[key]!.clear();
        }
      }
    } catch (e) {
      print('[ResourceMonitor] CPU check error: $e');
    }

    return alerts;
  }

  Future<List<MonitorAlert>> _checkMemory(
    String sessionId,
    ResourceMonitorSettings settings,
    String monitorId,
  ) async {
    final alerts = <MonitorAlert>[];

    try {
      // Get memory usage
      final command = "free | grep Mem | awk '{printf \"%.0f\", \$3/\$2 * 100.0}'";
      final output = await _sshRepository.runCommand(sessionId, command);
      final memUsage = double.tryParse(output.trim()) ?? 0;

      if (memUsage > settings.memoryThresholdPercent) {
        final key = '$sessionId-memory';
        _highMemoryEvents.putIfAbsent(key, () => []);
        _highMemoryEvents[key]!.add(DateTime.now());

        final cutoff = DateTime.now().subtract(
          Duration(minutes: settings.durationMinutes),
        );
        _highMemoryEvents[key]!.removeWhere((time) => time.isBefore(cutoff));

        if (_highMemoryEvents[key]!.length >= (settings.durationMinutes ~/ 2)) {
          alerts.add(MonitorAlert(
            id: _uuid.v4(),
            monitorId: monitorId,
            sessionId: sessionId,
            title: 'High Memory Usage',
            message: 'Memory at ${memUsage.toStringAsFixed(1)}% for ${settings.durationMinutes}+ minutes',
            severity: memUsage > 95 ? AlertSeverity.critical : AlertSeverity.warning,
            timestamp: DateTime.now(),
            data: {
              'memory': memUsage,
              'threshold': settings.memoryThresholdPercent,
            },
            actions: [
              AlertAction(
                id: 'free',
                label: 'Memory Stats',
                command: 'free -h',
                requiresConfirmation: false,
              ),
              AlertAction(
                id: 'ps',
                label: 'Memory Hogs',
                command: 'ps aux --sort=-%mem | head -10',
                requiresConfirmation: false,
              ),
              AlertAction(
                id: 'sync',
                label: 'Clear Cache',
                command: 'sync && echo 3 | sudo tee /proc/sys/vm/drop_caches',
              ),
            ],
          ));

          _highMemoryEvents[key]!.clear();
        }
      }
    } catch (e) {
      print('[ResourceMonitor] Memory check error: $e');
    }

    return alerts;
  }

  Future<List<MonitorAlert>> _checkDisk(
    String sessionId,
    ResourceMonitorSettings settings,
    String monitorId,
  ) async {
    final alerts = <MonitorAlert>[];

    try {
      // Get disk usage for root and common mount points
      final command = "df -h | grep -E '^/dev/' | awk '{print \$1\"|\"\$5\"|\"\$6}' | sed 's/%//'";
      final output = await _sshRepository.runCommand(sessionId, command);

      if (output.isEmpty) return alerts;

      final lines = output.split('\n').where((line) => line.trim().isNotEmpty);

      for (final line in lines) {
        final parts = line.split('|');
        if (parts.length < 3) continue;

        final device = parts[0];
        final usagePercent = int.tryParse(parts[1]) ?? 0;
        final mountPoint = parts[2];

        if (usagePercent > settings.diskThresholdPercent) {
          alerts.add(MonitorAlert(
            id: _uuid.v4(),
            monitorId: monitorId,
            sessionId: sessionId,
            title: 'Low Disk Space',
            message: '$mountPoint at $usagePercent% ($device)',
            severity: usagePercent > 95 ? AlertSeverity.critical : AlertSeverity.warning,
            timestamp: DateTime.now(),
            data: {
              'device': device,
              'usage': usagePercent,
              'mountPoint': mountPoint,
            },
            actions: [
              AlertAction(
                id: 'df',
                label: 'Disk Usage',
                command: 'df -h $mountPoint',
                requiresConfirmation: false,
              ),
              AlertAction(
                id: 'du',
                label: 'Large Directories',
                command: 'du -sh $mountPoint/* 2>/dev/null | sort -rh | head -10',
                requiresConfirmation: false,
              ),
              AlertAction(
                id: 'clean',
                label: 'Clean Logs',
                command: 'sudo journalctl --vacuum-time=7d && sudo apt-get clean',
              ),
            ],
          ));
        }
      }
    } catch (e) {
      print('[ResourceMonitor] Disk check error: $e');
    }

    return alerts;
  }

  /// Check for specific resource patterns
  Future<List<MonitorAlert>> checkResourcePatterns(
    String sessionId,
    String monitorId,
  ) async {
    final alerts = <MonitorAlert>[];

    try {
      // Check for zombie processes
      final zombieCommand = "ps aux | grep -c 'Z' | awk '{if(\$1>5) print \$1; else print 0}'";
      final zombieOutput = await _sshRepository.runCommand(sessionId, zombieCommand);
      final zombieCount = int.tryParse(zombieOutput.trim()) ?? 0;

      if (zombieCount > 5) {
        alerts.add(MonitorAlert(
          id: _uuid.v4(),
          monitorId: monitorId,
          sessionId: sessionId,
          title: 'Zombie Processes Detected',
          message: '$zombieCount zombie processes found',
          severity: AlertSeverity.warning,
          timestamp: DateTime.now(),
          data: {'count': zombieCount},
          actions: [
            AlertAction(
              id: 'view',
              label: 'View Zombies',
              command: "ps aux | grep 'Z'",
              requiresConfirmation: false,
            ),
          ],
        ));
      }

      // Check load average
      final loadCommand = "uptime | awk -F'load average:' '{print \$2}' | awk '{print \$1}' | sed 's/,//'";
      final loadOutput = await _sshRepository.runCommand(sessionId, loadCommand);
      final load = double.tryParse(loadOutput.trim()) ?? 0;

      // Get CPU count
      final cpuCommand = "nproc";
      final cpuOutput = await _sshRepository.runCommand(sessionId, cpuCommand);
      final cpuCount = int.tryParse(cpuOutput.trim()) ?? 1;

      // Alert if load is > 2x CPU count
      if (load > cpuCount * 2) {
        alerts.add(MonitorAlert(
          id: _uuid.v4(),
          monitorId: monitorId,
          sessionId: sessionId,
          title: 'High System Load',
          message: 'Load average: ${load.toStringAsFixed(2)} (${cpuCount} CPUs)',
          severity: AlertSeverity.warning,
          timestamp: DateTime.now(),
          data: {
            'load': load,
            'cpuCount': cpuCount,
          },
          actions: [
            AlertAction(
              id: 'uptime',
              label: 'View Uptime',
              command: 'uptime',
              requiresConfirmation: false,
            ),
            AlertAction(
              id: 'top',
              label: 'Top Processes',
              command: 'top -bn1 | head -20',
              requiresConfirmation: false,
            ),
          ],
        ));
      }
    } catch (e) {
      print('[ResourceMonitor] Pattern check error: $e');
    }

    return alerts;
  }
}
