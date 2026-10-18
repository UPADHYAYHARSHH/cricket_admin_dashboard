import 'package:cricket_admin_panel/admin/data/models/sport_model.dart';
import 'package:cricket_admin_panel/admin/domain/analytics.dart';

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
  final List<SportAnalytics> sportsAnalytics;
  final List<DailyTrendPoint> recentTrend;
  final Map<String, int> statusDistribution;
  final int totalBookingsCount;
  final List<Map<String, dynamic>> allBookings;
  final List<SportModel> sportsCatalogue;

  AdminDashboardLoaded({
    required this.pendingApprovalsCount,
    required this.activeGroundsCount,
    required this.ownersCount,
    required this.usersCount,
    required this.totalRevenue,
    required this.recentPendingOwners,
    this.sportsAnalytics = const [],
    this.recentTrend = const [],
    this.statusDistribution = const {},
    this.totalBookingsCount = 0,
    this.allBookings = const [],
    this.sportsCatalogue = const [],
  });
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  AdminDashboardError(this.message);
}
