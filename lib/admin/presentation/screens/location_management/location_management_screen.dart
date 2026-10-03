import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_admin_panel/common/responsive/admin_page_scaffold.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/widgets/shimmer_placeholder.dart';
import '../../blocs/locations/location_management_cubit.dart';
import '../../blocs/locations/location_management_state.dart';
import 'location_detail_screen.dart';
import 'widgets/location_row.dart';
import 'widgets/location_views.dart';

/// List of ground locations with verification controls.
///
/// The cubit calls, their arguments and the visibility toggle are unchanged.
/// What changed: search and status filters, a count summary, the rejection
/// reason is now surfaced, a card layout for phones, and the detail screen is
/// pushed onto the navigator so the system and browser back buttons work.
class LocationManagementScreen extends StatefulWidget {
  const LocationManagementScreen({super.key});

  @override
  State<LocationManagementScreen> createState() =>
      _LocationManagementScreenState();
}

class _LocationManagementScreenState extends State<LocationManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  LocationFilter _filter = LocationFilter.all;

  @override
  void initState() {
    super.initState();
    context.read<LocationManagementCubit>().fetchLocations();
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

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _filter = LocationFilter.all;
    });
  }

  static List<LocationRow> _toRows(LocationManagementLoaded loaded) {
    return loaded.locations.map((location) {
      return LocationRow(
        location: location,
        ownerName: loaded.ownerNameById[location['owner_id'].toString()] ??
            'Owner',
        status: LocationVerificationStatus.of(location),
      );
    }).toList();
  }

  static bool _matches(LocationRow row, String query) {
    if (query.isEmpty) return true;
    final needle = query.toLowerCase();

    bool hit(Object? value) =>
        value != null && value.toString().toLowerCase().contains(needle);

    return hit(row.address) ||
        hit(row.city) ||
        hit(row.state) ||
        hit(row.ownerName);
  }

  static bool _passesFilter(LocationRow row, LocationFilter filter) {
    return switch (filter) {
      LocationFilter.all => true,
      LocationFilter.pending =>
        row.status == LocationVerificationStatus.pending,
      LocationFilter.approved =>
        row.status == LocationVerificationStatus.approved,
      LocationFilter.rejected =>
        row.status == LocationVerificationStatus.rejected,
      LocationFilter.inactive => !row.isActive,
    };
  }

  Map<LocationFilter, int> _counts(List<LocationRow> rows) {
    final counts = <LocationFilter, int>{};
    for (final filter in LocationFilter.values) {
      counts[filter] = 0;
    }
    for (final row in rows) {
      for (final filter in LocationFilter.values) {
        if (_passesFilter(row, filter)) {
          counts[filter] = (counts[filter] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  void _showRejectDialog(LocationRow row) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject location'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection (optional)',
            helperText: 'Shown to the owner in their app',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              context.read<LocationManagementCubit>().rejectLocation(
                row.id,
                reason: reasonController.text.trim().isNotEmpty
                    ? reasonController.text.trim()
                    : null,
              );
              Navigator.pop(context);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    ).whenComplete(reasonController.dispose);
  }

  /// Pushed as a route so the system and browser back buttons return here
  /// instead of doing nothing. Previously the detail replaced this screen's
  /// Scaffold in place, which left no navigator entry to pop.
  void _openDetail(LocationRow row) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LocationDetailScreen(
          location: row.location,
          ownerName: row.ownerName,
          onBack: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LocationManagementCubit>();

    return BlocBuilder<LocationManagementCubit, LocationManagementState>(
      builder: (context, state) {
        final loaded = state is LocationManagementLoaded ? state : null;
        final rows = loaded == null ? <LocationRow>[] : _toRows(loaded);

        return AdminPageScaffold(
          title: 'Location Verification',
          subtitle: switch (state) {
            LocationManagementLoaded() =>
              '${rows.length} location${rows.length == 1 ? '' : 's'}',
            LocationManagementLoading() => 'Loading…',
            _ => 'Loading',
          },
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: state is LocationManagementLoading
                  ? null
                  : () => cubit.fetchLocations(),
              icon: state is LocationManagementLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
          child: _buildBody(context, state, rows),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    LocationManagementState state,
    List<LocationRow> rows,
  ) {
    final cubit = context.read<LocationManagementCubit>();

    if (state is LocationManagementError) {
      return AdminStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load locations',
        message: state.message,
        actionLabel: 'Retry',
        onAction: () => cubit.fetchLocations(),
        tone: AdminStateTone.error,
      );
    }

    if (state is! LocationManagementLoaded) {
      return ShimmerPage(
        children: [
          const ShimmerTileGrid(
            count: 4,
            columnsAtExpanded: 4,
            columnsAtMedium: 2,
            columnsAtCompact: 2,
          ),
          const SizedBox(height: 14),
          ShimmerFilterBar(
            chips: 4,
            stacked: AdminBreakpoints.isCompact(context),
          ),
          const SizedBox(height: 14),
          if (AdminBreakpoints.hasTableSpace(context))
            const ShimmerSurface(child: ShimmerTable(rows: 8, columns: 6))
          else
            const ShimmerCardList(count: 4, lineCount: 3, footerActions: true),
        ],
      );
    }

    if (rows.isEmpty) {
      return const AdminStateView(
        icon: Icons.location_off_outlined,
        title: 'No locations yet',
        message: 'Venues added by owners will appear here for verification.',
      );
    }

    final visible = rows
        .where((row) => _passesFilter(row, _filter))
        .where((row) => _matches(row, _query))
        .toList();

    final useTable = AdminBreakpoints.hasTableSpace(context);

    return Column(
      children: [
        if (state is LocationManagementLoading)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => cubit.fetchLocations(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                LocationSummary(rows: rows),
                const SizedBox(height: 14),
                LocationFiltersBar(
                  controller: _searchController,
                  query: _query,
                  onQueryChanged: _setQuery,
                  filter: _filter,
                  onFilterChanged: (value) => setState(() => _filter = value),
                  counts: _counts(rows),
                  visibleCount: visible.length,
                  totalCount: rows.length,
                  onClear: _clearFilters,
                ),
                const SizedBox(height: 14),
                if (visible.isEmpty)
                  AdminSurface(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: AdminStateView(
                      icon: Icons.search_off_rounded,
                      title: 'No locations match your filters',
                      message: 'Try a different search term or clear the filter.',
                      actionLabel: 'Clear filters',
                      actionIcon: Icons.filter_alt_off_rounded,
                      onAction: _clearFilters,
                    ),
                  )
                else if (useTable)
                  LocationTable(
                    rows: visible,
                    onApprove: (row) => cubit.approveLocation(row.id),
                    onReject: _showRejectDialog,
                    onToggleActive: (row, value) =>
                        cubit.toggleLocationActive(row.id, value),
                    onViewDetails: _openDetail,
                  )
                else
                  Column(
                    children: [
                      for (final row in visible) ...[
                        LocationCard(
                          row: row,
                          onApprove: () => cubit.approveLocation(row.id),
                          onReject: () => _showRejectDialog(row),
                          onToggleActive: (value) =>
                              cubit.toggleLocationActive(row.id, value),
                          onViewDetails: () => _openDetail(row),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
