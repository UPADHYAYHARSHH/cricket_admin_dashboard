import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_admin_panel/admin/domain/analytics.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/booking_repository.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/location_repository.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/owner_repository.dart';
import 'owner_management_state.dart';

class OwnerManagementCubit extends Cubit<OwnerManagementState> {
  final AdminOwnerRepository _ownerRepository;
  final AdminBookingRepository _bookingRepository;
  final AdminLocationRepository _locationRepository;

  OwnerManagementCubit(
    this._ownerRepository,
    this._bookingRepository,
    this._locationRepository,
  ) : super(OwnerManagementInitial());

  Future<void> fetchOwners() async {
    emit(OwnerManagementLoading());
    try {
      final owners = await _ownerRepository.getAllOwners();
      final bookings = await _bookingRepository.getAllBookingsWithDetails();
      final locations = await _locationRepository.getAllLocations();

      final byOwner = revenueByOwner(bookings);
      final locationCountByOwner = <String, int>{};
      for (final l in locations) {
        final ownerId = l['owner_id']?.toString();
        if (ownerId == null) continue;
        locationCountByOwner[ownerId] = (locationCountByOwner[ownerId] ?? 0) + 1;
      }

      final summaries = owners.map((owner) {
        final id = owner['id'].toString();
        final stats = byOwner[id];
        return OwnerSummary(
          owner: owner,
          locationsCount: locationCountByOwner[id] ?? 0,
          bookingsCount: stats?.bookings ?? 0,
          revenue: stats?.revenue ?? 0,
        );
      }).toList()
        ..sort((a, b) => b.revenue.compareTo(a.revenue));

      emit(OwnerManagementLoaded(summaries));
    } catch (e) {
      emit(OwnerManagementError(e.toString()));
    }
  }

  Future<void> approveOwner(String ownerId) async {
    final current = state;
    if (current is! OwnerManagementLoaded) return;

    await _ownerRepository.approveOwner(ownerId);

    final updated = current.owners.map((s) {
      if (s.owner['id'].toString() == ownerId) {
        return OwnerSummary(
          owner: {...s.owner, 'status': 'approved'},
          locationsCount: s.locationsCount,
          bookingsCount: s.bookingsCount,
          revenue: s.revenue,
        );
      }
      return s;
    }).toList();
    emit(OwnerManagementLoaded(updated));
  }

  Future<void> rejectOwner(String ownerId, {String? reason}) async {
    final current = state;
    if (current is! OwnerManagementLoaded) return;

    await _ownerRepository.rejectOwner(ownerId, reason: reason);

    final updated = current.owners.map((s) {
      if (s.owner['id'].toString() == ownerId) {
        return OwnerSummary(
          owner: {...s.owner, 'status': 'rejected', 'rejection_reason': reason ?? 'Rejected by admin'},
          locationsCount: s.locationsCount,
          bookingsCount: s.bookingsCount,
          revenue: s.revenue,
        );
      }
      return s;
    }).toList();
    emit(OwnerManagementLoaded(updated));
  }
}
