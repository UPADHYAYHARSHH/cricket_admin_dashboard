import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cricket_admin_panel/admin/domain/analytics.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/common/utils/formatters.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';

/// A card with an interactive bar chart displaying booking trends over recent days.
class BookingTrendChartCard extends StatelessWidget {
  final List<DailyTrendPoint> trend;
  final String title;
  final String subtitle;
  final String? pillLabel;

  const BookingTrendChartCard({
    super.key,
    required this.trend,
    this.title = 'Booking Activity Trends',
    this.subtitle = 'Daily booking volume',
    this.pillLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalRecent = trend.fold<int>(0, (s, p) => s + p.bookingsCount);
    final maxBookings = trend.fold<int>(0, (max, p) => p.bookingsCount > max ? p.bookingsCount : max);
    final maxY = (maxBookings <= 4 ? 5.0 : (maxBookings * 1.25).ceilToDouble());

    // Dynamically calculate bar width and corner radius based on point count
    final double barWidth;
    final double barRadius;
    if (trend.length <= 7) {
      barWidth = 22.0;
      barRadius = 6.0;
    } else if (trend.length <= 14) {
      barWidth = 14.0;
      barRadius = 5.0;
    } else if (trend.length <= 22) {
      barWidth = 10.0;
      barRadius = 4.0;
    } else if (trend.length <= 32) {
      barWidth = 7.0;
      barRadius = 3.0;
    } else {
      barWidth = 4.5;
      barRadius = 2.0;
    }

    // Determine how frequently to show bottom X-axis labels to prevent collisions
    final int labelStep;
    if (trend.length > 40) {
      labelStep = (trend.length / 6).ceil();
    } else if (trend.length > 20) {
      labelStep = 5; // e.g. day 1, 6, 11, 16, 21, 26, 31 for month views
    } else if (trend.length > 12) {
      labelStep = 3;
    } else if (trend.length > 7) {
      labelStep = 2;
    } else {
      labelStep = 1;
    }

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
                  color: Colors.blue.shade700.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  size: 18,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Mini pill showing period total
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLightGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pillLabel ?? '$totalRecent in ${trend.length} days',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLightGreen,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => theme.colorScheme.surfaceContainerHighest,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final point = trend[group.x.toInt()];
                      final d = point.date;
                      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      const monthNames = [
                        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                      ];
                      final dateTitle =
                          '${dayNames[d.weekday - 1]}, ${d.day} ${monthNames[d.month - 1]} ${d.year}';

                      return BarTooltipItem(
                        '$dateTitle\n',
                        TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '${point.bookingsCount} booking${point.bookingsCount == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: AppColors.primaryLightGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          if (point.revenue > 0)
                            TextSpan(
                              text: '\n₹${formatInr(point.revenue.round())}',
                              style: const TextStyle(
                                color: AppColors.goldenYellow,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= trend.length) return const SizedBox.shrink();

                        final isFirst = index == 0;
                        final isLast = index == trend.length - 1;
                        final isStep = index % labelStep == 0;

                        // Avoid crowded labels if the last item is immediately adjacent to a step
                        final remainder = index % labelStep;
                        final tooCloseToLast = isLast && remainder > 0 && remainder <= 2 && index > 3;

                        if (!isFirst && !isStep && (!isLast || tooCloseToLast)) {
                          return const SizedBox.shrink();
                        }

                        final point = trend[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            point.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: maxY > 5 ? (maxY / 4).roundToDouble().clamp(1.0, 50.0) : 1,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 5 ? (maxY / 4).roundToDouble().clamp(1.0, 50.0) : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.dividerColor.withValues(alpha: 0.4),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(trend.length, (i) {
                  final p = trend[i];
                  final isZero = p.bookingsCount == 0;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: isZero ? 0.08 : p.bookingsCount.toDouble(),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: isZero
                              ? [
                                  theme.dividerColor.withValues(alpha: 0.25),
                                  theme.dividerColor.withValues(alpha: 0.25),
                                ]
                              : [
                                  AppColors.primaryDarkGreen,
                                  AppColors.primaryLightGreen,
                                ],
                        ),
                        width: barWidth,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(barRadius)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
