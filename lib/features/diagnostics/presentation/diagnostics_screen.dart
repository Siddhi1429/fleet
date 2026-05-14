import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/fleet_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/diagnostics_provider.dart';

class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diagnosticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Column(
        children: [
          FleetAppBar(
            title: 'Diagnostics',
            subtitle: 'App health & observability',
            actions: [
              GestureDetector(
                onTap: () => ref.read(diagnosticsProvider.notifier).clearLogs(),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : AppColors.offline.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: const Icon(Icons.delete_sweep_rounded,
                      size: 16, color: AppColors.offline),
                ),
              ),
            ],
          ),

          // Tab bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCard
                  : AppColors.lightCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(9),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark
                    ? AppColors.textSecondary
                    : AppColors.textMuted,
                labelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
                dividerColor: Colors.transparent,
                tabs: const [
                  Padding(
                    padding: EdgeInsets.only(left:12,right:12),
                    child: Tab(text: 'Metrics'),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left:12,right:12),
                    child: Tab(text: 'Log Terminal'),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MetricsTab(state: state),
                _LogTerminalTab(
                  logs: state.recentLogs,
                  scrollController: _logScrollController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// METRICS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _MetricsTab extends StatelessWidget {
  final DiagnosticsState state;
  const _MetricsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary metrics grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _MetricCard(
                label: 'Active API Calls',
                value: '${state.activeApiCalls}',
                icon: Icons.swap_horiz_rounded,
                color: AppColors.accentBlue,
                isLive: state.activeApiCalls > 0,
              ),
              _MetricCard(
                label: 'Total API Calls',
                value: '${state.totalApiCalls}',
                icon: Icons.timeline_rounded,
                color: AppColors.primaryLight,
              ),
              _MetricCard(
                label: 'Offline Queue',
                value: '${state.offlineQueueCount}',
                icon: Icons.cloud_queue_rounded,
                color: AppColors.warning,
              ),
              _MetricCard(
                label: 'Cache Records',
                value: '${state.cachedRecordsCount}',
                icon: Icons.storage_rounded,
                color: AppColors.online,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Socket + network status
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle('Network & Socket'),
                const SizedBox(height: 12),
                _StatusRow(
                  label: 'Socket State',
                  value: state.socketStatus,
                  valueColor: state.socketStatus == 'Connected'
                      ? AppColors.online
                      : AppColors.warning,
                ),
                const SizedBox(height: 8),
                _StatusRow(
                  label: 'Error Count',
                  value: '${state.totalErrors}',
                  valueColor: state.totalErrors > 0
                      ? AppColors.offline
                      : AppColors.online,
                ),
                const SizedBox(height: 8),
                _StatusRow(
                  label: 'Last Sync',
                  value: state.lastSync != null
                      ? DateFormat('HH:mm:ss').format(state.lastSync!)
                      : 'Never',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Mock performance
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle('Performance (Mock)'),
                const SizedBox(height: 12),
                _BarMetric(
                  label: 'API Latency',
                  value: 0.65,
                  display: '650ms avg',
                  color: AppColors.accentBlue,
                ),
                const SizedBox(height: 10),
                _BarMetric(
                  label: 'Memory Usage',
                  value: 0.42,
                  display: '42%',
                  color: AppColors.primaryLight,
                ),
                const SizedBox(height: 10),
                _BarMetric(
                  label: 'Frame Rate',
                  value: 0.95,
                  display: '57 fps',
                  color: AppColors.online,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Build info
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle('Build Info'),
                const SizedBox(height: 12),
                const _StatusRow(label: 'App Name', value: 'FleetOps Pro'),
                const SizedBox(height: 8),
                const _StatusRow(label: 'Version', value: '1.0.0+1'),
                const SizedBox(height: 8),
                const _StatusRow(
                    label: 'Architecture', value: 'Clean + Riverpod'),
                const SizedBox(height: 8),
                const _StatusRow(label: 'Map Provider', value: 'OpenStreetMap'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOG TERMINAL TAB
// ─────────────────────────────────────────────────────────────────────────────
class _LogTerminalTab extends StatelessWidget {
  final List<String> logs;
  final ScrollController scrollController;

  const _LogTerminalTab(
      {required this.logs, required this.scrollController});

  Color _logColor(String log) {
    if (log.contains('[ERR]')) return AppColors.offline;
    if (log.contains('[SYNC]')) return AppColors.online;
    if (log.contains('[QUEUE]')) return AppColors.warning;
    if (log.contains('[NET]')) return AppColors.accentBlue;
    if (log.contains('[RES]')) return AppColors.primaryLight;
    return const Color(0xFF9E9E9E);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF080B14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          // Terminal header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1320),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                _TermDot(color: AppColors.offline),
                const SizedBox(width: 6),
                _TermDot(color: AppColors.warning),
                const SizedBox(width: 6),
                _TermDot(color: AppColors.online),
                const SizedBox(width: 12),
                Text(
                  'fleet-ops-pro — log stream',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.4),
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.online,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      '// No logs yet\n// Interact with the app to generate logs',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.25),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          log,
                          style: TextStyle(
                            color: _logColor(log),
                            fontSize: 11,
                            fontFamily: 'monospace',
                            height: 1.5,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isLive;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              if (isLive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.online.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.online,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textPrimary : AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondary : AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textSecondary : AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatusRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondary : AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ??
                (isDark ? AppColors.textPrimary : AppColors.textDark),
          ),
        ),
      ],
    );
  }
}

class _BarMetric extends StatelessWidget {
  final String label;
  final double value;
  final String display;
  final Color color;

  const _BarMetric({
    required this.label,
    required this.value,
    required this.display,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondary : AppColors.textMuted,
              ),
            ),
            Text(
              display,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(builder: (_, constraints) {
          return Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(
                height: 6,
                width: constraints.maxWidth * value,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [color.withOpacity(0.7), color]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _TermDot extends StatelessWidget {
  final Color color;
  const _TermDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
