import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';

/// A navigation destination.
///
/// [index] is the position in the shell's `IndexedStack` and must not change;
/// the visual order is defined by [AdminNavGroup] and is independent of it.
class AdminNavItem {
  const AdminNavItem({
    required this.index,
    required this.label,
    required this.icon,
  });

  final int index;
  final String label;
  final IconData icon;
}

/// Visual grouping for the navigation list.
///
/// The sidebar previously ran top to bottom with a single divider, so
/// "App Config" sat directly under "Notification History" with no indication
/// that they belong to different concerns.
class AdminNavGroup {
  const AdminNavGroup(this.label, this.items);

  /// `null` renders the group without a heading.
  final String? label;
  final List<AdminNavItem> items;
}

/// The navigation catalogue.
///
/// Index values are bound to `MainLayoutScreen`'s `IndexedStack` order and are
/// deliberately out of visual order here: Payouts (index 9) is grouped with the
/// other marketplace entries rather than trailing the system section.
const List<AdminNavGroup> adminNavGroups = [
  AdminNavGroup(null, [
    AdminNavItem(index: 0, label: 'Dashboard', icon: Icons.dashboard_rounded),
  ]),
  AdminNavGroup('Review queue', [
    AdminNavItem(index: 1, label: 'Approvals', icon: Icons.pending_actions_rounded),
  ]),
  AdminNavGroup('Marketplace', [
    AdminNavItem(
        index: 2, label: 'Owner verification', icon: Icons.storefront_rounded),
    AdminNavItem(
        index: 3, label: 'Location verification', icon: Icons.location_on_rounded),
    AdminNavItem(index: 4, label: 'Sports', icon: Icons.sports_cricket_rounded),
    AdminNavItem(index: 5, label: 'Users', icon: Icons.people_alt_rounded),
    AdminNavItem(
        index: 9, label: 'Payouts', icon: Icons.payments_rounded),
  ]),
  AdminNavGroup('Communications', [
    AdminNavItem(
        index: 6,
        label: 'Send notification',
        icon: Icons.campaign_rounded),
    AdminNavItem(
        index: 7,
        label: 'Notification history',
        icon: Icons.history_rounded),
  ]),
  AdminNavGroup('System', [
    AdminNavItem(
        index: 8, label: 'App config', icon: Icons.settings_rounded),
  ]),
];

/// Primary navigation panel.
///
/// Used as a permanent sidebar from the `expanded` breakpoint and as a drawer
/// below it.
///
/// The pending-approval badge is passed in as [pendingApprovals] rather than
/// read from a cubit here. The shell already owns `AdminDashboardCubit`, so
/// making this widget depend on an ancestor provider meant it could not be
/// rendered, or tested, without standing up the whole dashboard's dependencies.
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    this.pendingApprovals = 0,
    this.isDrawer = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  /// Badge count for the Approvals entry. Zero or less hides the badge.
  final int pendingApprovals;

  /// Drawer presentation gets a slightly narrower horizontal inset.
  final bool isDrawer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = isDrawer
        ? (MediaQuery.sizeOf(context).width * 0.86)
            .clamp(240.0, AdminBreakpoints.sidebarWidth)
        : AdminBreakpoints.sidebarWidth;

    return Container(
      width: width,
      color: theme.colorScheme.surface,
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const _SidebarHeader(),
            Divider(height: 1, color: theme.dividerColor),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final group in adminNavGroups) ...[
                    if (group.label != null) _GroupLabel(group.label!),
                    for (final item in group.items)
                      _NavTile(
                        item: item,
                        isSelected: selectedIndex == item.index,
                        // The badge belongs to Approvals only.
                        badgeCount: item.index == 1 ? pendingApprovals : 0,
                        onTap: () => onSelect(item.index),
                      ),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            _LogoutTile(onTap: onLogout),
          ],
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryDarkGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.sports_cricket_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TurfPro',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Admin console',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
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

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.7,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.badgeCount,
    required this.onTap,
  });

  final AdminNavItem item;
  final bool isSelected;

  /// Zero hides the badge.
  final int badgeCount;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final foreground = isSelected ? primary : theme.colorScheme.onSurface;

    return Material(
      color: isSelected
          ? primary.withValues(alpha: 0.10)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // A left rule makes the active row unambiguous, rather than relying
            // on a background tint alone.
            if (isSelected)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 3, color: primary),
              ),
            Padding(
              // Leaves room for the active rule.
              padding: const EdgeInsets.fromLTRB(17, 0, 14, 0),
              child: SizedBox(
                height: 46,
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 19,
                      color: isSelected
                          ? primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: foreground,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (badgeCount > 0) _Badge(count: badgeCount),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentOrange,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger = theme.colorScheme.error;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 19, color: danger),
              const SizedBox(width: 13),
              Text(
                'Log out',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
