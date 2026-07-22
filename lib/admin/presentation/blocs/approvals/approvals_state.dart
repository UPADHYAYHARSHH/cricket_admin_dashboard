abstract class ApprovalsState {}

class ApprovalsInitial extends ApprovalsState {}

class ApprovalsLoading extends ApprovalsState {}

class ApprovalsLoaded extends ApprovalsState {
  final List<Map<String, dynamic>> pendingOwners;

  ApprovalsLoaded({required this.pendingOwners});
}

class ApprovalsError extends ApprovalsState {
  final String message;
  ApprovalsError(this.message);
}
