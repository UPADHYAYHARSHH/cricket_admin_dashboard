import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';

/// Circular monogram built from the owner's name.
///
/// Gives each row a stable visual anchor so an admin can track the same owner
/// down the page without re-reading the name.
class OwnerMonogram extends StatelessWidget {
  const OwnerMonogram({super.key, required this.name, this.size = 38});

  final String name;
  final double size;

  static const List<Color> _palette = [
    Color(0xFF0B8457),
    Color(0xFF1D6FA5),
    Color(0xFF7B4FB5),
    Color(0xFFB5561F),
    Color(0xFF16697A),
    Color(0xFF8A6D1F),
  ];

  /// Stable, platform-independent hash. [Object.hashCode] is deliberately
  /// avoided because it is not guaranteed to be stable across runs, which would
  /// change a given owner's swatch on every hot restart.
  static int _stableHash(String input) {
    var hash = 0;
    for (final unit in input.codeUnits) {
      hash = (hash * 31 + unit) & 0x1FFFFFFF;
    }
    return hash;
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initials = trimmed.isEmpty
        ? '?'
        : trimmed
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    final seed = _stableHash(trimmed) % _palette.length;
    final swatch = _palette[seed];

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: swatch.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: swatch.withValues(alpha: 0.30)),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: swatch,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
          height: 1,
        ),
      ),
    );
  }
}

/// Owner name over business name.
class OwnerIdentity extends StatelessWidget {
  const OwnerIdentity({super.key, required this.summary, this.monogramSize = 38});

  final Map<String, dynamic> summary;
  final double monogramSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (summary['owner_name'] as String?)?.trim();
    final business = (summary['business_name'] as String?)?.trim();

    return Row(
      children: [
        OwnerMonogram(name: name ?? '', size: monogramSize),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (name == null || name.isEmpty) ? 'Unknown owner' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              if (business != null && business.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  business,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Email over phone, both selectable and copy-friendly.
class OwnerContact extends StatelessWidget {
  const OwnerContact({super.key, required this.owner});

  final Map<String, dynamic> owner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.lightTextSecondary,
      height: 1.5,
    );

    final email = (owner['business_email'] as String?)?.trim();
    final phone = (owner['phone'] as String?)?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mail_outline_rounded,
                size: 13, color: AppColors.lightTextSecondary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                (email == null || email.isEmpty) ? 'No email' : email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style?.copyWith(
                  color: (email == null || email.isEmpty)
                      ? AppColors.lightTextSecondary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_outlined,
                size: 13, color: AppColors.lightTextSecondary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                (phone == null || phone.isEmpty) ? 'No phone' : phone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style?.copyWith(
                  color: (phone == null || phone.isEmpty)
                      ? AppColors.lightTextSecondary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
