import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/common/utils/formatters.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';

/// Tab shown on the withdrawals screen.
enum PayoutTab {
  pending('Pending', {'pending'}),
  processing('Processing', {'processing'}),
  settled('Settled', {'success'}),
  failed('Failed / Rejected', {'failed', 'rejected'});

  const PayoutTab(this.label, this.statuses);

  final String label;

  /// Status values this tab matches in the database.
  ///
  /// Rejecting a withdrawal sets the status to `rejected`, which is a different
  /// value from `failed`. Querying only `failed` therefore made every rejected
  /// withdrawal invisible in the UI even though the tab is labelled
  /// "Failed / Rejected".
  final Set<String> statuses;

  static PayoutTab statusOf(Object? status) {
    final value = status?.toString().toLowerCase();
    return PayoutTab.values.firstWhere(
      (tab) => tab.statuses.contains(value),
      orElse: () => PayoutTab.pending,
    );
  }
}

/// Visual treatment for a withdrawal status.
({String label, Color color, IconData icon}) payoutStatusStyle(
  BuildContext context,
  Object? status,
) {
  final error = Theme.of(context).colorScheme.error;

  return switch (PayoutTab.statusOf(status)) {
    PayoutTab.pending => (
        label: 'Pending',
        color: AppColors.accentOrange,
        icon: Icons.schedule_rounded
      ),
    PayoutTab.processing => (
        label: 'Processing',
        color: Colors.blue.shade700,
        icon: Icons.sync_rounded
      ),
    PayoutTab.settled => (
        label: 'Settled',
        color: AppColors.primaryDarkGreen,
        icon: Icons.check_circle_rounded
      ),
    PayoutTab.failed => (
        label: 'Not settled',
        color: error,
        icon: Icons.cancel_rounded
      ),
  };
}

/// Status filter chips and the tab total.
///
/// Uses a [Wrap] so the four tabs reflow on a phone instead of overflowing, and
/// shows the total value of the visible tab so the admin can size the queue
/// before opening it.
class PayoutFilterBar extends StatelessWidget {
  const PayoutFilterBar({
    super.key,
    required this.tab,
    required this.onChanged,
    required this.visibleCount,
    required this.visibleTotal,
    required this.isLoading,
  });

  final PayoutTab tab;
  final ValueChanged<PayoutTab> onChanged;
  final int visibleCount;
  final int visibleTotal;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminSurface(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in PayoutTab.values)
                _TabChip(
                  label: option.label,
                  isSelected: option == tab,
                  onTap: () => onChanged(option),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                isLoading
                    ? 'Loading…'
                    : '$visibleCount withdrawal${visibleCount == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'Total ${formatInr(visibleTotal)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? primary : primary.withValues(alpha: 0.30),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected ? Colors.white : primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline warning strip.
class PayoutWarningBanner extends StatelessWidget {
  const PayoutWarningBanner({super.key, required this.message});

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
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
