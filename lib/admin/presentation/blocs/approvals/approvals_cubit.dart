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
      final pendingOwners = await _ownerRepository.getPendingOwners();
      emit(ApprovalsLoaded(pendingOwners: pendingOwners));
    } catch (e) {
      emit(ApprovalsError(e.toString()));
    }
  }

  Future<void> approve(String ownerId) async {
    await _ownerRepository.approveOwner(ownerId);
    await fetchPending();
  }

  Future<void> reject(String ownerId, {String? reason}) async {
    await _ownerRepository.rejectOwner(ownerId, reason: reason);
    await fetchPending();
  }
}
