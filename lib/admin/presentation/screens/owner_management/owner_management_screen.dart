import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../common/constants/app_colors.dart';

class OwnerManagementScreen extends StatefulWidget {
  const OwnerManagementScreen({super.key});

  @override
  State<OwnerManagementScreen> createState() => _OwnerManagementScreenState();
}

class _OwnerManagementScreenState extends State<OwnerManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _owners = [];

  @override
  void initState() {
    super.initState();
    _fetchOwners();
  }

  Future<void> _fetchOwners() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('*')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _owners = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching owners: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load owners: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String ownerId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'status': newStatus})
          .eq('id', ownerId);

      _fetchOwners(); // Refresh the list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Owner successfully $newStatus.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  void _showRejectDialog(String ownerId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Owner'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                // Ideally, we'd save the reason in a separate field or table, 
                // but for now we just update the status
                _updateStatus(ownerId, 'rejected');
              },
              child: const Text('Reject', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
          'Owner Management',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchOwners();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _owners.isEmpty
              ? const Center(child: Text('No owners found.'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    width: double.infinity,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Phone')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _owners.map((owner) {
                          final status = owner['status'] ?? 'pending';
                          return DataRow(
                            cells: [
                              DataCell(Text(owner['name'] ?? 'Unknown')),
                              DataCell(Text(owner['email'] ?? 'Unknown')),
                              DataCell(Text(owner['phone'] ?? 'Unknown')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    status.toString().toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    if (status == 'pending') ...[
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.primaryDarkGreen,
                                        ),
                                        onPressed: () => _updateStatus(owner['id'].toString(), 'approved'),
                                        child: const Text('Approve'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        onPressed: () => _showRejectDialog(owner['id'].toString()),
                                        child: const Text('Reject'),
                                      ),
                                    ] else ...[
                                      const Text('No pending actions', style: TextStyle(color: Colors.grey)),
                                    ]
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.primaryDarkGreen;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return AppColors.accentOrange;
    }
  }
}
