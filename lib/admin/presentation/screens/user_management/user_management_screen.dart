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

    return name.contains(needle) || username.contains(needle) || email.contains(needle);
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
                  headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Username')),
                    DataColumn(label: Text('Role')),
                  ],
                  rows: visible.map((u) {
                    final isOwner = u['is_owner'] == true;
                    return DataRow(
                      cells: [
                        DataCell(Text(u['name']?.toString() ?? '-')),
                        DataCell(Text(u['email']?.toString() ?? '-')),
                        DataCell(Text(u['username']?.toString() ?? '-')),
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
