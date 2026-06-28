import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../../common/constants/app_colors.dart';
import '../../blocs/locations/location_management_cubit.dart';

class LocationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> location;
  final String ownerName;

  const LocationDetailScreen({super.key, required this.location, required this.ownerName});

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _grounds = [];
  List<Map<String, dynamic>> _bookings = [];

  bool get _locationIsLive =>
      widget.location['is_active'] != false && widget.location['documents_verified'] == true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cubit = context.read<LocationManagementCubit>();
    final locationId = widget.location['id'] as String;
    final results = await Future.wait([
      cubit.fetchGroundsForLocation(locationId),
      cubit.fetchBookingHistory(locationId),
    ]);
    if (!mounted) return;
    setState(() {
      _grounds = results[0];
      _bookings = results[1];
      _loading = false;
    });
  }

  Future<void> _toggleGround(String groundId, bool value) async {
    if (value && !_locationIsLive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Approve and activate the location before enabling its grounds.'),
          backgroundColor: AppColors.accentOrange,
        ),
      );
      return;
    }
    await context.read<LocationManagementCubit>().toggleGroundAvailable(groundId, value);
    setState(() {
      _grounds = _grounds
          .map((g) => g['id'] == groundId ? {...g, 'is_available': value} : g)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            (widget.location['address'] as String?) ?? 'Location',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            tabs: [Tab(text: 'Grounds'), Tab(text: 'Booking History')],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (!_locationIsLive)
                    Container(
                      width: double.infinity,
                      color: AppColors.accentOrange.withOpacity(0.1),
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'This location is ${widget.location['documents_verified'] == true ? 'disabled' : 'not yet approved'}. '
                        'Its grounds stay hidden from players until it is approved and active.',
                        style: const TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.w600),
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _GroundsTab(
                          grounds: _grounds,
                          isDesktop: isDesktop,
                          onToggle: _toggleGround,
                        ),
                        _HistoryTab(bookings: _bookings, isDesktop: isDesktop),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GroundsTab extends StatelessWidget {
  final List<Map<String, dynamic>> grounds;
  final bool isDesktop;
  final void Function(String groundId, bool value) onToggle;

  const _GroundsTab({required this.grounds, required this.isDesktop, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    if (grounds.isEmpty) {
      return const Center(child: Text('No grounds added at this location yet.'));
    }
    return ListView.separated(
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      itemCount: grounds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ground = grounds[index];
        final isAvailable = ground['is_available'] != false;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ground['name'] as String? ?? 'Ground',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ground['category'] ?? ''} • ₹${ground['price_per_hour'] ?? 0}/hr',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Text(isAvailable ? 'Available' : 'Disabled',
                  style: TextStyle(color: isAvailable ? AppColors.primaryDarkGreen : Colors.grey)),
              Switch(
                value: isAvailable,
                activeColor: AppColors.primaryDarkGreen,
                onChanged: (value) => onToggle(ground['id'] as String, value),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;
  final bool isDesktop;

  const _HistoryTab({required this.bookings, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings at this location yet.'));
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
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Ground')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Checked In')),
            ],
            rows: bookings.map((b) {
              final ground = b['grounds'] as Map<String, dynamic>?;
              DateTime? date;
              try {
                date = DateTime.parse((b['booking_date'] ?? b['created_at']) as String).toLocal();
              } catch (_) {}
              return DataRow(cells: [
                DataCell(Text(date != null ? DateFormat('d MMM yyyy, h:mm a').format(date) : '-')),
                DataCell(Text(ground?['name'] as String? ?? 'Ground')),
                DataCell(Text('₹${((b['amount'] ?? b['total_amount'] ?? 0) as num).toInt()}')),
                DataCell(Text((b['status'] ?? '').toString().toUpperCase())),
                DataCell(Icon(
                  b['checked_in'] == true ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: b['checked_in'] == true ? AppColors.primaryDarkGreen : Colors.grey,
                  size: 18,
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
