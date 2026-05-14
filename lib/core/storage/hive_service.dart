import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/offline_action.dart';

class HiveService {
  static const String offlineQueueBoxName = 'offline_queue_box';
  static const String vehicleCacheBoxName = 'vehicle_cache_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(OfflineActionAdapter());
    await Hive.openBox<OfflineAction>(offlineQueueBoxName);
    await Hive.openBox<String>(vehicleCacheBoxName); // stores JSON strings
  }

  static Box<OfflineAction> get offlineQueueBox =>
      Hive.box<OfflineAction>(offlineQueueBoxName);

  static Box<String> get vehicleCacheBox =>
      Hive.box<String>(vehicleCacheBoxName);

  static Future<void> clearAll() async {
    await offlineQueueBox.clear();
    await vehicleCacheBox.clear();
  }
}
