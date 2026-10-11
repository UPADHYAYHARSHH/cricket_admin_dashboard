import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reviews_management_state.dart';

class ReviewsManagementCubit extends Cubit<ReviewsManagementState> {
  final SupabaseClient _supabase;

  ReviewsManagementCubit(this._supabase) : super(ReviewsManagementInitial());

  Future<void> fetchReviews() async {
    emit(ReviewsManagementLoading());
    try {
      final response = await _supabase
          .from('location_reviews')
          .select('*, locations(name, address, city)')
          .order('created_at', ascending: false);

      final rawReviews = List<Map<String, dynamic>>.from(response);

      // Collect user IDs to resolve author details safely
      final userIds = rawReviews
          .map((r) => r['user_id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> userLookup = {};
      if (userIds.isNotEmpty) {
        try {
          final usersResponse = await _supabase
              .from('users')
              .select('id, name, username, email')
              .inFilter('id', userIds);
          for (final u in (usersResponse as List)) {
            final uid = u['id']?.toString() ?? '';
            if (uid.isNotEmpty) {
              userLookup[uid] = Map<String, dynamic>.from(u as Map);
            }
          }
        } catch (_) {}
      }

      final reviews = rawReviews.map((r) {
        final review = Map<String, dynamic>.from(r);
        final uid = review['user_id']?.toString();
        if (uid != null && userLookup.containsKey(uid)) {
          review['users'] = userLookup[uid];
        }
        return review;
      }).toList();

      emit(ReviewsManagementLoaded(reviews));
    } catch (e) {
      emit(ReviewsManagementError(e.toString()));
    }
  }

  Future<void> deleteReview(String reviewId, String locationId) async {
    try {
      await _supabase.from('location_reviews').delete().eq('id', reviewId);

      // Recalculate average rating for the location
      if (locationId.isNotEmpty) {
        try {
          final remaining = await _supabase
              .from('location_reviews')
              .select('rating')
              .eq('location_id', locationId);
          final list = remaining as List;
          double avg = 0.0;
          if (list.isNotEmpty) {
            final sum = list.fold<double>(
              0.0,
              (prev, r) => prev + ((r['rating'] as num?)?.toDouble() ?? 0.0),
            );
            avg = sum / list.length;
          }
          await _supabase.from('locations').update({
            'rating': avg,
            'total_reviews': list.length,
          }).eq('id', locationId);
        } catch (_) {}
      }

      await fetchReviews();
    } catch (e) {
      emit(ReviewsManagementError('Failed to delete review: $e'));
    }
  }
}
