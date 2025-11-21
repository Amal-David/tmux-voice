import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/app_theme.dart';
import '../../ssh/state/ssh_providers.dart';
import '../models/monitor_config.dart';
import '../state/monitoring_provider.dart';

class MonitoringPage extends ConsumerWidget {
  const MonitoringPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorsAsync = ref.watch(activeMonitorsProvider);
    final alertsAsync = ref.watch(recentAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Alert History',
            onPressed: () => _showAlertHistory(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AlertsSummaryCard(alertsAsync: alertsAsync),
          const SizedBox(height: 24),
          _MonitorsList(monitorsAsync: monitorsAsync),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMonitorDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Monitor'),
      ),
    );
  }

  void _showAlertHistory(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AlertHistoryPage(),
      ),
    );
  }

  void _showAddMonitorDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AddMonitorDialog(ref: ref),
    );
  }
}

class _AlertsSummaryCard extends StatelessWidget {
  const _AlertsSummaryCard({required this.alertsAsync});

  final AsyncValue<List<MonitorAlert>> alertsAsync;

  @override
  Widget build(BuildContext context) {
    return alertsAsync.when(
      data: (alerts) {
        final critical = alerts.where((a) => a.severity == AlertSeverity.critical).length;
        final warnings = alerts.where((a) => a.severity == AlertSeverity.warning).length;
        final recent = alerts.take(3).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active, color: AppTheme.primaryPurple),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Alerts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _AlertBadge(count: critical, label: 'Critical', color: AppTheme.errorRed),
                    const SizedBox(width: 12),
                    _AlertBadge(count: warnings, label: 'Warnings', color: AppTheme.warningYellow),
                    const SizedBox(width: 12),
                    _AlertBadge(count: alerts.length, label: 'Total', color: Colors.blue),
                  ],
                ),
                if (recent.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  ...recent.map((alert) => _AlertItem(alert: alert)),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, s) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading alerts: $e'),
        ),
      ),
    );
  }
}

class _AlertBadge extends StatelessWidget {
  const _AlertBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  const _AlertItem({required this.alert});

  final MonitorAlert alert;

  @override
  Widget build(BuildContext context) {
    final icon = alert.severity == AlertSeverity.critical
        ? Icons.error
        : alert.severity == AlertSeverity.warning
            ? Icons.warning
            : Icons.info;

    final color = alert.severity == AlertSeverity.critical
        ? AppTheme.errorRed
        : alert.severity == AlertSeverity.warning
            ? AppTheme.warningYellow
            : Colors.blue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alert.title,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatTime(alert.timestamp),
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

class _MonitorsList extends ConsumerWidget {
  const _MonitorsList({required this.monitorsAsync});

  final AsyncValue<List<MonitorConfig>> monitorsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return monitorsAsync.when(
      data: (monitors) {
        if (monitors.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.monitor_heart_outlined, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'No Monitors Configured',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add monitors to track Docker containers, services, and resources',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Monitors',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ...monitors.map((monitor) => _MonitorCard(monitor: monitor)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e'),
    );
  }
}

class _MonitorCard extends ConsumerWidget {
  const _MonitorCard({required this.monitor});

  final MonitorConfig monitor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = _getMonitorIcon(monitor.type);
    final color = _getMonitorColor(monitor.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(monitor.name),
        subtitle: Text(
          '${monitor.type.name.toUpperCase()} • Every ${monitor.checkIntervalMinutes}m',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: monitor.enabled,
              onChanged: (value) async {
                final updated = monitor.copyWith(enabled: value);
                await ref.read(monitoringOrchestratorProvider).updateMonitor(updated);
                ref.invalidate(activeMonitorsProvider);
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings, size: 20),
              onPressed: () => _showEditDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMonitorIcon(MonitorType type) {
    switch (type) {
      case MonitorType.docker:
        return Icons.widgets;
      case MonitorType.gpu:
        return Icons.memory;
      case MonitorType.service:
        return Icons.miscellaneous_services;
      case MonitorType.resource:
        return Icons.analytics;
      case MonitorType.uptime:
        return Icons.schedule;
      case MonitorType.logPattern:
        return Icons.description;
    }
  }

  Color _getMonitorColor(MonitorType type) {
    switch (type) {
      case MonitorType.docker:
        return Colors.blue;
      case MonitorType.gpu:
        return Colors.green;
      case MonitorType.service:
        return Colors.orange;
      case MonitorType.resource:
        return Colors.purple;
      case MonitorType.uptime:
        return Colors.teal;
      case MonitorType.logPattern:
        return Colors.red;
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    // TODO: Show edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit monitor coming soon...')),
    );
  }
}

class AddMonitorDialog extends StatefulWidget {
  const AddMonitorDialog({super.key, required this.ref});

  final WidgetRef ref;

  @override
  State<AddMonitorDialog> createState() => _AddMonitorDialogState();
}

class _AddMonitorDialogState extends State<AddMonitorDialog> {
  MonitorType _selectedType = MonitorType.docker;
  final _nameController = TextEditingController();
  String? _selectedSessionId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Monitor'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Monitor Name',
                hintText: 'e.g., Production Docker',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MonitorType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Monitor Type'),
              items: MonitorType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            _SessionSelector(
              onSessionSelected: (sessionId) {
                setState(() => _selectedSessionId = sessionId);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _selectedSessionId == null ? null : _addMonitor,
          child: const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _addMonitor() async {
    if (_nameController.text.isEmpty || _selectedSessionId == null) return;

    final monitor = MonitorConfig(
      id: const Uuid().v4(),
      sessionId: _selectedSessionId!,
      name: _nameController.text,
      type: _selectedType,
      enabled: true,
      checkIntervalMinutes: 15,
      settings: _getDefaultSettings(),
    );

    await widget.ref.read(monitoringOrchestratorProvider).addMonitor(monitor);
    widget.ref.invalidate(activeMonitorsProvider);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Map<String, dynamic> _getDefaultSettings() {
    switch (_selectedType) {
      case MonitorType.docker:
        return const DockerMonitorSettings().toJson();
      case MonitorType.gpu:
        return const GpuMonitorSettings().toJson();
      case MonitorType.service:
        return const ServiceMonitorSettings().toJson();
      case MonitorType.resource:
        return const ResourceMonitorSettings().toJson();
      default:
        return {};
    }
  }
}

class _SessionSelector extends ConsumerWidget {
  const _SessionSelector({required this.onSessionSelected});

  final ValueChanged<String?> onSessionSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sshSessionsProvider);

    if (sessions.isEmpty) {
      return const Text('No active sessions. Connect to a server first.');
    }

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Server Session'),
      items: sessions.map((session) {
        return DropdownMenuItem(
          value: session.id,
          child: Text(session.profile.label),
        );
      }).toList(),
      onChanged: onSessionSelected,
    );
  }
}

class AlertHistoryPage extends ConsumerWidget {
  const AlertHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(recentAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              await ref.read(monitoringOrchestratorProvider).clearAlerts();
              ref.invalidate(recentAlertsProvider);
            },
          ),
        ],
      ),
      body: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return const Center(
              child: Text('No alerts yet'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _AlertHistoryCard(alert: alert);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _AlertHistoryCard extends StatelessWidget {
  const _AlertHistoryCard({required this.alert});

  final MonitorAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = alert.severity == AlertSeverity.critical
        ? AppTheme.errorRed
        : alert.severity == AlertSeverity.warning
            ? AppTheme.warningYellow
            : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    alert.severity.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  _formatDateTime(alert.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(alert.message),
            if (alert.actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: alert.actions.map((action) {
                  return Chip(
                    label: Text(action.label, style: const TextStyle(fontSize: 11)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.day}/${time.month}';
  }
}
