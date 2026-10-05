import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_management_state.dart';

class UserManagementCubit extends Cubit<UserManagementState> {
  final SupabaseClient _supabase;

  UserManagementCubit(this._supabase) : super(UserManagementInitial());

  Future<void> fetchUsers() async {
    emit(UserManagementLoading());
    try {
      final usersResponse = await _supabase.from('users').select();
      final ownersResponse = await _supabase.from('owner_details').select('id, status');
      
      final ownerSet = <String>{};
      for (var o in ownersResponse) {
        ownerSet.add(o['id'] as String);
      }
      
      final users = List<Map<String, dynamic>>.from(usersResponse);
      for (var u in users) {
        u['is_owner'] = ownerSet.contains(u['id']);
      }
      
      emit(UserManagementLoaded(users));
    } catch (e) {
      emit(UserManagementError(e.toString()));
    }
  }
}
