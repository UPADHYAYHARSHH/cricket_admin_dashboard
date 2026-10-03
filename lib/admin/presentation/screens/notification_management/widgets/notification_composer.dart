import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';

/// Read-only preview of how the notification will appear.
///
/// Rebuilt from the two text controllers via [ListenableBuilder] so it tracks
/// typing. The previous implementation read `_titleController.text` inside
/// `build` without listening to the controllers, so the preview only appeared
/// after an unrelated rebuild and showed whatever was typed at that moment.
class NotificationPreview extends StatelessWidget {
  const NotificationPreview({
    super.key,
    required this.changes,
    required this.title,
    required this.message,
    required this.audienceLabel,
  });

  /// Merged listenable for the title and message controllers.
  final Listenable changes;

  final String title;
  final String message;
  final String audienceLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasContent = title.trim().isNotEmpty || message.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'PREVIEW',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              'as $audienceLabel see it',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AdminSurface(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.trim().isEmpty ? 'Notification title' : title.trim(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: title.trim().isEmpty
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message.trim().isEmpty
                    ? 'The message body will appear here.'
                    : message.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: message.trim().isEmpty
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
              if (hasContent) ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: theme.dividerColor),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Push notification · $audienceLabel',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Character counter shown under a text field.
///
/// Informational only. It does not block sending, because tightening the
/// validators would reject submissions that currently succeed.
class FieldCounter extends StatelessWidget {
  const FieldCounter({
    super.key,
    required this.text,
    required this.suggestedLimit,
  });

  final String text;
  final int suggestedLimit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final length = text.trim().length;
    final isOver = length > suggestedLimit;

    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        isOver
            ? '$length characters — longer than the ~$suggestedLimit usually '
                'shown before truncation'
            : '$length / ~$suggestedLimit',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isOver
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Audience selector.
///
/// The values sent to the `send_notification_to_all` RPC are unchanged, and so
/// are the labels. They are genuinely ambiguous ("All Users" versus
/// "All Users Only") but the RPC body is not in the repository, so the meaning
/// of each value could not be verified and the labels were deliberately left
/// alone rather than guessed.
///
/// The segmented control does not fit three labelled segments on a phone, so a
/// vertical list is used below the compact breakpoint. Both render the same
/// labels and return the same values.
class AudienceSelector extends StatelessWidget {
  const AudienceSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<({String value, String label})> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (AdminBreakpoints.isCompact(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OptionRow(
                label: option.label,
                isSelected: option.value == selected,
                onTap: () => onChanged(option.value),
              ),
            ),
        ],
      );
    }

    return SegmentedButton<String>(
      segments: [
        for (final option in options)
          ButtonSegment(value: option.value, label: Text(option.label)),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (value) => onChanged(value.first),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
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
      color: isSelected
          ? primary.withValues(alpha: 0.10)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? primary
                  : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: isSelected
                    ? primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
