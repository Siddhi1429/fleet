import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/fleet_app_bar.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../domain/fleet_provider.dart';
import 'widgets/vehicle_card.dart';

class FleetDashboardScreen extends ConsumerStatefulWidget {
  const FleetDashboardScreen({super.key});

  @override
  ConsumerState<FleetDashboardScreen> createState() =>
      _FleetDashboardScreenState();
}

class _FleetDashboardScreenState
    extends ConsumerState<FleetDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      ref.read(fleetProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fleetProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Column(
        children: [
          FleetAppBar(
            title: 'FleetOps Pro',
            subtitle: '${state.totalCount} vehicles in fleet',
            actions: [
              _ThemeToggleButton(),
            ],
          ),
          _buildSearchBar(state, isDark),
          _buildFilterChips(state, isDark),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor:
                  isDark ? AppColors.darkCard : Colors.white,
              onRefresh: () => ref.read(fleetProvider.notifier).refresh(),
              child: _buildBody(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(FleetState state, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDark ? AppColors.textPrimary : AppColors.textDark,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Search by ID, driver or status…',
          prefixIcon: Icon(Icons.search_rounded,
              size: 20,
              color: isDark ? AppColors.textMuted : AppColors.textMuted),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(fleetProvider.notifier).search('');
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {});
          // Debounce: only search after user stops typing briefly
          Future.delayed(const Duration(milliseconds: 400), () {
            if (_searchController.text == value) {
              ref.read(fleetProvider.notifier).search(value);
            }
          });
        },
      ),
    );
  }

  Widget _buildFilterChips(FleetState state, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          ...kStatusFilters.map((filter) {
            final selected = state.statusFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () =>
                    ref.read(fleetProvider.notifier).setFilter(filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? AppColors.primaryGradient
                        : null,
                    color: selected
                        ? null
                        : isDark
                            ? AppColors.darkCard
                            : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : isDark
                              ? AppColors.glassBorder
                              : AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : isDark
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          if (state.totalCount > 0)
            Text(
              '${state.vehicles.length} of ${state.totalCount}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMuted : AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(FleetState state) {
    if (state.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: 5,
        itemBuilder: (_, __) => const VehicleCardSkeleton(),
      );
    }

    if (state.error != null && state.vehicles.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.error_outline_rounded,
        title: 'Failed to Load Fleet',
        subtitle: state.error!,
        actionLabel: 'Retry',
        onAction: () => ref.read(fleetProvider.notifier).refresh(),
      );
    }

    if (state.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.local_shipping_rounded,
        title: 'No Vehicles Found',
        subtitle: 'Try a different search or filter.',
        actionLabel: 'Clear Search',
        onAction: () {
          _searchController.clear();
          ref.read(fleetProvider.notifier).search('');
          ref.read(fleetProvider.notifier).setFilter('All');
        },
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: state.vehicles.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.vehicles.length) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
          );
        }

        final vehicle = state.vehicles[index];
        return VehicleCard(
          vehicle: vehicle,
          onTap: () => context.pushNamed(
            'tracking',
            pathParameters: {'vehicleId': vehicle.id},
          ),
        );
      },
    );
  }
}

/// Small inline theme toggle
class _ThemeToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => ref.read(themeModeProvider.notifier).state =
          isDark ? ThemeMode.light : ThemeMode.dark,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          size: 18,
          color: isDark ? AppColors.warning : AppColors.primary,
        ),
      ),
    );
  }
}

/// Global theme mode provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
