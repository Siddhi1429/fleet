import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/fleet_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../shared/models/offline_action.dart';
import '../domain/offline_queue_provider.dart';
import '../domain/sync_manager.dart';

const _kSimulatedActions = [
  ('Mark Inspected', Icons.fact_check_rounded),
  ('Refresh Tracking', Icons.refresh_rounded),
  ('Update Delivery Progress', Icons.local_shipping_rounded),
  ('Add Driver Note', Icons.note_add_rounded),
];

const _kVehicleIds = [
  'VEH-1001', 'VEH-1005', 'VEH-1012', 'VEH-1023', 'VEH-1034',
];

class OfflineQueueScreen extends ConsumerStatefulWidget {
  const OfflineQueueScreen({super.key});

  @override
  ConsumerState<OfflineQueueScreen> createState() => _OfflineQueueScreenState();
}

class _OfflineQueueScreenState extends ConsumerState<OfflineQueueScreen> {
  int _actionIndex = 0;
  int _vehicleIndex = 0;
  bool _isSyncing = false;

  Future<void> _addAction() async {
    final action = _kSimulatedActions[_actionIndex % _kSimulatedActions.length];
    final vehicleId = _kVehicleIds[_vehicleIndex % _kVehicleIds.length];
    _actionIndex++;
    _vehicleIndex++;
    await ref.read(syncManagerProvider).queueAction(
          name: action.$1,
          vehicleId: vehicleId,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              Icon(action.$2, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                '${action.$1} queued for $vehicleId',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _syncAll() async {
    setState(() => _isSyncing = true);
    await ref.read(syncManagerProvider).syncAll();
    if (mounted) setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(offlineQueueProvider);
    final stats = ref.watch(queueStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Column(
        children: [
          FleetAppBar(
            title: 'Offline Queue',
            subtitle: '${stats['total']} actions',
            actions: [
              // Sync button
              GestureDetector(
                onTap: _isSyncing ? null : _syncAll,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: _isSyncing ? null : AppColors.primaryGradient,
                    color: _isSyncing
                        ? (isDark ? AppColors.darkCard : Colors.grey.shade200)
                        : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        )
                      : const Row(
                          children: [
                            Icon(Icons.cloud_sync_rounded,
                                size: 14, color: Colors.white),
                            SizedBox(width: 5),
                            Text('Sync All',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                ),
              ),
              // Add action button
              GestureDetector(
                onTap: _addAction,
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: const Icon(Icons.add_rounded,
                      size: 18, color: AppColors.primary),
                ),
              ),
            ],
          ),

          // Stats bar
          _buildStatsBar(stats, isDark),

          // Clear synced button
          if ((stats['synced'] ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: GestureDetector(
                onTap: () => ref.read(syncManagerProvider).clearSynced(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isDark
                            ? AppColors.glassBorder
                            : Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cleaning_services_rounded,
                          size: 14,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        'Clear ${stats['synced']} synced item(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Queue list
          Expanded(
            child: queueAsync.when(
              data: (actions) {
                if (actions.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.inbox_rounded,
                    title: 'Queue is Empty',
                    subtitle:
                        'Tap + to simulate offline actions.\nThey will auto-sync when connected.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: actions.length,
                  itemBuilder: (context, index) {
                    return _QueueItemCard(
                      action: actions[index],
                      isLast: index == actions.length - 1,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              error: (e, _) => EmptyStateWidget(
                icon: Icons.error_outline_rounded,
                title: 'Error Loading Queue',
                subtitle: e.toString(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(Map<String, int> stats, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          _StatPill(
              label: 'Pending',
              count: stats['pending'] ?? 0,
              color: AppColors.warning),
          const SizedBox(width: 6),
          _StatPill(
              label: 'Retrying',
              count: stats['retrying'] ?? 0,
              color: AppColors.accentBlue),
          const SizedBox(width: 6),
          _StatPill(
              label: 'Failed',
              count: stats['failed'] ?? 0,
              color: AppColors.offline),
          const SizedBox(width: 6),
          _StatPill(
              label: 'Synced',
              count: stats['synced'] ?? 0,
              color: AppColors.online),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatPill(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueItemCard extends StatelessWidget {
  final OfflineAction action;
  final bool isLast;

  const _QueueItemCard({required this.action, required this.isLast});

  Color _statusColor() {
    switch (action.status) {
      case 'Synced':
        return AppColors.online;
      case 'Failed':
        return AppColors.offline;
      case 'Retrying':
        return AppColors.accentBlue;
      default:
        return AppColors.warning;
    }
  }

  IconData _statusIcon() {
    switch (action.status) {
      case 'Synced':
        return Icons.check_circle_rounded;
      case 'Failed':
        return Icons.cancel_rounded;
      case 'Retrying':
        return Icons.sync_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  IconData _actionIcon() {
    final n = action.name.toLowerCase();
    if (n.contains('inspect')) return Icons.fact_check_rounded;
    if (n.contains('refresh')) return Icons.refresh_rounded;
    if (n.contains('delivery')) return Icons.local_shipping_rounded;
    if (n.contains('note')) return Icons.note_add_rounded;
    return Icons.task_alt_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _statusColor();
    final timeFormat = DateFormat('HH:mm:ss');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Icon(_statusIcon(), size: 14, color: color),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color.withOpacity(0.4), Colors.transparent],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Card content
        Expanded(
          child: GlassCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_actionIcon(),
                        size: 16,
                        color: isDark
                            ? AppColors.primaryLight
                            : AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        action.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        action.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MetaChip(
                        icon: Icons.directions_car_rounded,
                        label: action.vehicleId),
                    const SizedBox(width: 8),
                    _MetaChip(
                        icon: Icons.refresh_rounded,
                        label: '${action.retryAttempts} retries'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 11,
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Created ${timeFormat.format(action.createdAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textMuted,
                      ),
                    ),
                    if (action.lastSyncAttempt != null) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.sync_rounded,
                          size: 11,
                          color: isDark
                              ? AppColors.textMuted
                              : AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Last: ${timeFormat.format(action.lastSyncAttempt!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textMuted
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? AppColors.glassBorder
              : AppColors.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11,
              color: isDark ? AppColors.textSecondary : AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textSecondary : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
