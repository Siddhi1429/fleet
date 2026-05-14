import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusPill.fromStatus(String status) {
    if (status == 'Online') return StatusPill.online();
    return StatusPill.offline();
  }

  factory StatusPill.online() => const StatusPill(
        label: 'Online',
        color: AppColors.online,
        icon: Icons.wifi_rounded,
      );

  factory StatusPill.offline() => const StatusPill(
        label: 'Offline',
        color: AppColors.offline,
        icon: Icons.wifi_off_rounded,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
