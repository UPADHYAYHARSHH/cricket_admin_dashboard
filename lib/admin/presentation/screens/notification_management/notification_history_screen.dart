import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../../../../common/constants/app_colors.dart';
import '../../blocs/notification/admin_notification_cubit.dart';
import '../../blocs/notification/admin_notification_state.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    context.read<AdminNotificationCubit>().fetchNotifications();
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
          'Notification History',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminNotificationCubit>().fetchNotifications(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            child: Row(
              children: [
                _filterChip('All', 'all'),
                const SizedBox(width: 8),
                _filterChip('Promotion', 'promotion'),
                const SizedBox(width: 8),
                _filterChip('Announcement', 'announcement'),
                const SizedBox(width: 8),
                _filterChip('General', 'general'),
              ],
            ),
          ),

          // Notifications list
          Expanded(
            child: BlocBuilder<AdminNotificationCubit, AdminNotificationState>(
              builder: (context, state) {
                if (state is AdminNotificationLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AdminNotificationError) {
                  return Center(child: Text(state.message));
                }
                if (state is AdminNotificationLoaded) {
                  var notifications = state.notifications;

                  if (_filterType != 'all') {
                    notifications = notifications
                        .where((n) => n['type'] == _filterType)
                        .toList();
                  }

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedNotification03,
                            size: 64,
                            color: AppColors.primaryDarkGreen.withValues(alpha:0.4),
                          ),
                          const SizedBox(height: 16),
                          const Text('No notifications sent yet.'),
                        ],
                      ),
                    );
                  }

                  return isDesktop
                      ? _buildDataTable(notifications)
                      : _buildCardList(notifications);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _filterType = value);
      },
      selectedColor: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> notifications) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Card(
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Title')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Target')),
              DataColumn(label: Text('Message')),
            ],
            rows: notifications.map((n) {
              final createdAt = DateTime.tryParse(n['created_at'] ?? '');
              return DataRow(cells: [
                DataCell(Text(
                  createdAt != null ? DateFormat('MMM d, yyyy HH:mm').format(createdAt) : '-',
                )),
                DataCell(Text(n['title'] ?? '-')),
                DataCell(_typeBadge(n['type'])),
                DataCell(Text(_targetFromType(n['type']))),
                DataCell(
                  SizedBox(
                    width: 300,
                    child: Text(
                      n['message'] ?? '-',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCardList(List<Map<String, dynamic>> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final n = notifications[index];
        final createdAt = DateTime.tryParse(n['created_at'] ?? '');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryDarkGreen.withValues(alpha:0.1),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedNotification03,
                color: AppColors.primaryDarkGreen,
                size: 20,
              ),
            ),
            title: Text(n['title'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  n['message'] ?? '-',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _typeBadge(n['type']),
                    const SizedBox(width: 8),
                    Text(
                      createdAt != null ? DateFormat('MMM d, yyyy HH:mm').format(createdAt) : '-',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _typeBadge(String? type) {
    Color color;
    switch (type) {
      case 'promotion':
        color = Colors.blue;
        break;
      case 'announcement':
        color = Colors.orange;
        break;
      case 'reminder':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type ?? 'general',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _targetFromType(String? type) {
    switch (type) {
      case 'location_approved':
      case 'location_rejected':
      case 'new_booking':
      case 'booking_cancelled_by_user':
      case 'payment_received':
        return 'Owner';
      default:
        return 'All';
    }
  }
}
