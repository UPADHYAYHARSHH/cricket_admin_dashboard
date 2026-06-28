abstract class OwnerManagementState {}

class OwnerManagementInitial extends OwnerManagementState {}

class OwnerManagementLoading extends OwnerManagementState {}

/// One row's worth of computed breakdown for an owner.
class OwnerSummary {
  final Map<String, dynamic> owner;
  final int locationsCount;
  final int bookingsCount;
  final double revenue;

  const OwnerSummary({
    required this.owner,
    required this.locationsCount,
    required this.bookingsCount,
    required this.revenue,
  });
}

class OwnerManagementLoaded extends OwnerManagementState {
  final List<OwnerSummary> owners;
  OwnerManagementLoaded(this.owners);
}

class OwnerManagementError extends OwnerManagementState {
  final String message;
  OwnerManagementError(this.message);
}
