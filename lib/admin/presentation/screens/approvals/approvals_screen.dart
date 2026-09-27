import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_admin_panel/common/responsive/admin_page_scaffold.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/widgets/shimmer_placeholder.dart';
import '../../blocs/approvals/approvals_cubit.dart';
import '../../blocs/approvals/approvals_state.dart';
import 'widgets/approval_widgets.dart';
import 'widgets/approval_cards.dart';
import 'widgets/document_preview_screen.dart';

/// Review queue for owner and location verifications.
///
/// Behaviour is unchanged: the same cubit calls with the same arguments, the
/// same snackbars, the same document preview. The screen now separates owners
/// from locations behind a filter, reports counts, warns when required
/// documents are missing, and uses the shared responsive scaffold so it works
/// on a phone.
class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  ApprovalFilter _filter = ApprovalFilter.all;

  @override
  void initState() {
    super.initState();
    context.read<ApprovalsCubit>().fetchPending();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Shared reject flow for both owners and locations.
  Future<void> _confirmReject({
    required String title,
    required Future<void> Function(String reason) onConfirm,
    required String successMessage,
  }) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            helperText: 'Shown to the owner in their app',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
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

    if (confirmed != true) {
      controller.dispose();
      return;
    }

    final reason = controller.text.trim();
    controller.dispose();

    if (!mounted) return;
    await onConfirm(reason);
    if (mounted) _showMessage(successMessage);
  }

  Future<void> _rejectOwner(String ownerId) => _confirmReject(
        title: 'Reject owner',
        successMessage: 'Owner rejected.',
        onConfirm: (reason) =>
            context.read<ApprovalsCubit>().reject(ownerId, reason: reason),
      );

  Future<void> _approveOwner(String ownerId) async {
    await context.read<ApprovalsCubit>().approve(ownerId);
    if (mounted) _showMessage('Owner approved.');
  }

  Future<void> _approveLocation(String locationId, String ownerId) async {
    await context.read<ApprovalsCubit>().approveLocation(locationId, ownerId);
    if (mounted) _showMessage('Location approved.');
  }

  Future<void> _rejectLocation(String locationId, String ownerId) =>
      _confirmReject(
        title: 'Reject location',
        successMessage: 'Location rejected.',
        onConfirm: (reason) => context
            .read<ApprovalsCubit>()
            .rejectLocation(locationId, ownerId, reason: reason),
      );

  void _openDocument(String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentPreviewScreen(
          url: url,
          title: title,
          isPdf: url.toLowerCase().endsWith('.pdf'),
        ),
      ),
    );
  }

  static bool _hasValue(Object? value) {
    if (value == null) return false;
    return value.toString().trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ApprovalsCubit>();

    return BlocBuilder<ApprovalsCubit, ApprovalsState>(
      builder: (context, state) {
        final loaded = state is ApprovalsLoaded ? state : null;

        final ownerCount = loaded?.pendingOwners.length ?? 0;
        final locationCount = loaded?.pendingLocations.length ?? 0;

        final subtitle = switch (state) {
          ApprovalsLoaded() => ownerCount + locationCount == 0
              ? 'Nothing waiting'
              : '$ownerCount owner${ownerCount == 1 ? '' : 's'} · '
                  '$locationCount location${locationCount == 1 ? '' : 's'}',
          ApprovalsLoading() => 'Refreshing…',
          _ => 'Loading',
        };

        return AdminPageScaffold(
          title: 'Pending Approvals',
          subtitle: subtitle,
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed:
                  state is ApprovalsLoading ? null : () => cubit.fetchPending(),
              icon: state is ApprovalsLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
          child: _buildBody(context, state, cubit),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ApprovalsState state,
    ApprovalsCubit cubit,
  ) {
    if (state is ApprovalsError) {
      return AdminStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load approvals',
        message: state.message,
        actionLabel: 'Retry',
        onAction: () => cubit.fetchPending(),
        tone: AdminStateTone.error,
      );
    }

    if (state is! ApprovalsLoaded) {
      return const ShimmerPage(
        children: [
          ShimmerTileGrid(
            count: 4,
            columnsAtExpanded: 4,
            columnsAtMedium: 2,
            columnsAtCompact: 2,
          ),
          SizedBox(height: 14),
          ShimmerFilterBar(chips: 3),
          SizedBox(height: 14),
          ShimmerCardList(count: 3, lineCount: 3, footerActions: true),
        ],
      );
    }

    if (state.pendingOwners.isEmpty && state.pendingLocations.isEmpty) {
      return const AdminStateView(
        icon: Icons.verified_rounded,
        title: 'Nothing to review',
        message: 'New owner and location submissions will appear here.',
      );
    }

    // Count how many submissions are missing at least one required document so
    // the risk is visible before the admin starts clicking through.
    final ownersMissingDocs = state.pendingOwners.where((o) {
      return !_hasValue(o['pan_url']) || !_hasValue(o['aadhar_url']);
    }).length;
    final locationsMissingDocs = state.pendingLocations.where((l) {
      return !_hasValue(l['property_document_url']) || !_hasValue(l['noc_url']);
    }).length;

    final showOwners = _filter != ApprovalFilter.locations;
    final showLocations = _filter != ApprovalFilter.owners;

    return RefreshIndicator(
      onRefresh: () => cubit.fetchPending(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ApprovalsSummary(
            ownerCount: state.pendingOwners.length,
            locationCount: state.pendingLocations.length,
            ownersMissingDocs: ownersMissingDocs,
            locationsMissingDocs: locationsMissingDocs,
          ),
          const SizedBox(height: 14),
          ApprovalsFilterBar(
            filter: _filter,
            onChanged: (value) => setState(() => _filter = value),
            ownerCount: state.pendingOwners.length,
            locationCount: state.pendingLocations.length,
          ),
          const SizedBox(height: 14),

          if (showOwners)
            for (final owner in state.pendingOwners) ...[
              OwnerApprovalCard(
                owner: owner,
                locations: state.locationsByOwner[owner['id'].toString()] ?? [],
                onApprove: () => _approveOwner(owner['id'].toString()),
                onReject: () => _rejectOwner(owner['id'].toString()),
                onDocumentTap: _openDocument,
              ),
              const SizedBox(height: 12),
            ],

          if (showLocations)
            for (final location in state.pendingLocations) ...[
              LocationApprovalCard(
                location: location,
                onApprove: () => _approveLocation(
                  location['id'].toString(),
                  location['owner_id'].toString(),
                ),
                onReject: () => _rejectLocation(
                  location['id'].toString(),
                  location['owner_id'].toString(),
                ),
                onDocumentTap: _openDocument,
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}
