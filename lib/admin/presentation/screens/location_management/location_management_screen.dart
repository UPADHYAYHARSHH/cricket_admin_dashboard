import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/constants/app_colors.dart';
import '../../blocs/locations/location_management_cubit.dart';
import '../../blocs/locations/location_management_state.dart';
import 'location_detail_screen.dart';

class LocationManagementScreen extends StatefulWidget {
  const LocationManagementScreen({super.key});

  @override
  State<LocationManagementScreen> createState() => _LocationManagementScreenState();
}

class _LocationManagementScreenState extends State<LocationManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LocationManagementCubit>().fetchLocations();
  }

  ({String label, Color color}) _statusOf(Map<String, dynamic> location) {
    if (location['documents_verified'] == true) {
      return (label: 'Approved', color: AppColors.primaryDarkGreen);
    }
    if (location['rejection_reason'] != null) {
      return (label: 'Rejected', color: Colors.red);
    }
    return (label: 'Pending', color: AppColors.accentOrange);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final cubit = context.read<LocationManagementCubit>();

    return Scaffold(
      appBar: AppBar(
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => context.findRootAncestorStateOfType<ScaffoldState>()?.openDrawer(),
              ),
        title: Text(
          'Location Management',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: cubit.fetchLocations),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<LocationManagementCubit, LocationManagementState>(
        builder: (context, state) {
          if (state is LocationManagementLoading || state is LocationManagementInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is LocationManagementError) {
            return Center(child: Text(state.message));
          }

          final loaded = state as LocationManagementLoaded;
          if (loaded.locations.isEmpty) {
            return const Center(child: Text('No locations found.'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
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
                  headingTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  columns: const [
                    DataColumn(label: Text('Location')),
                    DataColumn(label: Text('Owner')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Active')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: loaded.locations.map((location) {
                    final status = _statusOf(location);
                    final ownerName = loaded.ownerNameById[location['owner_id'].toString()] ?? 'Owner';
                    final isActive = location['is_active'] != false;
                    return DataRow(
                      cells: [
                        DataCell(Text(
                          (location['address'] as String?)?.isNotEmpty == true
                              ? location['address'] as String
                              : 'Unnamed',
                        )),
                        DataCell(Text(ownerName)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: status.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              status.label.toUpperCase(),
                              style: TextStyle(color: status.color, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        DataCell(
                          Switch(
                            value: isActive,
                            activeColor: AppColors.primaryDarkGreen,
                            onChanged: (value) =>
                                cubit.toggleLocationActive(location['id'] as String, value),
                          ),
                        ),
                        DataCell(
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LocationDetailScreen(
                                  location: location,
                                  ownerName: ownerName,
                                ),
                              ),
                            ),
                            child: const Text('View Details'),
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
