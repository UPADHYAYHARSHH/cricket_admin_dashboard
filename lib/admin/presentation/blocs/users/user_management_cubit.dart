import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cricket_admin_panel/common/services/firebase_auth_admin_service.dart';
import 'user_management_state.dart';

class UserManagementCubit extends Cubit<UserManagementState> {
  final SupabaseClient _supabase;

  UserManagementCubit(this._supabase) : super(UserManagementInitial());

  Future<void> fetchUsers() async {
    emit(UserManagementLoading());
    try {
      // 1. Fetch Supabase users table
      final usersResponse = await _supabase.from('users').select();
      
      // 2. Fetch owner details for role lookup
      final ownersResponse = await _supabase.from('owner_details').select('id, status');
      final ownerSet = <String>{};
      for (var o in ownersResponse) {
        final id = o['id']?.toString();
        if (id != null) ownerSet.add(id);
      }

      // 3. Fetch Firebase Auth users
      List<Map<String, dynamic>> fbUsers = [];
      try {
        fbUsers = await FirebaseAuthAdminService.fetchFirebaseUsers();
      } catch (e) {
        debugPrint('⚠️ Error fetching Firebase Auth users: $e');
      }

      // 4. Merge without duplicates (Indexed by ID and Email)
      final Map<String, Map<String, dynamic>> mergedUsersById = {};
      final Map<String, String> emailToIdMap = {};

      // First add Supabase users
      for (final raw in usersResponse) {
        final u = Map<String, dynamic>.from(raw as Map);
        final id = (u['id'] ?? '').toString();
        final email = (u['email'] ?? '').toString().trim().toLowerCase();

        u['is_owner'] = ownerSet.contains(id);
        u['source'] = 'supabase';

        if (id.isNotEmpty) {
          mergedUsersById[id] = u;
          if (email.isNotEmpty) {
            emailToIdMap[email] = id;
          }
        }
      }

      // Then merge Firebase Auth users
      for (final fb in fbUsers) {
        final fbUid = (fb['localId'] ?? '').toString();
        final fbEmail = (fb['email'] ?? '').toString().trim().toLowerCase();
        final fbDisplayName = (fb['displayName'] ?? '').toString().trim();
        final fbPhone = (fb['phoneNumber'] ?? '').toString().trim();
        final fbPhoto = (fb['photoUrl'] ?? '').toString().trim();

        // Check if user already exists by ID or by email
        String? existingId;
        if (mergedUsersById.containsKey(fbUid)) {
          existingId = fbUid;
        } else if (fbEmail.isNotEmpty && emailToIdMap.containsKey(fbEmail)) {
          existingId = emailToIdMap[fbEmail];
        }

        if (existingId != null) {
          // Merge details into existing user
          final existing = mergedUsersById[existingId]!;
          if ((existing['name'] == null || existing['name'].toString().trim().isEmpty) && fbDisplayName.isNotEmpty) {
            existing['name'] = fbDisplayName;
          }
          if ((existing['email'] == null || existing['email'].toString().trim().isEmpty) && fbEmail.isNotEmpty) {
            existing['email'] = fbEmail;
          }
          if ((existing['phone'] == null || existing['phone'].toString().trim().isEmpty) && fbPhone.isNotEmpty) {
            existing['phone'] = fbPhone;
          }
          if (existing['is_owner'] != true) {
            existing['is_owner'] = ownerSet.contains(fbUid);
          }
          existing['source'] = 'both';
          if (fb['createdAt'] != null && existing['created_at'] == null) {
            try {
              final ms = int.tryParse(fb['createdAt'].toString());
              if (ms != null) {
                existing['created_at'] = DateTime.fromMillisecondsSinceEpoch(ms).toIso8601String();
              }
            } catch (_) {}
          }
        } else {
          // New user found only in Firebase Auth
          final newUser = <String, dynamic>{
            'id': fbUid,
            'name': fbDisplayName.isNotEmpty ? fbDisplayName : (fbEmail.isNotEmpty ? fbEmail.split('@').first : 'User'),
            'email': fbEmail,
            'phone': fbPhone,
            'photo_url': fbPhoto,
            'username': fbEmail.isNotEmpty ? fbEmail.split('@').first : '',
            'is_owner': ownerSet.contains(fbUid),
            'source': 'firebase',
          };

          if (fb['createdAt'] != null) {
            try {
              final ms = int.tryParse(fb['createdAt'].toString());
              if (ms != null) {
                newUser['created_at'] = DateTime.fromMillisecondsSinceEpoch(ms).toIso8601String();
              }
            } catch (_) {}
          }

          final key = fbUid.isNotEmpty ? fbUid : (fbEmail.isNotEmpty ? fbEmail : UniqueKey().toString());
          mergedUsersById[key] = newUser;
          if (fbEmail.isNotEmpty) {
            emailToIdMap[fbEmail] = key;
          }
        }
      }

      final combinedList = mergedUsersById.values.toList();
      emit(UserManagementLoaded(combinedList));
    } catch (e) {
      emit(UserManagementError(e.toString()));
    }
  }

  Future<void> grantLoyaltyPoints(String userId, int points, String reason) async {
    try {
      final expiry = DateTime.now().add(const Duration(days: 90)).toIso8601String();
      await _supabase.from('loyalty_points').insert({
        'user_id': userId,
        'points': points,
        'is_used': false,
        'expiry_date': expiry,
        'source': reason.isEmpty ? 'admin_grant' : reason,
        'created_at': DateTime.now().toIso8601String(),
      });
      await fetchUsers();
    } catch (e) {
      debugPrint('Error granting loyalty points: $e');
      rethrow;
    }
  }
}
