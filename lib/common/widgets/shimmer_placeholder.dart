import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';

/// Skeleton placeholders shown while a module fetches its data.
///
/// Replaces the bare `CircularProgressIndicator` page loaders. A spinner tells
/// the admin something is happening but nothing about what is arriving, so the
/// page visibly reflows when the real layout replaces it. These skeletons
/// reserve the same space the loaded content will occupy, which removes that
/// jump.
///
/// Every builder is brightness-aware and derives its column count from
/// [AdminBreakpoints], so a skeleton reflows exactly like the content it
/// stands in for.
class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? const Color(0xFF2E2E2E)
          : AppColors.lightBorder.withValues(alpha: 0.75),
      highlightColor:
          isDark ? const Color(0xFF424242) : Colors.white.withValues(alpha: 0.95),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

/// A generic shimmering block.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 6,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A text-like line. Give [width] a value for a fixed-length label, or leave it
/// null inside a parent that constrains the width (such as [Expanded]).
class ShimmerLine extends StatelessWidget {
  const ShimmerLine({super.key, this.width, this.height = 12, this.radius = 4});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(width: width, height: height, radius: radius);
  }
}

/// A circular placeholder for avatars and monograms.
class ShimmerCircle extends StatelessWidget {
  const ShimmerCircle({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A row of text-like lines. The first stands in for a title, the rest for
/// secondary metadata.
class ShimmerTextLines extends StatelessWidget {
  const ShimmerTextLines({super.key, this.count = 2, this.firstWidth = 0.7});

  final int count;

  /// Fraction of the available width the first (title) line occupies.
  final double firstWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          FractionallySizedBox(
            widthFactor: i == 0 ? firstWidth : 0.45,
            alignment: Alignment.centerLeft,
            child: ShimmerLine(height: i == 0 ? 13 : 10),
          ),
        ],
      ],
    );
  }
}

/// A KPI tile grid, matching the `Wrap`-of-tiles layout used by the summary
/// strips in the owner, location, sports and dashboard modules.
class ShimmerTileGrid extends StatelessWidget {
  const ShimmerTileGrid({
    super.key,
    this.count = 4,
    this.columnsAtExpanded = 4,
    this.columnsAtMedium = 3,
    this.columnsAtCompact = 2,
    this.tileHeight = 74,
  });

  final int count;
  final int columnsAtExpanded;
  final int columnsAtMedium;
  final int columnsAtCompact;
  final double tileHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (AdminBreakpoints.of(context)) {
          AdminSize.expanded => columnsAtExpanded,
          AdminSize.medium => columnsAtMedium,
          AdminSize.compact => columnsAtCompact,
        }
            .clamp(1, count);

        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < count; i++)
              SizedBox(
                width: width,
                child: AppShimmer(
                  child: Container(
                    height: tileHeight,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const ShimmerBox(width: 34, height: 34, radius: 10),
                        const SizedBox(width: 11),
                        const Expanded(child: ShimmerTextLines()),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A wide banner placeholder, used for the dashboard's review-queue call to
/// action and the location detail visibility banner.
class ShimmerBanner extends StatelessWidget {
  const ShimmerBanner({super.key, this.height = 84});

  final double height;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            ShimmerCircle(size: 44),
            SizedBox(width: 14),
            Expanded(child: ShimmerTextLines(count: 2)),
          ],
        ),
      ),
    );
  }
}

/// A section heading placeholder: a title line and an optional trailing action.
class ShimmerSectionHeader extends StatelessWidget {
  const ShimmerSectionHeader({super.key, this.showAction = true});

  final bool showAction;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Row(
        children: [
          const ShimmerBox(width: 168, height: 14),
          const Spacer(),
          if (showAction) const ShimmerBox(width: 62, height: 12),
        ],
      ),
    );
  }
}

/// A search field plus a row of filter chips, matching the filter bars in the
/// owner, location, sports, payout and notification modules.
class ShimmerFilterBar extends StatelessWidget {
  const ShimmerFilterBar({
    super.key,
    this.chips = 4,
    this.stacked = false,
  });

  final int chips;

  /// True when the real bar stacks the search field above the chips, as it
  /// does on a phone.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stacked) ...[
            const ShimmerBox(height: 42, radius: 10),
            const SizedBox(height: 10),
            const ShimmerBox(width: 132, height: 40, radius: 10),
          ] else
            const Row(
              children: [
                Expanded(child: ShimmerBox(height: 42, radius: 10)),
                SizedBox(width: 12),
                ShimmerBox(width: 132, height: 42, radius: 10),
              ],
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < chips; i++)
                const ShimmerBox(width: 86, height: 32, radius: 999),
            ],
          ),
        ],
      ),
    );
  }
}

/// A stack of card-shaped placeholders, matching the phone-width card lists in
/// the owner, location, notification and payout modules.
class ShimmerCardList extends StatelessWidget {
  const ShimmerCardList({
    super.key,
    this.count = 3,
    this.lineCount = 3,
    this.avatar = true,
    this.footerActions = false,
  });

  final int count;
  final int lineCount;
  final bool avatar;

  /// True when the real card ends with a row of buttons, as owner and location
  /// cards do.
  final bool footerActions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppShimmer(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (avatar) ...[
                          const ShimmerCircle(),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: ShimmerTextLines(
                            count: lineCount,
                            firstWidth: 0.65,
                          ),
                        ),
                        if (lineCount > 0) ...[
                          const SizedBox(width: 10),
                          const ShimmerBox(width: 54, height: 20, radius: 999),
                        ],
                      ],
                    ),
                    if (footerActions) ...[
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          ShimmerBox(width: 92, height: 32, radius: 8),
                          SizedBox(width: 8),
                          ShimmerBox(width: 92, height: 32, radius: 8),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A data-table placeholder with a header row and [rows] body rows.
class ShimmerTable extends StatelessWidget {
  const ShimmerTable({super.key, this.rows = 6, this.columns = 5});

  final int rows;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                for (var c = 0; c < columns; c++)
                  Expanded(
                    flex: c == 0 ? 3 : 2,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 20),
                      child: ShimmerLine(height: 10),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (var r = 0; r < rows; r++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0x0F000000))),
              ),
              child: Row(
                children: [
                  for (var c = 0; c < columns; c++)
                    Expanded(
                      flex: c == 0 ? 3 : 2,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: ShimmerLine(height: 12),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A labelled-field placeholder, matching the app config and notification
/// composer forms.
class ShimmerField extends StatelessWidget {
  const ShimmerField({super.key, this.height = 44, this.labelWidth = 92});

  final double height;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShimmerLine(width: labelWidth, height: 10),
          const SizedBox(height: 6),
          ShimmerBox(height: height, radius: 10),
        ],
      ),
    );
  }
}

/// A card-shaped placeholder with a heading, body text and a field, matching
/// the app config cards.
class ShimmerConfigCard extends StatelessWidget {
  const ShimmerConfigCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBox(width: 34, height: 34, radius: 9),
                SizedBox(width: 11),
                Expanded(child: ShimmerLine(width: 120, height: 13)),
              ],
            ),
            SizedBox(height: 12),
            ShimmerLine(height: 10),
            SizedBox(height: 7),
            ShimmerLine(height: 10),
            SizedBox(height: 18),
            ShimmerBox(height: 40, radius: 10),
            SizedBox(height: 12),
            ShimmerBox(height: 46, radius: 10),
          ],
        ),
      ),
    );
  }
}

/// A grid of config cards, reflowing with the same 1 / 2 / 3 column rules the
/// real app config grid uses.
class ShimmerConfigGrid extends StatelessWidget {
  const ShimmerConfigGrid({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 620
            ? 1
            : constraints.maxWidth < 1000
                ? 2
                : 3;

        const gap = 14.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < count; i++)
              SizedBox(width: width, child: const ShimmerConfigCard()),
          ],
        );
      },
    );
  }
}

/// Page-level skeleton host.
///
/// Fills the space the loaded content will occupy and hosts [children] as the
/// skeleton body. The `SingleChildScrollView` keeps it usable when the
/// skeleton is taller than the viewport.
class ShimmerPage extends StatelessWidget {
  const ShimmerPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Scrollable, because a tall skeleton (app config, for one) otherwise
      // puts content below the fold with no way to reach it.
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Wraps a skeleton in a [AdminSurface] so it picks up the same border and
/// background as the real content it replaces.
class ShimmerSurface extends StatelessWidget {
  const ShimmerSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AdminSurface(child: child);
  }
}
