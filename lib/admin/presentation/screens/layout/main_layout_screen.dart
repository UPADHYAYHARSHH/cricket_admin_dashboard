import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../common/constants/app_colors.dart';
import '../dashboard/dashboard_screen.dart';
import '../owner_management/owner_management_screen.dart';
import '../ground_management/ground_management_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const OwnerManagementScreen(),
    const GroundManagementScreen(),
    const Center(child: Text('Users')), // Placeholder
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final sidebar = Container(
      width: 250,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            'Admin Panel',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDarkGreen,
            ),
          ),
          const SizedBox(height: 32),
          _buildNavItem(
            icon: HugeIcons.strokeRoundedHome01,
            label: 'Dashboard',
            index: 0,
          ),
          _buildNavItem(
            icon: HugeIcons.strokeRoundedUserGroup,
            label: 'Owners',
            index: 1,
          ),
          _buildNavItem(
            icon: HugeIcons.strokeRoundedLocation01,
            label: 'Grounds',
            index: 2,
          ),
          _buildNavItem(
            icon: HugeIcons.strokeRoundedUser,
            label: 'Users',
            index: 3,
          ),
        ],
      ),
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop ? null : Drawer(child: sidebar),
      body: Row(
        children: [
          if (isDesktop) ...[
            sidebar,
            const VerticalDivider(width: 1, thickness: 1),
          ],
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({required dynamic icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        // Close drawer if on mobile
        if (MediaQuery.of(context).size.width < 800 && _scaffoldKey.currentState?.isDrawerOpen == true) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        color: isSelected ? AppColors.primaryDarkGreen.withOpacity(0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              color: isSelected ? AppColors.primaryDarkGreen : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primaryDarkGreen : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
