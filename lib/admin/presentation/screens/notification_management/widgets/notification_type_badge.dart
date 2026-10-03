import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/common/widgets/admin_status_pill.dart';

/// Visual identity for a notification type.
({String label, Color color, IconData icon}) notificationTypeStyle(String? type) {
  return switch (type) {
    'promotion' => (
        label: 'Promotion',
        color: Colors.blue.shade700,
        icon: Icons.local_offer_outlined
      ),
    'announcement' => (
        label: 'Announcement',
        color: AppColors.accentOrange,
        icon: Icons.campaign_outlined
      ),
    'reminder' => (
        label: 'Reminder',
        color: Colors.purple.shade700,
        icon: Icons.alarm_outlined
      ),
    _ => (
        label: 'General',
        color: const Color(0xFF5B6472),
        icon: Icons.notifications_none_rounded
      ),
  };
}

/// Types that are delivered to a single ground owner rather than broadcast.
const Set<String> _ownerFacingTypes = {
  'location_approved',
  'location_rejected',
  'new_booking',
  'booking_cancelled_by_user',
  'payment_received',
};

/// Infers the audience from the notification type.
///
/// This is an inference, not stored data. `send_notification_to_all` writes one
/// row per recipient with only `user_id` populated, so the group a broadcast
/// went to is not recorded anywhere. The previous implementation presented this
/// guess in a column headed "Target", which read as authoritative; it is
/// labelled "Audience" here and the inference is documented at the call site.
String notificationAudience(String? type) =>
    _ownerFacingTypes.contains(type) ? 'Owner' : 'Broadcast';

/// Coloured type badge.
class NotificationTypeBadge extends StatelessWidget {
  const NotificationTypeBadge({super.key, required this.type, this.compact = false});

  final String? type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = notificationTypeStyle(type);

    return AdminStatusPill(
      label: style.label,
      color: style.color,
      icon: style.icon,
      compact: compact,
    );
  }
}
