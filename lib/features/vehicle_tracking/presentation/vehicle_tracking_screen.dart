import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/progress_bars.dart';
import '../../../core/widgets/status_pill.dart';
import '../data/mock_socket_service.dart';
import '../domain/tracking_provider.dart';

class VehicleTrackingScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  const VehicleTrackingScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<VehicleTrackingScreen> createState() =>
      _VehicleTrackingScreenState();
}

class _VehicleTrackingScreenState
    extends ConsumerState<VehicleTrackingScreen>
    with SingleTickerProviderStateMixin {
  late MapController _mapController;
  late AnimationController _pulseController;
  bool _followVehicle = true;
  bool _sheetExpanded = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _connectionColor(SocketConnectionState s) {
    switch (s) {
      case SocketConnectionState.connected:
        return AppColors.online;
      case SocketConnectionState.connecting:
      case SocketConnectionState.reconnecting:
        return AppColors.warning;
      case SocketConnectionState.disconnected:
        return AppColors.offline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackingProvider(widget.vehicleId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-follow camera
    if (_followVehicle && state.vehicle != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(
            LatLng(state.vehicle!.latitude, state.vehicle!.longitude),
            15.5,
          );
        } catch (_) {}
      });
    }

    final connectionColor = _connectionColor(state.connectionState);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Stack(
        children: [
          // ── MAP LAYER ──────────────────────────────────────────────
          _buildMap(state, isDark),

          // ── TOP BAR ───────────────────────────────────────────────
          _buildTopBar(context, state, isDark, connectionColor),

          // ── CONNECTION STATE BANNER ───────────────────────────────
          if (state.connectionState != SocketConnectionState.connected)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: _ConnectionBannerCard(
                label: state.connectionLabel,
                color: connectionColor,
              ),
            ),

          // ── FLOATING CONTROLS ─────────────────────────────────────
          _buildFloatingControls(state),

          // ── BOTTOM SHEET ──────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSheet(state, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(TrackingState state, bool isDark) {
    final position = state.vehicle != null
        ? LatLng(state.vehicle!.latitude, state.vehicle!.longitude)
        : const LatLng(37.7749, -122.4194);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: position,
        initialZoom: 15.5,
        onTap: (_, __) => setState(() => _followVehicle = false),
      ),
      children: [
        // OSM tile layer
        TileLayer(
          urlTemplate: isDark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.fleetops.pro',
        ),

        // Route polyline
        if (state.routeHistory.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: state.routeHistory,
                strokeWidth: 4,
                color: AppColors.primary.withOpacity(0.8),
                borderColor: AppColors.primaryDark.withOpacity(0.3),
                borderStrokeWidth: 2,
              ),
            ],
          ),

        // Vehicle marker
        if (state.vehicle != null)
          MarkerLayer(
            markers: [
              Marker(
                point: position,
                width: 60,
                height: 60,
                child: _AnimatedVehicleMarker(
                  controller: _pulseController,
                  isConnected: state.connectionState ==
                      SocketConnectionState.connected,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, TrackingState state, bool isDark,
      Color connectionColor) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (isDark ? AppColors.darkBg : Colors.white).withOpacity(0.95),
              (isDark ? AppColors.darkBg : Colors.white).withOpacity(0.0),
            ],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: isDark ? AppColors.textPrimary : AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.vehicleId,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color:
                          isDark ? AppColors.textPrimary : AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Live Tracking',
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
            // Connection pill
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: connectionColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: connectionColor.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PulsingDot(color: connectionColor),
                  const SizedBox(width: 5),
                  Text(
                    state.connectionLabel,
                    style: TextStyle(
                      color: connectionColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingControls(TrackingState state) {
    return Positioned(
      right: 16,
      bottom: _sheetExpanded ? 300 : 220,
      child: Column(
        children: [
          _FloatingButton(
            icon: _followVehicle
                ? Icons.my_location_rounded
                : Icons.location_searching_rounded,
            color: _followVehicle ? AppColors.primary : AppColors.textMuted,
            onTap: () => setState(() => _followVehicle = !_followVehicle),
            tooltip: 'Follow vehicle',
          ),
          const SizedBox(height: 8),
          _FloatingButton(
            icon: Icons.add_rounded,
            onTap: () {
              try {
                _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom + 1,
                );
              } catch (_) {}
            },
            tooltip: 'Zoom in',
          ),
          const SizedBox(height: 8),
          _FloatingButton(
            icon: Icons.remove_rounded,
            onTap: () {
              try {
                _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom - 1,
                );
              } catch (_) {}
            },
            tooltip: 'Zoom out',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(TrackingState state, bool isDark) {
    final v = state.vehicle;

    return GestureDetector(
      onVerticalDragEnd: (d) {
        setState(() => _sheetExpanded = d.primaryVelocity! < 0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.cardGradient
              : const LinearGradient(
                  colors: [Colors.white, Color(0xFFFAF7FF)],
                ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(
            top: BorderSide(color: AppColors.glassBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.15)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            if (v == null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Waiting for vehicle data…',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Driver + Status
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.driverName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppColors.textDark,
                                ),
                              ),
                              Text(
                                '${v.vehicleType} · ${v.id}',
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
                        StatusPill.online(),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Stats row
                    Row(
                      children: [
                        _TrackingStat(
                          label: 'Speed',
                          value: '${v.currentSpeed.toStringAsFixed(0)} km/h',
                          icon: Icons.speed_rounded,
                          color: AppColors.accentBlue,
                        ),
                        const SizedBox(width: 10),
                        _TrackingStat(
                          label: 'ETA',
                          value: v.eta,
                          icon: Icons.schedule_rounded,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(width: 10),
                        _TrackingStat(
                          label: 'Signal',
                          value: '${v.connectionQuality}%',
                          icon: Icons.signal_cellular_alt_rounded,
                          color: AppColors.online,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Progress bars
                    FuelBar(value: v.fuelLevel, showLabel: true),
                    const SizedBox(height: 10),
                    DeliveryProgressBar(
                        value: v.deliveryProgress, showLabel: true),

                    if (_sheetExpanded) ...[
                      const SizedBox(height: 16),
                      _buildRouteInfo(v, isDark),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo(vehicle, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Route Points',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textMuted,
                    )),
                const SizedBox(height: 4),
                Text(
                  '${ref.read(trackingProvider(widget.vehicleId)).routeHistory.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : AppColors.online.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivery',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textMuted,
                    )),
                const SizedBox(height: 4),
                Text(
                  '${(vehicle.deliveryProgress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.online,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ──────────────────────────────────────────────────────────────────────────────

class _AnimatedVehicleMarker extends StatelessWidget {
  final AnimationController controller;
  final bool isConnected;

  const _AnimatedVehicleMarker({
    required this.controller,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final pulse = 0.7 + controller.value * 0.3;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring
            if (isConnected)
              Container(
                width: 60 * pulse,
                height: 60 * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.15 * (1 - controller.value)),
                ),
              ),
            // Vehicle dot
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrackingStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _TrackingStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
            const SizedBox(height: 6),
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
              label,
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

class _FloatingButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color? color;

  const _FloatingButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18,
            color: color ?? (isDark ? AppColors.textPrimary : AppColors.textDark),
          ),
        ),
      ),
    );
  }
}

class _ConnectionBannerCard extends StatelessWidget {
  final String label;
  final Color color;

  const _ConnectionBannerCard({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: 0.5 + _c.value * 0.5,
        child: Container(
          width: 7,
          height: 7,
          decoration:
              BoxDecoration(color: widget.color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
