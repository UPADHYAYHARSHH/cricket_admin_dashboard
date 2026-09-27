import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/common/widgets/admin_status_pill.dart';

/// Verification state of a location.
///
/// The mapping is unchanged from the previous inline `_statusOf`: verified
/// wins, then a recorded rejection reason, otherwise pending.
enum LocationVerificationStatus {
  pending,
  approved,
  rejected;

  static LocationVerificationStatus of(Map<String, dynamic> location) {
    if (location['documents_verified'] == true) {
      return LocationVerificationStatus.approved;
    }
    if (location['rejection_reason'] != null) {
      return LocationVerificationStatus.rejected;
    }
    return LocationVerificationStatus.pending;
  }

  String get label => switch (this) {
        LocationVerificationStatus.pending => 'Pending',
        LocationVerificationStatus.approved => 'Approved',
        LocationVerificationStatus.rejected => 'Rejected',
      };

  Color get color => switch (this) {
        LocationVerificationStatus.pending => AppColors.accentOrange,
        LocationVerificationStatus.approved => AppColors.primaryDarkGreen,
        LocationVerificationStatus.rejected => const Color(0xFFD32F2F),
      };

  IconData get icon => switch (this) {
        LocationVerificationStatus.pending => Icons.schedule_rounded,
        LocationVerificationStatus.approved => Icons.check_circle_rounded,
        LocationVerificationStatus.rejected => Icons.cancel_rounded,
      };
}

class LocationStatusPill extends StatelessWidget {
  const LocationStatusPill({super.key, required this.status, this.compact = false});

  final LocationVerificationStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AdminStatusPill(
      label: status.label,
      color: status.color,
      icon: status.icon,
      compact: compact,
    );
  }
}

/// Location type filter.
enum LocationFilter {
  all('All'),
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected'),
  inactive('Inactive');

  const LocationFilter(this.label);
  final String label;
}

/// A location paired with its resolved owner name and derived flags.
class LocationRow {
  const LocationRow({
    required this.location,
    required this.ownerName,
    required this.status,
  });

  final Map<String, dynamic> location;
  final String ownerName;
  final LocationVerificationStatus status;

  String get id => location['id']?.toString() ?? '';

  /// The cubit treats anything other than an explicit `false` as active.
  bool get isActive => location['is_active'] != false;

  String get address {
    final value = (location['address'] as String?)?.trim();
    return (value == null || value.isEmpty) ? 'Unnamed location' : value;
  }

  String? get city {
    final value = (location['city'] as String?)?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  String? get state {
    final value = (location['state'] as String?)?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  String get locality => [city, state].whereType<String>().join(', ');

  /// The cubit writes this placeholder when an admin rejects without typing.
  String? get rejectionReason {
    final value = (location['rejection_reason'] as String?)?.trim();
    if (value == null || value.isEmpty) return null;
    if (value == 'Rejected by admin') return null;
    return value;
  }
}
