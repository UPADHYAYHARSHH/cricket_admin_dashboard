import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'booking_management_state.dart';

class BookingManagementCubit extends Cubit<BookingManagementState> {
  final SupabaseClient _supabase;

  BookingManagementCubit(this._supabase) : super(BookingManagementInitial());

  Future<void> fetchBookings() async {
    emit(BookingManagementLoading());
    try {
      final response = await _supabase.from('bookings').select('''
        *,
        users ( name, email ),
        grounds ( name, locations ( name ) )
      ''').order('created_at', ascending: false);
      
      final bookings = List<Map<String, dynamic>>.from(response);
      emit(BookingManagementLoaded(bookings));
    } catch (e) {
      emit(BookingManagementError(e.toString()));
    }
  }
}
