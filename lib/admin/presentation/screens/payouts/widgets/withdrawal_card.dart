import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';
import 'package:cricket_admin_panel/common/utils/formatters.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/widgets/admin_status_pill.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import '../../owner_management/widgets/owner_identity.dart';
import 'payout_widgets.dart';

/// One withdrawal request.
///
/// Surfaces the owner's available wallet balance, which the previous
/// implementation already fetched but never displayed. Without it the admin
/// cannot tell whether a request is fully backed by the owner's balance before
/// approving a real bank transfer.
class WithdrawalCard extends StatelessWidget {
  const WithdrawalCard({
    super.key,
    required this.withdrawal,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> withdrawal;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  static bool _hasValue(Object? value) =>
      value != null && value.toString().trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = AdminBreakpoints.isCompact(context);

    final status = withdrawal['status'];
    final isPending = status?.toString().toLowerCase() == 'pending';

    final owner = withdrawal['owner_details'] as Map<String, dynamic>?;
    final ownerName = (owner?['owner_name'] as String?)?.trim();
    final businessName = (owner?['business_name'] as String?)?.trim();
    final phone = (owner?['phone'] as String?)?.trim();
    final ownerId = withdrawal['owner_id'];

    final amount = asInt(withdrawal['amount']);
    final wallet = withdrawal['owner_wallets'] as Map<String, dynamic>?;
    final available = wallet == null ? null : asInt(wallet['available_balance']);

    // A request larger than the recorded balance is the case worth flagging.
    final exceedsBalance =
        available != null && amount > 0 && amount > available;

    final failureReason = (withdrawal['failure_reason'] as String?)?.trim();

    final style = payoutStatusStyle(context, status);

    return AdminSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Owner + status -------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: OwnerIdentity(
                  summary: {'owner_name': ownerName ?? 'Unknown owner'},
                  monogramSize: 40,
                ),
              ),
              const SizedBox(width: 10),
              AdminStatusPill(
                label: style.label,
                color: style.color,
                icon: style.icon,
                compact: true,
              ),
            ],
          ),

          if (_hasValue(businessName) || _hasValue(phone)) ...[
            const SizedBox(height: 8),
            Text(
              [
                if (_hasValue(businessName)) businessName,
                if (_hasValue(phone)) phone,
              ].join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // --- Amount + balance ----------------------------------------------
          AdminSurface(
            padding: const EdgeInsets.all(12),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AmountBlock(amount: amount),
                      const SizedBox(height: 10),
                      _BalanceBlock(available: available),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _AmountBlock(amount: amount)),
                      Expanded(child: _BalanceBlock(available: available)),
                    ],
                  ),
          ),

          if (exceedsBalance) ...[
            const SizedBox(height: 10),
            PayoutWarningBanner(
              message: 'Requested ${formatInr(amount)} but the owner only has '
                  '${formatInr(available)} available. '
                  'Check the amount before approving.',
            ),
          ],

          if (_hasValue(failureReason)) ...[
            const SizedBox(height: 10),
            PayoutWarningBanner(message: 'Reason: $failureReason'),
          ],

          const SizedBox(height: 10),

          // --- Requested at ---------------------------------------------------
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Requested ${formatRelative(withdrawal['created_at'])}'
                  '${formatDateTime(withdrawal['created_at']).isEmpty ? '' : ' · ${formatDateTime(withdrawal['created_at'])}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (_hasValue(ownerId))
                Text(
                  'ID ${ownerId.toString().substring(0, ownerId.toString().length > 8 ? 8 : ownerId.toString().length)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),

          // --- Actions ---------------------------------------------------------
          if (isPending) ...[
            const SizedBox(height: 16),
            if (isCompact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.payments_rounded, size: 18),
                    label: const Text('Approve & pay'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 46),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      minimumSize: const Size(0, 46),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.payments_rounded, size: 18),
                    label: const Text('Approve & pay'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  const _AmountBlock({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'REQUESTED',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '₹${formatInr(amount)}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDarkGreen,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _BalanceBlock extends StatelessWidget {
  const _BalanceBlock({required this.available});

  final int? available;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'OWNER AVAILABLE BALANCE',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          available == null ? '—' : '₹${formatInr(available!)}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
