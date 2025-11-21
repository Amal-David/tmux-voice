import 'package:uuid/uuid.dart';

import '../../ssh/services/ssh_repository.dart';
import '../models/monitor_config.dart';

class GpuMonitorService {
  final SshRepository _sshRepository;
  final _uuid = const Uuid();

  GpuMonitorService(this._sshRepository);

  Future<List<MonitorAlert>> checkGpuHealth(
    String sessionId,
    GpuMonitorSettings settings,
    String monitorId,
  ) async {
    final alerts = <MonitorAlert>[];

    try {
      // Check if nvidia-smi is available
      final checkCommand = 'which nvidia-smi';
      final checkOutput = await _sshRepository.runCommand(sessionId, checkCommand);
      
      if (checkOutput.isEmpty) {
        // No NVIDIA GPU or nvidia-smi not installed
        return alerts;
      }

      // Get GPU stats
      final command = 'nvidia-smi --query-gpu=index,name,temperature.gpu,utilization.gpu,utilization.memory,memory.used,memory.total --format=csv,noheader,nounits';
      final output = await _sshRepository.runCommand(sessionId, command);

      if (output.isEmpty) return alerts;

      final lines = output.split('\n').where((line) => line.trim().isNotEmpty);

      for (final line in lines) {
        final parts = line.split(',').map((p) => p.trim()).toList();
        if (parts.length < 7) continue;

        final index = parts[0];
        final name = parts[1];
        final temp = int.tryParse(parts[2]) ?? 0;
        final gpuUtil = int.tryParse(parts[3]) ?? 0;
        final memUtil = int.tryParse(parts[4]) ?? 0;
        final memUsed = int.tryParse(parts[5]) ?? 0;
        final memTotal = int.tryParse(parts[6]) ?? 0;

        // Check temperature
        if (settings.alertOnHighTemp && temp > settings.temperatureThresholdC) {
          alerts.add(MonitorAlert(
            id: _uuid.v4(),
            monitorId: monitorId,
            sessionId: sessionId,
            title: 'High GPU Temperature',
            message: 'GPU $index ($name): ${temp}°C',
            severity: temp > settings.temperatureThresholdC + 10 
                ? AlertSeverity.critical 
                : AlertSeverity.warning,
            timestamp: DateTime.now(),
            data: {
              'gpu': index,
              'name': name,
              'temperature': temp,
            },
            actions: [
              AlertAction(
                id: 'check',
                label: 'Check GPU Status',
                command: 'nvidia-smi',
                requiresConfirmation: false,
              ),
              AlertAction(
                id: 'processes',
                label: 'View GPU Processes',
                command: 'nvidia-smi pmon -c 1',
                requiresConfirmation: false,
              ),
            ],
          ));
        }

        // Check GPU utilization
        if (settings.alertOnHighUtilization && gpuUtil > settings.utilizationThresholdPercent) {
          alerts.add(MonitorAlert(
            id: _uuid.v4(),
            monitorId: monitorId,
            sessionId: sessionId,
            title: 'High GPU Utilization',
            message: 'GPU $index ($name): $gpuUtil% utilization',
            severity: AlertSeverity.info,
            timestamp: DateTime.now(),
            data: {
              'gpu': index,
              'name': name,
              'utilization': gpuUtil,
            },
            actions: [
              AlertAction(
                id: 'processes',
                label: 'View GPU Processes',
                command: 'nvidia-smi pmon -c 1',
                requiresConfirmation: false,
              ),
            ],
          ));
        }

        // Check memory utilization
        if (settings.alertOnHighUtilization && memTotal > 0) {
          final memPercent = (memUsed / memTotal * 100).toInt();
          if (memPercent > settings.memoryThresholdPercent) {
            alerts.add(MonitorAlert(
              id: _uuid.v4(),
              monitorId: monitorId,
              sessionId: sessionId,
              title: 'High GPU Memory',
              message: 'GPU $index ($name): $memPercent% memory ($memUsed/$memTotal MB)',
              severity: AlertSeverity.warning,
              timestamp: DateTime.now(),
              data: {
                'gpu': index,
                'name': name,
                'memoryPercent': memPercent,
                'memoryUsed': memUsed,
                'memoryTotal': memTotal,
              },
              actions: [
                AlertAction(
                  id: 'processes',
                  label: 'View GPU Processes',
                  command: 'nvidia-smi pmon -c 1',
                  requiresConfirmation: false,
                ),
                AlertAction(
                  id: 'details',
                  label: 'Detailed Memory Info',
                  command: 'nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv',
                  requiresConfirmation: false,
                ),
              ],
            ));
          }
        }
      }
    } catch (e) {
      print('[GpuMonitor] Error: $e');
    }

    return alerts;
  }

  /// Check if any GPU processes completed (useful for ML/mining jobs)
  Future<List<MonitorAlert>> checkGpuProcesses(
    String sessionId,
    String monitorId,
    List<String> watchedProcessNames,
  ) async {
    final alerts = <MonitorAlert>[];

    try {
      final command = 'nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader';
      final output = await _sshRepository.runCommand(sessionId, command);

      if (output.isEmpty) {
        // No processes running - could be completion
        for (final processName in watchedProcessNames) {
          alerts.add(MonitorAlert(
            id: _uuid.v4(),
            monitorId: monitorId,
            sessionId: sessionId,
            title: 'GPU Process Completed',
            message: 'Process "$processName" no longer using GPU',
            severity: AlertSeverity.info,
            timestamp: DateTime.now(),
            data: {
              'process': processName,
            },
            actions: [],
          ));
        }
      }
    } catch (e) {
      print('[GpuMonitor] Process check error: $e');
    }

    return alerts;
  }
}
