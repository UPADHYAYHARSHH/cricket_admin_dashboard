import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';

/// Lifecycle state of a ground owner.
///
/// The database stores `submitted` for a not-yet-reviewed owner. Everything
/// that is neither `approved` nor `rejected` is treated as [pending], which
/// preserves the behaviour the previous implementation had inline.
enum OwnerStatus {
  pending,
  approved,
  rejected;

  static OwnerStatus from(Map<String, dynamic> owner) {
    switch ((owner['status']?.toString() ?? '').toLowerCase()) {
      case 'approved':
        return OwnerStatus.approved;
      case 'rejected':
        return OwnerStatus.rejected;
      default:
        return OwnerStatus.pending;
    }
  }

  String get label => switch (this) {
        OwnerStatus.pending => 'Pending',
        OwnerStatus.approved => 'Approved',
        OwnerStatus.rejected => 'Rejected',
      };

  /// The raw value persisted in `owner_details.status`.
  String get dbValue => switch (this) {
        OwnerStatus.pending => 'submitted',
        OwnerStatus.approved => 'approved',
        OwnerStatus.rejected => 'rejected',
      };

  Color get color => switch (this) {
        OwnerStatus.pending => AppColors.accentOrange,
        OwnerStatus.approved => AppColors.primaryDarkGreen,
        OwnerStatus.rejected => Colors.red.shade600,
      };

  Color get backgroundColor => switch (this) {
        OwnerStatus.pending => AppColors.accentOrange.withValues(alpha: 0.12),
        OwnerStatus.approved => AppColors.primaryDarkGreen.withValues(alpha: 0.12),
        OwnerStatus.rejected => Colors.red.shade600.withValues(alpha: 0.10),
      };

  Color get borderColor => switch (this) {
        OwnerStatus.pending => AppColors.accentOrange.withValues(alpha: 0.35),
        OwnerStatus.approved => AppColors.primaryDarkGreen.withValues(alpha: 0.35),
        OwnerStatus.rejected => Colors.red.shade600.withValues(alpha: 0.30),
      };

  IconData get icon => switch (this) {
        OwnerStatus.pending => Icons.schedule_rounded,
        OwnerStatus.approved => Icons.check_circle_rounded,
        OwnerStatus.rejected => Icons.cancel_rounded,
      };
}

/// Compact status indicator: coloured dot plus label inside a soft pill.
///
/// Replaces the previous plain uppercase `Text` chip, which had no dot, no
/// icon and a low-contrast background, making the most important column on the
/// page the hardest to scan.
class OwnerStatusPill extends StatelessWidget {
  const OwnerStatusPill({super.key, required this.status, this.compact = false});

  final OwnerStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: status.color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
