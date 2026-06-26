import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../common/constants/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _pendingOwners = 0;
  int _pendingGrounds = 0;
  int _activeGrounds = 0;
  int _totalUsers = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Changed 'owners' to 'users' based on schema hint
      final ownersResponse = await supabase.from('users').select('id, status').catchError((_) => []);
      final groundsResponse = await supabase.from('grounds').select('id, state').catchError((_) => []);
      final usersResponse = await supabase.from('users').select('id').catchError((_) => []);

      if (mounted) {
        setState(() {
          _pendingOwners = (ownersResponse as List).where((o) => o['status'] == 'pending').length;
          _pendingGrounds = (groundsResponse as List).where((g) => g['state'] == 'pending').length;
          _activeGrounds = (groundsResponse as List).where((g) => g['state'] == 'approved').length;
          _totalUsers = (usersResponse as List).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        leading: isDesktop ? null : IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            context.findRootAncestorStateOfType<ScaffoldState>()?.openDrawer();
          },
        ),
        title: Text(
          'Overview',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Statistics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    SizedBox(
                      width: 240,
                      child: _buildStatCard(
                        title: 'Pending Owners',
                        count: _pendingOwners,
                        icon: HugeIcons.strokeRoundedUserAdd01,
                        color: AppColors.accentOrange,
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: _buildStatCard(
                        title: 'Pending Grounds',
                        count: _pendingGrounds,
                        icon: HugeIcons.strokeRoundedLocationAdd01,
                        color: AppColors.accentOrange,
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: _buildStatCard(
                        title: 'Active Grounds',
                        count: _activeGrounds,
                        icon: HugeIcons.strokeRoundedLocation01,
                        color: AppColors.primaryLightGreen,
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: _buildStatCard(
                        title: 'Total Users',
                        count: _totalUsers,
                        icon: HugeIcons.strokeRoundedUserGroup,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required dynamic icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                  softWrap: true,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: HugeIcon(
                  icon: icon,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
