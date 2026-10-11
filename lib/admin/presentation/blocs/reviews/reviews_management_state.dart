abstract class ReviewsManagementState {}

class ReviewsManagementInitial extends ReviewsManagementState {}

class ReviewsManagementLoading extends ReviewsManagementState {}

class ReviewsManagementLoaded extends ReviewsManagementState {
  final List<Map<String, dynamic>> reviews;
  ReviewsManagementLoaded(this.reviews);
}

class ReviewsManagementError extends ReviewsManagementState {
  final String message;
  ReviewsManagementError(this.message);
}
