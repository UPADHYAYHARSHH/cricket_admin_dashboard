abstract class AdminDashboardState {}

class AdminDashboardInitial extends AdminDashboardState {}

class AdminDashboardLoading extends AdminDashboardState {}

class AdminDashboardLoaded extends AdminDashboardState {
  final int pendingApprovalsCount;
  final int activeGroundsCount;
  final int ownersCount;
  final int usersCount;
  final double totalRevenue;
  final List<Map<String, dynamic>> recentPendingOwners;

  AdminDashboardLoaded({
    required this.pendingApprovalsCount,
    required this.activeGroundsCount,
    required this.ownersCount,
    required this.usersCount,
    required this.totalRevenue,
    required this.recentPendingOwners,
  });
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  AdminDashboardError(this.message);
}
