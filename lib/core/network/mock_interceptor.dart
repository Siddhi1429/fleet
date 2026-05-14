import 'package:dio/dio.dart';
import 'dart:math';

/// Vehicle types for mock data diversity
const _vehicleTypes = [
  'Heavy Truck',
  'Delivery Van',
  'Refrigerated Truck',
  'Flatbed',
  'Tanker',
  'Box Truck',
  'Pickup',
  'Semi-Trailer',
];

const _driverNames = [
  'Marcus Johnson',
  'Aisha Patel',
  'Carlos Rivera',
  'Emily Chen',
  'David Okonkwo',
  'Sarah Kim',
  'James Okafor',
  'Priya Sharma',
  'Lucas Müller',
  'Fatima Al-Hassan',
  'Miguel Torres',
  'Anna Kowalski',
  'Raj Nair',
  'Sofia Andersen',
  'Omar Hassan',
  'Yuki Tanaka',
  'Abdul Karim',
  'Nadia Petrova',
  'Thomas Weber',
  'Leila Ahmadi',
];

const _etaOptions = [
  '12 min', '25 min', '38 min', '1h 05m', '1h 42m',
  '2h 10m', '45 min', '55 min', 'Arrived', '8 min',
];

/// Mock interceptor that simulates a real fleet management API
class MockInterceptor extends Interceptor {
  final Random _random = Random(42); // Seeded for consistent names
  final Random _dynamicRandom = Random();

  List<Map<String, dynamic>> _generateAllVehicles() {
    return List.generate(60, (index) {
      final isOnline = index % 6 != 0; // ~83% online
      return {
        'id': 'VEH-${1000 + index}',
        'driverName': _driverNames[index % _driverNames.length],
        'vehicleType': _vehicleTypes[index % _vehicleTypes.length],
        'currentSpeed': isOnline
            ? _dynamicRandom.nextDouble() * 90 + 10
            : 0.0,
        'status': isOnline ? 'Online' : 'Offline',
        'lastUpdated': DateTime.now()
            .subtract(Duration(minutes: _dynamicRandom.nextInt(30)))
            .toIso8601String(),
        'deliveryProgress': _dynamicRandom.nextDouble(),
        'latitude': 37.7749 + (_dynamicRandom.nextDouble() - 0.5) * 0.2,
        'longitude': -122.4194 + (_dynamicRandom.nextDouble() - 0.5) * 0.2,
        'fuelLevel': _dynamicRandom.nextDouble() * 0.8 + 0.1,
        'eta': isOnline ? _etaOptions[index % _etaOptions.length] : 'N/A',
        'connectionQuality': isOnline
            ? _dynamicRandom.nextInt(40) + 60
            : 0,
      };
    });
  }

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    await Future.delayed(Duration(milliseconds: 600 + _dynamicRandom.nextInt(400)));

    final path = options.path;

    // GET /vehicles — paginated list
    if (path == '/vehicles' && options.method == 'GET') {
      final page =
          int.tryParse(options.queryParameters['page']?.toString() ?? '1') ??
              1;
      final limit =
          int.tryParse(options.queryParameters['limit']?.toString() ?? '20') ??
              20;
      final search = options.queryParameters['search']?.toString().toLowerCase();
      final statusFilter = options.queryParameters['status']?.toString();

      var all = _generateAllVehicles();

      if (search != null && search.isNotEmpty) {
        all = all
            .where((v) =>
                v['id']!.toString().toLowerCase().contains(search) ||
                v['driverName']!.toString().toLowerCase().contains(search) ||
                v['status']!.toString().toLowerCase().contains(search))
            .toList();
      }

      if (statusFilter != null && statusFilter != 'All') {
        all = all.where((v) => v['status'] == statusFilter).toList();
      }

      final total = all.length;
      final start = (page - 1) * limit;
      final end = (start + limit).clamp(0, total);
      final paginated = start < total ? all.sublist(start, end) : <Map<String, dynamic>>[];

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'data': paginated,
          'total': total,
          'page': page,
          'limit': limit,
          'hasMore': end < total,
        },
      ));
    }

    // GET /vehicles/:id — single vehicle
    if (path.startsWith('/vehicles/') && options.method == 'GET') {
      final id = path.split('/').last;
      final all = _generateAllVehicles();
      final match = all.firstWhere(
        (v) => v['id'] == id,
        orElse: () => all.first,
      );
      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: match,
      ));
    }

    // Default 404
    return handler.resolve(Response(
      requestOptions: options,
      statusCode: 404,
      data: {'message': 'Not Found'},
    ));
  }
}
