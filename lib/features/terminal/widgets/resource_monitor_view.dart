import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/resource_monitor_provider.dart';
import '../models/resource_stats.dart';

class ResourceMonitorView extends ConsumerStatefulWidget {
  const ResourceMonitorView({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ResourceMonitorView> createState() => _ResourceMonitorViewState();
}

class _LoadingStepsView extends StatefulWidget {
  const _LoadingStepsView();

  @override
  State<_LoadingStepsView> createState() => _LoadingStepsViewState();
}

class _LoadingStepsViewState extends State<_LoadingStepsView> {
  static const _steps = [
    'Contacting host',
    'Collecting CPU / memory stats',
    'Inspecting storage & services',
    'Summarizing charts',
  ];

  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        _current = (_current + 1) % _steps.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preparing metrics…',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hang tight while we query your server for live stats.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < _steps.length; i++) _LoadingStepTile(label: _steps[i], index: i, current: _current),
          const Spacer(),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _LoadingStepTile extends StatelessWidget {
  const _LoadingStepTile({required this.label, required this.index, required this.current});

  final String label;
  final int index;
  final int current;

  @override
  Widget build(BuildContext context) {
    final completed = index < current;
    final isActive = index == current;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: completed
                ? const Icon(Icons.check_circle, color: Colors.green)
                : isActive
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Icon(Icons.radio_button_unchecked, color: Colors.black26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? Colors.black : Colors.black54,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceMonitorViewState extends ConsumerState<ResourceMonitorView> {
  @override
  void initState() {
    super.initState();
    // Start monitoring when view is created
    ref.read(resourceMonitorServiceProvider).startMonitoring(widget.sessionId);
  }

  @override
  void dispose() {
    ref.read(resourceMonitorServiceProvider).stopMonitoring(widget.sessionId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(resourceStatsProvider(widget.sessionId));
    final history = ref.watch(resourceHistoryProvider);
    final sessionHistory = history[widget.sessionId] ?? [];

    return statsAsync.when(
      data: (stats) {
        if (stats == null) {
          return const _LoadingStepsView();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(resourceHistoryProvider.notifier).addStats(widget.sessionId, stats);
        });

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Usage'),
                  Tab(text: 'Processes'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _UsageTab(stats: stats, history: sessionHistory),
                    _ProcessTab(stats: stats),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to load resources:\n$error'),
          ],
        ),
      ),
    );
  }
}

class _UsageTab extends StatelessWidget {
  const _UsageTab({required this.stats, required this.history});

  final ResourceStats? stats;
  final List<ResourceStats> history;

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const Center(child: Text('Collecting usage data...'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _CurrentStatsCard(stats: stats!),
            const SizedBox(height: 16),
            _LoadCard(stats: stats!),
            const SizedBox(height: 16),
            _ResourceChart(
              title: 'CPU Usage',
              data: history,
              getValue: (stat) => stat.cpuPercent,
              color: Colors.blue,
              unit: '%',
            ),
            const SizedBox(height: 16),
            _ResourceChart(
              title: 'Memory Usage',
              data: history,
              getValue: (stat) => stat.memoryPercent,
              color: Colors.green,
              unit: '%',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessTab extends StatelessWidget {
  const _ProcessTab({required this.stats});

  final ResourceStats? stats;

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const Center(child: Text('Collecting process data...'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _TopProcessList(stats: stats!),
            const SizedBox(height: 16),
            _DockerCard(info: stats!.dockerInfo),
            const SizedBox(height: 16),
            _NginxCard(info: stats!.nginxInfo),
          ],
        ),
      ),
    );
  }
}

class _CurrentStatsCard extends StatelessWidget {
  const _CurrentStatsCard({required this.stats});

  final ResourceStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Resource Usage',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.memory,
                    label: 'CPU Utilization',
                    value: '${stats.cpuPercent.toStringAsFixed(1)}%',
                    color: Colors.blue,
                    subtitle: '${stats.cpuCores} cores',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatTile(
                    icon: Icons.storage,
                    label: 'Memory utilization (MB)',
                    value: '${stats.memoryPercent.toStringAsFixed(1)}%',
                    subtitle: '${stats.memoryUsedMb} / ${stats.memoryTotalMb} MB',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.sd_storage,
                    label: 'Storage utilization (MB)',
                    value: '${stats.diskPercent.toStringAsFixed(1)}%',
                    subtitle: '${stats.diskUsedMb} / ${stats.diskTotalMb} MB',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatTile(
                    icon: Icons.timeline,
                    label: 'Load Average',
                    value: stats.loadAverage.toStringAsFixed(2),
                    subtitle: '1 min average',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadCard extends StatelessWidget {
  const _LoadCard({required this.stats});

  final ResourceStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline, color: Colors.white70),
        title: const Text('System Summary'),
        subtitle: Text(
          'Cores: ${stats.cpuCores} | Load: ${stats.loadAverage.toStringAsFixed(2)} | Storage: ${stats.diskUsedMb} / ${stats.diskTotalMb} MB',
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
        ],
      ],
    );
  }
}

class _TopProcessList extends StatelessWidget {
  const _TopProcessList({required this.stats});

  final ResourceStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Processes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (stats.topProcesses.isEmpty)
              const Text('No process data available.')
            else
              ...stats.topProcesses.map(
                (proc) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(proc.name),
                  subtitle: Text('CPU ${proc.cpuPercent.toStringAsFixed(1)}% · RAM ${proc.memoryPercent.toStringAsFixed(1)}%'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DockerCard extends StatelessWidget {
  const _DockerCard({required this.info});

  final DockerInfo? info;

  @override
  Widget build(BuildContext context) {
    final available = info?.available ?? false;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.dns, color: available ? Colors.tealAccent : Colors.grey),
            title: const Text('Docker'),
            subtitle: available
                ? Text(
                    '${info!.runningContainers} running / ${info!.totalContainers} containers\n${info!.composeStacks} compose projects detected',
                  )
                : const Text('Docker not detected on this host'),
            trailing: available
                ? IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _showDockerDetails(context),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  void _showDockerDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _DockerDetailsPage(),
      ),
    );
  }
}

class _DockerDetailsPage extends ConsumerStatefulWidget {
  const _DockerDetailsPage();

  @override
  ConsumerState<_DockerDetailsPage> createState() => _DockerDetailsPageState();
}

class _DockerDetailsPageState extends ConsumerState<_DockerDetailsPage> {
  List<DockerContainer>? _containers;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContainers();
  }

  Future<void> _loadContainers() async {
    setState(() => _loading = true);
    // TODO: Fetch actual container list from SSH
    // For now, simulate
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _containers = [
        DockerContainer(
          id: 'abc123',
          name: 'web-app',
          image: 'nginx:latest',
          status: 'running',
          ports: '80:80, 443:443',
        ),
        DockerContainer(
          id: 'def456',
          name: 'database',
          image: 'postgres:14',
          status: 'running',
          ports: '5432:5432',
        ),
      ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Docker Containers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContainers,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _containers == null || _containers!.isEmpty
              ? const Center(child: Text('No containers found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _containers!.length,
                  itemBuilder: (context, index) {
                    final container = _containers![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          Icons.widgets,
                          color: container.status == 'running' ? Colors.green : Colors.grey,
                        ),
                        title: Text(container.name),
                        subtitle: Text(
                          '${container.image}\n${container.status} • ${container.ports}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.article_outlined),
                          onPressed: () => _showContainerLogs(context, container),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showContainerLogs(BuildContext context, DockerContainer container) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ContainerLogsView(container: container),
    );
  }
}

class DockerContainer {
  final String id;
  final String name;
  final String image;
  final String status;
  final String ports;

  DockerContainer({
    required this.id,
    required this.name,
    required this.image,
    required this.status,
    required this.ports,
  });
}

class _ContainerLogsView extends StatefulWidget {
  const _ContainerLogsView({required this.container});

  final DockerContainer container;

  @override
  State<_ContainerLogsView> createState() => _ContainerLogsViewState();
}

class _ContainerLogsViewState extends State<_ContainerLogsView> {
  String _logs = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    // TODO: Fetch actual logs from SSH: docker logs ${widget.container.name} --tail 100
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _logs = '''
[2024-01-15 10:30:45] Starting container ${widget.container.name}
[2024-01-15 10:30:46] Initializing...
[2024-01-15 10:30:47] Service ready on port ${widget.container.ports}
[2024-01-15 10:30:50] Accepting connections
[2024-01-15 10:31:00] Health check passed
''';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          AppBar(
            title: Text('Logs: ${widget.container.name}'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadLogs,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    color: Colors.black,
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _logs,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NginxCard extends StatelessWidget {
  const _NginxCard({required this.info});

  final NginxInfo? info;

  @override
  Widget build(BuildContext context) {
    final available = info?.available ?? false;
    return Card(
      child: ListTile(
        leading: Icon(Icons.cloud, color: available ? Colors.lightBlueAccent : Colors.grey),
        title: const Text('Nginx'),
        subtitle: available
            ? Text(
                'Status: ${info!.status}\nServer name: ${info!.primaryServerName ?? 'unknown'}',
              )
            : const Text('Nginx not detected on this host'),
      ),
    );
  }
}

class _ResourceChart extends StatelessWidget {
  const _ResourceChart({
    required this.title,
    required this.data,
    required this.getValue,
    required this.color,
    required this.unit,
  });

  final String title;
  final List<ResourceStats> data;
  final double Function(ResourceStats) getValue;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),
              const Text('Collecting data...'),
            ],
          ),
        ),
      );
    }

    final maxValue = data.map(getValue).reduce((a, b) => a > b ? a : b);
    final currentValue = getValue(data.last);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  '${currentValue.toStringAsFixed(1)}$unit',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: CustomPaint(
                painter: _LineChartPainter(
                  data: data.map(getValue).toList(),
                  color: color,
                  maxValue: maxValue > 0 ? maxValue : 100,
                ),
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.data,
    required this.color,
    required this.maxValue,
  });

  final List<double> data;
  final Color color;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1).clamp(1, double.infinity);

    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxValue) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
