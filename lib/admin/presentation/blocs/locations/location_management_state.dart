abstract class LocationManagementState {}

class LocationManagementInitial extends LocationManagementState {}

class LocationManagementLoading extends LocationManagementState {}

class LocationManagementLoaded extends LocationManagementState {
  final List<Map<String, dynamic>> locations;
  final Map<String, String> ownerNameById;

  LocationManagementLoaded({required this.locations, required this.ownerNameById});
}

class LocationManagementError extends LocationManagementState {
  final String message;
  LocationManagementError(this.message);
}
