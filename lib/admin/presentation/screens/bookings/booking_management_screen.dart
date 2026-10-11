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
  String? _selectedStatus; // null means 'ALL'
  int _currentPage = 1;
  static const int _pageSize = 10;

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
    setState(() {
      _query = value;
      _currentPage = 1; // reset page on search
    });
  }

  void _setStatusFilter(String? status) {
    if (_selectedStatus == status) return;
    setState(() {
      _selectedStatus = status;
      _currentPage = 1; // reset page on filter change
    });
  }

  bool _matchesQueryAndStatus(Map<String, dynamic> booking, String query, String? statusFilter) {
    final status = (booking['status'] ?? '').toString().toLowerCase();

    // Check status filter
    if (statusFilter != null && statusFilter.isNotEmpty) {
      if (status != statusFilter.toLowerCase()) {
        return false;
      }
    }

    // Check search query
    if (query.isEmpty) return true;
    final needle = query.toLowerCase();

    final displayId = (booking['display_id'] ?? '').toString().toLowerCase();
    final user = booking['users'] as Map<String, dynamic>?;
    final userName = (user?['name'] ?? '').toString().toLowerCase();
    final userUsername = (user?['username'] ?? '').toString().toLowerCase();
    final userEmail = (user?['email'] ?? '').toString().toLowerCase();
    final userPhone = (user?['phone'] ?? '').toString().toLowerCase();
    final ground = booking['grounds'] as Map<String, dynamic>?;
    final groundName = (ground?['name'] ?? '').toString().toLowerCase();

    return displayId.contains(needle) ||
        status.contains(needle) ||
        userName.contains(needle) ||
        userUsername.contains(needle) ||
        userEmail.contains(needle) ||
        userPhone.contains(needle) ||
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

  String _formatSlot(Map<String, dynamic> b) {
    final dateStr = b['date'] ?? b['booking_date'];
    final startStr = b['start_time'];
    final endStr = b['end_time'];
    final slotTimeStr = b['slot_time'];
    final periodStr = b['period'];

    if (dateStr != null && startStr != null && endStr != null) {
      try {
        final dt = DateTime.parse(dateStr.toString()).toLocal();
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

        return '$date\n${formatTime(startStr.toString())} - ${formatTime(endStr.toString())}';
      } catch (_) {
        return '$dateStr $startStr-$endStr';
      }
    }

    if (slotTimeStr != null) {
      try {
        final dt = DateTime.parse(slotTimeStr.toString()).toLocal();
        final date = DateFormat('dd MMM yyyy').format(dt);
        final time = DateFormat('hh:mm a').format(dt);
        if (periodStr != null && periodStr.toString().isNotEmpty) {
          return '$date\n$periodStr';
        }
        return '$date\n$time';
      } catch (_) {
        return slotTimeStr.toString();
      }
    }

    if (periodStr != null && periodStr.toString().isNotEmpty) {
      return periodStr.toString();
    }

    return '-';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'confirmed':
      case 'completed':
        return const Color(0xFF0B8457);
      case 'pending':
      case 'requested':
        return Colors.orange;
      case 'cancelled':
      case 'declined':
      case 'failed':
        return Colors.red;
      case 'expired':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  void _showBookingDetailDialog(Map<String, dynamic> b, BookingManagementCubit cubit) {
    final displayId = b['display_id']?.toString() ?? b['id']?.toString() ?? '-';
    final user = b['users'] as Map<String, dynamic>?;
    final userName = user?['name']?.toString() ?? '-';
    final username = user?['username']?.toString() ?? '-';
    final userEmail = user?['email']?.toString() ?? '-';
    final userPhone = user?['phone']?.toString() ?? '-';

    final ground = b['grounds'] as Map<String, dynamic>?;
    final groundName = ground?['name']?.toString() ?? '-';
    final location = ground?['locations'] as Map<String, dynamic>?;
    final locationName = location?['name']?.toString() ?? '-';

    final status = (b['status']?.toString() ?? '-').toUpperCase();
    final statusColor = _getStatusColor(status);
    final isCheckedIn = b['checked_in'] == true;
    final checkedInAt = b['checked_in_at'];

    // Financial breakdown
    final amount = b['amount']?.toString() ?? '0';
    final baseAmount = b['base_amount']?.toString() ?? b['amount']?.toString() ?? '0';
    final platformFee = b['platform_fee']?.toString() ?? '0';
    final ownerEarnings = b['owner_earnings']?.toString() ?? '0';
    final commissionRate = b['commission_rate']?.toString() ?? '0';
    final commissionIsPercentage = b['commission_is_percentage'] == true;

    // Payment Gateway & Cashfree transaction metadata
    final orderId = (b['cashfree_order_id'] ?? b['order_id'] ?? b['razorpay_order_id'] ?? '-').toString();
    final paymentId = (b['cashfree_payment_id'] ?? b['payment_id'] ?? b['razorpay_payment_id'] ?? '-').toString();
    final payoutStatus = b['payout_status']?.toString() ?? '-';
    final cancellationReason = b['cancellation_reason']?.toString();
    final cancelledBy = b['cancelled_by']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B8457).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Booking #$displayId',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B8457),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
            ],
          ),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Customer Info ---
                  _buildSectionHeader('Customer Details', Icons.person_rounded),
                  _buildDetailRow('Username', username),
                  _buildDetailRow('Full Name', userName),
                  _buildDetailRow('Email', userEmail),
                  _buildDetailRow('Phone', userPhone),
                  const Divider(height: 24),

                  // --- Ground & Slot Info ---
                  _buildSectionHeader('Venue & Schedule', Icons.stadium_rounded),
                  _buildDetailRow('Ground', groundName),
                  if (locationName != '-') _buildDetailRow('Location', locationName),
                  _buildDetailRow('Slot Schedule', _formatSlot(b).replaceAll('\n', ' • ')),
                  _buildDetailRow('Booked At', _formatDate(b['created_at'])),
                  _buildDetailRow(
                    'Check-In Status',
                    isCheckedIn
                        ? 'Checked in at ${_formatDate(checkedInAt)}'
                        : 'Not Checked In',
                  ),
                  const Divider(height: 24),

                  // --- Financial Breakdown ---
                  _buildSectionHeader('Financial & Commission Breakdown', Icons.payments_rounded),
                  _buildDetailRow('Total Paid by User', '₹$amount'),
                  _buildDetailRow('Base Turf Amount', '₹$baseAmount'),
                  _buildDetailRow('Platform Fee', '₹$platformFee'),
                  _buildDetailRow(
                    'Admin Commission',
                    commissionIsPercentage ? '$commissionRate%' : '₹$commissionRate',
                  ),
                  _buildDetailRow('Partner / Owner Earnings', '₹$ownerEarnings'),
                  _buildDetailRow('Owner Payout Status', payoutStatus.toUpperCase()),
                  const Divider(height: 24),

                  // --- Transaction Identifiers ---
                  _buildSectionHeader('Payment Gateway Data (Cashfree)', Icons.receipt_long_rounded),
                  _buildDetailRow('Cashfree Order ID', orderId),
                  _buildDetailRow('Payment / Transaction ID', paymentId),
                  if (cancellationReason != null && cancellationReason.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cancelled by ${cancelledBy ?? "user"}: $cancellationReason',
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            // Check-in toggle
            OutlinedButton.icon(
              icon: Icon(
                isCheckedIn ? Icons.close_rounded : Icons.check_circle_outline_rounded,
                size: 18,
                color: isCheckedIn ? Colors.orange : Colors.green,
              ),
              label: Text(isCheckedIn ? 'Undo Check-In' : 'Mark Checked-In'),
              onPressed: () async {
                Navigator.pop(ctx);
                await cubit.toggleCheckIn(b['id'].toString(), isCheckedIn);
              },
            ),

            // Force Cancel button if active
            if (status != 'CANCELLED' && status != 'DECLINED' && status != 'FAILED')
              OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                label: const Text('Cancel Booking'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmCancelBooking(b, cubit);
                },
              ),

            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0B8457)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B8457),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancelBooking(Map<String, dynamic> b, BookingManagementCubit cubit) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Force Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel booking #${b['display_id'] ?? b['id']}? This will update the status to Cancelled.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                hintText: 'e.g., Weather interruption, turf conflict, or customer dispute',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final reason = reasonController.text.trim();
              Navigator.pop(ctx);
              await cubit.updateBookingStatus(
                b['id'].toString(),
                'cancelled',
                reason: reason.isEmpty ? 'Cancelled by Admin' : reason,
              );
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingManagementCubit>();

    return BlocBuilder<BookingManagementCubit, BookingManagementState>(
      builder: (context, state) {
        final List<Map<String, dynamic>>? bookings =
            state is BookingManagementLoaded ? state.bookings : null;

        return AdminPageScaffold(
          title: 'Bookings',
          subtitle: bookings == null
              ? 'Loading bookings...'
              : '${bookings.length} total bookings',
          actions: [
            IconButton(
              tooltip: 'Refresh bookings',
              onPressed: state is BookingManagementLoading
                  ? null
                  : () => cubit.fetchBookings(),
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

  Widget _buildBody(
    BuildContext context,
    BookingManagementState state,
    List<Map<String, dynamic>>? bookings,
    BookingManagementCubit cubit,
  ) {
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

    // Build filter options and counts
    final statusCounts = <String, int>{};
    for (final b in bookings) {
      final s = (b['status'] ?? '').toString().toLowerCase();
      if (s.isNotEmpty) {
        statusCounts[s] = (statusCounts[s] ?? 0) + 1;
      }
    }

    // Known standard filters
    final filterOptions = [
      {'key': null, 'label': 'All', 'count': bookings.length, 'color': const Color(0xFF0B8457)},
      {'key': 'paid', 'label': 'Paid', 'count': statusCounts['paid'] ?? 0, 'color': const Color(0xFF0B8457)},
      {'key': 'confirmed', 'label': 'Confirmed', 'count': statusCounts['confirmed'] ?? 0, 'color': Colors.teal},
      {'key': 'pending', 'label': 'Pending', 'count': (statusCounts['pending'] ?? 0) + (statusCounts['requested'] ?? 0), 'color': Colors.orange},
      {'key': 'cancelled', 'label': 'Cancelled', 'count': (statusCounts['cancelled'] ?? 0) + (statusCounts['declined'] ?? 0), 'color': Colors.red},
      {'key': 'expired', 'label': 'Expired', 'count': statusCounts['expired'] ?? 0, 'color': Colors.blueGrey},
    ];

    // Filter results
    final filtered = bookings
        .where((b) => _matchesQueryAndStatus(b, _query, _selectedStatus))
        .toList();

    // Pagination calculations
    final totalItems = filtered.length;
    final totalPages = (totalItems / _pageSize).ceil().clamp(1, 999999);
    final currentPage = _currentPage.clamp(1, totalPages);
    final startIndex = (currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, totalItems);
    final pageBookings = totalItems == 0 ? <Map<String, dynamic>>[] : filtered.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Search bar ---
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _searchController,
            onChanged: _setQuery,
            decoration: InputDecoration(
              hintText: 'Search by Booking ID, Customer, Ground, or Status...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _setQuery('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        // --- Filter Chips ---
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filterOptions.map((filter) {
                final key = filter['key'] as String?;
                final label = filter['label'] as String;
                final count = filter['count'] as int;
                final color = filter['color'] as Color;
                final isSelected = _selectedStatus == key;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.2,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10.5,
                              height: 1.1,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: color,
                    backgroundColor: color.withValues(alpha: 0.08),
                    checkmarkColor: Colors.white,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? color : color.withValues(alpha: 0.3),
                      ),
                    ),
                    onSelected: (_) => _setStatusFilter(key),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // --- Table or Empty View ---
        if (filtered.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No bookings match your selected filters.',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _query = '';
                        _selectedStatus = null;
                        _currentPage = 1;
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reset filters'),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          showCheckboxColumn: false,
                          headingRowColor: WidgetStateProperty.all(
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          columns: const [
                            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Ground', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Slot', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Booked At', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: pageBookings.map((b) {
                            final displayId = b['display_id']?.toString() ?? b['id']?.toString() ?? '-';
                            final user = b['users'] as Map<String, dynamic>?;
                            final ground = b['grounds'] as Map<String, dynamic>?;
                            final groundName = ground?['name']?.toString() ?? '-';
                            final status = (b['status']?.toString() ?? '-').toUpperCase();
                            final amount = b['amount']?.toString() ?? '-';
                            final statusColor = _getStatusColor(status);

                            return DataRow(
                              onSelectChanged: (_) => _showBookingDetailDialog(b, cubit),
                              cells: [
                                DataCell(
                                  Text(
                                    '#$displayId',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        () {
                                          final rawUsername = (user?['username'] ?? '').toString().trim();
                                          if (rawUsername.isNotEmpty) return rawUsername;
                                          final rawName = (user?['name'] ?? '').toString().trim();
                                          if (rawName.isNotEmpty) return rawName;
                                          final rawEmail = (user?['email'] ?? '').toString().trim();
                                          if (rawEmail.isNotEmpty) return rawEmail.split('@').first;
                                          return '-';
                                        }(),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      if (user?['name'] != null &&
                                          user!['name'].toString().trim().isNotEmpty &&
                                          (user['username'] != null && user['username'].toString().trim().isNotEmpty))
                                        Text(
                                          user['name'].toString().trim(),
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        )
                                      else if (user?['email'] != null && user!['email'].toString().isNotEmpty)
                                        Text(
                                          user['email'].toString(),
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                    ],
                                  ),
                                ),
                                DataCell(Text(groundName)),
                                DataCell(Text(_formatSlot(b))),
                                DataCell(
                                  Text(
                                    '₹$amount',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(_formatDate(b['created_at']))),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined, size: 20),
                                    tooltip: 'View Booking Details',
                                    onPressed: () => _showBookingDetailDialog(b, cubit),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  // --- Pagination Bar (10 Bookings / page) ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${totalItems == 0 ? 0 : startIndex + 1} - $endIndex of $totalItems bookings',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.first_page_rounded),
                              tooltip: 'First Page',
                              onPressed: currentPage > 1
                                  ? () => setState(() => _currentPage = 1)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded),
                              tooltip: 'Previous Page',
                              onPressed: currentPage > 1
                                  ? () => setState(() => _currentPage = currentPage - 1)
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'Page $currentPage of $totalPages',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded),
                              tooltip: 'Next Page',
                              onPressed: currentPage < totalPages
                                  ? () => setState(() => _currentPage = currentPage + 1)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.last_page_rounded),
                              tooltip: 'Last Page',
                              onPressed: currentPage < totalPages
                                  ? () => setState(() => _currentPage = totalPages)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
