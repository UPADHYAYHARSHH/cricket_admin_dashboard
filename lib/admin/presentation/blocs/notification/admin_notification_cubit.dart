import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/admin_notification_repository.dart';
import 'admin_notification_state.dart';

class AdminNotificationCubit extends Cubit<AdminNotificationState> {
  final AdminNotificationRepository _notificationRepository;

  AdminNotificationCubit(this._notificationRepository) : super(AdminNotificationInitial());

  Future<void> fetchNotifications() async {
    emit(AdminNotificationLoading());
    try {
      final notifications = await _notificationRepository.getAllNotifications();
      final totalCount = await _notificationRepository.getNotificationCount();
      emit(AdminNotificationLoaded(notifications: notifications, totalCount: totalCount));
    } catch (e) {
      emit(AdminNotificationError(e.toString()));
    }
  }

  Future<void> sendNotification({
    required String title,
    required String message,
    required String type,
    required String target,
    Map<String, dynamic>? data,
  }) async {
    emit(AdminNotificationSending());
    try {
      await _notificationRepository.sendNotification(
        title: title,
        message: message,
        type: type,
        target: target,
        data: data,
      );
      emit(AdminNotificationSent('Notification sent successfully!'));
      await fetchNotifications();
    } catch (e) {
      emit(AdminNotificationError(e.toString()));
    }
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    emit(AdminNotificationSending());
    try {
      await _notificationRepository.sendNotificationToUser(
        userId: userId,
        title: title,
        message: message,
        type: type,
        data: data,
      );
      emit(AdminNotificationSent('Notification sent to user!'));
      await fetchNotifications();
    } catch (e) {
      emit(AdminNotificationError(e.toString()));
    }
  }
}
