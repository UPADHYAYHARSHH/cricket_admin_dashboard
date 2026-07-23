abstract class AdminNotificationRepository {
  Future<List<Map<String, dynamic>>> getAllNotifications();

  Future<int> getNotificationCount();

  Future<void> sendNotification({
    required String title,
    required String message,
    required String type,
    required String target, // 'all', 'users', 'owners'
    Map<String, dynamic>? data,
  });

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  });

  Future<void> sendNotificationToBatch({
    required List<String> userIds,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  });
}
