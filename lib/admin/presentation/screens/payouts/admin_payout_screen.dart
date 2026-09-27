import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cricket_admin_panel/common/responsive/admin_page_scaffold.dart';
import 'package:cricket_admin_panel/common/utils/formatters.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/widgets/shimmer_placeholder.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';
import 'widgets/payout_widgets.dart';
import 'widgets/withdrawal_card.dart';

/// Owner withdrawal queue.
///
/// The query, the `process-payout` invocation and its arguments are unchanged.
/// What changed is presentation and three defects:
///
///  * the "Failed / Rejected" tab queried only `status = 'failed'`, so every
///    rejected withdrawal was invisible even though the tab name promised it,
///  * a failed request was reported as "No withdrawals found.", so a network
///    error looked like an empty queue,
///  * the screen had no [Scaffold], so there was no app bar and no way to open
///    the navigation drawer on a phone.
class AdminPayoutScreen extends StatefulWidget {
  const AdminPayoutScreen({super.key});

  @override
  State<AdminPayoutScreen> createState() => _AdminPayoutScreenState();
}

class _AdminPayoutScreenState extends State<AdminPayoutScreen> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _withdrawals = [];
  bool _isLoading = true;
  String? _error;
  PayoutTab _tab = PayoutTab.pending;

  @override
  void initState() {
    super.initState();
    _fetchWithdrawals();
  }

  Future<void> _fetchWithdrawals() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final statuses = _tab.statuses.toList();

      final response = await _supabase
          .from('withdrawals')
          .select('*, owner_wallets(owner_id, total_earnings, available_balance)')
          .inFilter('status', statuses)
          .order('created_at', ascending: false);

      final withdrawals = List<Map<String, dynamic>>.from(response);

      if (withdrawals.isNotEmpty) {
        final ownerIds = withdrawals.map((w) => w['owner_id']).toSet().toList();
        final ownersResponse = await _supabase
            .from('owner_details')
            .select('id, owner_name, business_name, phone')
            .filter('id', 'in', ownerIds);

        final ownersMap = {for (var o in ownersResponse) o['id']: o};

        for (final w in withdrawals) {
          w['owner_details'] = ownersMap[w['owner_id']];
        }
      }

      if (!mounted) return;
      setState(() {
        _withdrawals = withdrawals;
        _isLoading = false;
      });
    } catch (e) {
      // Previously this collapsed into "No withdrawals found.", which made a
      // failed request indistinguishable from an empty queue.
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Blocking loader that is dismissed by reference rather than by popping the
  /// current route, which could remove the wrong screen.
  void _showLoader() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _dismissLoader() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _processPayout(String withdrawalId, String action) async {
    _showLoader();
    try {
      final res = await _supabase.functions.invoke(
        'process-payout',
        body: {'withdrawal_id': withdrawalId, 'action': action},
      );

      _dismissLoader();
      if (!mounted) return;

      _notify(res.data['message'] ?? 'Processed successfully');
      _fetchWithdrawals();
    } catch (e) {
      _dismissLoader();
      if (!mounted) return;
      _notify('Error: $e');
    }
  }

  /// Approving moves real money and cannot be undone from this screen, so it is
  /// confirmed first. This is the one intentional interaction change in the
  /// module.
  Future<void> _confirmApprove(Map<String, dynamic> withdrawal) async {
    final amount = asInt(withdrawal['amount']);
    final ownerName =
        ((withdrawal['owner_details'] as Map<String, dynamic>?)?['owner_name']
                as String?) ??
            'this owner';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm payout'),
        content: Text(
          'Send ₹${formatInr(amount)} to $ownerName? '
          'This transfers real money and cannot be undone from here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send payout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _processPayout(withdrawal['id'].toString(), 'approve');
  }

  Future<void> _confirmReject(Map<String, dynamic> withdrawal) async {
    final amount = asInt(withdrawal['amount']);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject withdrawal'),
        content: Text(
          'Reject the ₹${formatInr(amount)} request? '
          'The amount is returned to the owner\'s available balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _processPayout(withdrawal['id'].toString(), 'reject');
  }

  int get _visibleTotal => _withdrawals.fold<int>(
        0,
        (sum, w) => sum + asInt(w['amount']),
      );

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Owner Withdrawals',
      subtitle: _isLoading
          ? 'Loading…'
          : _error != null
              ? 'Could not load'
              : '${_withdrawals.length} in ${_tab.label.toLowerCase()}',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _isLoading ? null : _fetchWithdrawals,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return AdminStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load withdrawals',
        message: _error,
        actionLabel: 'Retry',
        onAction: _fetchWithdrawals,
        tone: AdminStateTone.error,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchWithdrawals,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          PayoutFilterBar(
            tab: _tab,
            onChanged: (tab) {
              setState(() => _tab = tab);
              _fetchWithdrawals();
            },
            visibleCount: _withdrawals.length,
            visibleTotal: _visibleTotal,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            // The filter bar above stays visible so the admin can switch tabs
            // while the first load is still running.
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: AdminBreakpoints.hasTableSpace(context)
                  ? const ShimmerSurface(
                      child: ShimmerTable(rows: 6, columns: 5),
                    )
                  : const ShimmerCardList(count: 4, lineCount: 3),
            )
          else if (_withdrawals.isEmpty)
            AdminSurface(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: AdminStateView(
                icon: Icons.payments_rounded,
                title: 'No ${_tab.label.toLowerCase()} withdrawals',
                message: 'Nothing to action in this tab right now.',
                actionLabel: 'Refresh',
                onAction: _fetchWithdrawals,
              ),
            )
          else
            for (final withdrawal in _withdrawals) ...[
              WithdrawalCard(
                withdrawal: withdrawal,
                onApprove: () => _confirmApprove(withdrawal),
                onReject: () => _confirmReject(withdrawal),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}
