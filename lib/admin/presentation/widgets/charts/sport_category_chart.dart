import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cricket_admin_panel/admin/domain/analytics.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/common/utils/formatters.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';

enum SportChartMode { donut, bars }

/// A card that displays which sports category has how many bookings,
/// with interactive Donut chart and ranked progress bars.
class SportCategoryChartCard extends StatefulWidget {
  final List<SportAnalytics> sports;
  final String title;
  final String subtitle;
  final VoidCallback? onManageSports;
  final String? selectedSport;
  final ValueChanged<String>? onSelectSport;

  const SportCategoryChartCard({
    super.key,
    required this.sports,
    this.title = 'Bookings by Sports Category',
    this.subtitle = 'Volume and revenue breakdown by sport',
    this.onManageSports,
    this.selectedSport,
    this.onSelectSport,
  });

  @override
  State<SportCategoryChartCard> createState() => _SportCategoryChartCardState();
}

class _SportCategoryChartCardState extends State<SportCategoryChartCard> {
  String? _hoveredSportName;
  SportChartMode _mode = SportChartMode.donut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isSpecificSportSelected = widget.selectedSport != null &&
        widget.selectedSport!.trim().isNotEmpty &&
        widget.selectedSport!.toLowerCase() != 'all';

    final SportAnalytics? selectedSportModel = isSpecificSportSelected
        ? widget.sports.cast<SportAnalytics?>().firstWhere(
            (s) =>
                s != null &&
                (s.name.toLowerCase() == widget.selectedSport!.toLowerCase() ||
                    s.slug.toLowerCase() == widget.selectedSport!.toLowerCase()),
            orElse: () => null,
          )
        : null;

    // When 'All Sports' is selected, display ALL sports from widget.sports
    // including those with 0 bookings so that each category's percentage is visible.
    // When a specific sport is selected, display that sport specifically.
    final List<SportAnalytics> displayedSports = isSpecificSportSelected
        ? (selectedSportModel != null ? [selectedSportModel] : widget.sports)
        : widget.sports;

    final totalBookings = isSpecificSportSelected && selectedSportModel != null
        ? selectedSportModel.totalBookings
        : widget.sports.fold<int>(0, (sum, s) => sum + s.totalBookings);

    final totalRevenue = isSpecificSportSelected && selectedSportModel != null
        ? selectedSportModel.revenue
        : widget.sports.fold<double>(0.0, (sum, s) => sum + s.revenue);

    final cardTitle = isSpecificSportSelected
        ? 'Bookings for ${selectedSportModel?.name ?? widget.selectedSport}'
        : widget.title;

    final cardSubtitle = isSpecificSportSelected
        ? 'Volume and revenue breakdown for ${selectedSportModel?.name ?? widget.selectedSport}'
        : widget.subtitle;

    return AdminSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title and Mode Switcher
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDarkGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.sports_cricket_rounded,
                            size: 18,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cardTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cardSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Toggle between Donut and Bar view
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ViewToggleButton(
                      icon: Icons.pie_chart_outline_rounded,
                      tooltip: 'Donut chart',
                      isSelected: _mode == SportChartMode.donut,
                      onTap: () => setState(() => _mode = SportChartMode.donut),
                    ),
                    _ViewToggleButton(
                      icon: Icons.bar_chart_rounded,
                      tooltip: 'Ranked bars',
                      isSelected: _mode == SportChartMode.bars,
                      onTap: () => setState(() => _mode = SportChartMode.bars),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Total stats chip banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                _StatBadge(
                  label: isSpecificSportSelected ? 'Sport Bookings' : 'Total Bookings',
                  value: '$totalBookings',
                  color: AppColors.primaryDarkGreen,
                ),
                Container(
                  height: 24,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: theme.dividerColor,
                ),
                _StatBadge(
                  label: isSpecificSportSelected ? 'Sport Revenue' : 'Sports Revenue',
                  value: '₹${formatInr(totalRevenue.round())}',
                  color: AppColors.goldenYellow,
                ),
                if (isSpecificSportSelected) ...[
                  Container(
                    height: 24,
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: theme.dividerColor,
                  ),
                  InkWell(
                    onTap: () => widget.onSelectSport?.call('All'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDarkGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primaryDarkGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.close_rounded, size: 14, color: AppColors.primaryDarkGreen),
                          SizedBox(width: 4),
                          Text(
                            'Show all sports',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDarkGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (widget.onManageSports != null)
                  TextButton.icon(
                    onPressed: widget.onManageSports,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text('Manage sports', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Content body
          if (displayedSports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sports_soccer_outlined,
                      size: 44,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No sports registered yet',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sports you add in the catalogue will show up here.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 640;

                if (_mode == SportChartMode.donut) {
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Donut Chart
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: _buildDonutChart(
                            displayedSports,
                            totalBookings,
                            isSpecificSportSelected: isSpecificSportSelected,
                            selectedSportName: selectedSportModel?.name ?? widget.selectedSport,
                          ),
                        ),
                        const SizedBox(width: 28),
                        // Right: Sport Legend & Breakdown
                        Expanded(
                          child: _buildLegendList(displayedSports, totalBookings),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: _buildDonutChart(
                            displayedSports,
                            totalBookings,
                            isSpecificSportSelected: isSpecificSportSelected,
                            selectedSportName: selectedSportModel?.name ?? widget.selectedSport,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLegendList(displayedSports, totalBookings),
                      ],
                    );
                  }
                } else {
                  // Bar breakdown mode
                  return _buildBarBreakdown(displayedSports, totalBookings);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(
    List<SportAnalytics> sports,
    int totalBookings, {
    bool isSpecificSportSelected = false,
    String? selectedSportName,
  }) {
    final theme = Theme.of(context);
    final sportsWithBookings = sports.where((s) => s.totalBookings > 0).toList();

    SportAnalytics? hoveredSport;
    if (_hoveredSportName != null) {
      for (final s in sports) {
        if (s.name.toLowerCase() == _hoveredSportName!.toLowerCase() ||
            s.slug.toLowerCase() == _hoveredSportName!.toLowerCase()) {
          hoveredSport = s;
          break;
        }
      }
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        if (sportsWithBookings.isEmpty)
          PieChart(
            PieChartData(
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              centerSpaceRadius: 48,
              sections: [
                PieChartSectionData(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  value: 1,
                  showTitle: false,
                  radius: 28.0,
                ),
              ],
            ),
          )
        else
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _hoveredSportName = null;
                      return;
                    }
                    final index =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                    if (index >= 0 && index < sportsWithBookings.length) {
                      _hoveredSportName = sportsWithBookings[index].name;
                    } else {
                      _hoveredSportName = null;
                    }
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: sportsWithBookings.length > 1 ? 3 : 0,
              centerSpaceRadius: 48,
              sections: List.generate(sportsWithBookings.length, (i) {
                final sport = sportsWithBookings[i];
                final isTouched = _hoveredSportName != null &&
                    (_hoveredSportName!.toLowerCase() == sport.name.toLowerCase() ||
                        _hoveredSportName!.toLowerCase() == sport.slug.toLowerCase());
                final color = parseHexColor(sport.colorHex) ??
                    AppColors.primaryDarkGreen;

                final pctLabel = sport.percentage.round() == sport.percentage
                    ? '${sport.percentage.toInt()}%'
                    : '${sport.percentage.toStringAsFixed(1)}%';

                return PieChartSectionData(
                  color: color,
                  value: sport.totalBookings.toDouble(),
                  title: pctLabel,
                  radius: isTouched ? 36.0 : 30.0,
                  titleStyle: TextStyle(
                    fontSize: isTouched ? 12.0 : 11.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black45, blurRadius: 2),
                    ],
                  ),
                  showTitle: sport.percentage >= 6.0,
                );
              }),
            ),
          ),
        // Center text display
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hoveredSport != null) ...[
              Text(
                '${hoveredSport.totalBookings}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: parseHexColor(hoveredSport.colorHex) ??
                      AppColors.primaryDarkGreen,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hoveredSport.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: (parseHexColor(hoveredSport.colorHex) ??
                          AppColors.primaryDarkGreen)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${hoveredSport.percentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    color: parseHexColor(hoveredSport.colorHex) ??
                        AppColors.primaryDarkGreen,
                  ),
                ),
              ),
            ] else ...[
              Text(
                '$totalBookings',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isSpecificSportSelected
                    ? (selectedSportName ?? 'Bookings')
                    : 'Bookings',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isSpecificSportSelected) ...[
                const SizedBox(height: 2),
                Text(
                  'All Sports',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryDarkGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildLegendList(List<SportAnalytics> sports, int totalBookings) {
    return Column(
      children: [
        for (final sport in sports)
          _SportLegendRow(
            sport: sport,
            isHovered: _hoveredSportName != null &&
                (_hoveredSportName!.toLowerCase() == sport.name.toLowerCase() ||
                    _hoveredSportName!.toLowerCase() == sport.slug.toLowerCase()),
            isSelected: widget.selectedSport != null &&
                (widget.selectedSport!.toLowerCase() == sport.name.toLowerCase() ||
                    widget.selectedSport!.toLowerCase() == sport.slug.toLowerCase()),
            onHover: (hovered) {
              setState(() => _hoveredSportName = hovered ? sport.name : null);
            },
            onTap: widget.onSelectSport != null
                ? () => widget.onSelectSport!(sport.name)
                : null,
          ),
      ],
    );
  }

  Widget _buildBarBreakdown(List<SportAnalytics> sports, int totalBookings) {
    return Column(
      children: [
        for (final sport in sports)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SportBarRow(
              sport: sport,
              totalBookings: totalBookings,
              isHovered: _hoveredSportName != null &&
                  (_hoveredSportName!.toLowerCase() == sport.name.toLowerCase() ||
                      _hoveredSportName!.toLowerCase() == sport.slug.toLowerCase()),
              onHover: (hovered) {
                setState(() => _hoveredSportName = hovered ? sport.name : null);
              },
              isSelected: widget.selectedSport != null &&
                  (widget.selectedSport!.toLowerCase() == sport.name.toLowerCase() ||
                      widget.selectedSport!.toLowerCase() == sport.slug.toLowerCase()),
              onTap: widget.onSelectSport != null
                  ? () => widget.onSelectSport!(sport.name)
                  : null,
            ),
          ),
      ],
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.1,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _SportLegendRow extends StatelessWidget {
  final SportAnalytics sport;
  final bool isHovered;
  final bool isSelected;
  final ValueChanged<bool> onHover;
  final VoidCallback? onTap;

  const _SportLegendRow({
    required this.sport,
    required this.isHovered,
    this.isSelected = false,
    required this.onHover,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = parseHexColor(sport.colorHex) ?? AppColors.primaryDarkGreen;

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.16)
                : (isHovered ? color.withValues(alpha: 0.08) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: color, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sport.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: (isHovered || isSelected) ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              // Bookings count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${sport.totalBookings} booking${sport.totalBookings == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Percentage share
              SizedBox(
                width: 44,
                child: Text(
                  '${sport.percentage.toStringAsFixed(1)}%',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Revenue
              SizedBox(
                width: 72,
                child: Text(
                  '₹${formatInr(sport.revenue.round())}',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldenYellow,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SportBarRow extends StatelessWidget {
  final SportAnalytics sport;
  final int totalBookings;
  final bool isSelected;
  final bool isHovered;
  final ValueChanged<bool>? onHover;
  final VoidCallback? onTap;

  const _SportBarRow({
    required this.sport,
    required this.totalBookings,
    this.isSelected = false,
    this.isHovered = false,
    this.onHover,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = parseHexColor(sport.colorHex) ?? AppColors.primaryDarkGreen;
    final ratio = totalBookings > 0 ? sport.totalBookings / totalBookings : 0.0;

    return MouseRegion(
      onEnter: (_) => onHover?.call(true),
      onExit: (_) => onHover?.call(false),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.16)
                : (isHovered ? color.withValues(alpha: 0.08) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: color, width: 1.5)
                : (isHovered ? Border.all(color: color.withValues(alpha: 0.3)) : null),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sport.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: (isSelected || isHovered) ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${sport.totalBookings} bookings',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '(${sport.percentage.toStringAsFixed(1)}%)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '₹${formatInr(sport.revenue.round())}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldenYellow,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
