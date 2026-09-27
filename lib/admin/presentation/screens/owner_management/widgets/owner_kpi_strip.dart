import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/admin/presentation/blocs/owners/owner_management_state.dart';
import 'package:cricket_admin_panel/common/utils/formatters.dart';
import 'owner_status_pill.dart';

/// How the owner list is ordered.
enum OwnerSort {
  revenueDesc('Revenue: high to low'),
  pendingFirst('Pending first'),
  nameAsc('Name: A to Z'),
  bookingsDesc('Bookings: most to least');

  const OwnerSort(this.label);
  final String label;
}

/// One tile in the summary strip.
class _Kpi {
  const _Kpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

/// At-a-glance summary of the owner base.
///
/// The previous layout offered no aggregate view, so an admin had to scan and
/// mentally total every row to answer "how many are waiting on me?". All values
/// are derived from the already-loaded [OwnerManagementLoaded] state, so this
/// adds no queries and no state management of its own.
class OwnerKpiStrip extends StatelessWidget {
  const OwnerKpiStrip({super.key, required this.owners});

  final List<OwnerSummary> owners;

  @override
  Widget build(BuildContext context) {
    var pending = 0;
    var approved = 0;
    var rejected = 0;
    var locations = 0;
    var bookings = 0;
    var revenue = 0.0;

    for (final summary in owners) {
      switch (OwnerStatus.from(summary.owner)) {
        case OwnerStatus.pending:
          pending++;
        case OwnerStatus.approved:
          approved++;
        case OwnerStatus.rejected:
          rejected++;
      }
      locations += summary.locationsCount;
      bookings += summary.bookingsCount;
      revenue += summary.revenue;
    }

    final tiles = <_Kpi>[
      _Kpi(
        label: 'Total owners',
        value: '${owners.length}',
        icon: Icons.groups_rounded,
        color: AppColors.primaryDarkGreen,
      ),
      _Kpi(
        label: 'Pending review',
        value: '$pending',
        icon: Icons.schedule_rounded,
        color: AppColors.accentOrange,
      ),
      _Kpi(
        label: 'Approved',
        value: '$approved',
        icon: Icons.verified_rounded,
        color: AppColors.primaryLightGreen,
      ),
      _Kpi(
        label: 'Rejected',
        value: '$rejected',
        icon: Icons.block_rounded,
        color: Colors.red.shade600,
      ),
      _Kpi(
        label: 'Locations',
        value: '$locations',
        icon: Icons.location_on_rounded,
        color: Colors.blue.shade600,
      ),
      _Kpi(
        label: 'Confirmed bookings',
        value: '$bookings',
        icon: Icons.event_available_rounded,
        color: AppColors.primaryLightGreen,
      ),
      _Kpi(
        label: 'Total revenue',
        value: 'â‚¹${formatInr(revenue.round())}',
        icon: Icons.payments_rounded,
        color: AppColors.goldenYellow,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tile count follows the shared breakpoints so the strip matches every
        // other module's behaviour at a given width.
        final columns = constraints.maxWidth >= 1180
            ? 6
            : constraints.maxWidth >= 760
                ? 3
                : 2;
        const gap = 12.0;

        final tileWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles)
              SizedBox(width: tileWidth, child: _KpiTile(tile: tile)),
          ],
        );
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.tile});

  final _Kpi tile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tile.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tile.icon, size: 20, color: tile.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tile.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tile.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
