import 'package:flutter/material.dart';

/// Layout size class for admin screens.
///
/// Replaces the ad-hoc `MediaQuery.of(context).size.width >= 800` checks that
/// were duplicated across every screen, each with a different threshold.
enum AdminSize {
  /// Phone portrait, and narrow windows on a tablet. Single column, cards
  /// instead of tables, drawer navigation.
  compact,

  /// Tablet portrait, small laptop, or a split-screen window. Single column
  /// with wider content, table or cards depending on the module.
  medium,

  /// Desktop. Room for a permanent sidebar and full data tables.
  expanded;

  bool get isCompact => this == AdminSize.compact;
  bool get isMedium => this == AdminSize.medium;
  bool get isExpanded => this == AdminSize.expanded;

  /// True for anything that is not a phone-width layout.
  bool get isAtLeastMedium => this != AdminSize.compact;
}

/// Single source of truth for admin layout breakpoints.
///
/// The values are chosen against the widest thing the app has to fit:
/// the owner table needs about 1230px, and the navigation sidebar takes 260px,
/// so a table only has room to breathe at roughly 1500px of window width.
/// Below that it becomes a horizontally scrollable table, and on a phone it
/// becomes cards.
abstract final class AdminBreakpoints {
  /// Below this width the layout is phone-first.
  static const double medium = 700;

  /// At or above this width a permanent navigation rail is shown.
  static const double expanded = 1000;

  /// At or above this width data tables are used instead of cards.
  static const double table = 1180;

  /// Width of the permanent sidebar on expanded layouts.
  static const double sidebarWidth = 260;

  static AdminSize of(BuildContext context) =>
      sizeFor(MediaQuery.sizeOf(context).width);

  /// Pure function version, so the rules can be unit tested without a widget.
  static AdminSize sizeFor(double width) {
    if (width < medium) return AdminSize.compact;
    if (width < expanded) return AdminSize.medium;
    return AdminSize.expanded;
  }

  static bool isCompact(BuildContext context) => of(context).isCompact;

  static bool isAtLeastMedium(BuildContext context) =>
      of(context).isAtLeastMedium;

  /// True when a data table has room to show without horizontal scrolling.
  static bool hasTableSpace(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= table;

  /// Horizontal page padding, tightened on phones so content is not squeezed.
  static double pagePadding(BuildContext context) => switch (of(context)) {
        AdminSize.compact => 16,
        AdminSize.medium => 20,
        AdminSize.expanded => 24,
      };

  /// Vertical page padding.
  static double pagePaddingVertical(BuildContext context) =>
      switch (of(context)) {
        AdminSize.compact => 14,
        AdminSize.medium => 18,
        AdminSize.expanded => 20,
      };

  /// Stacking direction for a list of stat tiles: vertical on a phone so each
  /// tile gets full width, horizontal from tablet upwards.
  static Axis axisForTiles(BuildContext context) =>
      of(context).isCompact ? Axis.vertical : Axis.horizontal;

  /// Below this width a two-up segmented control drops its icons, because the
  /// icon plus label no longer fits and the label truncates to nonsense.
  ///
  /// Narrower than [medium] on purpose: a small phone and a narrow split-screen
  /// window both need the label-only treatment, and that range is not the same
  /// as the phone layout breakpoint.
  static const double segmentedControlIconFloor = 380;

  /// True when a segmented control should show text labels only.
  static bool segmentedControlIsIconless(BuildContext context) =>
      MediaQuery.sizeOf(context).width < segmentedControlIconFloor;
}
