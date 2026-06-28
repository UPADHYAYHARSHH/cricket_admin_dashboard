abstract class AdminGroundRepository {
  Future<List<Map<String, dynamic>>> getAllGrounds();

  Future<List<Map<String, dynamic>>> getGroundsForLocation(String locationId);

  Future<void> setGroundAvailable(String groundId, bool isAvailable);
}
