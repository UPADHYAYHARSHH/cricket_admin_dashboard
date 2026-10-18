import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';

/// Displays the health and status distribution of bookings (Confirmed, Completed, Pending, Cancelled).
class BookingStatusChartCard extends StatefulWidget {
  final Map<String, int> statusDistribution;
  final String title;

  const BookingStatusChartCard({
    super.key,
    required this.statusDistribution,
    this.title = 'Booking Status Distribution',
  });

  @override
  State<BookingStatusChartCard> createState() => _BookingStatusChartCardState();
}

class _BookingStatusChartCardState extends State<BookingStatusChartCard> {
  int _touchedIndex = -1;

  static const _statusColors = {
    'confirmed': AppColors.primaryLightGreen,
    'completed': Color(0xFF00BFA5),
    'pending': AppColors.accentOrange,
    'cancelled': Color(0xFFEF5350),
    'paid': AppColors.primaryDarkGreen,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.statusDistribution.values.fold<int>(0, (s, c) => s + c);

    final entries = widget.statusDistribution.entries
        .where((e) => e.value > 0)
        .toList();

    return AdminSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  size: 18,
                  color: AppColors.accentOrange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Booking lifecycle and conversion health',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (entries.isEmpty || total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No booking status data available',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                // Donut Chart
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 36,
                          sections: List.generate(entries.length, (i) {
                            final isTouched = i == _touchedIndex;
                            final entry = entries[i];
                            final color = _statusColors[entry.key] ??
                                theme.colorScheme.onSurfaceVariant;

                            return PieChartSectionData(
                              color: color,
                              value: entry.value.toDouble(),
                              showTitle: false,
                              radius: isTouched ? 22.0 : 16.0,
                            );
                          }),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          Text(
                            'Total',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                // Status breakdown pills
                Expanded(
                  child: Column(
                    children: [
                      for (int i = 0; i < entries.length; i++) ...[
                        _StatusRow(
                          status: entries[i].key,
                          count: entries[i].value,
                          total: total,
                          color: _statusColors[entries[i].key] ??
                              theme.colorScheme.onSurfaceVariant,
                          isHovered: i == _touchedIndex,
                        ),
                        if (i != entries.length - 1) const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String status;
  final int count;
  final int total;
  final Color color;
  final bool isHovered;

  const _StatusRow({
    required this.status,
    required this.count,
    required this.total,
    required this.color,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    final label = '${status[0].toUpperCase()}${status.substring(1)}';

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isHovered ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$count',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '($pct%)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
