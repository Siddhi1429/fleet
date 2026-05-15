import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'core/services/router.dart';
import 'core/storage/hive_service.dart';
import 'features/fleet_dashboard/presentation/fleet_dashboard_screen.dart';
import 'features/offline_queue/domain/sync_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  await HiveService.init();

  runApp(
    const ProviderScope(
      child: FleetOpsApp(),
    ),
  );
}

class FleetOpsApp extends ConsumerWidget {
  const FleetOpsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    ref.watch(syncManagerProvider);

    return MaterialApp.router(
      title: 'FleetOps Pro',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
