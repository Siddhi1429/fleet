import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/models/vehicle.dart';

abstract class IFleetRepository {
  Future<({List<Vehicle> vehicles, int total, bool hasMore})> getVehicles({
    required int page,
    required int limit,
    String? search,
    String? statusFilter,
  });
}

final fleetRepositoryProvider = Provider<IFleetRepository>((ref) {
  return FleetRepository(ref.read(dioProvider));
});

class FleetRepository implements IFleetRepository {
  final Dio _dio;
  FleetRepository(this._dio);

  @override
  Future<({List<Vehicle> vehicles, int total, bool hasMore})> getVehicles({
    required int page,
    required int limit,
    String? search,
    String? statusFilter,
  }) async {
    final response = await _dio.get(
      '/vehicles',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (statusFilter != null && statusFilter != 'All') 'status': statusFilter,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List)
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();

    return (
      vehicles: list,
      total: data['total'] as int,
      hasMore: data['hasMore'] as bool? ?? false,
    );
  }
}
