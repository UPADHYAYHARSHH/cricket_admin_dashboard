import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';
import 'package:cricket_admin_panel/common/utils/formatters.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/widgets/admin_status_pill.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';

/// Formats an hourly rate, keeping a decimal only when one is present.
///
/// The previous code interpolated the raw column, so a `numeric` rate of 500.0
/// rendered as "₹500.0" and a rate of 49.5 lost precision under a plain
/// integer conversion.
String formatHourlyRate(Object? value) {
  final amount = asDouble(value);
  if (amount == 0) return '₹0';
  final isWhole = amount == amount.roundToDouble();
  return isWhole ? '₹${formatInr(amount.round())}' : '₹${amount.toStringAsFixed(2)}';
}

/// Display treatment for a booking status.
///
/// `approved` means the owner approved the slot but the player has not paid
/// yet, which is the single most confusing status in this table, so it is
/// relabelled. The mapping is otherwise unchanged.
({String label, Color color}) bookingStatusStyle(BuildContext context, Object? status) {
  final value = status?.toString().toLowerCase() ?? '';
  final error = Theme.of(context).colorScheme.error;
  final muted = Theme.of(context).colorScheme.onSurfaceVariant;

  if (value == 'approved') {
    return (label: 'Awaiting payment', color: AppColors.accentOrange);
  }
  if (value == 'requested') {
    return (label: 'Requested', color: AppColors.accentOrange);
  }
  if (value == 'confirmed') {
    return (label: 'Confirmed', color: AppColors.primaryDarkGreen);
  }
  if (value == 'cancelled' || value == 'declined' || value == 'expired') {
    return (label: _titleCase(value), color: error);
  }

  // Any other status keeps its own name rather than being folded into a
  // neighbouring bucket, so nothing is hidden from the admin.
  return (label: _titleCase(value.isEmpty ? 'unknown' : value), color: muted);
}

String _titleCase(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

/// Banner explaining why a location's grounds are not visible to players.
class LocationVisibilityBanner extends StatelessWidget {
  const LocationVisibilityBanner({super.key, required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warn = AppColors.accentOrange;

    return Container(
      width: double.infinity,
      color: warn.withValues(alpha: 0.10),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_off_outlined, size: 18, color: warn),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified
                      ? 'This location is disabled'
                      : 'This location is not yet approved',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Its grounds stay hidden from players until the location is '
                  'approved and switched on.',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact counters shown above each tab.
class LocationDetailSummary extends StatelessWidget {
  const LocationDetailSummary({super.key, required this.tiles});

  final List<({String label, String value, IconData icon, Color color})> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? tiles.length : 2;
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
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: tile.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(tile.icon, size: 18, color: tile.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tile.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700, height: 1.1),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tile.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontSize: 11),
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

/// A single ground with its availability toggle.
class GroundCard extends StatelessWidget {
  const GroundCard({
    super.key,
    required this.ground,
    required this.onToggle,
  });

  final Map<String, dynamic> ground;
  final void Function(String groundId, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = ground['is_available'] != false;
    final name = (ground['name'] as String?)?.trim();
    final category = (ground['category'] as String?)?.trim();

    return AdminSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (name == null || name.isEmpty) ? 'Unnamed ground' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (category != null && category.isNotEmpty) category,
                    '${formatHourlyRate(ground['price_per_hour'])}/hr',
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AdminStatusPill(
            label: isAvailable ? 'Available' : 'Disabled',
            color: isAvailable
                ? AppColors.primaryDarkGreen
                : theme.colorScheme.onSurfaceVariant,
            icon: isAvailable
                ? Icons.check_circle_rounded
                : Icons.pause_circle_outline_rounded,
            compact: true,
          ),
          const SizedBox(width: 4),
          Switch(
            value: isAvailable,
            onChanged: (value) => onToggle(ground['id']?.toString() ?? '', value),
          ),
        ],
      ),
    );
  }
}

/// Desktop booking table with a persistent horizontal scrollbar.
class LocationBookingTable extends StatefulWidget {
  const LocationBookingTable({
    super.key,
    required this.bookings,
  });

  final List<Map<String, dynamic>> bookings;

  @override
  State<LocationBookingTable> createState() => _LocationBookingTableState();
}

class _LocationBookingTableState extends State<LocationBookingTable> {
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
            dataRowMinHeight: 52,
            dataRowMaxHeight: 60,
            columnSpacing: 28,
            horizontalMargin: 20,
            headingTextStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            dividerThickness: 0.5,
            columns: const [
              DataColumn(label: Text('DATE')),
              DataColumn(label: Text('GROUND')),
              DataColumn(label: Text('AMOUNT'), numeric: true),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('CHECKED IN')),
            ],
            rows: [
              for (final booking in widget.bookings)
                DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          formatDateTime(
                            booking['booking_date'] ?? booking['created_at'],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 180,
                        child: Text(
                          (booking['grounds'] as Map<String, dynamic>?)?['name']
                                  as String? ??
                              'Ground',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '₹${formatInr(asInt(booking['amount'] ?? booking['total_amount']))}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDarkGreen,
                        ),
                      ),
                    ),
                    DataCell(
                      AdminStatusPill(
                        label: bookingStatusStyle(context, booking['status']).label,
                        color: bookingStatusStyle(context, booking['status']).color,
                      ),
                    ),
                    DataCell(
                      Icon(
                        booking['checked_in'] == true
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: booking['checked_in'] == true
                            ? AppColors.primaryDarkGreen
                            : theme.colorScheme.onSurfaceVariant,
                        size: 18,
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

/// Compact booking row for phones.
class LocationBookingCard extends StatelessWidget {
  const LocationBookingCard({super.key, required this.booking});

  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = bookingStatusStyle(context, booking['status']);
    final checkedIn = booking['checked_in'] == true;

    return AdminSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (booking['grounds'] as Map<String, dynamic>?)?['name']
                          as String? ??
                      'Ground',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AdminStatusPill(label: style.label, color: style.color, compact: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '₹${formatInr(asInt(booking['amount'] ?? booking['total_amount']))}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkGreen,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                checkedIn
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 15,
                color: checkedIn
                    ? AppColors.primaryDarkGreen
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                checkedIn ? 'Checked in' : 'Not checked in',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formatDateTime(booking['booking_date'] ?? booking['created_at']),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared empty state for a tab with no rows.
class LocationTabEmpty extends StatelessWidget {
  const LocationTabEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AdminStateView(icon: icon, title: title, message: message);
  }
}

/// Page padding helper so both tabs line up with the rest of the app.
EdgeInsets locationTabPadding(BuildContext context) => EdgeInsets.all(
      AdminBreakpoints.pagePadding(context),
    );
