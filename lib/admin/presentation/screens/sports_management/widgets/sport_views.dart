import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/widgets/admin_status_pill.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/admin/data/models/sport_model.dart';

/// Parses a `#RGB` / `#RRGGBB` / `AARRGGBB` hex string, tolerating a missing
/// leading `#` and a short three-digit form.
///
/// Returns `null` for anything unparseable so callers can fall back
/// deliberately instead of rendering an unintended colour.
///
/// The previous implementation inlined `int.tryParse(color.replaceFirst('#',
/// '0xFF'))` in three separate places, which silently produced grey for a
/// three-digit hex such as `#F00` and for any typo.
Color? parseHexColor(String? hex) {
  if (hex == null) return null;

  var value = hex.trim().replaceFirst('#', '');

  // #F00 -> #FF0000
  if (value.length == 3) {
    value = value.split('').map((char) => '$char$char').join();
  }
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;

  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? null : Color(parsed);
}

/// Sport icon, falling back to a coloured disc when no icon URL is set.
///
/// Decode is constrained to the display size: an unconstrained `Image.network`
/// decodes a 512px icon at full resolution to paint a 40px circle.
class SportIcon extends StatelessWidget {
  const SportIcon({super.key, required this.sport, this.size = 40});

  final SportModel sport;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = parseHexColor(sport.color) ?? theme.colorScheme.onSurfaceVariant;

    if (sport.iconUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(
          Icons.sports_cricket_rounded,
          color: Colors.white,
          size: size * 0.55,
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        sport.iconUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(
            Icons.sports_cricket_rounded,
            color: Colors.white,
            size: size * 0.55,
          ),
        ),
      ),
    );
  }
}

/// Colour swatch used in the table and the edit form.
class SportColorSwatch extends StatelessWidget {
  const SportColorSwatch({super.key, required this.hex, this.size = 24});

  final String hex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = parseHexColor(hex);

    return Tooltip(
      message: color == null ? '$hex (unrecognised)' : hex.toUpperCase(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color ?? theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(color: theme.dividerColor),
        ),
        child: color == null
            ? Icon(
                Icons.error_outline_rounded,
                size: size * 0.6,
                color: theme.colorScheme.error,
              )
            : null,
      ),
    );
  }
}

/// Active-state filter.
enum SportFilter {
  all('All'),
  active('Active'),
  inactive('Hidden');

  const SportFilter(this.label);
  final String label;
}

/// Counters for the sport list.
class SportSummary extends StatelessWidget {
  const SportSummary({super.key, required this.sports});

  final List<SportModel> sports;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = sports.where((s) => s.isActive).length;
    final missingIcon = sports.where((s) => s.iconUrl.isEmpty).length;

    final tiles = <_Tile>[
      _Tile('Total sports', '${sports.length}', Icons.sports_cricket_rounded,
          AppColors.primaryDarkGreen),
      _Tile('Visible in app', '$active', Icons.visibility_outlined,
          AppColors.primaryLightGreen),
      _Tile('Hidden', '${sports.length - active}', Icons.visibility_off_outlined,
          Theme.of(context).colorScheme.onSurfaceVariant),
      _Tile('Without an icon', '$missingIcon', Icons.image_not_supported_outlined,
          Theme.of(context).colorScheme.onSurfaceVariant),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : 2;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: width,
                child: AdminSurface(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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

/// Active-state filter chips.
class SportFilterBar extends StatelessWidget {
  const SportFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
    required this.counts,
    required this.visibleCount,
    required this.totalCount,
  });

  final SportFilter filter;
  final ValueChanged<SportFilter> onChanged;
  final Map<SportFilter, int> counts;
  final int visibleCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AdminSurface(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in SportFilter.values)
                Material(
                  color: filter == option
                      ? primary
                      : primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: () => onChanged(option),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: filter == option
                              ? primary
                              : primary.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            option.label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: filter == option ? Colors.white : primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: filter == option
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : primary.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${counts[option] ?? 0}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color:
                                    filter == option ? Colors.white : primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            visibleCount == totalCount
                ? 'Showing all $totalCount sports'
                : 'Showing $visibleCount of $totalCount sports',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Desktop table of sports.
class SportTable extends StatelessWidget {
  const SportTable({
    super.key,
    required this.sports,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.isFirst,
    required this.isLast,
  });

  final List<SportModel> sports;
  final ValueChanged<SportModel> onEdit;
  final ValueChanged<SportModel> onDelete;
  final void Function(SportModel sport, bool value) onToggleActive;
  final ValueChanged<SportModel> onMoveUp;
  final ValueChanged<SportModel> onMoveDown;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminSurface(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 12),
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          ),
          headingRowHeight: 46,
          dataRowMinHeight: 58,
          dataRowMaxHeight: 66,
          columnSpacing: 26,
          horizontalMargin: 20,
          headingTextStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          dividerThickness: 0.5,
          columns: const [
            DataColumn(label: Text('ORDER')),
            DataColumn(label: Text('ICON')),
            DataColumn(label: Text('NAME')),
            DataColumn(label: Text('SLUG')),
            DataColumn(label: Text('COLOUR')),
            DataColumn(label: Text('VISIBLE')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: [
            for (final sport in sports)
              DataRow(
                key: ValueKey(sport.id),
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${sport.sortOrder}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ReorderButton(
                              icon: Icons.keyboard_arrow_up_rounded,
                              tooltip: 'Move ${sport.name} up',
                              onPressed: () => onMoveUp(sport),
                            ),
                            _ReorderButton(
                              icon: Icons.keyboard_arrow_down_rounded,
                              tooltip: 'Move ${sport.name} down',
                              onPressed: () => onMoveDown(sport),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  DataCell(SportIcon(sport: sport, size: 32)),
                  DataCell(
                    SizedBox(
                      width: 160,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sport.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          AdminStatusPill(
                            label: sport.isActive ? 'Visible' : 'Hidden',
                            color: sport.isActive
                                ? AppColors.primaryLightGreen
                                : theme.colorScheme.onSurfaceVariant,
                            icon: sport.isActive
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 130,
                      child: Text(
                        sport.slug,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  DataCell(SportColorSwatch(hex: sport.color)),
                  DataCell(
                    Switch(
                      value: sport.isActive,
                      onChanged: (value) => onToggleActive(sport, value),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit ${sport.name}',
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          onPressed: () => onEdit(sport),
                        ),
                        IconButton(
                          tooltip: 'Delete ${sport.name}',
                          icon: Icon(
                            Icons.delete_rounded,
                            size: 20,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () => onDelete(sport),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ReorderButton extends StatelessWidget {
  const _ReorderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 18,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Icon(icon, size: 16),
        ),
      ),
    );
  }
}

/// Compact card used below the table breakpoint.
///
/// The previous version used a `ListTile` whose `trailing` held a `Switch` and
/// two `IconButton`s. That is roughly 150px of trailing widgets, which overflows
/// a `ListTile` at phone widths.
class SportCard extends StatelessWidget {
  const SportCard({
    super.key,
    required this.sport,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final SportModel sport;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(bool value) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SportIcon(sport: sport, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sport.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sport.slug,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SportColorSwatch(hex: sport.color, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Order ${sport.sortOrder}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  value: sport.isActive,
                  onChanged: onToggleActive,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    sport.isActive ? 'Visible in app' : 'Hidden from users',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_rounded, size: 20),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Delete',
                icon: Icon(
                  Icons.delete_rounded,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
