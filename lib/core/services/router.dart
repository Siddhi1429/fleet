import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/fleet_dashboard/presentation/fleet_dashboard_screen.dart';
import '../../features/vehicle_tracking/presentation/vehicle_tracking_screen.dart';
import '../../features/offline_queue/presentation/offline_queue_screen.dart';
import '../../features/diagnostics/presentation/diagnostics_screen.dart';
import '../constants/app_colors.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (context, state) => const FleetDashboardScreen(),
          ),
          GoRoute(
            path: '/offline',
            name: 'offline',
            builder: (context, state) => const OfflineQueueScreen(),
          ),
          GoRoute(
            path: '/diagnostics',
            name: 'diagnostics',
            builder: (context, state) => const DiagnosticsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/tracking/:vehicleId',
        name: 'tracking',
        builder: (context, state) {
          final vehicleId = state.pathParameters['vehicleId']!;
          return VehicleTrackingScreen(vehicleId: vehicleId);
        },
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.glassBorder : Colors.grey.shade200,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _calculateSelectedIndex(location),
          onTap: (index) => _onItemTapped(index, context),
          elevation: 0,
          backgroundColor: isDark ? AppColors.darkBg : Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark ? AppColors.textMuted : Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Fleet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud_off_rounded),
              activeIcon: Icon(Icons.cloud_queue_rounded),
              label: 'Offline',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              activeIcon: Icon(Icons.analytics_rounded),
              label: 'Stats',
            ),
          ],
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(String location) {
    if (location == '/') return 0;
    if (location == '/offline') return 1;
    if (location == '/diagnostics') return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed('dashboard');
        break;
      case 1:
        context.goNamed('offline');
        break;
      case 2:
        context.goNamed('diagnostics');
        break;
    }
  }
}
