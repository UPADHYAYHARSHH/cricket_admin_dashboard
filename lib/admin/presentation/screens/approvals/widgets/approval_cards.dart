import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'approval_widgets.dart';

/// Card for a single owner awaiting verification.
///
/// Shows the same fields as the previous implementation (identity, KYC
/// documents, bank details, linked locations) but tightens the spacing, uses
/// theme colours instead of hardcoded grey, and raises a warning when a
/// required document is missing so an approval is never a blind click.
class OwnerApprovalCard extends StatelessWidget {
  const OwnerApprovalCard({
    super.key,
    required this.owner,
    required this.locations,
    required this.onApprove,
    required this.onReject,
    required this.onDocumentTap,
  });

  final Map<String, dynamic> owner;
  final List<Map<String, dynamic>> locations;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final void Function(String url, String title) onDocumentTap;

  static bool _hasValue(Object? value) {
    if (value == null) return false;
    final text = value.toString().trim();
    return text.isNotEmpty;
  }

  /// Masks all but the last four digits.
  static String _maskAccount(String account) {
    final trimmed = account.trim();
    if (trimmed.length <= 4) return '****';
    return '${trimmed.substring(0, trimmed.length - 4)}****';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final panUrl = owner['pan_url'] as String?;
    final aadharUrl = owner['aadhar_url'] as String?;
    final kycConfig = owner['kyc_config'] as Map<String, dynamic>?;

    final accountName = (kycConfig?['account_name'] as String?)?.trim() ?? '';
    final accountNumber = (kycConfig?['account_number'] as String?)?.trim() ?? '';
    final ifscCode = (kycConfig?['ifsc_code'] as String?)?.trim() ?? '';

    final hasPan = _hasValue(panUrl);
    final hasAadhar = _hasValue(aadharUrl);
    final missingDocs = <String>[
      if (!hasPan) 'PAN card',
      if (!hasAadhar) 'Aadhaar card',
    ];

    final businessName = (owner['business_name'] as String?)?.trim();
    final phone = (owner['phone'] as String?)?.trim();
    final email = (owner['business_email'] as String?)?.trim();
    final subtitle = [
      if (_hasValue(businessName)) businessName,
      if (_hasValue(phone)) phone,
    ].join(' • ');

    return AdminSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Identity ------------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  size: 21,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (owner['owner_name'] as String?)?.trim().isNotEmpty == true
                          ? (owner['owner_name'] as String).trim()
                          : 'Unnamed owner',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (_hasValue(email)) ...[
                      const SizedBox(height: 2),
                      Text(
                        email!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (missingDocs.isNotEmpty) ...[
            const SizedBox(height: 12),
            ApprovalWarningBanner(
              message: 'Missing ${missingDocs.join(' and ')}. '
                  'Verify before approving.',
            ),
          ],

          const SizedBox(height: 16),

          // --- KYC documents -------------------------------------------------
          const ApprovalSectionHeader(title: 'KYC documents'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ApprovalDocumentChip(
                label: 'PAN card',
                url: panUrl,
                icon: Icons.badge_outlined,
                onTap: onDocumentTap,
              ),
              ApprovalDocumentChip(
                label: 'Aadhaar card',
                url: aadharUrl,
                icon: Icons.credit_card_outlined,
                onTap: onDocumentTap,
              ),
            ],
          ),

          // --- Bank details --------------------------------------------------
          if (accountName.isNotEmpty || accountNumber.isNotEmpty || ifscCode.isNotEmpty) ...[
            const SizedBox(height: 16),
            const ApprovalSectionHeader(title: 'Bank details'),
            AdminSurface(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (accountName.isNotEmpty)
                    ApprovalInfoRow(label: 'Account holder', value: accountName),
                  if (accountNumber.isNotEmpty)
                    ApprovalInfoRow(
                      label: 'Account number',
                      value: _maskAccount(accountNumber),
                    ),
                  if (ifscCode.isNotEmpty)
                    ApprovalInfoRow(label: 'IFSC code', value: ifscCode),
                ],
              ),
            ),
          ],

          // --- Linked locations ----------------------------------------------
          if (locations.isNotEmpty) ...[
            const SizedBox(height: 16),
            ApprovalSectionHeader(
              title: 'Locations',
              trailing: '${locations.length}',
            ),
            for (final location in locations)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        [
                          (location['address'] as String?)?.trim().isNotEmpty == true
                              ? (location['address'] as String).trim()
                              : 'Unnamed location',
                          if (_hasValue(location['city'])) location['city'],
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ApprovalDocPresence(
                      label: 'Property',
                      present: _hasValue(location['property_document_url']),
                    ),
                    const SizedBox(width: 4),
                    ApprovalDocPresence(
                      label: 'NOC',
                      present: _hasValue(location['noc_url']),
                    ),
                  ],
                ),
              ),
          ],

          const SizedBox(height: 18),
          ApprovalActionBar(
            onApprove: onApprove,
            onReject: onReject,
            approveLabel: 'Approve owner',
          ),
        ],
      ),
    );
  }
}

/// Card for a single location awaiting document verification.
class LocationApprovalCard extends StatelessWidget {
  const LocationApprovalCard({
    super.key,
    required this.location,
    required this.onApprove,
    required this.onReject,
    required this.onDocumentTap,
  });

  final Map<String, dynamic> location;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final void Function(String url, String title) onDocumentTap;

  static bool _hasValue(Object? value) {
    if (value == null) return false;
    final text = value.toString().trim();
    return text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final propertyUrl = location['property_document_url'] as String?;
    final nocUrl = location['noc_url'] as String?;

    final missing = <String>[
      if (!_hasValue(propertyUrl)) 'Property document',
      if (!_hasValue(nocUrl)) 'NOC',
    ];

    final address = (location['address'] as String?)?.trim();
    final locality = [
      if (_hasValue(location['city'])) location['city'],
      if (_hasValue(location['state'])) location['state'],
    ].join(', ');

    return AdminSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.blue.shade600.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 21,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (address != null && address.isNotEmpty)
                          ? address
                          : 'Unnamed location',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (locality.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        locality,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            ApprovalWarningBanner(
              message: 'Missing ${missing.join(' and ')}. '
                  'Verify before approving.',
            ),
          ],

          const SizedBox(height: 16),
          const ApprovalSectionHeader(title: 'Location documents'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ApprovalDocumentChip(
                label: 'Property document',
                url: propertyUrl,
                icon: Icons.description_outlined,
                onTap: onDocumentTap,
              ),
              ApprovalDocumentChip(
                label: 'NOC',
                url: nocUrl,
                icon: Icons.verified_user_outlined,
                onTap: onDocumentTap,
              ),
            ],
          ),

          const SizedBox(height: 18),
          ApprovalActionBar(
            onApprove: onApprove,
            onReject: onReject,
            approveLabel: 'Approve location',
          ),
        ],
      ),
    );
  }
}
