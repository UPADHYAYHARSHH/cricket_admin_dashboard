import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../common/constants/app_colors.dart';
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
      ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return BlocProvider.value(
      value: _statsCubit,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: isDesktop ? null : Drawer(child: _Sidebar(
          selectedIndex: _selectedIndex,
          onSelect: (index) {
            setState(() => _selectedIndex = index);
            if (MediaQuery.of(context).size.width < 800 && _scaffoldKey.currentState?.isDrawerOpen == true) {
              Navigator.of(context).pop();
            }
          },
          onLogout: _confirmLogout,
        )),
        body: Row(
          children: [
            if (isDesktop) ...[
              _Sidebar(
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
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 28),
                    Text(
                      'Admin Panel',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDarkGreen,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
                      builder: (context, state) {
                        final owners = state is AdminDashboardLoaded ? state.ownersCount : null;
                        final users = state is AdminDashboardLoaded ? state.usersCount : null;
                        final revenue = state is AdminDashboardLoaded ? state.totalRevenue : null;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDarkGreen.withValues(alpha:0.06),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                _SidebarStatRow(
                                  icon: HugeIcons.strokeRoundedUserGroup,
                                  label: 'Owners',
                                  value: owners?.toString() ?? '—',
                                ),
                                const SizedBox(height: 10),
                                _SidebarStatRow(
                                  icon: HugeIcons.strokeRoundedUser,
                                  label: 'Users',
                                  value: users?.toString() ?? '—',
                                ),
                                const SizedBox(height: 10),
                                _SidebarStatRow(
                                  icon: HugeIcons.strokeRoundedMoneyBag01,
                                  label: 'Revenue',
                                  value: revenue != null ? '₹${revenue.toInt()}' : '—',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildNavItem(context, icon: HugeIcons.strokeRoundedHome01, label: 'Dashboard', index: 0),
                    BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
                      builder: (context, state) {
                        final pending = state is AdminDashboardLoaded ? state.pendingApprovalsCount : 0;
                        return _buildNavItem(
                          context,
                          icon: HugeIcons.strokeRoundedLocationAdd01,
                          label: 'Approvals',
                          badge: pending > 0 ? pending : null,
                          index: 1,
                        );
                      },
                    ),
                    _buildNavItem(context, icon: HugeIcons.strokeRoundedUserGroup, label: 'Owner Verification', index: 2),
                    _buildNavItem(context, icon: HugeIcons.strokeRoundedLocation01, label: 'Location Verification', index: 3),
                    _buildNavItem(context, icon: HugeIcons.strokeRoundedCricketBat, label: 'Sports', index: 4),
                    _buildNavItem(context, icon: HugeIcons.strokeRoundedUser, label: 'Users', index: 5),
                    _buildNavItem(context, icon: HugeIcons.strokeRoundedNotification03, label: 'Send Notification', index: 6),
                    _buildNavItem(context, icon: HugeIcons.strokeRoundedClock01, label: 'Notification History', index: 7),
                    const Divider(indent: 16, endIndent: 16),
                    _buildNavItem(context, icon: HugeIcons.strokeRoundedSettings01, label: 'App Config', index: 8),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            InkWell(
              onTap: onLogout,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedLogout01, color: Colors.red.shade400),
                    const SizedBox(width: 16),
                    Text(
                      'Log Out',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.red.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required dynamic icon, required String label, required int index, int? badge}) {
    final isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onSelect(index),
      child: Container(
        color: isSelected ? AppColors.primaryDarkGreen.withValues(alpha:0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              color: isSelected ? AppColors.primaryDarkGreen : Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primaryDarkGreen : Theme.of(context).colorScheme.onSurface.withValues(alpha:0.8),
                    ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }


}

class _SidebarStatRow extends StatelessWidget {
  final dynamic icon;
  final String label;
  final String value;

  const _SidebarStatRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HugeIcon(icon: icon, size: 16, color: AppColors.primaryDarkGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDarkGreen)),
      ],
    );
  }
}
