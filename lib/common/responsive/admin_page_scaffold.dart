import 'package:flutter/material.dart';
import '../responsive/admin_breakpoints.dart';

/// Responsive page wrapper for admin module screens.
///
/// Provides the three things every module was repeating by hand:
///
///  * a title AppBar with an optional subtitle line,
///  * a hamburger button on phone widths so the drawer can be opened,
///  * consistent, breakpoint-aware page padding with the bottom safe-area inset
///    respected, which matters on phones with a gesture bar or home button.
///
/// It deliberately does **not** own the [Scaffold] body decisions, so a module
/// can still use a [RefreshIndicator] or a custom scroll view if it needs to.
class AdminPageScaffold extends StatelessWidget {
  const AdminPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.floatingActionButton,
    this.showHamburger = true,
    this.padding,
  });

  final String title;

  /// Secondary line under the title, e.g. a live record count.
  final String? subtitle;

  final Widget child;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  /// Set false when the module is not hosted inside [AdminShell]'s drawer.
  final bool showHamburger;

  /// Overrides the default breakpoint-aware padding.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = AdminBreakpoints.of(context);

    // Phones need a tighter title so the actions are not pushed off-screen.
    final titleStyle = size.isCompact
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700);

    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showHamburger && size.isCompact
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Open navigation',
                onPressed: () => Scaffold.of(context).openDrawer(),
              )
            : null,
        titleSpacing: showHamburger && size.isCompact ? 0 : 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: titleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle!,
                  style: subtitleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        actions: [...actions, const SizedBox(width: 8)],
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: padding ??
              EdgeInsets.fromLTRB(
                AdminBreakpoints.pagePadding(context),
                AdminBreakpoints.pagePaddingVertical(context),
                AdminBreakpoints.pagePadding(context),
                // Leave room for the home indicator / gesture bar.
                AdminBreakpoints.pagePaddingVertical(context) +
                    MediaQuery.paddingOf(context).bottom,
              ),
          child: child,
        ),
      ),
    );
  }
}
