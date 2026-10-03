import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';
import 'package:cricket_admin_panel/common/utils/formatters.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'notification_type_badge.dart';

/// Desktop table of sent notifications.
///
/// The previous version nested a vertical `SingleChildScrollView` directly
/// inside a `Card` and handed the whole result set to a `DataTable`, which
/// builds every cell eagerly. `getAllNotifications` returns up to 500 rows, so
/// that produced a very long, unvirtualised list. This uses a bounded
/// `SingleChildScrollView` inside a `Flexible` with a persistent horizontal
/// scrollbar, and the message column is width-constrained so rows stay
/// readable.
class NotificationHistoryTable extends StatefulWidget {
  const NotificationHistoryTable({
    super.key,
    required this.notifications,
    required this.onOpen,
  });

  final List<Map<String, dynamic>> notifications;
  final ValueChanged<Map<String, dynamic>> onOpen;

  @override
  State<NotificationHistoryTable> createState() => _NotificationHistoryTableState();
}

class _NotificationHistoryTableState extends State<NotificationHistoryTable> {
  final ScrollController _horizontalController = ScrollController();

  /// Placeholder for a null or whitespace-only column value.
  static String _text(Object? value) {
    final trimmed = value?.toString().trim();
    return (trimmed == null || trimmed.isEmpty) ? '—' : trimmed;
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminSurface(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 10,
              radius: const Radius.circular(5),
              interactive: true,
              notificationPredicate: (notification) => notification.depth == 0,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 12),
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(
                    theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.35),
                  ),
                  headingRowHeight: 46,
                  dataRowMinHeight: 54,
                  dataRowMaxHeight: 64,
                  columnSpacing: 28,
                  horizontalMargin: 20,
                  headingTextStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  dividerThickness: 0.5,
                  columns: const [
                    DataColumn(label: Text('SENT')),
                    DataColumn(label: Text('TITLE')),
                    DataColumn(label: Text('TYPE')),
                    DataColumn(label: Text('AUDIENCE')),
                    DataColumn(label: Text('MESSAGE')),
                  ],
                  rows: [
                    for (final notification in widget.notifications)
                      DataRow(
                        onSelectChanged: (_) => widget.onOpen(notification),
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 132,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatDateTime(notification['created_at']),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatRelative(notification['created_at']),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 190,
                              child: Text(
                                _text(notification['title']),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            NotificationTypeBadge(
                              type: notification['type'] as String?,
                            ),
                          ),
                          DataCell(
                            Text(
                              notificationAudience(notification['type'] as String?),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 320,
                              child: Text(
                                _text(notification['message']),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact card used below the table breakpoint.
class NotificationHistoryCard extends StatelessWidget {
  const NotificationHistoryCard({
    super.key,
    required this.notification,
    required this.onOpen,
  });

  final Map<String, dynamic> notification;
  final VoidCallback onOpen;

  static String _text(Object? value) {
    final trimmed = value?.toString().trim();
    return (trimmed == null || trimmed.isEmpty) ? '—' : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = _text(notification['message']);
    final isLong = message.length > 120;

    return AdminSurface(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _text(notification['title']),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                NotificationTypeBadge(
                  type: notification['type'] as String?,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
            ),
            if (isLong) ...[
              const SizedBox(height: 4),
              Text(
                'Tap to read the full message',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Divider(height: 1, color: theme.dividerColor),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    formatDateTime(notification['created_at']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  notificationAudience(notification['type'] as String?),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full detail view for a single notification.
///
/// The list truncates the message for layout reasons, which previously left no
/// way to read a long notification in full.
class NotificationDetailSheet extends StatelessWidget {
  const NotificationDetailSheet({super.key, required this.notification});

  final Map<String, dynamic> notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String text(Object? value) {
      final trimmed = value?.toString().trim();
      return (trimmed == null || trimmed.isEmpty) ? '—' : trimmed;
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              text(notification['title']),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                NotificationTypeBadge(type: notification['type'] as String?),
                Text(
                  'To ${notificationAudience(notification['type'] as String?)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  formatDateTime(notification['created_at']),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'MESSAGE',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              text(notification['message']),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter chips plus a search field.
///
/// The chips use a [Wrap] because four of them overflow at phone widths, and
/// the search exists because the query returns up to 500 rows with no other way
/// to locate one.
class NotificationFiltersBar extends StatefulWidget {
  const NotificationFiltersBar({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.visibleCount,
    required this.totalCount,
  });

  static const List<({String value, String label})> types = [
    (value: 'all', label: 'All'),
    (value: 'promotion', label: 'Promotion'),
    (value: 'announcement', label: 'Announcement'),
    (value: 'reminder', label: 'Reminder'),
    (value: 'general', label: 'General'),
  ];

  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final int visibleCount;
  final int totalCount;

  @override
  State<NotificationFiltersBar> createState() => _NotificationFiltersBarState();
}

class _NotificationFiltersBarState extends State<NotificationFiltersBar> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = AdminBreakpoints.isCompact(context);

    final search = SizedBox(
      height: 42,
      child: TextField(
        controller: _searchController,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          hintText: isCompact ? 'Search' : 'Search title or message',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => setState(() => _query = value),
      ),
    );

    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in NotificationFiltersBar.types)
          _TypeChip(
            label: type.label,
            isSelected: widget.selectedType == type.value,
            onTap: () => widget.onTypeChanged(type.value),
          ),
      ],
    );

    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompact) ...[
            search,
            const SizedBox(height: 10),
            chips,
          ] else
            Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 14),
                Flexible(child: chips),
              ],
            ),
          const SizedBox(height: 12),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 10),
          Text(
            _summaryLine(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _summaryLine() {
    final total = widget.totalCount;
    final visible = widget.visibleCount;

    if (visible == total) {
      return 'Showing all $total notifications';
    }
    if (total > visible) {
      return 'Showing $visible of $total · the list is capped at 500 most recent';
    }
    return 'Showing $visible of $total';
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: isSelected ? primary : primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? primary : primary.withValues(alpha: 0.30),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected ? Colors.white : primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
