abstract class AdminOwnerRepository {
  Future<List<Map<String, dynamic>>> getAllOwners();

  Future<int> getUserCount();

<<<<<<< Updated upstream
  Future<List<Map<String, dynamic>>> getPendingOwners();
  Future<void> approveOwner(String ownerId);
  Future<void> rejectOwner(String ownerId, {String? reason});
=======
  Future<void> approveOwner(String ownerId);

  Future<void> rejectOwner(String ownerId, {String? reason});

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  });
>>>>>>> Stashed changes
}
