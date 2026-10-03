import 'package:flutter/material.dart';

/// Shared full-height state for loading, empty, error and no-match.
///
/// Every admin module needs the same four states, and duplicating them per
/// screen is how the "bare Text in the middle of the page" pattern spread in
/// the first place. Placeholders are visually distinct from data and
/// actionable, so a failure always has a way out.
class AdminStateView extends StatelessWidget {
  const AdminStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.refresh_rounded,
    this.tone = AdminStateTone.neutral,
    this.isBusy = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final AdminStateTone tone;

  /// Replaces [icon] with a spinner.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final accent = switch (tone) {
      AdminStateTone.neutral => theme.colorScheme.onSurfaceVariant,
      AdminStateTone.error => theme.colorScheme.error,
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBusy)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: theme.colorScheme.primary,
                  ),
                )
              else
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: accent),
                ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
              if (onAction != null && actionLabel != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon, size: 18),
                  label: Text(actionLabel!),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum AdminStateTone { neutral, error }

/// A titled surface used for every card, panel and table container in the app.
///
/// Centralises the radius, border and background so modules look identical
/// without each screen restating the values.
class AdminSurface extends StatelessWidget {
  const AdminSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: child,
    );
  }
}
