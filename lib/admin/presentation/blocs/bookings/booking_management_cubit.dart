import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cricket_admin_panel/common/services/firebase_auth_admin_service.dart';
import 'booking_management_state.dart';

class BookingManagementCubit extends Cubit<BookingManagementState> {
  final SupabaseClient _supabase;

  BookingManagementCubit(this._supabase) : super(BookingManagementInitial());

  Future<void> fetchBookings() async {
    emit(BookingManagementLoading());
    try {
      // 1. Fetch bookings with grounds and locations (FK exists for grounds)
      final response = await _supabase.from('bookings').select('''
        *,
        grounds ( name, category, locations ( name ) )
      ''').order('created_at', ascending: false);

      final rawBookings = List<Map<String, dynamic>>.from(response);

      // Collect unique user_ids
      final userIds = rawBookings
          .map((b) => b['user_id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> userLookup = {};

      if (userIds.isNotEmpty) {
        // 2. Fetch Supabase users for those IDs
        try {
          final usersResponse = await _supabase
              .from('users')
              .select('id, name, username, email, phone')
              .inFilter('id', userIds);
          for (final u in (usersResponse as List)) {
            final userMap = Map<String, dynamic>.from(u as Map);
            final uid = userMap['id']?.toString() ?? '';
            if (uid.isNotEmpty) {
              userLookup[uid] = userMap;
            }
          }
        } catch (_) {}

        // 3. Check for any missing user IDs in Firebase Auth
        final missingIds = userIds.where((id) => !userLookup.containsKey(id)).toSet();
        if (missingIds.isNotEmpty) {
          try {
            final fbUsers = await FirebaseAuthAdminService.fetchFirebaseUsers();
            for (final fb in fbUsers) {
              final fbUid = (fb['localId'] ?? '').toString();
              if (missingIds.contains(fbUid)) {
                final fbEmail = (fb['email'] ?? '').toString().trim();
                final fbDisplayName = (fb['displayName'] ?? '').toString().trim();
                final fbUsername = fbEmail.isNotEmpty ? fbEmail.split('@').first : '';
                userLookup[fbUid] = {
                  'id': fbUid,
                  'name': fbDisplayName.isNotEmpty
                      ? fbDisplayName
                      : (fbUsername.isNotEmpty ? fbUsername : 'User'),
                  'username': fbUsername,
                  'email': fbEmail,
                  'phone': (fb['phoneNumber'] ?? '').toString().trim(),
                };
              }
            }
          } catch (_) {}
        }
      }

      // 4. Attach users object to each booking
      final bookings = rawBookings.map((b) {
        final booking = Map<String, dynamic>.from(b);
        final uid = booking['user_id']?.toString();
        if (uid != null && userLookup.containsKey(uid)) {
          booking['users'] = userLookup[uid];
        } else if (uid != null) {
          booking['users'] = {'name': uid, 'email': ''};
        }
        return booking;
      }).toList();

      emit(BookingManagementLoaded(bookings));
    } catch (e) {
      emit(BookingManagementError(e.toString()));
    }
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus, {String? reason}) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus.toLowerCase(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (reason != null && reason.isNotEmpty) {
        updateData['cancellation_reason'] = reason;
        updateData['cancelled_by'] = 'admin';
        updateData['cancelled_at'] = DateTime.now().toIso8601String();
      }

      await _supabase.from('bookings').update(updateData).eq('id', bookingId);
      await fetchBookings();
    } catch (e) {
      emit(BookingManagementError('Failed to update booking status: $e'));
    }
  }

  Future<void> toggleCheckIn(String bookingId, bool currentCheckedIn) async {
    try {
      final newCheckedIn = !currentCheckedIn;
      await _supabase.from('bookings').update({
        'checked_in': newCheckedIn,
        'checked_in_at': newCheckedIn ? DateTime.now().toIso8601String() : null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
      await fetchBookings();
    } catch (e) {
      emit(BookingManagementError('Failed to update check-in status: $e'));
    }
  }
}
