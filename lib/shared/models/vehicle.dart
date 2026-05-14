/// Vehicle entity — domain model used throughout the app
class Vehicle {
  final String id;
  final String driverName;
  final String vehicleType;
  final double currentSpeed;
  final String status; // "Online" | "Offline"
  final DateTime lastUpdated;
  final double deliveryProgress;
  final double latitude;
  final double longitude;
  final double fuelLevel;
  final String eta;
  final int connectionQuality; // 0-100

  Vehicle({
    required this.id,
    required this.driverName,
    required this.vehicleType,
    required this.currentSpeed,
    required this.status,
    required this.lastUpdated,
    required this.deliveryProgress,
    required this.latitude,
    required this.longitude,
    required this.fuelLevel,
    required this.eta,
    required this.connectionQuality,
  });

  bool get isOnline => status == 'Online';

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      driverName: json['driverName'] as String,
      vehicleType: json['vehicleType'] as String? ?? 'Truck',
      currentSpeed: (json['currentSpeed'] as num).toDouble(),
      status: json['status'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      deliveryProgress: (json['deliveryProgress'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      fuelLevel: (json['fuelLevel'] as num).toDouble(),
      eta: json['eta'] as String? ?? '--',
      connectionQuality: (json['connectionQuality'] as num?)?.toInt() ?? 85,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverName': driverName,
      'vehicleType': vehicleType,
      'currentSpeed': currentSpeed,
      'status': status,
      'lastUpdated': lastUpdated.toIso8601String(),
      'deliveryProgress': deliveryProgress,
      'latitude': latitude,
      'longitude': longitude,
      'fuelLevel': fuelLevel,
      'eta': eta,
      'connectionQuality': connectionQuality,
    };
  }

  Vehicle copyWith({
    String? id,
    String? driverName,
    String? vehicleType,
    double? currentSpeed,
    String? status,
    DateTime? lastUpdated,
    double? deliveryProgress,
    double? latitude,
    double? longitude,
    double? fuelLevel,
    String? eta,
    int? connectionQuality,
  }) {
    return Vehicle(
      id: id ?? this.id,
      driverName: driverName ?? this.driverName,
      vehicleType: vehicleType ?? this.vehicleType,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      deliveryProgress: deliveryProgress ?? this.deliveryProgress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      eta: eta ?? this.eta,
      connectionQuality: connectionQuality ?? this.connectionQuality,
    );
  }
}
