abstract class AdminNotificationState {}

class AdminNotificationInitial extends AdminNotificationState {}

class AdminNotificationLoading extends AdminNotificationState {}

class AdminNotificationLoaded extends AdminNotificationState {
  final List<Map<String, dynamic>> notifications;
  final int totalCount;

  AdminNotificationLoaded({required this.notifications, required this.totalCount});
}

class AdminNotificationError extends AdminNotificationState {
  final String message;
  AdminNotificationError(this.message);
}

class AdminNotificationSending extends AdminNotificationState {}

class AdminNotificationSent extends AdminNotificationState {
  final String message;
  AdminNotificationSent(this.message);
}
