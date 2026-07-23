import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../common/constants/app_colors.dart';
import '../../blocs/notification/admin_notification_cubit.dart';
import '../../blocs/notification/admin_notification_state.dart';

class NotificationSendScreen extends StatefulWidget {
  const NotificationSendScreen({super.key});

  @override
  State<NotificationSendScreen> createState() => _NotificationSendScreenState();
}

class _NotificationSendScreenState extends State<NotificationSendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedTarget = 'all';
  String _selectedType = 'promotion';

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _send() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AdminNotificationCubit>().sendNotification(
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      type: _selectedType,
      target: _selectedTarget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => context.findRootAncestorStateOfType<ScaffoldState>()?.openDrawer(),
              ),
        title: Text(
          'Send Notification',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocListener<AdminNotificationCubit, AdminNotificationState>(
        listener: (context, state) {
          if (state is AdminNotificationSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            _titleController.clear();
            _messageController.clear();
          } else if (state is AdminNotificationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 32 : 16),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notification Details',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 24),

                            // Target selection
                            Text('Send To', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'all', label: Text('All Users')),
                                ButtonSegment(value: 'owners', label: Text('All Owners')),
                                ButtonSegment(value: 'users', label: Text('All Users Only')),
                              ],
                              selected: {_selectedTarget},
                              onSelectionChanged: (value) {
                                setState(() => _selectedTarget = value.first);
                              },
                            ),
                            const SizedBox(height: 20),

                            // Type selection
                            Text('Notification Type', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'promotion', child: Text('Promotion')),
                                DropdownMenuItem(value: 'announcement', child: Text('Announcement')),
                                DropdownMenuItem(value: 'reminder', child: Text('Reminder')),
                                DropdownMenuItem(value: 'general', child: Text('General')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedType = value);
                                }
                              },
                            ),
                            const SizedBox(height: 20),

                            // Title
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Title is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Message
                            TextFormField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                labelText: 'Message',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 4,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Message is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Preview
                            if (_titleController.text.isNotEmpty || _messageController.text.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha:0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Preview', style: Theme.of(context).textTheme.titleSmall),
                                    const SizedBox(height: 8),
                                    Text(
                                      _titleController.text.isNotEmpty ? _titleController.text : 'Title',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _messageController.text.isNotEmpty ? _messageController.text : 'Message',
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 24),

                            // Send button
                            BlocBuilder<AdminNotificationCubit, AdminNotificationState>(
                              builder: (context, state) {
                                return SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryDarkGreen,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    onPressed: state is AdminNotificationSending ? null : _send,
                                    icon: state is AdminNotificationSending
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const HugeIcon(
                                            icon: HugeIcons.strokeRoundedNotification03,
                                            color: Colors.white,
                                          ),
                                    label: Text(
                                      state is AdminNotificationSending ? 'Sending...' : 'Send Notification',
                                      style: const TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
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
