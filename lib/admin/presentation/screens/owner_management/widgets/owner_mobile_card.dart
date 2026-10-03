import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/admin/presentation/blocs/owners/owner_management_state.dart';
import 'package:cricket_admin_panel/common/utils/formatters.dart';
import 'owner_identity.dart';
import 'owner_status_pill.dart';

/// Narrow-screen owner card.
///
/// The previous layout was a single `DataTable` for every breakpoint, so below
/// roughly 800dp the page became a horizontal scroll with eight columns and
/// unusable action buttons. Cards keep the same data and the same actions
/// without horizontal scrolling.
class OwnerMobileCard extends StatelessWidget {
  const OwnerMobileCard({
    super.key,
    required this.summary,
    required this.onApprove,
    required this.onReject,
  });

  final OwnerSummary summary;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = OwnerStatus.from(summary.owner);
    final ownerId = summary.owner['id'].toString();
    final showApprove = status != OwnerStatus.approved;
    final showReject = status != OwnerStatus.rejected;
    final reason = (summary.owner['rejection_reason'] as String?)?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: identity + status
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: OwnerIdentity(
                    summary: summary.owner,
                    monogramSize: 42,
                  ),
                ),
                const SizedBox(width: 10),
                OwnerStatusPill(status: status, compact: true),
              ],
            ),
          ),

          // Contact
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: OwnerContact(owner: summary.owner),
          ),

          // Metrics
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                _MiniStat(
                  icon: Icons.location_on_rounded,
                  label: 'Locations',
                  value: '${summary.locationsCount}',
                ),
                const SizedBox(width: 18),
                _MiniStat(
                  icon: Icons.event_available_rounded,
                  label: 'Bookings',
                  value: '${summary.bookingsCount}',
                ),
                const SizedBox(width: 18),
                _MiniStat(
                  icon: Icons.payments_rounded,
                  label: 'Revenue',
                  value: 'â‚¹${formatInr(summary.revenue.round())}',
                  valueColor: AppColors.primaryDarkGreen,
                ),
              ],
            ),
          ),

          if (reason != null && reason.isNotEmpty && reason != 'Rejected by admin')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Text(
                  'Reason: $reason',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.red.shade800,
                    height: 1.4,
                  ),
                ),
              ),
            ),

          // Actions
          if (showApprove || showReject)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  if (showApprove)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => onApprove(ownerId),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Approve'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryDarkGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  if (showApprove && showReject) const SizedBox(width: 10),
                  if (showReject)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onReject(ownerId),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.lightTextSecondary),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.lightTextSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
