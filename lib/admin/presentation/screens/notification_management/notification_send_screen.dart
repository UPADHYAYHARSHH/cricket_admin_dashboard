import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cricket_admin_panel/common/responsive/admin_page_scaffold.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import '../../blocs/notification/admin_notification_cubit.dart';
import '../../blocs/notification/admin_notification_state.dart';
import 'widgets/notification_composer.dart';

/// Compose and broadcast a push notification.
///
/// The cubit call, its arguments, the four notification types, the three
/// audience values and both validators are unchanged. What changed is that the
/// live preview now actually updates as you type, the audience is confirmed
/// before an irreversible broadcast, and the form uses the shared responsive
/// scaffold.
class NotificationSendScreen extends StatefulWidget {
  const NotificationSendScreen({super.key});

  @override
  State<NotificationSendScreen> createState() => _NotificationSendScreenState();
}

class _NotificationSendScreenState extends State<NotificationSendScreen> {
  static const List<({String value, String label})> _audiences = [
    (value: 'all', label: 'All Users'),
    (value: 'owners', label: 'All Owners'),
    (value: 'users', label: 'All Users Only'),
  ];

  static const List<({String value, String label})> _types = [
    (value: 'promotion', label: 'Promotion'),
    (value: 'announcement', label: 'Announcement'),
    (value: 'reminder', label: 'Reminder'),
    (value: 'general', label: 'General'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedTarget = 'all';
  String _selectedType = 'promotion';

  /// Merged listenable so only the preview rebuilds while typing, rather than
  /// the whole form on every keystroke.
  late final Listenable _composerChanges;

  /// Push notifications are truncated by the OS, so the counters are advisory.
  static const int _titleSoftLimit = 40;
  static const int _messageSoftLimit = 120;

  @override
  void initState() {
    super.initState();
    _composerChanges =
        Listenable.merge([_titleController, _messageController]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String get _audienceLabel => _audiences
      .firstWhere((option) => option.value == _selectedTarget)
      .label;

  String get _typeLabel =>
      _types.firstWhere((option) => option.value == _selectedType).label;

  /// A broadcast cannot be recalled, so the audience is confirmed explicitly.
  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send notification'),
        content: Text(
          'Send this $_typeLabel to $_audienceLabel?\n\n'
          '"$title"\n\n'
          'This cannot be recalled once delivered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDarkGreen,
            ),
            child: const Text('Send now'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    context.read<AdminNotificationCubit>().sendNotification(
          title: title,
          message: message,
          type: _selectedType,
          target: _selectedTarget,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminPageScaffold(
      title: 'Send Notification',
      subtitle: '$_audienceLabel · $_typeLabel',
      child: BlocListener<AdminNotificationCubit, AdminNotificationState>(
        listener: (context, state) {
          if (state is AdminNotificationSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.primaryDarkGreen,
              ),
            );
            _titleController.clear();
            _messageController.clear();
          } else if (state is AdminNotificationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdminSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Audience ---------------------------------
                          const _FieldLabel('Send to'),
                          const SizedBox(height: 8),
                          AudienceSelector(
                            options: _audiences,
                            selected: _selectedTarget,
                            onChanged: (value) =>
                                setState(() => _selectedTarget = value),
                          ),
                          const SizedBox(height: 20),

                          // --- Type ------------------------------------
                          const _FieldLabel('Notification type'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedType,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: [
                              for (final type in _types)
                                DropdownMenuItem(
                                  value: type.value,
                                  child: Text(type.label),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedType = value);
                              }
                            },
                          ),
                          const SizedBox(height: 20),

                          // --- Title -----------------------------------
                          const _FieldLabel('Title'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Short headline',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Title is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 6),
                          ListenableBuilder(
                            listenable: _titleController,
                            builder: (context, _) => FieldCounter(
                              text: _titleController.text,
                              suggestedLimit: _titleSoftLimit,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // --- Message --------------------------------
                          const _FieldLabel('Message'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _messageController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText: 'What should everyone know?',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Message is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 6),
                          ListenableBuilder(
                            listenable: _messageController,
                            builder: (context, _) => FieldCounter(
                              text: _messageController.text,
                              suggestedLimit: _messageSoftLimit,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // --- Live preview ---------------------------
                          ListenableBuilder(
                            listenable: _composerChanges,
                            builder: (context, _) => NotificationPreview(
                              changes: _composerChanges,
                              title: _titleController.text,
                              message: _messageController.text,
                              audienceLabel: _audienceLabel,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // --- Send ------------------------------------
                          BlocBuilder<AdminNotificationCubit,
                              AdminNotificationState>(
                            builder: (context, state) {
                              final isSending =
                                  state is AdminNotificationSending;

                              return SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.primaryDarkGreen,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: isSending ? null : _send,
                                  icon: isSending
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const HugeIcon(
                                          icon: HugeIcons
                                              .strokeRoundedNotification03,
                                          color: Colors.white,
                                        ),
                                  label: Text(
                                    isSending
                                        ? 'Sending…'
                                        : 'Send to $_audienceLabel',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        letterSpacing: 0.6,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
