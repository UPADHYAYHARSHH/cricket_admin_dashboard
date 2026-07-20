import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cricket_admin_panel/admin/data/models/sport_model.dart';
import 'sports_management_state.dart';

class SportsManagementCubit extends Cubit<SportsManagementState> {
  final SupabaseClient _supabase;

  SportsManagementCubit(this._supabase) : super(SportsManagementInitial());

  Future<void> fetchSports() async {
    emit(SportsManagementLoading());
    try {
      final response = await _supabase
          .from('sports')
          .select()
          .order('sort_order', ascending: true);

      final sports = (response as List)
          .map((e) => SportModel.fromJson(e as Map<String, dynamic>))
          .toList();

      emit(SportsManagementLoaded(sports));
    } catch (e) {
      debugPrint('[SportsManagementCubit] Error fetching sports: $e');
      emit(SportsManagementError(e.toString()));
    }
  }

  Future<void> addSport({
    required String name,
    required String slug,
    String iconUrl = '',
    String localAsset = '',
    String color = '#1B5E20',
    int sortOrder = 0,
  }) async {
    try {
      await _supabase.from('sports').insert({
        'name': name,
        'slug': slug,
        'icon_url': iconUrl,
        'local_asset': localAsset,
        'color': color,
        'sort_order': sortOrder,
        'is_active': true,
      });
      await fetchSports();
    } catch (e) {
      debugPrint('[SportsManagementCubit] Error adding sport: $e');
      emit(SportsManagementError(e.toString()));
    }
  }

  Future<void> updateSport({
    required String id,
    String? name,
    String? slug,
    String? iconUrl,
    String? localAsset,
    String? color,
    int? sortOrder,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (slug != null) updates['slug'] = slug;
      if (iconUrl != null) updates['icon_url'] = iconUrl;
      if (localAsset != null) updates['local_asset'] = localAsset;
      if (color != null) updates['color'] = color;
      if (sortOrder != null) updates['sort_order'] = sortOrder;
      if (isActive != null) updates['is_active'] = isActive;

      await _supabase.from('sports').update(updates).eq('id', id);
      await fetchSports();
    } catch (e) {
      debugPrint('[SportsManagementCubit] Error updating sport: $e');
      emit(SportsManagementError(e.toString()));
    }
  }

  Future<void> deleteSport(String id) async {
    try {
      await _supabase.from('sports').delete().eq('id', id);
      await fetchSports();
    } catch (e) {
      debugPrint('[SportsManagementCubit] Error deleting sport: $e');
      emit(SportsManagementError(e.toString()));
    }
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await updateSport(id: id, isActive: isActive);
  }

  Future<void> updateSortOrder(String id, int sortOrder) async {
    await updateSport(id: id, sortOrder: sortOrder);
  }
}
