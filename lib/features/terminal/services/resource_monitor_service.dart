import 'dart:async';

import '../models/resource_stats.dart';
import '../../ssh/services/ssh_repository.dart';

class ResourceMonitorService {
  ResourceMonitorService(this._sshRepo);

  final SshRepository _sshRepo;
  final _controllers = <String, StreamController<ResourceStats>>{};
  final _timers = <String, Timer>{};

  Stream<ResourceStats> startMonitoring(String sessionId) {
    if (_controllers.containsKey(sessionId)) {
      return _controllers[sessionId]!.stream;
    }

    final controller = StreamController<ResourceStats>.broadcast();
    _controllers[sessionId] = controller;

    _pollResources(sessionId, controller);

    return controller.stream;
  }

  Future<void> _pollResources(
    String sessionId,
    StreamController<ResourceStats> controller,
  ) async {
    final timer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }

      try {
        final stats = await _fetchResourceStats(sessionId);
        if (stats != null && !controller.isClosed) {
          controller.add(stats);
        }
      } catch (_) {
        // Silently ignore polling errors
      }
    });

    _timers[sessionId] = timer;
  }

  Future<ResourceStats?> _fetchResourceStats(String sessionId) async {
    try {
      final memOutput = await _executeCommand(
        sessionId,
        r"""bash -lc "free -m | awk '/Mem:/ {print \$2,\$3}'" """,
      );
      final cpuOutput = await _executeCommand(
        sessionId,
        r"""bash -lc "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/'" """,
      );
      final diskOutput = await _executeCommand(
        sessionId,
        r"""bash -lc "df -m / | tail -1 | awk '{print \$2,\$3}'" """,
      );
      final coreOutput = await _executeCommand(sessionId, 'nproc');
      final loadOutput = await _executeCommand(
        sessionId,
        r"""bash -lc "awk '{print \$1}' /proc/loadavg" """,
      );
      final processesOutput = await _executeCommand(
        sessionId,
        r"""bash -lc "ps -eo comm,%cpu,%mem --sort=-%cpu | head -n 6" """,
      );

      if (memOutput == null ||
          cpuOutput == null ||
          diskOutput == null ||
          coreOutput == null ||
          processesOutput == null) {
        return null;
      }

      final memParts = memOutput.trim().split(RegExp(r'\s+'));
      if (memParts.length < 2) return null;
      final diskParts = diskOutput.trim().split(RegExp(r'\s+'));
      if (diskParts.length < 2) return null;

      final totalMem = int.tryParse(memParts[0]) ?? 0;
      final usedMem = int.tryParse(memParts[1]) ?? 0;
      final totalDisk = int.tryParse(diskParts[0]) ?? 0;
      final usedDisk = int.tryParse(diskParts[1]) ?? 0;
      final cpuIdle = double.tryParse(cpuOutput.trim()) ?? 0.0;
      final cpuPercent = 100 - cpuIdle;
      final coreCount = int.tryParse(coreOutput.trim()) ?? 1;
      final loadAverage = double.tryParse(loadOutput?.trim() ?? '') ?? 0.0;
      final topProcesses = _parseProcesses(processesOutput);
      final dockerInfo = await _fetchDockerInfo(sessionId);
      final nginxInfo = await _fetchNginxInfo(sessionId);

      return ResourceStats(
        cpuPercent: cpuPercent,
        memoryUsedMb: usedMem,
        memoryTotalMb: totalMem,
        diskUsedMb: usedDisk,
        diskTotalMb: totalDisk,
        cpuCores: coreCount,
        loadAverage: loadAverage,
        topProcesses: topProcesses,
        dockerInfo: dockerInfo,
        nginxInfo: nginxInfo,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _executeCommand(String sessionId, String command) async {
    try {
      final output = await _sshRepo.runCommand(sessionId, command);
      return output;
    } catch (_) {
      return null;
    }
  }

  void stopMonitoring(String sessionId) {
    final controller = _controllers.remove(sessionId);
    controller?.close();
    _timers.remove(sessionId)?.cancel();
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  List<ProcessUsage> _parseProcesses(String raw) {
    final lines = raw.trim().split('\n');
    if (lines.length <= 1) return const <ProcessUsage>[];
    final entries = <ProcessUsage>[];
    for (final line in lines.skip(1)) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length < 3) continue;
      final name = parts[0];
      final cpu = double.tryParse(parts[1]) ?? 0;
      final mem = double.tryParse(parts[2]) ?? 0;
      entries.add(ProcessUsage(name: name, cpuPercent: cpu, memoryPercent: mem));
    }
    return entries;
  }

  Future<DockerInfo> _fetchDockerInfo(String sessionId) async {
    final availability = await _executeCommand(
      sessionId,
      r"""bash -lc "if command -v docker >/dev/null 2>&1; then echo installed; else echo missing; fi" """,
    );
    if (availability == null || !availability.contains('installed')) {
      return const DockerInfo(
        available: false,
        runningContainers: 0,
        totalContainers: 0,
        composeStacks: 0,
      );
    }

    final counts = await _executeCommand(
      sessionId,
      r"""bash -lc "echo $(docker ps -q | wc -l) $(docker ps -a -q | wc -l)" """,
    );
    final parts = counts?.trim().split(' ') ?? [];
    final running = parts.length >= 1 ? int.tryParse(parts[0]) ?? 0 : 0;
    final total = parts.length >= 2 ? int.tryParse(parts[1]) ?? running : running;

    final composeRaw = await _executeCommand(
      sessionId,
      r"""bash -lc "if docker compose version >/dev/null 2>&1; then docker compose ls --format '{{.Name}}' 2>/dev/null | wc -l; elif command -v docker-compose >/dev/null 2>&1; then docker-compose ls --format json 2>/dev/null | wc -l; else echo 0; fi" """,
    );
    final compose = int.tryParse(composeRaw?.trim() ?? '') ?? 0;

    return DockerInfo(
      available: true,
      runningContainers: running,
      totalContainers: total,
      composeStacks: compose,
    );
  }

  Future<NginxInfo> _fetchNginxInfo(String sessionId) async {
    final installed = await _executeCommand(
      sessionId,
      r"""bash -lc "if command -v nginx >/dev/null 2>&1; then echo yes; else echo no; fi" """,
    );
    if (installed == null || !installed.contains('yes')) {
      return const NginxInfo(available: false, status: 'missing');
    }

    final status = await _executeCommand(
      sessionId,
      r"""bash -lc "if command -v systemctl >/dev/null 2>&1; then systemctl is-active nginx 2>/dev/null || echo unknown; else echo running; fi" """,
    );
    final domain = await _executeCommand(
      sessionId,
      r"""bash -lc "nginx -T 2>/dev/null | grep -m1 'server_name' | awk '{print \$2}' | tr -d ';'" """,
    );

    return NginxInfo(
      available: true,
      status: status?.trim().isEmpty ?? true ? 'unknown' : status!.trim(),
      primaryServerName: domain?.trim().isEmpty ?? true ? null : domain!.trim(),
    );
  }
}
