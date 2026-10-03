import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_admin_panel/common/responsive/admin_page_scaffold.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/widgets/shimmer_placeholder.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/admin/data/models/sport_model.dart';
import '../../blocs/sports/sports_management_cubit.dart';
import '../../blocs/sports/sports_management_state.dart';
import 'widgets/sport_views.dart';
import 'widgets/sport_form_dialog.dart';

/// Catalogue of the sports offered in the apps.
///
/// Every cubit call keeps its original arguments. The add and edit forms are
/// now one dialog with proper validation and controller disposal, the phone
/// layout no longer overflows, and the existing but previously unreachable
/// `updateSortOrder` is wired to inline reorder controls.
class SportsManagementScreen extends StatefulWidget {
  const SportsManagementScreen({super.key});

  @override
  State<SportsManagementScreen> createState() => _SportsManagementScreenState();
}

class _SportsManagementScreenState extends State<SportsManagementScreen> {
  SportFilter _filter = SportFilter.all;

  @override
  void initState() {
    super.initState();
    context.read<SportsManagementCubit>().fetchSports();
  }

  Future<void> _addSport() async {
    final result = await SportFormDialog.show(context);
    if (result == null || !mounted) return;

    context.read<SportsManagementCubit>().addSport(
          name: result.name,
          slug: result.slug,
          iconUrl: result.iconUrl,
          localAsset: result.localAsset,
          color: result.color,
          sortOrder: result.sortOrder,
        );
  }

  Future<void> _editSport(SportModel sport) async {
    final result = await SportFormDialog.show(context, existing: sport);
    if (result == null || !mounted) return;

    context.read<SportsManagementCubit>().updateSport(
          id: sport.id,
          name: result.name,
          slug: result.slug,
          iconUrl: result.iconUrl,
          localAsset: result.localAsset,
          color: result.color,
          sortOrder: result.sortOrder,
        );
  }

  Future<void> _deleteSport(SportModel sport) async {
    final confirmed = await confirmDeleteSport(context, sport);
    if (!confirmed || !mounted) return;
    context.read<SportsManagementCubit>().deleteSport(sport.id);
  }

  /// Swaps sort order with the neighbouring visible sport and persists both.
  ///
  /// `updateSortOrder` already existed in the cubit but nothing called it, so
  /// ordering could only be changed by opening the edit dialog for each sport.
  Future<void> _move(SportModel sport, List<SportModel> ordered, int delta) async {
    final index = ordered.indexWhere((s) => s.id == sport.id);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= ordered.length) return;

    final other = ordered[target];
    final cubit = context.read<SportsManagementCubit>();

    // Write the lower value first so the two rows never share an order.
    final firstIsSport = delta > 0;
    await cubit.updateSortOrder(
      firstIsSport ? sport.id : other.id,
      firstIsSport ? other.sortOrder : sport.sortOrder,
    );
    if (!mounted) return;
    await cubit.updateSortOrder(
      firstIsSport ? other.id : sport.id,
      firstIsSport ? sport.sortOrder : other.sortOrder,
    );
  }

  Map<SportFilter, int> _counts(List<SportModel> sports) {
    final counts = <SportFilter, int>{};
    for (final filter in SportFilter.values) {
      counts[filter] = 0;
    }
    for (final sport in sports) {
      counts[SportFilter.all] = (counts[SportFilter.all] ?? 0) + 1;
      counts[sport.isActive ? SportFilter.active : SportFilter.inactive] =
          (counts[sport.isActive ? SportFilter.active : SportFilter.inactive] ??
                  0) +
              1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SportsManagementCubit>();

    return BlocBuilder<SportsManagementCubit, SportsManagementState>(
      builder: (context, state) {
        return AdminPageScaffold(
          title: 'Sports',
          subtitle: switch (state) {
            SportsManagementLoaded(:final sports) =>
              '${sports.length} sport${sports.length == 1 ? '' : 's'}',
            SportsManagementLoading() => 'Loading…',
            _ => 'Loading',
          },
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: state is SportsManagementLoading
                  ? null
                  : () => cubit.fetchSports(),
              icon: state is SportsManagementLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
            // The primary action collapses to an icon on a phone so it does
            // not crowd the title.
            if (AdminBreakpoints.isCompact(context))
              IconButton(
                tooltip: 'Add sport',
                onPressed: _addSport,
                icon: const Icon(Icons.add_rounded),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.icon(
                  onPressed: _addSport,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add sport'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDarkGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
          child: _buildBody(
            context,
            state,
            state is SportsManagementLoaded ? state.sports : null,
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    SportsManagementState state,
    List<SportModel>? sports,
  ) {
    final cubit = context.read<SportsManagementCubit>();

    if (state is SportsManagementError) {
      return AdminStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load sports',
        message: state.message,
        actionLabel: 'Retry',
        onAction: () => cubit.fetchSports(),
        tone: AdminStateTone.error,
      );
    }

    if (sports == null) {
      return ShimmerPage(
        children: [
          const ShimmerTileGrid(
            count: 3,
            columnsAtExpanded: 3,
            columnsAtMedium: 3,
            columnsAtCompact: 1,
          ),
          const SizedBox(height: 14),
          const ShimmerFilterBar(chips: 3),
          const SizedBox(height: 14),
          if (AdminBreakpoints.hasTableSpace(context))
            const ShimmerSurface(child: ShimmerTable(rows: 6, columns: 4))
          else
            const ShimmerCardList(count: 4, lineCount: 2),
        ],
      );
    }

    if (sports.isEmpty) {
      return AdminStateView(
        icon: Icons.sports_cricket_outlined,
        title: 'No sports yet',
        message: 'Sports you add here become selectable in the booking apps.',
        actionLabel: 'Add the first sport',
        actionIcon: Icons.add_rounded,
        onAction: _addSport,
      );
    }

    // The cubit returns the list ordered by sort_order ascending.
    final visible = sports
        .where((sport) => switch (_filter) {
              SportFilter.all => true,
              SportFilter.active => sport.isActive,
              SportFilter.inactive => !sport.isActive,
            })
        .toList();

    final useTable = AdminBreakpoints.hasTableSpace(context);

    return Column(
      children: [
        if (state is SportsManagementLoading)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => cubit.fetchSports(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SportSummary(sports: sports),
                const SizedBox(height: 14),
                SportFilterBar(
                  filter: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                  counts: _counts(sports),
                  visibleCount: visible.length,
                  totalCount: sports.length,
                ),
                const SizedBox(height: 14),
                if (visible.isEmpty)
                  AdminSurface(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: AdminStateView(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'No sports in this view',
                      message: 'Try a different filter.',
                      actionLabel: 'Show all',
                      onAction: () =>
                          setState(() => _filter = SportFilter.all),
                    ),
                  )
                else if (useTable)
                  SportTable(
                    sports: visible,
                    onEdit: _editSport,
                    onDelete: _deleteSport,
                    onToggleActive: (sport, value) =>
                        cubit.toggleActive(sport.id, value),
                    onMoveUp: (sport) => _move(sport, sports, -1),
                    onMoveDown: (sport) => _move(sport, sports, 1),
                    isFirst: true,
                    isLast: true,
                  )
                else
                  Column(
                    children: [
                      for (final sport in visible) ...[
                        SportCard(
                          key: ValueKey(sport.id),
                          sport: sport,
                          onEdit: () => _editSport(sport),
                          onDelete: () => _deleteSport(sport),
                          onToggleActive: (value) =>
                              cubit.toggleActive(sport.id, value),
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
