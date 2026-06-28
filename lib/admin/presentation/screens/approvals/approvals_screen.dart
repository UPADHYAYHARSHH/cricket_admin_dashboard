import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
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

  Future<void> _reject(String locationId) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Location'),
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
    await context.read<ApprovalsCubit>().reject(locationId, reason: controller.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location rejected.')));
    }
  }

  Future<void> _approve(String locationId) async {
    await context.read<ApprovalsCubit>().approve(locationId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location approved.')));
    }
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
          if (loaded.pendingLocations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                    size: 64,
                    color: AppColors.primaryDarkGreen.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text('No pending location approvals.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            itemCount: loaded.pendingLocations.length,
            itemBuilder: (context, index) {
              final location = loaded.pendingLocations[index];
              final ownerName = loaded.ownerNameById[location['owner_id'].toString()] ?? 'Owner';
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
                            icon: HugeIcons.strokeRoundedLocation01,
                            color: AppColors.accentOrange,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (location['address'] as String?)?.isNotEmpty == true
                                    ? location['address'] as String
                                    : 'Unnamed location',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$ownerName • ${location['city'] ?? ''}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _docChip('Property document', location['property_document_url'] != null),
                        _docChip('NOC', location['noc_url'] != null),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDarkGreen),
                          onPressed: () => _approve(location['id'] as String),
                          child: const Text('Approve', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => _reject(location['id'] as String),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _docChip(String label, bool present) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: present ? AppColors.primaryDarkGreen.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            present ? Icons.check_circle : Icons.remove_circle_outline,
            size: 14,
            color: present ? AppColors.primaryDarkGreen : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: present ? AppColors.primaryDarkGreen : Colors.grey)),
        ],
      ),
    );
  }
}
