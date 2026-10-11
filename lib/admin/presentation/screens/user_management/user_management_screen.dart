import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_admin_panel/common/responsive/admin_page_scaffold.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/widgets/shimmer_placeholder.dart';
import '../../blocs/users/user_management_cubit.dart';
import '../../blocs/users/user_management_state.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<UserManagementCubit>().fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    if (_query == value) return;
    setState(() => _query = value);
  }

  bool _matchesQuery(Map<String, dynamic> user, String query) {
    if (query.isEmpty) return true;
    final needle = query.toLowerCase();

    final name = (user['name'] ?? '').toString().toLowerCase();
    final username = (user['username'] ?? '').toString().toLowerCase();
    final email = (user['email'] ?? '').toString().toLowerCase();
    final phone = (user['phone'] ?? '').toString().toLowerCase();

    return name.contains(needle) || username.contains(needle) || email.contains(needle) || phone.contains(needle);
  }

  void _showUserDetailDialog(Map<String, dynamic> u, UserManagementCubit cubit) {
    final id = u['id']?.toString() ?? '-';
    final name = u['name']?.toString() ?? '-';
    final username = u['username']?.toString() ?? '-';
    final email = u['email']?.toString() ?? '-';
    final phone = u['phone']?.toString() ?? '-';
    final isOwner = u['is_owner'] == true;
    final source = u['source']?.toString() ?? 'supabase';
    final createdAt = u['created_at']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0B8457).withValues(alpha: 0.1),
              child: const Icon(Icons.person_rounded, color: Color(0xFF0B8457)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isNotEmpty ? name : 'User Profile',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (username.isNotEmpty && username != '-')
                    Text(
                      '@$username',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('User ID', id),
              _buildInfoRow('Email Address', email),
              _buildInfoRow('Phone Number', phone),
              _buildInfoRow('Account Role', isOwner ? 'Turf Owner / Partner' : 'Customer'),
              _buildInfoRow('Auth Provider', source.toUpperCase()),
              if (createdAt != null) _buildInfoRow('Registered At', createdAt),
              const Divider(height: 24),
              const Text(
                'Customer Support & Rewards Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                'Credit loyalty coins directly to this user account for customer appeasement, refund compensation, or promotional credit.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.card_giftcard_rounded, size: 18, color: Color(0xFF0B8457)),
            label: const Text('Grant Loyalty Coins'),
            onPressed: () {
              Navigator.pop(ctx);
              _showGrantCoinsDialog(u, cubit);
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showGrantCoinsDialog(Map<String, dynamic> u, UserManagementCubit cubit) {
    final pointsCtrl = TextEditingController(text: '100');
    final reasonCtrl = TextEditingController(text: 'Customer appreciation');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Grant Loyalty Coins'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grant coins to ${u['name'] ?? u['email']} (${u['id']}):'),
            const SizedBox(height: 16),
            TextField(
              controller: pointsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Coin Amount',
                suffixText: 'Coins',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason / Note',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final pts = int.tryParse(pointsCtrl.text.trim()) ?? 0;
              final r = reasonCtrl.text.trim();
              if (pts > 0) {
                Navigator.pop(ctx);
                await cubit.grantLoyaltyPoints(u['id'].toString(), pts, r);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully credited $pts coins to user!')),
                  );
                }
              }
            },
            child: const Text('Grant Coins'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UserManagementCubit>();

    return BlocBuilder<UserManagementCubit, UserManagementState>(
      builder: (context, state) {
        final List<Map<String, dynamic>>? users = state is UserManagementLoaded ? state.users : null;

        return AdminPageScaffold(
          title: 'User Management',
          subtitle: users == null ? 'Loading users...' : '${users.length} registered users',
          actions: [
            IconButton(
              tooltip: 'Refresh users',
              onPressed: state is UserManagementLoading ? null : () => cubit.fetchUsers(),
              icon: state is UserManagementLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
          child: _buildBody(context, state, users, cubit),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, UserManagementState state, List<Map<String, dynamic>>? users, UserManagementCubit cubit) {
    if (state is UserManagementError) {
      return AdminStateView(
        icon: Icons.error_outline_rounded,
        title: 'Could not load users',
        message: state.message,
        actionLabel: 'Retry',
        onAction: () => cubit.fetchUsers(),
      );
    }

    if (users == null) {
      return const ShimmerPage(
        children: [
          ShimmerSurface(child: ShimmerTable(rows: 8, columns: 4)),
        ],
      );
    }

    if (users.isEmpty) {
      return AdminStateView(
        icon: Icons.people_alt_rounded,
        title: 'No users found',
        message: 'No users have registered yet.',
        actionLabel: 'Refresh',
        onAction: () => cubit.fetchUsers(),
      );
    }

    final visible = users.where((u) => _matchesQuery(u, _query)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            controller: _searchController,
            onChanged: _setQuery,
            decoration: const InputDecoration(
              hintText: 'Search by name, username, or email...',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        if (visible.isEmpty)
          const Expanded(
            child: Center(child: Text('No users match your search.')),
          )
        else
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
                  columns: const [
                    DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Source', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: visible.map((u) {
                    final isOwner = u['is_owner'] == true;
                    final source = (u['source'] ?? 'supabase').toString();

                    Color sourceColor;
                    String sourceLabel;
                    if (source == 'both') {
                      sourceColor = Colors.purple;
                      sourceLabel = 'Both';
                    } else if (source == 'firebase') {
                      sourceColor = Colors.amber.shade800;
                      sourceLabel = 'Firebase';
                    } else {
                      sourceColor = Colors.teal.shade700;
                      sourceLabel = 'Supabase';
                    }

                    return DataRow(
                      onSelectChanged: (_) => _showUserDetailDialog(u, cubit),
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                u['name']?.toString().isNotEmpty == true ? u['name'].toString() : '-',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (u['username'] != null && u['username'].toString().isNotEmpty)
                                Text(
                                  '@${u['username']}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                        ),
                        DataCell(Text(u['email']?.toString().isNotEmpty == true ? u['email'].toString() : '-')),
                        DataCell(Text(u['phone']?.toString().isNotEmpty == true ? u['phone'].toString() : '-')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOwner ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isOwner ? 'Owner' : 'User',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isOwner ? Colors.blue.shade700 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: sourceColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              sourceLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: sourceColor,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.manage_accounts_outlined, size: 20),
                            tooltip: 'Inspect User & Actions',
                            onPressed: () => _showUserDetailDialog(u, cubit),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
