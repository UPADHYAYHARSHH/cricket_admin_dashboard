abstract class AdminLocationRepository {
  /// Locations awaiting a decision: documents_verified = false and no
  /// rejection_reason recorded yet.
  Future<List<Map<String, dynamic>>> getPendingLocations();

  /// Every location across every owner, for the management table.
  Future<List<Map<String, dynamic>>> getAllLocations();

  Future<void> approveLocation(String locationId);

  Future<void> rejectLocation(String locationId, {String? reason});

  /// Admin-level enable/disable, independent of the owner's own toggle.
  Future<void> setLocationActive(String locationId, bool isActive);
}
