import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';

/// Which category of approval is being reviewed.
enum ApprovalFilter {
  all('All'),
  owners('Owners'),
  locations('Locations');

  const ApprovalFilter(this.label);
  final String label;
}

/// At-a-glance counts of the review queue.
class ApprovalsSummary extends StatelessWidget {
  const ApprovalsSummary({
    super.key,
    required this.ownerCount,
    required this.locationCount,
    required this.ownersMissingDocs,
    required this.locationsMissingDocs,
  });

  final int ownerCount;
  final int locationCount;
  final int ownersMissingDocs;
  final int locationsMissingDocs;

  @override
  Widget build(BuildContext context) {
    final tiles = <_SummaryTile>[
      _SummaryTile(
        label: 'Pending owners',
        value: '$ownerCount',
        icon: Icons.storefront_rounded,
        color: AppColors.primaryDarkGreen,
      ),
      _SummaryTile(
        label: 'Pending locations',
        value: '$locationCount',
        icon: Icons.location_on_rounded,
        color: Colors.blue.shade600,
      ),
      _SummaryTile(
        label: 'Owners missing docs',
        value: '$ownersMissingDocs',
        icon: Icons.badge_outlined,
        // Zero is good news here, so it is muted rather than alarming.
        color: ownersMissingDocs > 0
            ? AppColors.accentOrange
            : mutedForeground(context),
      ),
      _SummaryTile(
        label: 'Locations missing docs',
        value: '$locationsMissingDocs',
        icon: Icons.description_outlined,
        color: locationsMissingDocs > 0
            ? AppColors.accentOrange
            : mutedForeground(context),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 620
                ? 2
                : 2;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles)
              SizedBox(width: width, child: _SummaryTileView(tile: tile)),
          ],
        );
      },
    );
  }

  static Color mutedForeground(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
}

class _SummaryTile {
  const _SummaryTile({
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

class _SummaryTileView extends StatelessWidget {
  const _SummaryTileView({required this.tile});

  final _SummaryTile tile;

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

/// Segmented control for switching between all approvals, owners only and
/// locations only.
///
/// The previous layout interleaved both categories in a single list with no way
/// to view one at a time, so reviewing a batch of location documents meant
/// scrolling past every owner card.
class ApprovalsFilterBar extends StatelessWidget {
  const ApprovalsFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
    required this.ownerCount,
    required this.locationCount,
  });

  final ApprovalFilter filter;
  final ValueChanged<ApprovalFilter> onChanged;
  final int ownerCount;
  final int locationCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    int countFor(ApprovalFilter value) => switch (value) {
          ApprovalFilter.all => ownerCount + locationCount,
          ApprovalFilter.owners => ownerCount,
          ApprovalFilter.locations => locationCount,
        };

    return AdminSurface(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          for (final value in ApprovalFilter.values)
            Expanded(
              child: _Segment(
                label: value.label,
                count: countFor(value),
                isSelected: filter == value,
                onTap: () => onChanged(value),
                theme: theme,
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.primaryDarkGreen
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
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

/// Section heading used inside approval cards.
class ApprovalSectionHeader extends StatelessWidget {
  const ApprovalSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tappable document chip that clearly distinguishes present from missing.
///
/// Replaces two byte-identical copies of this widget that lived in the owner
/// and location cards.
class ApprovalDocumentChip extends StatelessWidget {
  const ApprovalDocumentChip({
    super.key,
    required this.label,
    required this.url,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String? url;
  final IconData icon;
  final void Function(String url, String title) onTap;

  bool get _hasDoc => url != null && url!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _hasDoc
        ? AppColors.primaryDarkGreen
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: _hasDoc ? () => onTap(url!, label) : null,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _hasDoc ? icon : Icons.radio_button_unchecked_rounded,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (_hasDoc) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 12,
                  color: color.withValues(alpha: 0.7),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Read-only presence indicator for a document that is not directly openable
/// from this card.
class ApprovalDocPresence extends StatelessWidget {
  const ApprovalDocPresence({super.key, required this.label, required this.present});

  final String label;
  final bool present;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        present ? AppColors.primaryDarkGreen : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            present ? Icons.check_circle_rounded : Icons.remove_circle_outline,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Label / value row.
///
/// Uses a flexible label width rather than a hardcoded 120px column, which
/// squeezed the value on a phone.
class ApprovalInfoRow extends StatelessWidget {
  const ApprovalInfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = AdminBreakpoints.isCompact(context);

    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Approve / Reject action bar.
///
/// Stacks to full-width buttons on a phone so neither target is cramped, and
/// keeps the destructive action visually subordinate to the primary one.
class ApprovalActionBar extends StatelessWidget {
  const ApprovalActionBar({
    super.key,
    required this.onApprove,
    required this.onReject,
    required this.approveLabel,
    this.isBusy = false,
  });

  final VoidCallback onApprove;
  final VoidCallback onReject;
  final String approveLabel;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final isCompact = AdminBreakpoints.isCompact(context);

    final approve = FilledButton.icon(
      onPressed: isBusy ? null : onApprove,
      icon: const Icon(Icons.check_rounded, size: 18),
      label: Text(approveLabel),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryDarkGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
      ),
    );

    final reject = OutlinedButton.icon(
      onPressed: isBusy ? null : onReject,
      icon: const Icon(Icons.close_rounded, size: 18),
      label: const Text('Reject'),
      style: OutlinedButton.styleFrom(
        foregroundColor: rejectForeground(context),
        side: BorderSide(
          color: rejectForeground(context).withValues(alpha: 0.4),
        ),
        minimumSize: const Size(0, 44),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          approve,
          const SizedBox(height: 10),
          reject,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        approve,
        const SizedBox(width: 10),
        reject,
      ],
    );
  }

  static Color rejectForeground(BuildContext context) =>
      Theme.of(context).colorScheme.error;
}

/// Inline warning strip, used when required documents are missing.
class ApprovalWarningBanner extends StatelessWidget {
  const ApprovalWarningBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warn = AppColors.accentOrange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: warn.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: warn.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: warn),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
