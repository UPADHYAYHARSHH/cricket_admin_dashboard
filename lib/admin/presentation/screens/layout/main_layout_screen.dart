import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/responsive/admin_breakpoints.dart';
import 'admin_sidebar.dart';
import '../../../di/get_it/get_it.dart';
import '../../blocs/dashboard/admin_dashboard_cubit.dart';
import '../../blocs/dashboard/admin_dashboard_state.dart';
import '../../blocs/locations/location_management_cubit.dart';
import '../../blocs/owners/owner_management_cubit.dart';
import '../../blocs/approvals/approvals_cubit.dart';
import '../approvals/approvals_screen.dart';
import '../app_config/app_config_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../login/login_screen.dart';
import '../owner_management/owner_management_screen.dart';
import '../location_management/location_management_screen.dart';
import '../sports_management/sports_management_screen.dart';
import '../notification_management/notification_send_screen.dart';
import '../notification_management/notification_history_screen.dart';
import '../payouts/admin_payout_screen.dart';
import '../../blocs/sports/sports_management_cubit.dart';
import '../../blocs/notification/admin_notification_cubit.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedIndex = 0;
  late final AdminDashboardCubit _statsCubit;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _statsCubit = getIt<AdminDashboardCubit>()..fetchStats();
  }

  @override
  void dispose() {
    _statsCubit.close();
    super.dispose();
  }

  void _confirmLogout() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of the admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    });
  }

  void _openApprovals() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  List<Widget> get _screens => [
        BlocProvider.value(value: _statsCubit, child: DashboardScreen(onOpenApprovals: _openApprovals)),
        BlocProvider(create: (_) => getIt<ApprovalsCubit>(), child: const ApprovalsScreen()),
        BlocProvider(create: (_) => getIt<OwnerManagementCubit>(), child: const OwnerManagementScreen()),
        BlocProvider(create: (_) => getIt<LocationManagementCubit>(), child: const LocationManagementScreen()),
        BlocProvider(create: (_) => getIt<SportsManagementCubit>(), child: const SportsManagementScreen()),
        const Center(child: Text('Users')),
        BlocProvider(create: (_) => getIt<AdminNotificationCubit>(), child: const NotificationSendScreen()),
        BlocProvider(create: (_) => getIt<AdminNotificationCubit>()..fetchNotifications(), child: const NotificationHistoryScreen()),
        const AppConfigScreen(),
        const AdminPayoutScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    // Shared breakpoint instead of the previous hardcoded 800. The sidebar
    // becomes permanent from tablet width upwards; below that it is a drawer.
    final showPermanentSidebar =
        AdminBreakpoints.of(context).isAtLeastMedium;

    return BlocProvider.value(
      value: _statsCubit,
      child: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
        // Only the badge count matters here, so rebuild only when that changes
        // rather than on every dashboard state transition.
        buildWhen: (previous, current) =>
            _pendingApprovals(previous) != _pendingApprovals(current),
        builder: (context, state) {
          final pending = _pendingApprovals(state);

          return Scaffold(
            key: _scaffoldKey,
            drawer: showPermanentSidebar
                ? null
                : Drawer(
                    child: AdminSidebar(
                      isDrawer: true,
                      pendingApprovals: pending,
                      selectedIndex: _selectedIndex,
                      onSelect: (index) {
                        setState(() => _selectedIndex = index);
                        if (_scaffoldKey.currentState?.isDrawerOpen == true) {
                          Navigator.of(context).pop();
                        }
                      },
                      onLogout: _confirmLogout,
                    ),
                  ),
            body: Row(
              children: [
                if (showPermanentSidebar) ...[
                  AdminSidebar(
                    pendingApprovals: pending,
                    selectedIndex: _selectedIndex,
                    onSelect: (index) => setState(() => _selectedIndex = index),
                    onLogout: _confirmLogout,
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                ],
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Pending approval count for the sidebar badge, or zero when not loaded.
  static int _pendingApprovals(AdminDashboardState state) =>
      state is AdminDashboardLoaded ? state.pendingApprovalsCount : 0;
}
