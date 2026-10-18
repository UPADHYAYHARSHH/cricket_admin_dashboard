import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cricket_admin_panel/admin/data/models/sport_model.dart';
import 'package:cricket_admin_panel/admin/domain/analytics.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/booking_repository.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/ground_repository.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/owner_repository.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final AdminGroundRepository _groundRepository;
  final AdminOwnerRepository _ownerRepository;
  final AdminBookingRepository _bookingRepository;
  final SupabaseClient? _supabase;

  AdminDashboardCubit(
    this._groundRepository,
    this._ownerRepository,
    this._bookingRepository, [
    this._supabase,
  ]) : super(AdminDashboardInitial());

  Future<void> fetchStats() async {
    emit(AdminDashboardLoading());
    try {
      final grounds = await _groundRepository.getAllGrounds();
      final owners = await _ownerRepository.getAllOwners();
      final usersCount = await _ownerRepository.getUserCount();
      final bookings = await _bookingRepository.getAllBookingsWithDetails();

      // Optionally fetch sports catalogue to enrich analytics
      List<SportModel> sportsCatalogue = [];
      if (_supabase != null) {
        try {
          final res = await _supabase.from('sports').select().order('sort_order', ascending: true);
          sportsCatalogue = (res as List)
              .map((e) => SportModel.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }

      final pendingOwners = owners
          .where((o) => o['status'] == 'submitted')
          .toList();

      final activeGrounds = grounds.where((g) {
        final location = g['locations'] as Map<String, dynamic>?;
        return g['is_available'] == true &&
            location?['is_active'] == true &&
            location?['documents_verified'] == true;
      }).length;

      final sportsStats = computeSportAnalytics(bookings, knownSports: sportsCatalogue);
      final trend = recentBookingsTrend(bookings, days: 7);
      final statuses = bookingStatusDistribution(bookings);

      emit(AdminDashboardLoaded(
        pendingApprovalsCount: pendingOwners.length,
        activeGroundsCount: activeGrounds,
        ownersCount: owners.length,
        usersCount: usersCount,
        totalRevenue: totalRevenue(bookings),
        recentPendingOwners: pendingOwners.take(5).toList(),
        sportsAnalytics: sportsStats,
        recentTrend: trend,
        statusDistribution: statuses,
        totalBookingsCount: bookings.length,
        allBookings: bookings,
        sportsCatalogue: sportsCatalogue,
      ));
    } catch (e) {
      emit(AdminDashboardError(e.toString()));
    }
  }
}
