import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_admin_panel/common/responsive/admin_page_scaffold.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/widgets/shimmer_placeholder.dart';
import '../../blocs/notification/admin_notification_cubit.dart';
import '../../blocs/notification/admin_notification_state.dart';
import 'widgets/notification_history_widgets.dart';

/// Read-only log of notifications that have been sent.
///
/// The cubit call and the type filter values are unchanged. What changed: the
/// `totalCount` the cubit already fetches is now displayed, a search was added
/// because the query returns up to 500 rows, the truncated message can be read
/// in full, and the layout uses the shared responsive scaffold.
class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  String _filterType = 'all';
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<AdminNotificationCubit>().fetchNotifications();
  }

  /// Lower-cased text for searching, with null coerced to an empty string.
  static String _text(Object? value) =>
      value?.toString().trim().toLowerCase() ?? '';

  /// Client-side filter, matching the behaviour that was already there.
  List<Map<String, dynamic>> _applyView(List<Map<String, dynamic>> source) {
    final needle = _query.trim().toLowerCase();

    return source.where((notification) {
      if (_filterType != 'all' && notification['type'] != _filterType) {
        return false;
      }
      if (needle.isEmpty) return true;

      return _text(notification['title']).contains(needle) ||
          _text(notification['message']).contains(needle) ||
          _text(notification['type']).contains(needle);
    }).toList();
  }

  void _openDetail(Map<String, dynamic> notification) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => NotificationDetailSheet(notification: notification),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminNotificationCubit>();

    return BlocBuilder<AdminNotificationCubit, AdminNotificationState>(
      builder: (context, state) {
        final loaded = state is AdminNotificationLoaded ? state : null;
        final totalCount = loaded?.totalCount ?? 0;

        return AdminPageScaffold(
          title: 'Notification History',
          subtitle: switch (state) {
            AdminNotificationLoaded() => '$totalCount sent',
            AdminNotificationLoading() => 'Loading…',
            _ => 'Loading',
          },
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: state is AdminNotificationLoading
                  ? null
                  : () => cubit.fetchNotifications(),
              icon: state is AdminNotificationLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
          child: _buildBody(context, state, loaded, totalCount),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AdminNotificationState state,
    AdminNotificationLoaded? loaded,
    int totalCount,
  ) {
    if (state is AdminNotificationError) {
      return AdminStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load notifications',
        message: state.message,
        actionLabel: 'Retry',
        onAction: () => context.read<AdminNotificationCubit>().fetchNotifications(),
        tone: AdminStateTone.error,
      );
    }

    if (loaded == null) {
      return ShimmerPage(
        children: [
          const ShimmerFilterBar(chips: 3),
          const SizedBox(height: 14),
          if (AdminBreakpoints.hasTableSpace(context))
            const ShimmerSurface(child: ShimmerTable(rows: 6, columns: 4))
          else
            const ShimmerCardList(count: 4, lineCount: 3, avatar: false),
        ],
      );
    }

    final visible = _applyView(loaded.notifications);
    final useTable = AdminBreakpoints.hasTableSpace(context);

    return Column(
      children: [
        if (state is AdminNotificationLoading)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                context.read<AdminNotificationCubit>().fetchNotifications(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                NotificationFiltersBar(
                  selectedType: _filterType,
                  onTypeChanged: (value) => setState(() => _filterType = value),
                  visibleCount: visible.length,
                  totalCount: totalCount,
                ),
                const SizedBox(height: 14),
                if (visible.isEmpty)
                  AdminSurface(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: AdminStateView(
                      icon: loaded.notifications.isEmpty
                          ? Icons.notifications_off_outlined
                          : Icons.search_off_rounded,
                      title: loaded.notifications.isEmpty
                          ? 'No notifications sent yet'
                          : 'Nothing matches these filters',
                      message: loaded.notifications.isEmpty
                          ? 'Broadcasts you send will be listed here.'
                          : 'Try a different type or clear the search.',
                      actionLabel: loaded.notifications.isEmpty ? null : 'Reset',
                      onAction: loaded.notifications.isEmpty
                          ? null
                          : () => setState(() {
                                _filterType = 'all';
                                _query = '';
                              }),
                    ),
                  )
                else if (useTable)
                  NotificationHistoryTable(
                    notifications: visible,
                    onOpen: _openDetail,
                  )
                else
                  Column(
                    children: [
                      for (final notification in visible) ...[
                        NotificationHistoryCard(
                          notification: notification,
                          onOpen: () => _openDetail(notification),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
