import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/admin/presentation/blocs/sports/sports_management_cubit.dart';
import 'package:cricket_admin_panel/admin/presentation/blocs/sports/sports_management_state.dart';
import 'package:cricket_admin_panel/admin/data/models/sport_model.dart';

class SportsManagementScreen extends StatefulWidget {
  const SportsManagementScreen({super.key});

  @override
  State<SportsManagementScreen> createState() => _SportsManagementScreenState();
}

class _SportsManagementScreenState extends State<SportsManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SportsManagementCubit>().fetchSports();
  }

  void _showAddSportDialog() {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final iconUrlCtrl = TextEditingController();
    final localAssetCtrl = TextEditingController();
    final colorCtrl = TextEditingController(text: '#1B5E20');
    final sortOrderCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Sport'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Box Cricket',
                ),
                onChanged: (v) {
                  slugCtrl.text = v
                      .toLowerCase()
                      .replaceAll(RegExp(r'[^a-z0-9]'), '_')
                      .replaceAll(RegExp(r'_+'), '_');
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: slugCtrl,
                decoration: const InputDecoration(
                  labelText: 'Slug',
                  hintText: 'e.g. box_cricket',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Icon URL (optional)',
                  hintText: 'https://...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: localAssetCtrl,
                decoration: const InputDecoration(
                  labelText: 'Local Asset (optional)',
                  hintText: 'assets/images/sports/sport1.png',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Color (hex)',
                  hintText: '#1B5E20',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sortOrderCtrl,
                decoration: const InputDecoration(
                  labelText: 'Sort Order',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              context.read<SportsManagementCubit>().addSport(
                    name: nameCtrl.text.trim(),
                    slug: slugCtrl.text.trim(),
                    iconUrl: iconUrlCtrl.text.trim(),
                    localAsset: localAssetCtrl.text.trim(),
                    color: colorCtrl.text.trim(),
                    sortOrder: int.tryParse(sortOrderCtrl.text) ?? 0,
                  );
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDarkGreen,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSportDialog(SportModel sport) {
    final nameCtrl = TextEditingController(text: sport.name);
    final slugCtrl = TextEditingController(text: sport.slug);
    final iconUrlCtrl = TextEditingController(text: sport.iconUrl);
    final localAssetCtrl = TextEditingController(text: sport.localAsset);
    final colorCtrl = TextEditingController(text: sport.color);
    final sortOrderCtrl = TextEditingController(text: sport.sortOrder.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Sport'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: slugCtrl,
                decoration: const InputDecoration(labelText: 'Slug'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconUrlCtrl,
                decoration: const InputDecoration(labelText: 'Icon URL (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: localAssetCtrl,
                decoration: const InputDecoration(labelText: 'Local Asset (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colorCtrl,
                decoration: const InputDecoration(labelText: 'Color (hex)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sortOrderCtrl,
                decoration: const InputDecoration(labelText: 'Sort Order'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<SportsManagementCubit>().updateSport(
                    id: sport.id,
                    name: nameCtrl.text.trim(),
                    slug: slugCtrl.text.trim(),
                    iconUrl: iconUrlCtrl.text.trim(),
                    localAsset: localAssetCtrl.text.trim(),
                    color: colorCtrl.text.trim(),
                    sortOrder: int.tryParse(sortOrderCtrl.text) ?? 0,
                  );
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDarkGreen,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(SportModel sport) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sport'),
        content: Text('Are you sure you want to delete "${sport.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<SportsManagementCubit>().deleteSport(sport.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    context.findRootAncestorStateOfType<ScaffoldState>()?.openDrawer(),
              ),
        title: Text(
          'Sports Management',
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _showAddSportDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Sport'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<SportsManagementCubit, SportsManagementState>(
        builder: (context, state) {
          if (state is SportsManagementLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SportsManagementError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        context.read<SportsManagementCubit>().fetchSports(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is SportsManagementLoaded) {
            final sports = state.sports;
            if (sports.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sports, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No sports found. Add your first sport!'),
                  ],
                ),
              );
            }

            return isDesktop
                ? _buildDataTable(sports, theme)
                : _buildMobileList(sports, theme);
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildDataTable(List<SportModel> sports, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Icon')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Slug')),
            DataColumn(label: Text('Color')),
            DataColumn(label: Text('Order')),
            DataColumn(label: Text('Active')),
            DataColumn(label: Text('Actions')),
          ],
          rows: sports.map((sport) {
            final colorValue = int.tryParse(
              sport.color.replaceFirst('#', '0xFF'),
            );
            return DataRow(cells: [
              DataCell(
                sport.iconUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          sport.iconUrl,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.sports),
                        ),
                      )
                    : Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorValue != null ? Color(colorValue) : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sports, color: Colors.white, size: 18),
                      ),
              ),
              DataCell(Text(sport.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(sport.slug)),
              DataCell(
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorValue != null ? Color(colorValue) : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              DataCell(Text(sport.sortOrder.toString())),
              DataCell(
                Switch(
                  value: sport.isActive,
                  activeThumbColor: AppColors.primaryDarkGreen,
                  onChanged: (val) {
                    context.read<SportsManagementCubit>().toggleActive(sport.id, val);
                  },
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      onPressed: () => _showEditSportDialog(sport),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_rounded, size: 20, color: Colors.red.shade400),
                      onPressed: () => _confirmDelete(sport),
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<SportModel> sports, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sports.length,
      itemBuilder: (context, index) {
        final sport = sports[index];
        final colorValue = int.tryParse(
          sport.color.replaceFirst('#', '0xFF'),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: sport.iconUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      sport.iconUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.sports),
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorValue != null ? Color(colorValue) : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sports, color: Colors.white, size: 22),
                  ),
            title: Text(sport.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(sport.slug),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: sport.isActive,
                  activeThumbColor: AppColors.primaryDarkGreen,
                  onChanged: (val) {
                    context.read<SportsManagementCubit>().toggleActive(sport.id, val);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  onPressed: () => _showEditSportDialog(sport),
                ),
                IconButton(
                  icon: Icon(Icons.delete_rounded, size: 20, color: Colors.red.shade400),
                  onPressed: () => _confirmDelete(sport),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
