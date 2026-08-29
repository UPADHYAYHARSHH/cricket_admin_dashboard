abstract class ApprovalsState {}

class ApprovalsInitial extends ApprovalsState {}

class ApprovalsLoading extends ApprovalsState {}

class ApprovalsLoaded extends ApprovalsState {
  final List<Map<String, dynamic>> pendingOwners;
  final Map<String, List<Map<String, dynamic>>> locationsByOwner;
  final List<Map<String, dynamic>> pendingLocations;

  ApprovalsLoaded({
    required this.pendingOwners,
    required this.locationsByOwner,
    required this.pendingLocations,
  });
}

class ApprovalsError extends ApprovalsState {
  final String message;
  ApprovalsError(this.message);
}
