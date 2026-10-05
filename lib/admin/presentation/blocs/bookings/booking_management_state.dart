import 'package:flutter/foundation.dart';

@immutable
abstract class BookingManagementState {}

class BookingManagementInitial extends BookingManagementState {}

class BookingManagementLoading extends BookingManagementState {}

class BookingManagementLoaded extends BookingManagementState {
  final List<Map<String, dynamic>> bookings;
  BookingManagementLoaded(this.bookings);
}

class BookingManagementError extends BookingManagementState {
  final String message;
  BookingManagementError(this.message);
}
