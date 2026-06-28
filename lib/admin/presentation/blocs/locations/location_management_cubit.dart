import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/booking_repository.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/ground_repository.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/location_repository.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/owner_repository.dart';
import 'location_management_state.dart';

class LocationManagementCubit extends Cubit<LocationManagementState> {
  final AdminLocationRepository _locationRepository;
  final AdminGroundRepository _groundRepository;
  final AdminOwnerRepository _ownerRepository;
  final AdminBookingRepository _bookingRepository;

  LocationManagementCubit(
    this._locationRepository,
    this._groundRepository,
    this._ownerRepository,
    this._bookingRepository,
  ) : super(LocationManagementInitial());

  Future<void> fetchLocations() async {
    emit(LocationManagementLoading());
    try {
      final locations = await _locationRepository.getAllLocations();
      final owners = await _ownerRepository.getAllOwners();
      final ownerNameById = {
        for (final o in owners) o['id'].toString(): (o['owner_name'] as String?) ?? 'Owner',
      };
      emit(LocationManagementLoaded(locations: locations, ownerNameById: ownerNameById));
    } catch (e) {
      emit(LocationManagementError(e.toString()));
    }
  }

  Future<void> toggleLocationActive(String locationId, bool isActive) async {
    final current = state;
    if (current is! LocationManagementLoaded) return;

    await _locationRepository.setLocationActive(locationId, isActive);

    final updated = current.locations
        .map((l) => l['id'] == locationId ? {...l, 'is_active': isActive} : l)
        .toList();
    emit(LocationManagementLoaded(locations: updated, ownerNameById: current.ownerNameById));
  }

  Future<List<Map<String, dynamic>>> fetchGroundsForLocation(String locationId) =>
      _groundRepository.getGroundsForLocation(locationId);

  Future<void> toggleGroundAvailable(String groundId, bool isAvailable) =>
      _groundRepository.setGroundAvailable(groundId, isAvailable);

  Future<List<Map<String, dynamic>>> fetchBookingHistory(String locationId) =>
      _bookingRepository.getBookingsForLocation(locationId);
}
