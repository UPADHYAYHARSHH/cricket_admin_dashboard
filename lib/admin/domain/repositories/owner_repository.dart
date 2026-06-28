abstract class AdminOwnerRepository {
  Future<List<Map<String, dynamic>>> getAllOwners();

  Future<int> getUserCount();
}
