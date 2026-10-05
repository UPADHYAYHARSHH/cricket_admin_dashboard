import 'package:flutter/foundation.dart';

@immutable
abstract class UserManagementState {}

class UserManagementInitial extends UserManagementState {}

class UserManagementLoading extends UserManagementState {}

class UserManagementLoaded extends UserManagementState {
  final List<Map<String, dynamic>> users;
  UserManagementLoaded(this.users);
}

class UserManagementError extends UserManagementState {
  final String message;
  UserManagementError(this.message);
}
