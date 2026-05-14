import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/vehicle.dart';
import '../data/fleet_repository.dart';

const int _kPageSize = 20;

/// Filter options for status chip bar
const List<String> kStatusFilters = ['All', 'Online', 'Offline'];

class FleetState {
  final List<Vehicle> vehicles;
  final bool isLoading;
  final bool isPaginating;
  final bool hasMore;
  final int page;
  final String? error;
  final String searchQuery;
  final String statusFilter;
  final int totalCount;

  const FleetState({
    this.vehicles = const [],
    this.isLoading = false,
    this.isPaginating = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
    this.searchQuery = '',
    this.statusFilter = 'All',
    this.totalCount = 0,
  });

  bool get isEmpty => !isLoading && vehicles.isEmpty && error == null;

  FleetState copyWith({
    List<Vehicle>? vehicles,
    bool? isLoading,
    bool? isPaginating,
    bool? hasMore,
    int? page,
    String? error,
    bool clearError = false,
    String? searchQuery,
    String? statusFilter,
    int? totalCount,
  }) {
    return FleetState(
      vehicles: vehicles ?? this.vehicles,
      isLoading: isLoading ?? this.isLoading,
      isPaginating: isPaginating ?? this.isPaginating,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class FleetNotifier extends Notifier<FleetState> {
  @override
  FleetState build() {
    Future.microtask(() => _fetchPage(refresh: true));
    return const FleetState(isLoading: true);
  }

  Future<void> _fetchPage({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        page: 1,
        vehicles: [],
        hasMore: true,
      );
    } else {
      if (state.isPaginating || !state.hasMore) return;
      state = state.copyWith(isPaginating: true, clearError: true);
    }

    try {
      final repo = ref.read(fleetRepositoryProvider);
      final result = await repo.getVehicles(
        page: refresh ? 1 : state.page,
        limit: _kPageSize,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        statusFilter: state.statusFilter == 'All' ? null : state.statusFilter,
      );

      final updatedVehicles = refresh
          ? result.vehicles
          : [...state.vehicles, ...result.vehicles];

      state = state.copyWith(
        vehicles: updatedVehicles,
        page: (refresh ? 1 : state.page) + 1,
        hasMore: result.hasMore,
        isLoading: false,
        isPaginating: false,
        totalCount: result.total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isPaginating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() => _fetchPage(refresh: true);

  Future<void> loadMore() async {
    if (state.isLoading || state.isPaginating || !state.hasMore) return;
    await _fetchPage();
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
    _fetchPage(refresh: true);
  }

  void setFilter(String filter) {
    if (state.statusFilter == filter) return;
    state = state.copyWith(statusFilter: filter);
    _fetchPage(refresh: true);
  }
}

final fleetProvider = NotifierProvider<FleetNotifier, FleetState>(() {
  return FleetNotifier();
});
