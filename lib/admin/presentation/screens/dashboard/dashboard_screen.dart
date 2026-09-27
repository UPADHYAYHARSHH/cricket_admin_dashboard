import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_admin_panel/common/responsive/admin_page_scaffold.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/widgets/shimmer_placeholder.dart';
import 'package:cricket_admin_panel/common/utils/formatters.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import '../../blocs/dashboard/admin_dashboard_cubit.dart';
import '../../blocs/dashboard/admin_dashboard_state.dart';
import 'widgets/dashboard_widgets.dart';

/// Landing screen: headline numbers and the review queue.
///
/// The cubit call is unchanged. What changed: the stat cards are responsive
/// rather than a fixed 240px, revenue is grouped, the value text can no longer
/// overflow on a narrow tile, the actionable card is visually distinct from the
/// read-only metrics, and the list states that it is truncated.
class DashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenApprovals;

  const DashboardScreen({super.key, this.onOpenApprovals});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminDashboardCubit>().fetchStats();
  }

  void _openApprovals() => widget.onOpenApprovals?.call();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        return AdminPageScaffold(
          title: 'Overview',
          subtitle: switch (state) {
            AdminDashboardLoaded(:final ownersCount, :final usersCount) =>
              '$ownersCount owners · $usersCount users',
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

    return RefreshIndicator(
      onRefresh: () => context.read<AdminDashboardCubit>().fetchStats(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // The review queue is the one thing on this screen you can act on, so
          // it leads and is styled differently from the read-only metrics.
          DashboardActionCard(count: pending, onTap: _openApprovals),
          const SizedBox(height: 16),

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
          const SizedBox(height: 22),

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
}
