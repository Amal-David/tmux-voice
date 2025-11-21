class ResourceStats {
  const ResourceStats({
    required this.cpuPercent,
    required this.memoryUsedMb,
    required this.memoryTotalMb,
    required this.diskUsedMb,
    required this.diskTotalMb,
    required this.cpuCores,
    required this.loadAverage,
    required this.topProcesses,
    this.dockerInfo,
    this.nginxInfo,
    required this.timestamp,
  });

  final double cpuPercent;
  final int memoryUsedMb;
  final int memoryTotalMb;
  final int diskUsedMb;
  final int diskTotalMb;
  final int cpuCores;
  final double loadAverage;
  final List<ProcessUsage> topProcesses;
  final DockerInfo? dockerInfo;
  final NginxInfo? nginxInfo;
  final DateTime timestamp;

  double get memoryPercent => memoryTotalMb == 0 ? 0 : (memoryUsedMb / memoryTotalMb) * 100;
  double get diskPercent => diskTotalMb == 0 ? 0 : (diskUsedMb / diskTotalMb) * 100;

  Map<String, dynamic> toJson() => {
        'cpuPercent': cpuPercent,
        'memoryUsedMb': memoryUsedMb,
        'memoryTotalMb': memoryTotalMb,
        'diskUsedMb': diskUsedMb,
        'diskTotalMb': diskTotalMb,
        'cpuCores': cpuCores,
        'loadAverage': loadAverage,
        'topProcesses': topProcesses.map((p) => p.toJson()).toList(),
        'dockerInfo': dockerInfo?.toJson(),
        'nginxInfo': nginxInfo?.toJson(),
        'timestamp': timestamp.toIso8601String(),
      };

  factory ResourceStats.fromJson(Map<String, dynamic> json) {
    return ResourceStats(
      cpuPercent: (json['cpuPercent'] as num).toDouble(),
      memoryUsedMb: json['memoryUsedMb'] as int,
      memoryTotalMb: json['memoryTotalMb'] as int,
      diskUsedMb: json['diskUsedMb'] as int,
      diskTotalMb: json['diskTotalMb'] as int,
      cpuCores: json['cpuCores'] as int,
      loadAverage: (json['loadAverage'] as num).toDouble(),
      topProcesses: (json['topProcesses'] as List<dynamic>)
          .map((entry) => ProcessUsage.fromJson((entry as Map).cast<String, dynamic>()))
          .toList(),
      dockerInfo: json['dockerInfo'] != null
          ? DockerInfo.fromJson((json['dockerInfo'] as Map).cast<String, dynamic>())
          : null,
      nginxInfo: json['nginxInfo'] != null
          ? NginxInfo.fromJson((json['nginxInfo'] as Map).cast<String, dynamic>())
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class ProcessUsage {
  const ProcessUsage({
    required this.name,
    required this.cpuPercent,
    required this.memoryPercent,
  });

  final String name;
  final double cpuPercent;
  final double memoryPercent;

  Map<String, dynamic> toJson() => {
        'name': name,
        'cpuPercent': cpuPercent,
        'memoryPercent': memoryPercent,
      };

  factory ProcessUsage.fromJson(Map<String, dynamic> json) {
    return ProcessUsage(
      name: json['name'] as String,
      cpuPercent: (json['cpuPercent'] as num).toDouble(),
      memoryPercent: (json['memoryPercent'] as num).toDouble(),
    );
  }
}

class DockerInfo {
  const DockerInfo({
    required this.available,
    required this.runningContainers,
    required this.totalContainers,
    required this.composeStacks,
  });

  final bool available;
  final int runningContainers;
  final int totalContainers;
  final int composeStacks;

  Map<String, dynamic> toJson() => {
        'available': available,
        'runningContainers': runningContainers,
        'totalContainers': totalContainers,
        'composeStacks': composeStacks,
      };

  factory DockerInfo.fromJson(Map<String, dynamic> json) {
    return DockerInfo(
      available: json['available'] as bool,
      runningContainers: json['runningContainers'] as int,
      totalContainers: json['totalContainers'] as int,
      composeStacks: json['composeStacks'] as int,
    );
  }
}

class NginxInfo {
  const NginxInfo({
    required this.available,
    required this.status,
    this.primaryServerName,
  });

  final bool available;
  final String status;
  final String? primaryServerName;

  Map<String, dynamic> toJson() => {
        'available': available,
        'status': status,
        'primaryServerName': primaryServerName,
      };

  factory NginxInfo.fromJson(Map<String, dynamic> json) {
    return NginxInfo(
      available: json['available'] as bool,
      status: json['status'] as String,
      primaryServerName: json['primaryServerName'] as String?,
    );
  }
}
