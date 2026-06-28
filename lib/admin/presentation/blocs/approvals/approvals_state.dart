abstract class ApprovalsState {}

class ApprovalsInitial extends ApprovalsState {}

class ApprovalsLoading extends ApprovalsState {}

class ApprovalsLoaded extends ApprovalsState {
  final List<Map<String, dynamic>> pendingLocations;
  final Map<String, String> ownerNameById;

  ApprovalsLoaded({required this.pendingLocations, required this.ownerNameById});
}

class ApprovalsError extends ApprovalsState {
  final String message;
  ApprovalsError(this.message);
}
