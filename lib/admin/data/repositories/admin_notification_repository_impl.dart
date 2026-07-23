import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/admin_notification_repository.dart';

class AdminNotificationRepositoryImpl implements AdminNotificationRepository {
  final SupabaseClient _supabase;

  AdminNotificationRepositoryImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final response = await _supabase
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(500);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<int> getNotificationCount() async {
    final response = await _supabase.from('notifications').select('id');
    return (response as List).length;
  }

  @override
  Future<void> sendNotification({
    required String title,
    required String message,
    required String type,
    required String target,
    Map<String, dynamic>? data,
  }) async {
    // Use the RPC function for batch send
    await _supabase.rpc('send_notification_to_all', params: {
      'p_title': title,
      'p_message': message,
      'p_type': type,
      'p_data': data ?? {},
      'p_target': target,
    });
  }

  @override
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await _supabase.rpc('send_notification', params: {
      'p_user_id': userId,
      'p_title': title,
      'p_message': message,
      'p_type': type,
      'p_data': data ?? {},
    });
  }

  @override
  Future<void> sendNotificationToBatch({
    required List<String> userIds,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await _supabase.rpc('send_notification_batch', params: {
      'p_user_ids': userIds,
      'p_title': title,
      'p_message': message,
      'p_type': type,
      'p_data': data ?? {},
    });
  }
}
