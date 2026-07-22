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

  @override
  Future<List<Map<String, dynamic>>> getPendingOwners() async {
    final response = await _supabase
        .from('owner_details')
        .select()
        .eq('status', 'submitted')
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> approveOwner(String ownerId) async {
    await _supabase.from('owner_details').update({
      'status': 'approved',
    }).eq('id', ownerId);
  }

  @override
  Future<void> rejectOwner(String ownerId, {String? reason}) async {
    await _supabase.from('owner_details').update({
      'status': 'rejected',
      // If there's a reason column in the future, we can add it here.
      // 'rejection_reason': reason,
    }).eq('id', ownerId);
  }
}
