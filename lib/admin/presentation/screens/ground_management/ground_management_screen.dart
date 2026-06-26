import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../common/constants/app_colors.dart';

class GroundManagementScreen extends StatefulWidget {
  const GroundManagementScreen({super.key});

  @override
  State<GroundManagementScreen> createState() => _GroundManagementScreenState();
}

class _GroundManagementScreenState extends State<GroundManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _grounds = [];

  @override
  void initState() {
    super.initState();
    _fetchGrounds();
  }

  Future<void> _fetchGrounds() async {
    try {
      // Assuming 'grounds' table and joining with 'owners' to get the owner name
      // This query syntax assumes standard foreign key relations in Supabase
      final response = await Supabase.instance.client
          .from('grounds')
          .select('*, owner_id') 
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _grounds = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching grounds: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load grounds: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String groundId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('grounds')
          .update({'state': newStatus})
          .eq('id', groundId);

      _fetchGrounds(); // Refresh
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ground successfully $newStatus.')),
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

  void _showRejectDialog(String groundId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Ground'),
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
                _updateStatus(groundId, 'rejected');
              },
              child: const Text('Reject', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showGroundDetailsDialog(Map<String, dynamic> ground) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(ground['name'] ?? ground['ground_name'] ?? 'Ground Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: ground.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.key}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(e.value?.toString() ?? 'N/A'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if ((ground['state'] ?? 'pending') == 'pending') ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  _showRejectDialog(ground['id'].toString());
                },
                child: const Text('Reject', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDarkGreen),
                onPressed: () {
                  Navigator.pop(context);
                  _updateStatus(ground['id'].toString(), 'approved');
                },
                child: const Text('Approve', style: TextStyle(color: Colors.white)),
              ),
            ]
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
          'Ground Listings Management',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchGrounds();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _grounds.isEmpty
              ? const Center(child: Text('No grounds found.'))
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
                          DataColumn(label: Text('Ground Name')),
                          DataColumn(label: Text('Owner ID')),
                          DataColumn(label: Text('Location')),
                          DataColumn(label: Text('State')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _grounds.map((ground) {
                          final state = ground['state'] ?? 'pending';
                          return DataRow(
                            cells: [
                              DataCell(Text(ground['name'] ?? ground['ground_name'] ?? 'Unknown')),
                              DataCell(Text(ground['owner_id']?.toString() ?? 'N/A')),
                              DataCell(Text(ground['location'] ?? ground['address'] ?? 'Unknown')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(state).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    state.toString().toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(state),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.blue,
                                      ),
                                      onPressed: () => _showGroundDetailsDialog(ground),
                                      child: const Text('View Details'),
                                    ),
                                    const SizedBox(width: 8),
                                    if (state == 'pending') ...[
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.primaryDarkGreen,
                                        ),
                                        onPressed: () => _updateStatus(ground['id'].toString(), 'approved'),
                                        child: const Text('Approve'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        onPressed: () => _showRejectDialog(ground['id'].toString()),
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
