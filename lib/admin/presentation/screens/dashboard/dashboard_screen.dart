import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../common/constants/app_colors.dart';
import '../../blocs/dashboard/admin_dashboard_cubit.dart';
import '../../blocs/dashboard/admin_dashboard_state.dart';


class DashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenApprovals;

  const DashboardScreen({super.key, this.onOpenApprovals});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminDashboardCubit>().fetchStats();
  }

  void _openApprovals() {
    widget.onOpenApprovals?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => context.findRootAncestorStateOfType<ScaffoldState>()?.openDrawer(),
              ),
        title: Text(
          'Overview',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
        builder: (context, state) {
          if (state is AdminDashboardLoading || state is AdminDashboardInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminDashboardError) {
            return Center(child: Text(state.message));
          }

          final loaded = state as AdminDashboardLoaded;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Statistics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      SizedBox(
                        width: 240,
                        child: _StatCard(
                          title: 'Pending Approvals',
                          value: '${loaded.pendingApprovalsCount}',
                          icon: HugeIcons.strokeRoundedLocationAdd01,
                          color: AppColors.accentOrange,
                          onTap: _openApprovals,
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: _StatCard(
                          title: 'Active Grounds',
                          value: '${loaded.activeGroundsCount}',
                          icon: HugeIcons.strokeRoundedLocation01,
                          color: AppColors.primaryLightGreen,
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: _StatCard(
                          title: 'Owners',
                          value: '${loaded.ownersCount}',
                          icon: HugeIcons.strokeRoundedUserGroup,
                          color: AppColors.primaryDarkGreen,
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: _StatCard(
                          title: 'Users',
                          value: '${loaded.usersCount}',
                          icon: HugeIcons.strokeRoundedUser,
                          color: AppColors.primaryDarkGreen,
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: _StatCard(
                          title: 'Total Revenue',
                          value: '₹${loaded.totalRevenue.toInt()}',
                          icon: HugeIcons.strokeRoundedMoneyBag01,
                          color: AppColors.goldenYellow,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pending Approvals',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(onPressed: _openApprovals, child: const Text('View All')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (loaded.recentPendingOwners.isEmpty)
                    Text('No pending owner approvals.', style: Theme.of(context).textTheme.bodyMedium)
                  else
                    ...loaded.recentPendingOwners.map((owner) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          children: [
                            const HugeIcon(icon: HugeIcons.strokeRoundedUser02, color: AppColors.accentOrange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${owner['owner_name'] ?? 'Owner'} • ${owner['business_name'] ?? ''}',
                              ),
                            ),
                            TextButton(onPressed: _openApprovals, child: const Text('Review')),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final dynamic icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyMedium, softWrap: true)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
                  child: HugeIcon(icon: icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
