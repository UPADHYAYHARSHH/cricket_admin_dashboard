import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/constants/app_colors.dart';
import '../../blocs/owners/owner_management_cubit.dart';
import '../../blocs/owners/owner_management_state.dart';

class OwnerManagementScreen extends StatefulWidget {
  const OwnerManagementScreen({super.key});

  @override
  State<OwnerManagementScreen> createState() => _OwnerManagementScreenState();
}

class _OwnerManagementScreenState extends State<OwnerManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OwnerManagementCubit>().fetchOwners();
  }

  ({String label, Color color}) _statusOf(Map<String, dynamic> owner) {
    final status = (owner['status']?.toString() ?? '').toLowerCase();
    if (status == 'approved') {
      return (label: 'Approved', color: AppColors.primaryDarkGreen);
    }
    if (status == 'rejected') {
      return (label: 'Rejected', color: Colors.red);
    }
    return (label: 'Pending', color: AppColors.accentOrange);
  }

  void _showRejectDialog(String ownerId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Owner'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<OwnerManagementCubit>().rejectOwner(
                ownerId,
                reason: reasonController.text.trim().isNotEmpty
                    ? reasonController.text.trim()
                    : null,
              );
              Navigator.pop(context);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final cubit = context.read<OwnerManagementCubit>();

    return Scaffold(
      appBar: AppBar(
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => context.findRootAncestorStateOfType<ScaffoldState>()?.openDrawer(),
              ),
        title: Text(
          'Owner Management',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: cubit.fetchOwners),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<OwnerManagementCubit, OwnerManagementState>(
        builder: (context, state) {
          if (state is OwnerManagementLoading || state is OwnerManagementInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OwnerManagementError) {
            return Center(child: Text(state.message));
          }

          final loaded = state as OwnerManagementLoaded;
          if (loaded.owners.isEmpty) {
            return const Center(child: Text('No owners found.'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  columns: const [
                    DataColumn(label: Text('Owner')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Locations')),
                    DataColumn(label: Text('Bookings')),
                    DataColumn(label: Text('Revenue')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: loaded.owners.map((summary) {
                    final owner = summary.owner;
                    final status = _statusOf(owner);
                    return DataRow(
                      cells: [
                        DataCell(Text(owner['owner_name'] as String? ?? 'Unknown')),
                        DataCell(Text(owner['business_email'] as String? ?? '-')),
                        DataCell(Text(owner['phone'] as String? ?? '-')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: status.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              status.label.toUpperCase(),
                              style: TextStyle(
                                color: status.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text('${summary.locationsCount}')),
                        DataCell(Text('${summary.bookingsCount}')),
                        DataCell(Text(
                          '₹${summary.revenue.toInt()}',
                          style: const TextStyle(color: AppColors.primaryDarkGreen, fontWeight: FontWeight.bold),
                        )),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (status.label == 'Pending' || status.label == 'Rejected')
                                TextButton.icon(
                                  onPressed: () => cubit.approveOwner(
                                    owner['id'].toString(),
                                  ),
                                  icon: const Icon(Icons.check_circle, color: AppColors.primaryDarkGreen, size: 18),
                                  label: const Text('Approve', style: TextStyle(color: AppColors.primaryDarkGreen)),
                                ),
                              if (status.label == 'Pending' || status.label == 'Approved')
                                TextButton.icon(
                                  onPressed: () => _showRejectDialog(
                                    owner['id'].toString(),
                                  ),
                                  icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                                  label: const Text('Reject', style: TextStyle(color: Colors.red)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
