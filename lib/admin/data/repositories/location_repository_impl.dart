import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements AdminLocationRepository {
  final SupabaseClient _supabase;

  LocationRepositoryImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getPendingLocations() async {
    final response = await _supabase
        .from('locations')
        .select()
        .eq('documents_verified', false)
        .isFilter('rejection_reason', null)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllLocations() async {
    final response = await _supabase
        .from('locations')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> approveLocation(String locationId) async {
    await _supabase.from('locations').update({
      'documents_verified': true,
      'rejection_reason': null,
    }).eq('id', locationId);
  }

  @override
  Future<void> rejectLocation(String locationId, {String? reason}) async {
    await _supabase.from('locations').update({
      'documents_verified': false,
      'rejection_reason': (reason == null || reason.isEmpty) ? 'Rejected by admin' : reason,
    }).eq('id', locationId);
  }

  @override
  Future<void> setLocationActive(String locationId, bool isActive) async {
    await _supabase.from('locations').update({'is_active': isActive}).eq('id', locationId);
  }
}
