import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/owner_repository.dart';

class OwnerRepositoryImpl implements AdminOwnerRepository {
  final SupabaseClient _supabase;

  OwnerRepositoryImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getAllOwners() async {
    final response = await _supabase.from('owner_details').select();
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<int> getUserCount() async {
    final response = await _supabase.from('users').select('id');
    return (response as List).length;
  }
}
