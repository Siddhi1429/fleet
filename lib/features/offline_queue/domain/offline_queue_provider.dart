import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/storage/hive_service.dart';
import '../../../shared/models/offline_action.dart';

final offlineQueueProvider = StreamProvider<List<OfflineAction>>((ref) {
  final box = HiveService.offlineQueueBox;

  Stream<List<OfflineAction>> _sortedList() {
    final list = box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Stream.value(list);
  }

  return Stream.multi((controller) async {
    // Emit initial state
    final initial = box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    controller.add(initial);

    // Emit on every Hive change event
    final sub = box.watch().listen((_) {
      final updated = box.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(updated);
    });

    ref.onDispose(() => sub.cancel());
  });
});

/// Queue statistics provider
final queueStatsProvider = Provider<Map<String, int>>((ref) {
  final asyncQueue = ref.watch(offlineQueueProvider);
  return asyncQueue.when(
    data: (list) => {
      'total': list.length,
      'pending': list.where((a) => a.status == 'Pending').length,
      'retrying': list.where((a) => a.status == 'Retrying').length,
      'failed': list.where((a) => a.status == 'Failed').length,
      'synced': list.where((a) => a.status == 'Synced').length,
    },
    loading: () => {'total': 0, 'pending': 0, 'retrying': 0, 'failed': 0, 'synced': 0},
    error: (_, __) => {'total': 0, 'pending': 0, 'retrying': 0, 'failed': 0, 'synced': 0},
  );
});
