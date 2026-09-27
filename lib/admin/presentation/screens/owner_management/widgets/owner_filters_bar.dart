import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'owner_kpi_strip.dart';
import 'owner_status_pill.dart';

/// Search field, status filter chips and sort control.
///
/// Every control here filters the list that is already in memory, so no extra
/// network request is made. Counts beside each chip let an admin see where the
/// backlog is before clicking.
class OwnerFiltersBar extends StatelessWidget {
  const OwnerFiltersBar({
    super.key,
    required this.controller,
    required this.query,
    required this.onQueryChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.sort,
    required this.onSortChanged,
    required this.counts,
    required this.resultCount,
    required this.totalCount,
    required this.onClear,
  });

  /// Bound by the parent so that "Clear" and the field's own clear button can
  /// reset the visible text, not just the filter state.
  final TextEditingController controller;

  final String query;
  final ValueChanged<String> onQueryChanged;

  /// `null` means "All".
  final OwnerStatus? selectedStatus;
  final ValueChanged<OwnerStatus?> onStatusChanged;

  final OwnerSort sort;
  final ValueChanged<OwnerSort> onSortChanged;

  final Map<OwnerStatus?, int> counts;
  final int resultCount;
  final int totalCount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFilters = query.isNotEmpty || selectedStatus != null;
    final isCompact = AdminBreakpoints.isCompact(context);
    final gap = isCompact ? 10.0 : 12.0;

    final searchField = SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        onChanged: onQueryChanged,
        style: theme.textTheme.bodyMedium,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          hintText: isCompact
              ? 'Search owners'
              : 'Search by owner, business, email or phone',
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );

    final sortMenu = _SortMenu(sort: sort, onChanged: onSortChanged);

    return AdminSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Search + sort -------------------------------------------------
          // Stacked on a phone: a search field plus a sort button will not fit
          // side by side at 360dp without squeezing both.
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                SizedBox(height: gap),
                Align(alignment: Alignment.centerLeft, child: sortMenu),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: searchField),
                SizedBox(width: gap),
                sortMenu,
              ],
            ),
          SizedBox(height: gap),

          // --- Status chips + result count ----------------------------------
          Wrap(
            spacing: gap,
            runSpacing: gap,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusChip(
                label: 'All',
                count: counts[null] ?? 0,
                isSelected: selectedStatus == null,
                color: AppColors.primaryDarkGreen,
                onTap: () => onStatusChanged(null),
              ),
              for (final status in OwnerStatus.values)
                _StatusChip(
                  label: status.label,
                  count: counts[status] ?? 0,
                  isSelected: selectedStatus == status,
                  color: status.color,
                  onTap: () => onStatusChanged(
                    selectedStatus == status ? null : status,
                  ),
                ),
              if (hasFilters)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.lightTextSecondary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 10),
          Text(
            resultCount == totalCount
                ? 'Showing all $totalCount owners'
                : 'Showing $resultCount of $totalCount owners',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? color : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? Colors.white : color,
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
                      : color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected ? Colors.white : color,
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

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.sort, required this.onChanged});

  final OwnerSort sort;
  final ValueChanged<OwnerSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<OwnerSort>(
      initialValue: sort,
      tooltip: 'Sort owners',
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      itemBuilder: (context) => [
        for (final option in OwnerSort.values)
          PopupMenuItem<OwnerSort>(
            value: option,
            height: 40,
            child: Row(
              children: [
                Icon(
                  option == sort
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: option == sort
                      ? AppColors.primaryDarkGreen
                      : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 8),
                Text(option.label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
      ],
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert_rounded, size: 18),
            const SizedBox(width: 6),
            Text(
              sort.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
