import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_admin_panel/common/responsive/admin_page_scaffold.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/widgets/shimmer_placeholder.dart';
import 'package:cricket_admin_panel/common/utils/formatters.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/admin/domain/analytics.dart';
import '../../blocs/dashboard/admin_dashboard_cubit.dart';
import '../../blocs/dashboard/admin_dashboard_state.dart';
import 'widgets/dashboard_widgets.dart';
import 'package:cricket_admin_panel/admin/presentation/widgets/charts/sport_category_chart.dart';
import 'package:cricket_admin_panel/admin/presentation/widgets/charts/booking_trend_chart.dart';
import 'package:cricket_admin_panel/admin/presentation/widgets/charts/booking_status_chart.dart';

enum DashboardDateFilter {
  last7Days,
  currentMonth,
  custom,
}

/// Landing screen: headline numbers, category booking analytics, trends, and the review queue.
class DashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenApprovals;
  final VoidCallback? onOpenSports;

  const DashboardScreen({
    super.key,
    this.onOpenApprovals,
    this.onOpenSports,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardDateFilter _dateFilter = DashboardDateFilter.last7Days;
  DateTimeRange? _customDateRange;
  String _selectedSport = 'All';

  @override
  void initState() {
    super.initState();
    context.read<AdminDashboardCubit>().fetchStats();
  }

  void _openApprovals() => widget.onOpenApprovals?.call();

  DateTimeRange _getActiveDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_dateFilter) {
      case DashboardDateFilter.last7Days:
        // 0 to 7 days: today and last 7 days (7 days ago to end of today)
        return DateTimeRange(
          start: today.subtract(const Duration(days: 7)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case DashboardDateFilter.currentMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case DashboardDateFilter.custom:
        if (_customDateRange != null) {
          return DateTimeRange(
            start: DateTime(
              _customDateRange!.start.year,
              _customDateRange!.start.month,
              _customDateRange!.start.day,
            ),
            end: DateTime(
              _customDateRange!.end.year,
              _customDateRange!.end.month,
              _customDateRange!.end.day,
              23,
              59,
              59,
            ),
          );
        }
        return DateTimeRange(
          start: today.subtract(const Duration(days: 7)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
    }
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final initialRange = _customDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: initialRange,
      helpText: 'Select Custom Date Range',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryDarkGreen,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _dateFilter = DashboardDateFilter.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        return AdminPageScaffold(
          title: 'Overview',
          subtitle: switch (state) {
            AdminDashboardLoaded(:final ownersCount, :final usersCount, :final totalBookingsCount) =>
              '$ownersCount owners · $usersCount users · $totalBookingsCount bookings',
            AdminDashboardLoading() => 'Loading…',
            _ => 'Loading',
          },
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: state is AdminDashboardLoading
                  ? null
                  : () => context.read<AdminDashboardCubit>().fetchStats(),
              icon: state is AdminDashboardLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
          child: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AdminDashboardState state) {
    if (state is AdminDashboardError) {
      return AdminStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load the dashboard',
        message: state.message,
        actionLabel: 'Retry',
        onAction: () => context.read<AdminDashboardCubit>().fetchStats(),
        tone: AdminStateTone.error,
      );
    }

    if (state is! AdminDashboardLoaded) {
      return const ShimmerPage(
        children: [
          ShimmerBanner(),
          SizedBox(height: 16),
          ShimmerTileGrid(
            count: 4,
            columnsAtExpanded: 4,
            columnsAtMedium: 2,
            columnsAtCompact: 1,
            tileHeight: 82,
          ),
          SizedBox(height: 22),
          ShimmerSectionHeader(),
          SizedBox(height: 12),
          ShimmerCardList(count: 3, lineCount: 2, avatar: true),
        ],
      );
    }

    final pending = state.pendingApprovalsCount;
    final shown = state.recentPendingOwners.length;
    final hasMore = pending > shown;

    // ─── Filter Bookings based on Date & Sport selections ────────────────────
    final activeDateRange = _getActiveDateRange();
    final dateFilteredBookings = filterBookingsByDateRange(
      state.allBookings,
      activeDateRange.start,
      activeDateRange.end,
    );

    // Compute sports analytics for the active date range
    final filteredSportsAnalytics = computeSportAnalytics(
      dateFilteredBookings,
      knownSports: state.sportsCatalogue,
    );

    // Collect all sport category options (All Sports + catalogue sports + active sports)
    final allSportNames = <String>{'All'};
    for (final s in state.sportsCatalogue) {
      if (s.name.trim().isNotEmpty) allSportNames.add(s.name.trim());
    }
    for (final s in filteredSportsAnalytics) {
      if (s.name.trim().isNotEmpty) allSportNames.add(s.name.trim());
    }
    final sportOptions = allSportNames.toList();

    // Filter by selected sport category (if specific sport chosen)
    final isAllSports = _selectedSport.toLowerCase() == 'all';
    final fullyFilteredBookings = isAllSports
        ? dateFilteredBookings
        : filterBookingsBySport(dateFilteredBookings, _selectedSport);

    // Compute trend and status breakdown for the filtered bookings
    final trendData = bookingsTrendForRange(
      fullyFilteredBookings,
      start: activeDateRange.start,
      end: activeDateRange.end,
    );
    final statusDist = bookingStatusDistribution(fullyFilteredBookings);

    final trendPill = '${fullyFilteredBookings.length} bookings';
    final trendSubtitle = isAllSports
        ? (_dateFilter == DashboardDateFilter.last7Days
            ? 'Daily booking volume over the last 7 days'
            : (_dateFilter == DashboardDateFilter.currentMonth
                ? 'Daily booking volume for current month'
                : 'Daily booking volume for selected dates'))
        : 'Daily booking volume for $_selectedSport';

    return RefreshIndicator(
      onRefresh: () => context.read<AdminDashboardCubit>().fetchStats(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Review queue action card
          DashboardActionCard(count: pending, onTap: _openApprovals),
          const SizedBox(height: 16),

          // Primary KPI summary tiles
          DashboardTileGrid(
            tiles: [
              DashboardStatTile(
                label: 'Bookable grounds',
                value: '${state.activeGroundsCount}',
                icon: Icons.sports_cricket_rounded,
                color: AppColors.primaryLightGreen,
              ),
              DashboardStatTile(
                label: 'Registered owners',
                value: '${state.ownersCount}',
                icon: Icons.storefront_rounded,
                color: AppColors.primaryDarkGreen,
              ),
              DashboardStatTile(
                label: 'Registered users',
                value: '${state.usersCount}',
                icon: Icons.people_alt_rounded,
                color: Colors.blue.shade700,
              ),
              DashboardStatTile(
                label: 'Confirmed revenue',
                value: '₹${formatInr(state.totalRevenue.round())}',
                icon: Icons.payments_rounded,
                color: AppColors.goldenYellow,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Filter Bar: Date (0-7d, Month, Custom) & Sport Category Options ──
          _buildFilterBar(
            context,
            sportOptions: sportOptions,
            sportsAnalytics: filteredSportsAnalytics,
            totalDateBookings: dateFilteredBookings.length,
            isAllSports: isAllSports,
          ),
          const SizedBox(height: 20),

          // ─── Sports Category Bookings Breakdown & Analytics ───────────────
          SportCategoryChartCard(
            sports: filteredSportsAnalytics,
            selectedSport: isAllSports ? null : _selectedSport,
            onSelectSport: (sport) {
              setState(() {
                if (_selectedSport.toLowerCase() == sport.toLowerCase()) {
                  _selectedSport = 'All';
                } else {
                  _selectedSport = sport;
                }
              });
            },
            onManageSports: widget.onOpenSports,
          ),
          const SizedBox(height: 18),

          // ─── Booking Activity Trends & Status Distribution ─────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 960) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: BookingTrendChartCard(
                        trend: trendData,
                        subtitle: trendSubtitle,
                        pillLabel: trendPill,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: BookingStatusChartCard(
                        statusDistribution: statusDist,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    BookingTrendChartCard(
                      trend: trendData,
                      subtitle: trendSubtitle,
                      pillLabel: trendPill,
                    ),
                    const SizedBox(height: 16),
                    BookingStatusChartCard(
                      statusDistribution: statusDist,
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // ─── Owners Awaiting Approval Section ─────────────────────────────
          DashboardSectionHeader(
            title: 'Owners awaiting approval',
            actionLabel: hasMore || pending == 0 ? 'View all' : null,
            onAction: hasMore || pending == 0 ? _openApprovals : null,
          ),

          if (state.recentPendingOwners.isEmpty)
            AdminSurface(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: AdminStateView(
                icon: Icons.verified_rounded,
                title: 'No owners waiting',
                message: 'New submissions will appear here for review.',
              ),
            )
          else ...[
            for (final owner in state.recentPendingOwners) ...[
              DashboardPendingOwnerRow(owner: owner, onTap: _openApprovals),
              const SizedBox(height: 8),
            ],
            if (hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Showing the first $shown of $pending waiting owners.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context, {
    required List<String> sportOptions,
    required List<SportAnalytics> sportsAnalytics,
    required int totalDateBookings,
    required bool isAllSports,
  }) {
    final theme = Theme.of(context);

    String customRangeLabel = 'Custom';
    if (_dateFilter == DashboardDateFilter.custom && _customDateRange != null) {
      final s = _customDateRange!.start;
      final e = _customDateRange!.end;
      customRangeLabel = '${s.day}/${s.month} - ${e.day}/${e.month}';
    }

    return AdminSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Title & Date Filters (0 to 7 days, Current month, Custom) ──
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;

              final titleSection = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLightGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: AppColors.primaryLightGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Analytics Scope & Filters',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );

              final dateButtons = Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DateFilterChip(
                      label: '0 to 7 days',
                      icon: Icons.calendar_view_week_rounded,
                      isSelected: _dateFilter == DashboardDateFilter.last7Days,
                      onTap: () => setState(() => _dateFilter = DashboardDateFilter.last7Days),
                    ),
                    const SizedBox(width: 4),
                    _DateFilterChip(
                      label: 'Current month',
                      icon: Icons.calendar_month_rounded,
                      isSelected: _dateFilter == DashboardDateFilter.currentMonth,
                      onTap: () => setState(() => _dateFilter = DashboardDateFilter.currentMonth),
                    ),
                    const SizedBox(width: 4),
                    _DateFilterChip(
                      label: customRangeLabel,
                      icon: Icons.date_range_rounded,
                      isSelected: _dateFilter == DashboardDateFilter.custom,
                      onTap: _pickCustomDateRange,
                    ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    titleSection,
                    dateButtons,
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleSection,
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: dateButtons,
                    ),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
          const SizedBox(height: 12),

          // ── Sport Category Selection (Dropdown + Quick Option Chips) ────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 680;

              final dropdownWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: sportOptions.contains(_selectedSport) ? _selectedSport : 'All',
                    isDense: true,
                    borderRadius: BorderRadius.circular(8),
                    icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    items: [
                      for (final opt in sportOptions)
                        DropdownMenuItem(
                          value: opt,
                          child: Text(opt == 'All' ? 'All Sports' : opt),
                        ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSport = val);
                    },
                  ),
                ),
              );

              final chipsRow = SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // 'All Sports' option chip
                    _SportFilterChip(
                      name: 'All Sports',
                      count: totalDateBookings,
                      colorHex: '#0B8457',
                      isSelected: isAllSports,
                      onTap: () => setState(() => _selectedSport = 'All'),
                    ),
                    const SizedBox(width: 8),
                    // Each sport category option chip
                    for (final s in sportsAnalytics) ...[
                      _SportFilterChip(
                        name: s.name,
                        count: s.totalBookings,
                        colorHex: s.colorHex,
                        isSelected: _selectedSport.toLowerCase() == s.name.toLowerCase(),
                        onTap: () => setState(() => _selectedSport = s.name),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Sport Category:',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        dropdownWidget,
                      ],
                    ),
                    const SizedBox(height: 10),
                    chipsRow,
                  ],
                );
              } else {
                return Row(
                  children: [
                    Text(
                      'Sport Category:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                    dropdownWidget,
                    const SizedBox(width: 12),
                    Expanded(child: chipsRow),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _DateFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateFilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeBg = AppColors.primaryDarkGreen;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SportFilterChip extends StatelessWidget {
  final String name;
  final int count;
  final String colorHex;
  final bool isSelected;
  final VoidCallback onTap;

  const _SportFilterChip({
    required this.name,
    required this.count,
    required this.colorHex,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = parseHexColor(colorHex) ?? AppColors.primaryLightGreen;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? dotColor.withValues(alpha: 0.16)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? dotColor : theme.dividerColor.withValues(alpha: 0.6),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? dotColor : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? dotColor.withValues(alpha: 0.2)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? dotColor : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
