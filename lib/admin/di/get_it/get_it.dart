import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cricket_admin_panel/admin/data/repositories/booking_repository_impl.dart';
import 'package:cricket_admin_panel/admin/data/repositories/ground_repository_impl.dart';
import 'package:cricket_admin_panel/admin/data/repositories/location_repository_impl.dart';
import 'package:cricket_admin_panel/admin/data/repositories/owner_repository_impl.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/booking_repository.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/ground_repository.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/location_repository.dart';
import 'package:cricket_admin_panel/admin/domain/repositories/owner_repository.dart';
import 'package:cricket_admin_panel/admin/presentation/blocs/approvals/approvals_cubit.dart';
import 'package:cricket_admin_panel/admin/presentation/blocs/dashboard/admin_dashboard_cubit.dart';
import 'package:cricket_admin_panel/admin/presentation/blocs/locations/location_management_cubit.dart';
import 'package:cricket_admin_panel/admin/presentation/blocs/owners/owner_management_cubit.dart';
import 'package:cricket_admin_panel/admin/presentation/blocs/sports/sports_management_cubit.dart';

final getIt = GetIt.instance;

void initAdminDi() {
  final supabase = Supabase.instance.client;

  getIt.registerLazySingleton<SupabaseClient>(() => supabase);

  getIt.registerLazySingleton<AdminLocationRepository>(
    () => LocationRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<AdminGroundRepository>(
    () => GroundRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<AdminOwnerRepository>(
    () => OwnerRepositoryImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<AdminBookingRepository>(
    () => BookingRepositoryImpl(getIt<SupabaseClient>()),
  );

  getIt.registerFactory<ApprovalsCubit>(
    () => ApprovalsCubit(getIt<AdminLocationRepository>(), getIt<AdminOwnerRepository>()),
  );
  getIt.registerFactory<AdminDashboardCubit>(
    () => AdminDashboardCubit(
      getIt<AdminLocationRepository>(),
      getIt<AdminGroundRepository>(),
      getIt<AdminOwnerRepository>(),
      getIt<AdminBookingRepository>(),
    ),
  );
  getIt.registerFactory<LocationManagementCubit>(
    () => LocationManagementCubit(
      getIt<AdminLocationRepository>(),
      getIt<AdminGroundRepository>(),
      getIt<AdminOwnerRepository>(),
      getIt<AdminBookingRepository>(),
    ),
  );
  getIt.registerFactory<OwnerManagementCubit>(
    () => OwnerManagementCubit(
      getIt<AdminOwnerRepository>(),
      getIt<AdminBookingRepository>(),
      getIt<AdminLocationRepository>(),
    ),
  );
  getIt.registerFactory<SportsManagementCubit>(
    () => SportsManagementCubit(getIt<SupabaseClient>()),
  );
}
