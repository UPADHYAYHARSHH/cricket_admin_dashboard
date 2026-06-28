const _countedStatuses = {'confirmed', 'completed'};

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
