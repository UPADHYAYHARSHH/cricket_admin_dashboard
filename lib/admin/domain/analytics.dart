import 'package:cricket_admin_panel/admin/data/models/sport_model.dart';

const _countedStatuses = {'confirmed', 'completed', 'paid'};

double amountOf(Map<String, dynamic> booking) =>
    ((booking['amount'] ?? booking['total_amount'] ?? 0) as num).toDouble();

bool countsTowardsRevenue(Map<String, dynamic> booking) {
  final status = booking['status']?.toString().toLowerCase() ?? '';
  return _countedStatuses.contains(status);
}

String? ownerIdOf(Map<String, dynamic> booking) =>
    (booking['grounds'] as Map<String, dynamic>?)?['owner_id'] as String?;

String? locationIdOf(Map<String, dynamic> booking) =>
    (booking['grounds'] as Map<String, dynamic>?)?['location_id'] as String?;

/// Normalizes raw sport strings like 'box_cricket' -> 'Box Cricket'.
String normalizeSportName(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return 'Other';
  s = s.replaceAll('_', ' ').replaceAll('-', ' ');
  return s.split(' ').map((word) {
    if (word.isEmpty) return '';
    return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
  }).join(' ');
}

/// Identifies the sport for a booking from `sport_name`, `ground.category`, or ground name.
String sportOf(Map<String, dynamic> booking) {
  final fromBooking = booking['sport_name'] as String?;
  if (fromBooking != null && fromBooking.trim().isNotEmpty) {
    return normalizeSportName(fromBooking);
  }
  final ground = booking['grounds'] as Map<String, dynamic>?;
  final raw = ground?['category'] as String?;
  if (raw != null && raw.trim().isNotEmpty) {
    return normalizeSportName(raw);
  }
  final groundName = ground?['name'] as String?;
  if (groundName != null && groundName.trim().isNotEmpty) {
    final lower = groundName.toLowerCase();
    if (lower.contains('cricket')) return 'Box Cricket';
    if (lower.contains('football')) return 'Football';
    if (lower.contains('badminton')) return 'Badminton';
    if (lower.contains('tennis')) return 'Tennis';
    if (lower.contains('pickleball')) return 'Pickleball';
  }
  return 'Other';
}

/// A structured analytics record for a single sport category.
class SportAnalytics {
  final String id;
  final String name;
  final String slug;
  final int totalBookings;
  final int confirmedBookings;
  final double revenue;
  final double percentage; // 0.0 to 100.0%
  final String colorHex;
  final String iconUrl;
  final bool isActive;

  const SportAnalytics({
    required this.id,
    required this.name,
    required this.slug,
    required this.totalBookings,
    this.confirmedBookings = 0,
    required this.revenue,
    this.percentage = 0.0,
    this.colorHex = '#0B8457',
    this.iconUrl = '',
    this.isActive = true,
  });

  SportAnalytics copyWith({
    String? id,
    String? name,
    String? slug,
    int? totalBookings,
    int? confirmedBookings,
    double? revenue,
    double? percentage,
    String? colorHex,
    String? iconUrl,
    bool? isActive,
  }) {
    return SportAnalytics(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      totalBookings: totalBookings ?? this.totalBookings,
      confirmedBookings: confirmedBookings ?? this.confirmedBookings,
      revenue: revenue ?? this.revenue,
      percentage: percentage ?? this.percentage,
      colorHex: colorHex ?? this.colorHex,
      iconUrl: iconUrl ?? this.iconUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Fallback color palette for sports without a configured color.
const List<String> defaultSportColors = [
  '#0B8457', // Forest Green
  '#0288D1', // Cerulean Blue
  '#FF9800', // Amber
  '#E91E63', // Rose Pink
  '#9C27B0', // Purple
  '#00BFA5', // Teal
  '#FF5722', // Deep Orange
  '#3F51B5', // Indigo
  '#FFD600', // Yellow
  '#607D8B', // Blue Grey
];

/// Computes booking counts, revenue and percentages for each sport category.
List<SportAnalytics> computeSportAnalytics(
  List<Map<String, dynamic>> bookings, {
  List<SportModel> knownSports = const [],
}) {
  // Keyed by canonical lower-case name / slug
  final Map<String, _SportAccumulator> accumulators = {};

  // 1. Seed with all known sports from catalogue
  for (int i = 0; i < knownSports.length; i++) {
    final s = knownSports[i];
    final key = s.name.trim().toLowerCase();
    accumulators[key] = _SportAccumulator(
      id: s.id,
      name: s.name,
      slug: s.slug,
      colorHex: s.color.isNotEmpty ? s.color : defaultSportColors[i % defaultSportColors.length],
      iconUrl: s.iconUrl,
      isActive: s.isActive,
    );
  }

  // 2. Aggregate from bookings
  for (final b in bookings) {
    final detected = sportOf(b);
    final key = detected.toLowerCase();

    // Try finding in accumulators or knownSports
    _SportAccumulator? target = accumulators[key];
    if (target == null) {
      for (final entry in accumulators.entries) {
        if (entry.key.contains(key) || key.contains(entry.key)) {
          target = entry.value;
          break;
        }
      }
    }

    if (target == null) {
      final idx = accumulators.length;
      target = _SportAccumulator(
        id: 'dyn-$key',
        name: detected,
        slug: key.replaceAll(' ', '_'),
        colorHex: defaultSportColors[idx % defaultSportColors.length],
        iconUrl: '',
        isActive: true,
      );
      accumulators[key] = target;
    }

    target.totalBookings++;
    if (countsTowardsRevenue(b)) {
      target.confirmedBookings++;
      target.revenue += amountOf(b);
    }
  }

  final totalBookingsAll = bookings.length;

  final list = accumulators.values.map((acc) {
    final pct = totalBookingsAll > 0 ? (acc.totalBookings / totalBookingsAll) * 100 : 0.0;
    return SportAnalytics(
      id: acc.id,
      name: acc.name,
      slug: acc.slug,
      totalBookings: acc.totalBookings,
      confirmedBookings: acc.confirmedBookings,
      revenue: acc.revenue,
      percentage: pct,
      colorHex: acc.colorHex,
      iconUrl: acc.iconUrl,
      isActive: acc.isActive,
    );
  }).toList();

  // Sort: sports with bookings first (highest first), then catalogue sports alphabetically
  list.sort((a, b) {
    if (a.totalBookings != b.totalBookings) {
      return b.totalBookings.compareTo(a.totalBookings);
    }
    if (a.revenue != b.revenue) {
      return b.revenue.compareTo(a.revenue);
    }
    return a.name.compareTo(b.name);
  });

  return list;
}

class _SportAccumulator {
  final String id;
  final String name;
  final String slug;
  final String colorHex;
  final String iconUrl;
  final bool isActive;
  int totalBookings = 0;
  int confirmedBookings = 0;
  double revenue = 0.0;

  _SportAccumulator({
    required this.id,
    required this.name,
    required this.slug,
    required this.colorHex,
    required this.iconUrl,
    required this.isActive,
  });
}

/// Point in a daily trend series.
class DailyTrendPoint {
  final DateTime date;
  final String label;
  final int bookingsCount;
  final double revenue;

  const DailyTrendPoint({
    required this.date,
    required this.label,
    required this.bookingsCount,
    required this.revenue,
  });
}

/// Generates a day-by-day series for the last [days] days.
List<DailyTrendPoint> recentBookingsTrend(
  List<Map<String, dynamic>> bookings, {
  int days = 7,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dates = List.generate(
    days,
    (i) => today.subtract(Duration(days: days - 1 - i)),
  );

  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final counts = {for (final d in dates) d: 0};
  final revs = {for (final d in dates) d: 0.0};

  for (final b in bookings) {
    final raw = b['created_at'] ?? b['slot_time'] ?? b['date'];
    if (raw == null) continue;
    DateTime? dt;
    try {
      dt = DateTime.parse(raw.toString()).toLocal();
    } catch (_) {
      continue;
    }
    final dateOnly = DateTime(dt.year, dt.month, dt.day);
    if (counts.containsKey(dateOnly)) {
      counts[dateOnly] = (counts[dateOnly] ?? 0) + 1;
      if (countsTowardsRevenue(b)) {
        revs[dateOnly] = (revs[dateOnly] ?? 0.0) + amountOf(b);
      }
    }
  }

  return dates.map((d) {
    final dayLabel = dayNames[d.weekday - 1];
    final label = '$dayLabel ${d.day}';
    return DailyTrendPoint(
      date: d,
      label: label,
      bookingsCount: counts[d] ?? 0,
      revenue: revs[d] ?? 0.0,
    );
  }).toList();
}

/// Total revenue and successful-booking count per owner_id.
Map<String, ({double revenue, int bookings})> revenueByOwner(
  List<Map<String, dynamic>> bookings,
) {
  final result = <String, ({double revenue, int bookings})>{};
  for (final b in bookings) {
    if (!countsTowardsRevenue(b)) continue;
    final ownerId = ownerIdOf(b);
    if (ownerId == null) continue;
    final current = result[ownerId] ?? (revenue: 0.0, bookings: 0);
    result[ownerId] = (revenue: current.revenue + amountOf(b), bookings: current.bookings + 1);
  }
  return result;
}

double totalRevenue(List<Map<String, dynamic>> bookings) =>
    bookings.where(countsTowardsRevenue).fold(0.0, (sum, b) => sum + amountOf(b));

/// Counts of bookings by status (e.g. confirmed, completed, pending, cancelled).
Map<String, int> bookingStatusDistribution(List<Map<String, dynamic>> bookings) {
  final dist = <String, int>{
    'confirmed': 0,
    'completed': 0,
    'pending': 0,
    'cancelled': 0,
  };
  for (final b in bookings) {
    final st = b['status']?.toString().toLowerCase() ?? 'pending';
    dist[st] = (dist[st] ?? 0) + 1;
  }
  return dist;
}

/// Parses the timestamp or date of a booking.
DateTime? dateOfBooking(Map<String, dynamic> b) {
  final raw = b['booking_date'] ?? b['date'] ?? b['slot_time'] ?? b['created_at'];
  if (raw == null) return null;
  try {
    return DateTime.parse(raw.toString()).toLocal();
  } catch (_) {
    return null;
  }
}

/// Filters bookings within [start] and [end] inclusive.
List<Map<String, dynamic>> filterBookingsByDateRange(
  List<Map<String, dynamic>> bookings,
  DateTime? start,
  DateTime? end,
) {
  if (start == null && end == null) return bookings;
  final s = start != null ? DateTime(start.year, start.month, start.day) : null;
  final e = end != null ? DateTime(end.year, end.month, end.day, 23, 59, 59) : null;

  return bookings.where((b) {
    final dt = dateOfBooking(b);
    if (dt == null) return false;
    if (s != null && dt.isBefore(s)) return false;
    if (e != null && dt.isAfter(e)) return false;
    return true;
  }).toList();
}

/// Filters bookings matching a specific sport category name (or all if null/'all').
List<Map<String, dynamic>> filterBookingsBySport(
  List<Map<String, dynamic>> bookings,
  String? sportName,
) {
  if (sportName == null || sportName.isEmpty || sportName.toLowerCase() == 'all') {
    return bookings;
  }
  final target = sportName.trim().toLowerCase();
  return bookings.where((b) => sportOf(b).toLowerCase() == target).toList();
}

/// Generates trend points for a given date range.
List<DailyTrendPoint> bookingsTrendForRange(
  List<Map<String, dynamic>> bookings, {
  required DateTime start,
  required DateTime end,
}) {
  final s = DateTime(start.year, start.month, start.day);
  final e = DateTime(end.year, end.month, end.day);
  final dayCount = e.difference(s).inDays + 1;
  final cappedDays = dayCount.clamp(1, 90);

  final dates = List.generate(
    cappedDays,
    (i) => DateTime(s.year, s.month, s.day + i),
  );

  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  final counts = {for (final d in dates) d: 0};
  final revs = {for (final d in dates) d: 0.0};

  for (final b in bookings) {
    final dt = dateOfBooking(b);
    if (dt == null) continue;
    final dateOnly = DateTime(dt.year, dt.month, dt.day);
    if (counts.containsKey(dateOnly)) {
      counts[dateOnly] = (counts[dateOnly] ?? 0) + 1;
      if (countsTowardsRevenue(b)) {
        revs[dateOnly] = (revs[dateOnly] ?? 0.0) + amountOf(b);
      }
    }
  }

  return dates.map((d) {
    final dayLabel = dayNames[d.weekday - 1];
    final monthLabel = monthNames[d.month - 1];
    final label = cappedDays <= 7 ? '$dayLabel ${d.day}' : '${d.day} $monthLabel';
    return DailyTrendPoint(
      date: d,
      label: label,
      bookingsCount: counts[d] ?? 0,
      revenue: revs[d] ?? 0.0,
    );
  }).toList();
}
