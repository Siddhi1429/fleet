import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/storage/hive_service.dart';
import '../../../shared/models/offline_action.dart';
import '../../diagnostics/domain/diagnostics_provider.dart';

final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(ref);
  manager.init();
  ref.onDispose(manager.dispose);
  return manager;
});

class SyncManager {
  final Ref _ref;
  final _uuid = const Uuid();
  StreamSubscription? _connectivitySub;
  bool _isSyncing = false;

  SyncManager(this._ref);

  void init() {
    // Listen for connectivity changes → auto sync on reconnect
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);
      if (isOnline) {
        _ref
            .read(diagnosticsProvider.notifier)
            .addLog('[SYNC] Connectivity restored — starting sync');
        syncAll();
      } else {
        _ref
            .read(diagnosticsProvider.notifier)
            .addLog('[NET] Offline — queuing actions for later');
      }
    });
    // Wrap in microtask to avoid modifying providers during initialization
    Future.microtask(() => _updateDiagnostics());
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  /// Queue a new offline action
  Future<void> queueAction({
    required String name,
    required String vehicleId,
  }) async {
    final action = OfflineAction(
      id: _uuid.v4(),
      name: name,
      vehicleId: vehicleId,
      createdAt: DateTime.now(),
    );
    await HiveService.offlineQueueBox.put(action.id, action);
    _ref
        .read(diagnosticsProvider.notifier)
        .addLog('[QUEUE] Enqueued: $name for $vehicleId');
    _updateDiagnostics();
  }

  /// Retry all pending / failed actions
  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    final box = HiveService.offlineQueueBox;
    final pending = box.values
        .where((a) => a.status == 'Pending' || a.status == 'Failed')
        .toList();

    if (pending.isEmpty) {
      _isSyncing = false;
      return;
    }

    _ref
        .read(diagnosticsProvider.notifier)
        .addLog('[SYNC] Syncing ${pending.length} action(s)…');

    for (final action in pending) {
      action.status = 'Retrying';
      action.lastSyncAttempt = DateTime.now();
      action.retryAttempts += 1;
      await action.save();

      // Simulate API latency
      await Future.delayed(
          Duration(milliseconds: 600 + action.retryAttempts * 200));

      // 85% success rate simulation
      final success = DateTime.now().millisecondsSinceEpoch % 7 != 0;
      if (success) {
        action.status = 'Synced';
        _ref.read(diagnosticsProvider.notifier).addLog(
            '[SYNC] ✓ ${action.name} (${action.vehicleId}) synced');
      } else {
        action.status = 'Failed';
        _ref.read(diagnosticsProvider.notifier).addLog(
            '[SYNC] ✗ ${action.name} (${action.vehicleId}) failed (attempt ${action.retryAttempts})');
      }
      await action.save();
    }

    _isSyncing = false;
    _updateDiagnostics();
  }

  Future<void> clearSynced() async {
    final box = HiveService.offlineQueueBox;
    final synced =
        box.values.where((a) => a.status == 'Synced').map((a) => a.id).toList();
    for (final id in synced) {
      await box.delete(id);
    }
    _updateDiagnostics();
  }

  void _updateDiagnostics() {
    _ref.read(diagnosticsProvider.notifier).updateCacheCounts(
          cachedRecords: HiveService.vehicleCacheBox.length,
          offlineQueue: HiveService.offlineQueueBox.length,
        );
  }
}
