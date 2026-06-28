abstract class AdminBookingRepository {
  /// All bookings platform-wide, each joined with its ground (name, category,
  /// owner_id, location_id) and that ground's location (address, city).
  Future<List<Map<String, dynamic>>> getAllBookingsWithDetails();

  Future<List<Map<String, dynamic>>> getBookingsForLocation(String locationId);
}
