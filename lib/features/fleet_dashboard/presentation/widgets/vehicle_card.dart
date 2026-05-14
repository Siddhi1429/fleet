import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/progress_bars.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../shared/models/vehicle.dart';

class VehicleCard extends StatefulWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  const VehicleCard({super.key, required this.vehicle, required this.onTap});

  @override
  State<VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<VehicleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _vehicleIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('van')) return Icons.airport_shuttle_rounded;
    if (t.contains('tanker')) return Icons.local_gas_station_rounded;
    if (t.contains('flatbed')) return Icons.rv_hookup_rounded;
    if (t.contains('pickup')) return Icons.directions_car_rounded;
    return Icons.local_shipping_rounded;
  }

  Color _connectionColor(int quality) {
    if (quality >= 70) return AppColors.online;
    if (quality >= 40) return AppColors.warning;
    return AppColors.offline;
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeAgo =
        DateFormat('HH:mm').format(v.lastUpdated);

    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Top accent strip
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: v.isOnline
                      ? const LinearGradient(
                          colors: [AppColors.online, Color(0xFF00C8B4)])
                      : const LinearGradient(
                          colors: [AppColors.offline, Color(0xFFFF8080)]),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: ID + vehicle icon + status pill
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _vehicleIcon(v.vehicleType),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.id,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppColors.textDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                v.vehicleType,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusPill.fromStatus(v.status),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Row 2: Driver name + last updated
                    Row(
                      children: [
                        Icon(Icons.person_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.textMuted),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            v.driverName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.access_time_rounded,
                            size: 12,
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Row 3: Stats grid
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.speed_rounded,
                          value: '${v.currentSpeed.toStringAsFixed(0)}',
                          unit: 'km/h',
                          color: AppColors.accentBlue,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: Icons.schedule_rounded,
                          value: v.eta,
                          unit: 'ETA',
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: Icons.signal_cellular_alt_rounded,
                          value: '${v.connectionQuality}%',
                          unit: 'Signal',
                          color: _connectionColor(v.connectionQuality),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Progress bars
                    DeliveryProgressBar(
                      value: v.deliveryProgress,
                      showLabel: true,
                    ),
                    const SizedBox(height: 8),
                    FuelBar(value: v.fuelLevel, showLabel: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.glassBorder : color.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimary : AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.textMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
