import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/location_repository.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/owner_repository.dart';
import 'approvals_state.dart';

class ApprovalsCubit extends Cubit<ApprovalsState> {
  final AdminLocationRepository _locationRepository;
  final AdminOwnerRepository _ownerRepository;

  ApprovalsCubit(this._locationRepository, this._ownerRepository) : super(ApprovalsInitial());

  Future<void> fetchPending() async {
    emit(ApprovalsLoading());
    try {
      final pending = await _locationRepository.getPendingLocations();
      final owners = await _ownerRepository.getAllOwners();
      final ownerNameById = {
        for (final o in owners) o['id'].toString(): (o['owner_name'] as String?) ?? 'Owner',
      };
      emit(ApprovalsLoaded(pendingLocations: pending, ownerNameById: ownerNameById));
    } catch (e) {
      emit(ApprovalsError(e.toString()));
    }
  }

  Future<void> approve(String locationId) async {
    await _locationRepository.approveLocation(locationId);
    await fetchPending();
  }

  Future<void> reject(String locationId, {String? reason}) async {
    await _locationRepository.rejectLocation(locationId, reason: reason);
    await fetchPending();
  }
}
