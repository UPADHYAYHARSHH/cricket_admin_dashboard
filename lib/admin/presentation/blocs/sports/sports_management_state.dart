import 'package:cricket_admin_panel/admin/data/models/sport_model.dart';
import 'package:cricket_admin_panel/admin/domain/analytics.dart';

abstract class SportsManagementState {}

class SportsManagementInitial extends SportsManagementState {}

class SportsManagementLoading extends SportsManagementState {}

class SportsManagementLoaded extends SportsManagementState {
  final List<SportModel> sports;
  final List<SportAnalytics> sportsAnalytics;
  final Map<String, SportAnalytics> analyticsBySportId;
  final int totalBookings;
  final double totalRevenue;

  SportsManagementLoaded(
    this.sports, {
    this.sportsAnalytics = const [],
    this.analyticsBySportId = const {},
    this.totalBookings = 0,
    this.totalRevenue = 0.0,
  });

  /// Finds analytics for a specific SportModel.
  SportAnalytics? analyticsFor(SportModel sport) {
    if (analyticsBySportId.containsKey(sport.id)) {
      return analyticsBySportId[sport.id];
    }
    final nameKey = sport.name.trim().toLowerCase();
    for (final a in sportsAnalytics) {
      if (a.id == sport.id ||
          a.slug.toLowerCase() == sport.slug.toLowerCase() ||
          a.name.toLowerCase() == nameKey) {
        return a;
      }
    }
    return null;
  }
}

class SportsManagementError extends SportsManagementState {
  final String message;
  SportsManagementError(this.message);
}
