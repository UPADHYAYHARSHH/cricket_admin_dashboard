import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'location_row.dart';

/// Counters for the verification queue.
class LocationSummary extends StatelessWidget {
  const LocationSummary({super.key, required this.rows});

  final List<LocationRow> rows;

  @override
  Widget build(BuildContext context) {
    var pending = 0;
    var approved = 0;
    var rejected = 0;
    var inactive = 0;

    for (final row in rows) {
      switch (row.status) {
        case LocationVerificationStatus.pending:
          pending++;
        case LocationVerificationStatus.approved:
          approved++;
        case LocationVerificationStatus.rejected:
          rejected++;
      }
      if (!row.isActive) inactive++;
    }

    final tiles = <_Tile>[
      _Tile('Total', '${rows.length}', Icons.location_city_rounded,
          AppColors.primaryDarkGreen),
      _Tile('Pending', '$pending', Icons.schedule_rounded,
          AppColors.accentOrange),
      _Tile('Approved', '$approved', Icons.verified_rounded,
          AppColors.primaryLightGreen),
      _Tile('Rejected', '$rejected', Icons.block_rounded, const Color(0xFFD32F2F)),
      _Tile('Inactive', '$inactive', Icons.toggle_off_outlined,
          Theme.of(context).colorScheme.onSurfaceVariant),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 5
            : constraints.maxWidth >= 620
                ? 3
                : 2;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles)
              SizedBox(width: width, child: _TileView(tile: tile)),
          ],
        );
      },
    );
  }
}

class _Tile {
  const _Tile(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _TileView extends StatelessWidget {
  const _TileView({required this.tile});

  final _Tile tile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tile.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tile.icon, size: 19, color: tile.color),
          ),
          const SizedBox(width: 11),
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
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
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

/// Search plus a status filter.
///
/// The previous screen had neither, so locating one location meant scrolling a
/// table of every venue.
class LocationFiltersBar extends StatelessWidget {
  const LocationFiltersBar({
    super.key,
    required this.controller,
    required this.query,
    required this.onQueryChanged,
    required this.filter,
    required this.onFilterChanged,
    required this.counts,
    required this.visibleCount,
    required this.totalCount,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final LocationFilter filter;
  final ValueChanged<LocationFilter> onFilterChanged;
  final Map<LocationFilter, int> counts;
  final int visibleCount;
  final int totalCount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = AdminBreakpoints.isCompact(context);
    final hasFilters = query.isNotEmpty || filter != LocationFilter.all;

    final search = SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        onChanged: onQueryChanged,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          hintText:
              isCompact ? 'Search' : 'Search address, city or owner',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Clear search',
                  onPressed: () {
                    controller.clear();
                    onQueryChanged('');
                  },
                ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );

    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in LocationFilter.values)
          _Chip(
            label: option.label,
            count: counts[option] ?? 0,
            isSelected: filter == option,
            onTap: () => onFilterChanged(
              filter == option ? LocationFilter.all : option,
            ),
          ),
        if (hasFilters)
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
            label: const Text('Clear'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );

    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompact) ...[
            search,
            const SizedBox(height: 10),
            chips,
          ] else
            Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 14),
                Flexible(child: chips),
              ],
            ),
          const SizedBox(height: 12),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 10),
          Text(
            visibleCount == totalCount
                ? 'Showing all $totalCount locations'
                : 'Showing $visibleCount of $totalCount locations',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: isSelected ? primary : primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? primary : primary.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? Colors.white : primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected ? Colors.white : primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desktop table of locations.
class LocationTable extends StatefulWidget {
  const LocationTable({
    super.key,
    required this.rows,
    required this.onApprove,
    required this.onReject,
    required this.onToggleActive,
    required this.onViewDetails,
  });

  final List<LocationRow> rows;
  final ValueChanged<LocationRow> onApprove;
  final ValueChanged<LocationRow> onReject;
  final void Function(LocationRow row, bool value) onToggleActive;
  final ValueChanged<LocationRow> onViewDetails;

  @override
  State<LocationTable> createState() => _LocationTableState();
}

class _LocationTableState extends State<LocationTable> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminSurface(
      padding: EdgeInsets.zero,
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 10,
        radius: const Radius.circular(5),
        interactive: true,
        notificationPredicate: (notification) => notification.depth == 0,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 12),
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            ),
            headingRowHeight: 46,
            dataRowMinHeight: 58,
            dataRowMaxHeight: 72,
            columnSpacing: 28,
            horizontalMargin: 20,
            headingTextStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            dividerThickness: 0.5,
            columns: const [
              DataColumn(label: Text('LOCATION')),
              DataColumn(label: Text('OWNER')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('LIVE')),
              DataColumn(label: Text('ACTIONS')),
            ],
            rows: [
              for (final row in widget.rows)
                DataRow(
                  onSelectChanged: (_) => widget.onViewDetails(row),
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 260,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (row.locality.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                row.locality,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 160,
                        child: Text(
                          row.ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LocationStatusPill(status: row.status),
                          if (row.rejectionReason != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                row.rejectionReason!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: row.isActive,
                            onChanged: (value) =>
                                widget.onToggleActive(row, value),
                          ),
                          if (!row.isActive)
                            Text(
                              'Hidden',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(
                      _TableActions(
                        status: row.status,
                        onApprove: () => widget.onApprove(row),
                        onReject: () => widget.onReject(row),
                        onView: () => widget.onViewDetails(row),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableActions extends StatelessWidget {
  const _TableActions({
    required this.status,
    required this.onApprove,
    required this.onReject,
    required this.onView,
  });

  final LocationVerificationStatus status;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showApprove = status != LocationVerificationStatus.approved;
    final showReject = status != LocationVerificationStatus.rejected;

    if (!showApprove && !showReject) {
      return OutlinedButton.icon(
        onPressed: onView,
        icon: const Icon(Icons.visibility_outlined, size: 16),
        label: const Text('Details'),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showApprove)
          FilledButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Approve'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDarkGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              minimumSize: const Size(0, 36),
            ),
          ),
        if (showApprove && showReject) const SizedBox(width: 8),
        if (showReject)
          OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(
                  color: theme.colorScheme.error.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              minimumSize: const Size(0, 36),
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onView,
          tooltip: 'View details',
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

/// Compact card used below the table breakpoint.
class LocationCard extends StatelessWidget {
  const LocationCard({
    super.key,
    required this.row,
    required this.onApprove,
    required this.onReject,
    required this.onToggleActive,
    required this.onViewDetails,
  });

  final LocationRow row;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final void Function(bool value) onToggleActive;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showApprove = row.status != LocationVerificationStatus.approved;
    final showReject = row.status != LocationVerificationStatus.rejected;

    return AdminSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.address,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    if (row.locality.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        row.locality,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              LocationStatusPill(status: row.status, compact: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  row.ownerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (row.rejectionReason != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                'Reason: ${row.rejectionReason}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Visible to players',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Switch(value: row.isActive, onChanged: onToggleActive),
            ],
          ),
          if (showApprove || showReject) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (showApprove)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryDarkGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                if (showApprove && showReject) const SizedBox(width: 10),
                if (showReject)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
              label: const Text('View details'),
            ),
          ),
        ],
      ),
    );
  }
}
