enum MonitorType {
  uptime,
  docker,
  gpu,
  service,
  resource,
  logPattern,
}

enum AlertSeverity {
  info,
  warning,
  critical,
}

enum MonitorStatus {
  healthy,
  warning,
  critical,
  unknown,
}

class MonitorConfig {
  final String id;
  final String sessionId;
  final String name;
  final MonitorType type;
  final bool enabled;
  final int checkIntervalMinutes;
  final Map<String, dynamic> settings;

  const MonitorConfig({
    required this.id,
    required this.sessionId,
    required this.name,
    required this.type,
    this.enabled = true,
    this.checkIntervalMinutes = 15,
    this.settings = const {},
  });

  MonitorConfig copyWith({
    String? id,
    String? sessionId,
    String? name,
    MonitorType? type,
    bool? enabled,
    int? checkIntervalMinutes,
    Map<String, dynamic>? settings,
  }) {
    return MonitorConfig(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      name: name ?? this.name,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      checkIntervalMinutes: checkIntervalMinutes ?? this.checkIntervalMinutes,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'name': name,
        'type': type.name,
        'enabled': enabled,
        'checkIntervalMinutes': checkIntervalMinutes,
        'settings': settings,
      };

  factory MonitorConfig.fromJson(Map<String, dynamic> json) {
    return MonitorConfig(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      name: json['name'] as String,
      type: MonitorType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MonitorType.uptime,
      ),
      enabled: json['enabled'] as bool? ?? true,
      checkIntervalMinutes: json['checkIntervalMinutes'] as int? ?? 15,
      settings: json['settings'] as Map<String, dynamic>? ?? {},
    );
  }
}

// Docker monitoring settings
class DockerMonitorSettings {
  final List<String> containerNames; // Empty = monitor all
  final bool alertOnStopped;
  final bool alertOnUnhealthy;
  final int memoryThresholdMB;
  final int cpuThresholdPercent;

  const DockerMonitorSettings({
    this.containerNames = const [],
    this.alertOnStopped = true,
    this.alertOnUnhealthy = true,
    this.memoryThresholdMB = 1024,
    this.cpuThresholdPercent = 80,
  });

  Map<String, dynamic> toJson() => {
        'containerNames': containerNames,
        'alertOnStopped': alertOnStopped,
        'alertOnUnhealthy': alertOnUnhealthy,
        'memoryThresholdMB': memoryThresholdMB,
        'cpuThresholdPercent': cpuThresholdPercent,
      };

  factory DockerMonitorSettings.fromJson(Map<String, dynamic> json) {
    return DockerMonitorSettings(
      containerNames: (json['containerNames'] as List?)?.cast<String>() ?? [],
      alertOnStopped: json['alertOnStopped'] as bool? ?? true,
      alertOnUnhealthy: json['alertOnUnhealthy'] as bool? ?? true,
      memoryThresholdMB: json['memoryThresholdMB'] as int? ?? 1024,
      cpuThresholdPercent: json['cpuThresholdPercent'] as int? ?? 80,
    );
  }
}

// GPU monitoring settings
class GpuMonitorSettings {
  final int temperatureThresholdC;
  final int utilizationThresholdPercent;
  final int memoryThresholdPercent;
  final bool alertOnHighTemp;
  final bool alertOnHighUtilization;

  const GpuMonitorSettings({
    this.temperatureThresholdC = 80,
    this.utilizationThresholdPercent = 90,
    this.memoryThresholdPercent = 90,
    this.alertOnHighTemp = true,
    this.alertOnHighUtilization = true,
  });

  Map<String, dynamic> toJson() => {
        'temperatureThresholdC': temperatureThresholdC,
        'utilizationThresholdPercent': utilizationThresholdPercent,
        'memoryThresholdPercent': memoryThresholdPercent,
        'alertOnHighTemp': alertOnHighTemp,
        'alertOnHighUtilization': alertOnHighUtilization,
      };

  factory GpuMonitorSettings.fromJson(Map<String, dynamic> json) {
    return GpuMonitorSettings(
      temperatureThresholdC: json['temperatureThresholdC'] as int? ?? 80,
      utilizationThresholdPercent: json['utilizationThresholdPercent'] as int? ?? 90,
      memoryThresholdPercent: json['memoryThresholdPercent'] as int? ?? 90,
      alertOnHighTemp: json['alertOnHighTemp'] as bool? ?? true,
      alertOnHighUtilization: json['alertOnHighUtilization'] as bool? ?? true,
    );
  }
}

// Service monitoring settings
class ServiceMonitorSettings {
  final List<String> serviceNames;
  final bool alertOnStopped;
  final bool alertOnFailed;

  const ServiceMonitorSettings({
    this.serviceNames = const [],
    this.alertOnStopped = true,
    this.alertOnFailed = true,
  });

  Map<String, dynamic> toJson() => {
        'serviceNames': serviceNames,
        'alertOnStopped': alertOnStopped,
        'alertOnFailed': alertOnFailed,
      };

  factory ServiceMonitorSettings.fromJson(Map<String, dynamic> json) {
    return ServiceMonitorSettings(
      serviceNames: (json['serviceNames'] as List?)?.cast<String>() ?? [],
      alertOnStopped: json['alertOnStopped'] as bool? ?? true,
      alertOnFailed: json['alertOnFailed'] as bool? ?? true,
    );
  }
}

// Resource monitoring settings
class ResourceMonitorSettings {
  final int cpuThresholdPercent;
  final int memoryThresholdPercent;
  final int diskThresholdPercent;
  final int durationMinutes; // Alert after threshold exceeded for X minutes

  const ResourceMonitorSettings({
    this.cpuThresholdPercent = 80,
    this.memoryThresholdPercent = 85,
    this.diskThresholdPercent = 90,
    this.durationMinutes = 5,
  });

  Map<String, dynamic> toJson() => {
        'cpuThresholdPercent': cpuThresholdPercent,
        'memoryThresholdPercent': memoryThresholdPercent,
        'diskThresholdPercent': diskThresholdPercent,
        'durationMinutes': durationMinutes,
      };

  factory ResourceMonitorSettings.fromJson(Map<String, dynamic> json) {
    return ResourceMonitorSettings(
      cpuThresholdPercent: json['cpuThresholdPercent'] as int? ?? 80,
      memoryThresholdPercent: json['memoryThresholdPercent'] as int? ?? 85,
      diskThresholdPercent: json['diskThresholdPercent'] as int? ?? 90,
      durationMinutes: json['durationMinutes'] as int? ?? 5,
    );
  }
}

class MonitorAlert {
  final String id;
  final String monitorId;
  final String sessionId;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final List<AlertAction> actions;

  const MonitorAlert({
    required this.id,
    required this.monitorId,
    required this.sessionId,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.data = const {},
    this.actions = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'monitorId': monitorId,
        'sessionId': sessionId,
        'title': title,
        'message': message,
        'severity': severity.name,
        'timestamp': timestamp.toIso8601String(),
        'data': data,
        'actions': actions.map((a) => a.toJson()).toList(),
      };

  factory MonitorAlert.fromJson(Map<String, dynamic> json) {
    return MonitorAlert(
      id: json['id'] as String,
      monitorId: json['monitorId'] as String,
      sessionId: json['sessionId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.info,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: json['data'] as Map<String, dynamic>? ?? {},
      actions: (json['actions'] as List?)
              ?.map((a) => AlertAction.fromJson(a))
              .toList() ??
          [],
    );
  }
}

class AlertAction {
  final String id;
  final String label;
  final String command;
  final bool requiresConfirmation;

  const AlertAction({
    required this.id,
    required this.label,
    required this.command,
    this.requiresConfirmation = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'command': command,
        'requiresConfirmation': requiresConfirmation,
      };

  factory AlertAction.fromJson(Map<String, dynamic> json) {
    return AlertAction(
      id: json['id'] as String,
      label: json['label'] as String,
      command: json['command'] as String,
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? true,
    );
  }
}
