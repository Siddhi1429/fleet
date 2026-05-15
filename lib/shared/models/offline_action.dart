import 'package:hive/hive.dart';

class OfflineAction extends HiveObject {
  final String id;
  final String name;
  final String vehicleId;
  final DateTime createdAt;
  DateTime? lastSyncAttempt;
  int retryAttempts;
  String status;
  OfflineAction({
    required this.id,
    required this.name,
    required this.vehicleId,
    required this.createdAt,
    this.lastSyncAttempt,
    this.retryAttempts = 0,
    this.status = "Pending",
  });
}

class OfflineActionAdapter extends TypeAdapter<OfflineAction> {
  @override
  final int typeId = 0;

  @override
  OfflineAction read(BinaryReader reader) {
    return OfflineAction(
      id: reader.readString(),
      name: reader.readString(),
      vehicleId: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      lastSyncAttempt: reader.readBool() ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null,
      retryAttempts: reader.readInt(),
      status: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, OfflineAction obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.vehicleId);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeBool(obj.lastSyncAttempt != null);
    if (obj.lastSyncAttempt != null) {
      writer.writeInt(obj.lastSyncAttempt!.millisecondsSinceEpoch);
    }
    writer.writeInt(obj.retryAttempts);
    writer.writeString(obj.status);
  }
}
