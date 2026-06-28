import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/ground_repository.dart';

class GroundRepositoryImpl implements AdminGroundRepository {
  final SupabaseClient _supabase;

  GroundRepositoryImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getAllGrounds() async {
    final response = await _supabase
        .from('grounds')
        .select('*, locations(address, city, is_active, documents_verified)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getGroundsForLocation(String locationId) async {
    final response = await _supabase
        .from('grounds')
        .select()
        .eq('location_id', locationId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> setGroundAvailable(String groundId, bool isAvailable) async {
    await _supabase.from('grounds').update({'is_available': isAvailable}).eq('id', groundId);
  }
}
