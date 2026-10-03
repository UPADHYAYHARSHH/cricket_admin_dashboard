import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/admin/presentation/blocs/owners/owner_management_state.dart';
import 'package:cricket_admin_panel/common/utils/formatters.dart';
import 'owner_identity.dart';
import 'owner_status_pill.dart';

/// Wide-screen owner table.
///
/// Keeps the same columns and the same two actions as the previous
/// implementation, with three changes: the owner and contact cells are stacked
/// so they read as single entities, the rejection reason is surfaced (it was
/// already being written to the database but never displayed), and the actions
/// carry distinct visual weight so the destructive one is not the easiest to
/// hit by accident.
///
/// A persistent horizontal scrollbar is pinned to the bottom edge. The table
/// needs roughly 1230px, which is wider than a typical admin window, and a bare
/// `SingleChildScrollView` gave no indication that columns were off-screen.
class OwnerDesktopTable extends StatefulWidget {
  const OwnerDesktopTable({
    super.key,
    required this.owners,
    required this.onApprove,
    required this.onReject,
  });

  final List<OwnerSummary> owners;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;

  @override
  State<OwnerDesktopTable> createState() => _OwnerDesktopTableState();
}

class _OwnerDesktopTableState extends State<OwnerDesktopTable> {
  /// Shared between the [Scrollbar] and the scroll view so the bar can drive
  /// the table's horizontal position.
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = theme.dividerColor;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: divider),
      ),
      clipBehavior: Clip.antiAlias,
      // Flutter paints a horizontal Scrollbar's track along the bottom edge,
      // so a single always-visible bar is all that is needed.
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 10,
        radius: const Radius.circular(5),
        interactive: true,
        // Track only this table's own horizontal scroll view, not the vertical
        // page scroll that encloses it.
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
            dataRowMinHeight: 62,
            dataRowMaxHeight: 74,
            columnSpacing: 28,
            horizontalMargin: 20,
            headingTextStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            dividerThickness: 0.5,
            columns: const [
              DataColumn(label: Text('OWNER')),
              DataColumn(label: Text('CONTACT')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('LOCATIONS'), numeric: true),
              DataColumn(label: Text('BOOKINGS'), numeric: true),
              DataColumn(label: Text('REVENUE'), numeric: true),
              DataColumn(label: Text('ACTIONS')),
            ],
            rows: [
              for (final summary in widget.owners)
                DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 210,
                        child: OwnerIdentity(summary: summary.owner),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 210,
                        child: OwnerContact(owner: summary.owner),
                      ),
                    ),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OwnerStatusPill(
                            status: OwnerStatus.from(summary.owner),
                          ),
                          if (_rejectionReason(summary.owner) != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _rejectionReason(summary.owner)!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.lightTextSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(
                      _MetricCell(value: '${summary.locationsCount}'),
                    ),
                    DataCell(
                      _MetricCell(value: '${summary.bookingsCount}'),
                    ),
                    DataCell(
                      Text(
                        'â‚¹${formatInr(summary.revenue.round())}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDarkGreen,
                        ),
                      ),
                    ),
                    DataCell(
                      _OwnerActions(
                        status: OwnerStatus.from(summary.owner),
                        onApprove: () =>
                            widget.onApprove(summary.owner['id'].toString()),
                        onReject: () =>
                            widget.onReject(summary.owner['id'].toString()),
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

  static String? _rejectionReason(Map<String, dynamic> owner) {
    final reason = (owner['rejection_reason'] as String?)?.trim();
    if (reason == null || reason.isEmpty) return null;
    // The cubit writes this placeholder when an admin rejects without typing.
    if (reason == 'Rejected by admin') return null;
    return reason;
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

/// Approve / Reject controls.
///
/// Which buttons appear is unchanged from the previous implementation:
/// Approve for pending and rejected owners, Reject for pending and approved.
class _OwnerActions extends StatelessWidget {
  const _OwnerActions({
    required this.status,
    required this.onApprove,
    required this.onReject,
  });

  final OwnerStatus status;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showApprove = status != OwnerStatus.approved;
    final showReject = status != OwnerStatus.rejected;

    if (!showApprove && !showReject) {
      return Text(
        'No action needed',
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.lightTextSecondary,
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
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
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
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              minimumSize: const Size(0, 36),
            ),
          ),
      ],
    );
  }
}
