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
                    DataColumn(label: Text('Locations')),
                    DataColumn(label: Text('Bookings')),
                    DataColumn(label: Text('Revenue')),
                  ],
                  rows: loaded.owners.map((summary) {
                    final owner = summary.owner;
                    return DataRow(
                      cells: [
                        DataCell(Text(owner['owner_name'] as String? ?? 'Unknown')),
                        DataCell(Text(owner['business_email'] as String? ?? '-')),
                        DataCell(Text(owner['phone'] as String? ?? '-')),
                        DataCell(Text('${summary.locationsCount}')),
                        DataCell(Text('${summary.bookingsCount}')),
                        DataCell(Text(
                          '₹${summary.revenue.toInt()}',
                          style: const TextStyle(color: AppColors.primaryDarkGreen, fontWeight: FontWeight.bold),
                        )),
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
