import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements AdminBookingRepository {
  final SupabaseClient _supabase;

  BookingRepositoryImpl(this._supabase);

  static const _select =
      '*, grounds(name, category, owner_id, location_id, locations(address, city))';

  static const _selectForLocation =
      '*, grounds!inner(name, category, owner_id, location_id, locations(address, city))';

  @override
  Future<List<Map<String, dynamic>>> getAllBookingsWithDetails() async {
    final response = await _supabase
        .from('bookings')
        .select(_select)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getBookingsForLocation(String locationId) async {
    final response = await _supabase
        .from('bookings')
        .select(_selectForLocation)
        .eq('grounds.location_id', locationId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
