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

      final allLocations = await _locationRepository.getAllLocations();
      final locationsByOwner = <String, List<Map<String, dynamic>>>{};
      for (final loc in allLocations) {
        final ownerId = loc['owner_id'].toString();
        if (!locationsByOwner.containsKey(ownerId)) {
          locationsByOwner[ownerId] = [];
        }
        locationsByOwner[ownerId]!.add(loc);
      }

      emit(ApprovalsLoaded(
        pendingOwners: pendingOwners,
        locationsByOwner: locationsByOwner,
      ));
    } catch (e) {
      emit(ApprovalsError(e.toString()));
    }
  }

  Future<void> approve(String ownerId) async {
    try {
      await _ownerRepository.approveOwner(ownerId);

      final allLocations = await _locationRepository.getAllLocations();
      final ownerLocations = allLocations
          .where((l) => l['owner_id'].toString() == ownerId && l['documents_verified'] != true)
          .toList();
      for (final loc in ownerLocations) {
        await _locationRepository.approveLocation(loc['id'] as String);
      }

      await _ownerRepository.sendNotification(
        userId: ownerId,
        title: 'Account Approved',
        message: 'Your account has been approved by the admin. You can now access the dashboard.',
        type: 'location_approved',
      );

      await fetchPending();
    } catch (e) {
      emit(ApprovalsError(e.toString()));
    }
  }

  Future<void> reject(String ownerId, {String? reason}) async {
    try {
      await _ownerRepository.rejectOwner(ownerId, reason: reason);

      final allLocations = await _locationRepository.getAllLocations();
      final ownerLocations = allLocations
          .where((l) => l['owner_id'].toString() == ownerId && l['documents_verified'] != true)
          .toList();
      for (final loc in ownerLocations) {
        await _locationRepository.rejectLocation(loc['id'] as String, reason: reason);
      }

      await _ownerRepository.sendNotification(
        userId: ownerId,
        title: 'Account Rejected',
        message: reason != null && reason.isNotEmpty
            ? 'Your account has been rejected. Reason: $reason'
            : 'Your account has been rejected by the admin.',
        type: 'location_rejected',
      );

      await fetchPending();
    } catch (e) {
      emit(ApprovalsError(e.toString()));
    }
  }
}
