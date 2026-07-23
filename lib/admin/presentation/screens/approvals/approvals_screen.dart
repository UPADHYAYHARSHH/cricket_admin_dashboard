import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../common/constants/app_colors.dart';
import '../../blocs/approvals/approvals_cubit.dart';
import '../../blocs/approvals/approvals_state.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ApprovalsCubit>().fetchPending();
  }

  Future<void> _reject(String ownerId) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Owner'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<ApprovalsCubit>().reject(ownerId, reason: controller.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Owner rejected.')));
    }
  }

  Future<void> _approve(String ownerId) async {
    await context.read<ApprovalsCubit>().approve(ownerId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Owner approved.')));
    }
  }

  void _showDocumentPreview(String url, String title) {
    final isPdf = url.toLowerCase().endsWith('.pdf');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DocumentPreviewScreen(url: url, title: title, isPdf: isPdf),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => context.findRootAncestorStateOfType<ScaffoldState>()?.openDrawer(),
              ),
        title: Text(
          'Pending Approvals',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ApprovalsCubit>().fetchPending(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<ApprovalsCubit, ApprovalsState>(
        builder: (context, state) {
          if (state is ApprovalsLoading || state is ApprovalsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ApprovalsError) {
            return Center(child: Text(state.message));
          }

          final loaded = state as ApprovalsLoaded;
          if (loaded.pendingOwners.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                    size: 64,
                    color: AppColors.primaryDarkGreen.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text('No pending owner approvals.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            itemCount: loaded.pendingOwners.length,
            itemBuilder: (context, index) {
              final owner = loaded.pendingOwners[index];
<<<<<<< Updated upstream
              final ownerName = owner['owner_name'] ?? 'Unknown Owner';
              final businessName = owner['business_name'] ?? 'Unnamed Business';
              final venueName = owner['venue_name']?.toString().isNotEmpty == true ? owner['venue_name'] : null;
              final city = owner['city']?.toString().isNotEmpty == true ? owner['city'] : null;
              final phone = owner['phone']?.toString().isNotEmpty == true ? owner['phone'] : null;
              final address = owner['address'] ?? 'No address provided';
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedUserGroup,
                            color: AppColors.accentOrange,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                    Text(
                      ownerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (phone != null) ...[
                      const SizedBox(height: 2),
                      Text(phone, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _infoChip(Icons.store_outlined, businessName),
              if (venueName != null) _infoChip(Icons.stadium_outlined, venueName),
              if (city != null) _infoChip(Icons.location_city_outlined, city),
            ],
          ),
          const SizedBox(height: 4),
          Text(address, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _docChip('PAN Card', owner['pan_url'] != null && owner['pan_url'].toString().isNotEmpty),
                        _docChip('Aadhar Card', owner['aadhar_url'] != null && owner['aadhar_url'].toString().isNotEmpty),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDarkGreen),
                          onPressed: () => _approve(owner['id'] as String),
                          child: const Text('Approve', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => _reject(owner['id'] as String),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                ),
=======
              final ownerId = owner['id'].toString();
              final locations = loaded.locationsByOwner[ownerId] ?? [];
              return _OwnerApprovalCard(
                owner: owner,
                locations: locations,
                onApprove: () => _approve(ownerId),
                onReject: () => _reject(ownerId),
                onDocumentTap: _showDocumentPreview,
>>>>>>> Stashed changes
              );
            },
          );
        },
      ),
    );
  }
}

class _OwnerApprovalCard extends StatelessWidget {
  final Map<String, dynamic> owner;
  final List<Map<String, dynamic>> locations;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final void Function(String url, String title) onDocumentTap;

  const _OwnerApprovalCard({
    required this.owner,
    required this.locations,
    required this.onApprove,
    required this.onReject,
    required this.onDocumentTap,
  });

  @override
  Widget build(BuildContext context) {
    final panUrl = owner['pan_url'] as String?;
    final aadharUrl = owner['aadhar_url'] as String?;
    final kycConfig = owner['kyc_config'] as Map<String, dynamic>?;
    final accountName = kycConfig?['account_name'] as String? ?? '';
    final accountNumber = kycConfig?['account_number'] as String? ?? '';
    final ifscCode = kycConfig?['ifsc_code'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Owner header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryDarkGreen.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedUser02,
                  color: AppColors.primaryDarkGreen,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner['owner_name'] as String? ?? 'Owner',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${owner['business_name'] ?? ''} • ${owner['phone'] ?? ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (owner['business_email'] != null)
                      Text(
                        owner['business_email'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // KYC Documents section
          const SizedBox(height: 20),
          Text(
            'KYC Documents',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _docPreviewChip(
                context,
                label: 'PAN Card',
                url: panUrl,
                icon: Icons.badge_outlined,
                onTap: panUrl != null ? () => onDocumentTap(panUrl, 'PAN Card') : null,
              ),
              _docPreviewChip(
                context,
                label: 'Aadhar Card',
                url: aadharUrl,
                icon: Icons.credit_card_outlined,
                onTap: aadharUrl != null ? () => onDocumentTap(aadharUrl, 'Aadhar Card') : null,
              ),
            ],
          ),

          // Bank Details section
          if (accountName.isNotEmpty || accountNumber.isNotEmpty || ifscCode.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Bank Details',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (accountName.isNotEmpty)
                    _infoRow('Account Holder', accountName),
                  if (accountNumber.isNotEmpty)
                    _infoRow('Account Number', '${accountNumber.substring(0, accountNumber.length > 4 ? accountNumber.length - 4 : 0)}****'),
                  if (ifscCode.isNotEmpty)
                    _infoRow('IFSC Code', ifscCode),
                ],
              ),
            ),
          ],

          // Locations section
          if (locations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Locations (${locations.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...locations.map((loc) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${loc['address'] ?? 'Unnamed location'} • ${loc['city'] ?? ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  _locDocChip('Property Doc', loc['property_document_url'] != null),
                  const SizedBox(width: 6),
                  _locDocChip('NOC', loc['noc_url'] != null),
                ],
              ),
            )),
          ],

          // Action buttons
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDarkGreen),
                onPressed: onApprove,
                child: const Text('Approve', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: onReject,
                child: const Text('Reject'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _docPreviewChip(BuildContext context, {required String label, String? url, required IconData icon, VoidCallback? onTap}) {
    final hasDoc = url != null && url.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasDoc ? AppColors.primaryDarkGreen.withValues(alpha:0.1) : Colors.grey.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: hasDoc ? AppColors.primaryDarkGreen : Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: hasDoc ? AppColors.primaryDarkGreen : Colors.grey)),
            if (hasDoc) ...[
              const SizedBox(width: 4),
              Icon(Icons.open_in_new, size: 12, color: AppColors.primaryDarkGreen.withValues(alpha:0.6)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _locDocChip(String label, bool present) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: present ? AppColors.primaryDarkGreen.withValues(alpha:0.1) : Colors.grey.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            present ? Icons.check_circle : Icons.remove_circle_outline,
            size: 12,
            color: present ? AppColors.primaryDarkGreen : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: present ? AppColors.primaryDarkGreen : Colors.grey)),
        ],
      ),
    );
  }
  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }
}

class _DocumentPreviewScreen extends StatelessWidget {
  final String url;
  final String title;
  final bool isPdf;

  const _DocumentPreviewScreen({required this.url, required this.title, required this.isPdf});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
      body: Center(
        child: isPdf
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('PDF Document'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                    child: const Text('Open in Browser'),
                  ),
                ],
              )
            : InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const CircularProgressIndicator();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Failed to load image'),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}
