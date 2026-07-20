import 'package:cricket_admin_panel/admin/data/models/sport_model.dart';

abstract class SportsManagementState {}

class SportsManagementInitial extends SportsManagementState {}

class SportsManagementLoading extends SportsManagementState {}

class SportsManagementLoaded extends SportsManagementState {
  final List<SportModel> sports;
  SportsManagementLoaded(this.sports);
}

class SportsManagementError extends SportsManagementState {
  final String message;
  SportsManagementError(this.message);
}
