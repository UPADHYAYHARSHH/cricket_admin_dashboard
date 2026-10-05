import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cricket_admin_panel/common/responsive/admin_page_scaffold.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/widgets/shimmer_placeholder.dart';
import '../../blocs/bookings/booking_management_cubit.dart';
import '../../blocs/bookings/booking_management_state.dart';

class BookingManagementScreen extends StatefulWidget {
  const BookingManagementScreen({super.key});

  @override
  State<BookingManagementScreen> createState() => _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<BookingManagementCubit>().fetchBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    if (_query == value) return;
    setState(() => _query = value);
  }

  bool _matchesQuery(Map<String, dynamic> booking, String query) {
    if (query.isEmpty) return true;
    final needle = query.toLowerCase();

    final displayId = (booking['display_id'] ?? '').toString().toLowerCase();
    final status = (booking['status'] ?? '').toString().toLowerCase();
    
    final user = booking['users'] as Map<String, dynamic>?;
    final userName = (user?['name'] ?? '').toString().toLowerCase();
    
    final ground = booking['grounds'] as Map<String, dynamic>?;
    final groundName = (ground?['name'] ?? '').toString().toLowerCase();

    return displayId.contains(needle) || 
           status.contains(needle) || 
           userName.contains(needle) ||
           groundName.contains(needle);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
  
  String _formatSlot(String? dateStr, String? startStr, String? endStr) {
    if (dateStr == null || startStr == null || endStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final date = DateFormat('dd MMM yyyy').format(dt);
      
      String formatTime(String t) {
        final parts = t.split(':');
        if (parts.length >= 2) {
          final hr = int.parse(parts[0]);
          final min = int.parse(parts[1]);
          final now = DateTime.now();
          final temp = DateTime(now.year, now.month, now.day, hr, min);
          return DateFormat('hh:mm a').format(temp);
        }
        return t;
      }
      
      return '$date\n${formatTime(startStr)} - ${formatTime(endStr)}';
    } catch (_) {
      return '$dateStr $startStr-$endStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingManagementCubit>();

    return BlocBuilder<BookingManagementCubit, BookingManagementState>(
      builder: (context, state) {
        final List<Map<String, dynamic>>? bookings = state is BookingManagementLoaded ? state.bookings : null;

        return AdminPageScaffold(
          title: 'Bookings',
          subtitle: bookings == null ? 'Loading bookings...' : '${bookings.length} total bookings',
          actions: [
            IconButton(
              tooltip: 'Refresh bookings',
              onPressed: state is BookingManagementLoading ? null : () => cubit.fetchBookings(),
              icon: state is BookingManagementLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
          child: _buildBody(context, state, bookings, cubit),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, BookingManagementState state, List<Map<String, dynamic>>? bookings, BookingManagementCubit cubit) {
    if (state is BookingManagementError) {
      return AdminStateView(
        icon: Icons.error_outline_rounded,
        title: 'Could not load bookings',
        message: state.message,
        actionLabel: 'Retry',
        onAction: () => cubit.fetchBookings(),
      );
    }

    if (bookings == null) {
      return const ShimmerPage(
        children: [
          ShimmerSurface(child: ShimmerTable(rows: 8, columns: 6)),
        ],
      );
    }

    if (bookings.isEmpty) {
      return AdminStateView(
        icon: Icons.event_available_rounded,
        title: 'No bookings found',
        message: 'There are no bookings in the system yet.',
        actionLabel: 'Refresh',
        onAction: () => cubit.fetchBookings(),
      );
    }

    final visible = bookings.where((b) => _matchesQuery(b, _query)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            controller: _searchController,
            onChanged: _setQuery,
            decoration: const InputDecoration(
              hintText: 'Search by ID, User, Ground, or Status...',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        if (visible.isEmpty)
          const Expanded(
            child: Center(child: Text('No bookings match your search.')),
          )
        else
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Ground')),
                      DataColumn(label: Text('Slot')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Booked At')),
                    ],
                    rows: visible.map((b) {
                      final displayId = b['display_id']?.toString() ?? b['id']?.toString() ?? '-';
                      final user = b['users'] as Map<String, dynamic>?;
                      final userName = user?['name']?.toString() ?? '-';
                      final ground = b['grounds'] as Map<String, dynamic>?;
                      final groundName = ground?['name']?.toString() ?? '-';
                      final status = b['status']?.toString().toUpperCase() ?? '-';
                      final amount = b['amount']?.toString() ?? '-';
                      
                      Color statusColor = Colors.grey;
                      if (status == 'CONFIRMED' || status == 'COMPLETED') statusColor = Colors.green;
                      if (status == 'CANCELLED' || status == 'FAILED') statusColor = Colors.red;
                      if (status == 'PENDING') statusColor = Colors.orange;

                      return DataRow(
                        cells: [
                          DataCell(Text(displayId)),
                          DataCell(Text(userName)),
                          DataCell(Text(groundName)),
                          DataCell(Text(_formatSlot(b['date'], b['start_time'], b['end_time']))),
                          DataCell(Text('₹$amount')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(_formatDate(b['created_at']))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
