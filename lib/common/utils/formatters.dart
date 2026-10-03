/// Locale-independent formatting helpers.
///
/// The admin app depends on `package:intl` but does not initialise locale
/// data (no `flutter_localizations`, no `initializeDateFormatting`). Formatting
/// with an explicit locale such as `NumberFormat.decimalPattern('en_IN')` or
/// `DateFormat(...)` on a machine whose system locale has no loaded data throws
/// at runtime on web. These helpers are pure Dart so they behave identically on
/// every platform and need no initialisation.
library;

/// Formats an integer amount with Indian digit grouping (1,00,000).
///
/// The app is INR-only, so no currency argument is needed.
String formatInr(int amount) {
  final isNegative = amount < 0;
  final digits = amount.abs().toString();

  if (digits.length <= 3) {
    return '${isNegative ? '-' : ''}$digits';
  }

  // Groups from the least-significant end: first three digits, then pairs.
  final groups = <String>[];

  var index = digits.length;
  groups.add(digits.substring(index - 3));
  index -= 3;

  while (index > 0) {
    final start = index - 2 < 0 ? 0 : index - 2;
    groups.add(digits.substring(start, index));
    index = start;
  }

  return '${isNegative ? '-' : ''}${groups.reversed.join(',')}';
}

/// Reads a numeric value from a loosely typed database row.
///
/// Returns [fallback] when the value is absent or not parseable, so a `double`
/// column arriving as `"1200"` does not break a money display.
int asInt(Object? value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString().trim()) ?? fallback;
}

/// Reads a decimal value from a loosely typed database row.
double asDouble(Object? value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim()) ?? fallback;
}

/// Formats a timestamp as `15 Sep 2026, 3:42 pm`.
///
/// Accepts an ISO-8601 string or a [DateTime]. Returns an empty string for
/// anything unparseable rather than throwing, because these values come
/// straight from the database.
String formatDateTime(Object? value) {
  final date = switch (value) {
    DateTime dt => dt.toLocal(),
    String s => DateTime.tryParse(s)?.toLocal(),
    _ => null,
  };
  if (date == null) return '';

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final meridiem = date.hour < 12 ? 'am' : 'pm';

  return '${date.day} ${months[date.month - 1]} ${date.year}, '
      '$hour:$minute $meridiem';
}

/// Relative age such as `3h ago`, for "requested" timestamps where the exact
/// time matters less than recency.
String formatRelative(Object? value) {
  final date = switch (value) {
    DateTime dt => dt.toLocal(),
    String s => DateTime.tryParse(s)?.toLocal(),
    _ => null,
  };
  if (date == null) return '';

  final diff = DateTime.now().difference(date);

  if (diff.isNegative) return 'just now';
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 365) return '${diff.inDays ~/ 7}w ago';
  return '${diff.inDays ~/ 365}y ago';
}
