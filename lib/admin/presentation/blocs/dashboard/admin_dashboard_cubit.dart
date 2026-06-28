import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_admin_panel/admin/domain/analytics.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/booking_repository.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/ground_repository.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/location_repository.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/owner_repository.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final AdminLocationRepository _locationRepository;
  final AdminGroundRepository _groundRepository;
  final AdminOwnerRepository _ownerRepository;
  final AdminBookingRepository _bookingRepository;

  AdminDashboardCubit(
    this._locationRepository,
    this._groundRepository,
    this._ownerRepository,
    this._bookingRepository,
  ) : super(AdminDashboardInitial());

  Future<void> fetchStats() async {
    emit(AdminDashboardLoading());
    try {
      final locations = await _locationRepository.getAllLocations();
      final grounds = await _groundRepository.getAllGrounds();
      final owners = await _ownerRepository.getAllOwners();
      final usersCount = await _ownerRepository.getUserCount();
      final bookings = await _bookingRepository.getAllBookingsWithDetails();

      final pending = locations
          .where((l) => l['documents_verified'] != true && l['rejection_reason'] == null)
          .toList();

      final activeGrounds = grounds.where((g) {
        final location = g['locations'] as Map<String, dynamic>?;
        return g['is_available'] == true &&
            location?['is_active'] == true &&
            location?['documents_verified'] == true;
      }).length;

      final ownerNameById = {
        for (final o in owners) o['id'].toString(): (o['owner_name'] as String?) ?? 'Owner',
      };

      emit(AdminDashboardLoaded(
        pendingApprovalsCount: pending.length,
        activeGroundsCount: activeGrounds,
        ownersCount: owners.length,
        usersCount: usersCount,
        totalRevenue: totalRevenue(bookings),
        recentPending: pending.take(5).toList(),
        ownerNameById: ownerNameById,
      ));
    } catch (e) {
      emit(AdminDashboardError(e.toString()));
    }
  }
}
