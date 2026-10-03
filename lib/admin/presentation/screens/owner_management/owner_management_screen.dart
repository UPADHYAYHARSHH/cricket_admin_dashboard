import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';
import 'package:cricket_admin_panel/common/responsive/admin_page_scaffold.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/widgets/shimmer_placeholder.dart';
import '../../blocs/owners/owner_management_cubit.dart';
import '../../blocs/owners/owner_management_state.dart';
import 'widgets/owner_kpi_strip.dart';
import 'widgets/owner_filters_bar.dart';
import 'widgets/owner_desktop_table.dart';
import 'widgets/owner_mobile_card.dart';
import 'widgets/owner_status_pill.dart';

/// Admin screen for reviewing and approving ground owners.
///
/// Behaviour is unchanged from the original implementation: the same cubit
/// calls, the same arguments, the same state handling. The screen filters and
/// sorts the already-loaded list on the client, adds an at-a-glance summary,
/// surfaces the rejection reason that was previously written but never shown,
/// and switches between a data table and cards based on
/// [AdminBreakpoints.hasTableSpace].
class OwnerManagementScreen extends StatefulWidget {
  const OwnerManagementScreen({super.key});

  @override
  State<OwnerManagementScreen> createState() => _OwnerManagementScreenState();
}

class _OwnerManagementScreenState extends State<OwnerManagementScreen> {
  // --- View-only state. None of this is persisted or sent anywhere. ----------
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  OwnerStatus? _statusFilter;
  OwnerSort _sort = OwnerSort.revenueDesc;

  @override
  void initState() {
    super.initState();
    context.read<OwnerManagementCubit>().fetchOwners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    if (_query == value) return;
    setState(() => _query = value);
  }

  void _setStatus(OwnerStatus? value) {
    if (_statusFilter == value) return;
    setState(() => _statusFilter = value);
  }

  void _setSort(OwnerSort value) {
    if (_sort == value) return;
    setState(() => _sort = value);
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _statusFilter = null;
    });
  }

  /// Case-insensitive match across the identifying fields an admin would
  /// actually search by.
  static bool _matchesQuery(OwnerSummary summary, String query) {
    if (query.isEmpty) return true;
    final needle = query.toLowerCase();

    bool hit(Object? value) =>
        value != null && value.toString().toLowerCase().contains(needle);

    return hit(summary.owner['owner_name']) ||
        hit(summary.owner['business_name']) ||
        hit(summary.owner['business_email']) ||
        hit(summary.owner['phone']);
  }

  List<OwnerSummary> _applyView(List<OwnerSummary> owners) {
    final filtered = owners
        .where((s) => _matchesQuery(s, _query))
        .where((s) =>
            _statusFilter == null ||
            OwnerStatus.from(s.owner) == _statusFilter)
        .toList();

    switch (_sort) {
      case OwnerSort.revenueDesc:
        filtered.sort((a, b) => b.revenue.compareTo(a.revenue));
      case OwnerSort.bookingsDesc:
        filtered.sort((a, b) => b.bookingsCount.compareTo(a.bookingsCount));
      case OwnerSort.nameAsc:
        filtered.sort(
          (a, b) => (a.owner['owner_name'] as String? ?? '')
              .toLowerCase()
              .compareTo((b.owner['owner_name'] as String? ?? '').toLowerCase()),
        );
      case OwnerSort.pendingFirst:
        filtered.sort((a, b) {
          final rank = _pendingRank(OwnerStatus.from(a.owner))
              .compareTo(_pendingRank(OwnerStatus.from(b.owner)));
          if (rank != 0) return rank;
          return b.revenue.compareTo(a.revenue);
        });
    }

    return filtered;
  }

  static int _pendingRank(OwnerStatus status) => switch (status) {
        OwnerStatus.pending => 0,
        OwnerStatus.approved => 1,
        OwnerStatus.rejected => 2,
      };

  Map<OwnerStatus?, int> _statusCounts(List<OwnerSummary> owners) {
    final counts = <OwnerStatus?, int>{null: 0};
    for (final status in OwnerStatus.values) {
      counts[status] = 0;
    }
    for (final summary in owners) {
      final status = OwnerStatus.from(summary.owner);
      counts[status] = (counts[status] ?? 0) + 1;
      counts[null] = (counts[null] ?? 0) + 1;
    }
    return counts;
  }

  void _showRejectDialog(String ownerId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Owner'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<OwnerManagementCubit>().rejectOwner(
                ownerId,
                reason: reasonController.text.trim().isNotEmpty
                    ? reasonController.text.trim()
                    : null,
              );
              Navigator.pop(context);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).whenComplete(reasonController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OwnerManagementCubit>();
    final useTable = AdminBreakpoints.hasTableSpace(context);

    return BlocBuilder<OwnerManagementCubit, OwnerManagementState>(
      builder: (context, state) {
        final owners = state is OwnerManagementLoaded ? state.owners : null;

        return AdminPageScaffold(
          title: 'Owner Management',
          subtitle: owners == null
              ? 'Loading owners'
              : '${owners.length} owner${owners.length == 1 ? '' : 's'} registered',
          actions: [
            IconButton(
              tooltip: 'Refresh owners',
              onPressed: state is OwnerManagementLoading
                  ? null
                  : () => cubit.fetchOwners(),
              icon: state is OwnerManagementLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
          child: _buildBody(context, state, owners, cubit, useTable),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    OwnerManagementState state,
    List<OwnerSummary>? owners,
    OwnerManagementCubit cubit,
    bool useTable,
  ) {
    // Failure first: it must not be masked by an empty list.
    if (state is OwnerManagementError) {
      return AdminStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load owners',
        message: state.message,
        actionLabel: 'Retry',
        onAction: () => cubit.fetchOwners(),
        tone: AdminStateTone.error,
      );
    }

    if (owners == null) {
      // Mirrors the loaded layout: KPI strip, filter bar, then either the
      // table or the card list, so the page does not reflow when data lands.
      return ShimmerPage(
        children: [
          const ShimmerTileGrid(
            count: 7,
            columnsAtExpanded: 6,
            columnsAtMedium: 3,
            columnsAtCompact: 2,
          ),
          const SizedBox(height: 16),
          ShimmerFilterBar(
            chips: 5,
            stacked: AdminBreakpoints.isCompact(context),
          ),
          const SizedBox(height: 16),
          if (useTable)
            const ShimmerSurface(child: ShimmerTable(rows: 8, columns: 6))
          else
            const ShimmerCardList(count: 4, lineCount: 3, footerActions: true),
        ],
      );
    }

    if (owners.isEmpty) {
      return AdminStateView(
        icon: Icons.storefront_rounded,
        title: 'No owners yet',
        message:
            'Ground owners who complete onboarding will appear here for review.',
        actionLabel: 'Refresh',
        onAction: () => cubit.fetchOwners(),
      );
    }

    final visible = _applyView(owners);
    final isRefreshing = state is OwnerManagementLoading;

    return Column(
      children: [
        // A hairline progress bar keeps the previous list on screen during a
        // refresh instead of blanking the page.
        if (isRefreshing) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => cubit.fetchOwners(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OwnerKpiStrip(owners: owners),
                  const SizedBox(height: 16),
                  OwnerFiltersBar(
                    controller: _searchController,
                    query: _query,
                    onQueryChanged: _setQuery,
                    selectedStatus: _statusFilter,
                    onStatusChanged: _setStatus,
                    sort: _sort,
                    onSortChanged: _setSort,
                    counts: _statusCounts(owners),
                    resultCount: visible.length,
                    totalCount: owners.length,
                    onClear: _clearFilters,
                  ),
                  const SizedBox(height: 16),
                  if (visible.isEmpty)
                    AdminSurface(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: AdminStateView(
                        icon: Icons.search_off_rounded,
                        title: 'No owners match your filters',
                        message:
                            'Try a different search term, or clear the status filter.',
                        actionLabel: 'Clear filters',
                        actionIcon: Icons.filter_alt_off_rounded,
                        onAction: _clearFilters,
                      ),
                    )
                  else if (useTable)
                    OwnerDesktopTable(
                      owners: visible,
                      onApprove: (id) => cubit.approveOwner(id),
                      onReject: _showRejectDialog,
                    )
                  else
                    Column(
                      children: [
                        for (final summary in visible)
                          OwnerMobileCard(
                            summary: summary,
                            onApprove: (id) => cubit.approveOwner(id),
                            onReject: _showRejectDialog,
                          ),
                      ],
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
