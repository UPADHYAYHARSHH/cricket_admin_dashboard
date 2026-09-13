import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../common/constants/app_colors.dart';

class AdminPayoutScreen extends StatefulWidget {
  const AdminPayoutScreen({super.key});

  @override
  State<AdminPayoutScreen> createState() => _AdminPayoutScreenState();
}

class _AdminPayoutScreenState extends State<AdminPayoutScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _withdrawals = [];
  bool _isLoading = true;
  String _filter = 'pending'; // pending, success, failed, rejected

  @override
  void initState() {
    super.initState();
    _fetchWithdrawals();
  }

  Future<void> _fetchWithdrawals() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('withdrawals')
          .select('*, owner_wallets(owner_id, total_earnings, available_balance)')
          .eq('status', _filter)
          .order('created_at', ascending: false);
          
      final withdrawals = List<Map<String, dynamic>>.from(response);
      
      if (withdrawals.isNotEmpty) {
        final ownerIds = withdrawals.map((w) => w['owner_id']).toSet().toList();
        final ownersResponse = await _supabase
            .from('owner_details')
            .select('id, owner_name, business_name, phone')
            .filter('id', 'in', ownerIds);
            
        final ownersMap = {for (var o in ownersResponse) o['id']: o};
        
        for (var w in withdrawals) {
          w['owner_details'] = ownersMap[w['owner_id']];
        }
      }
      
      if (mounted) {
        setState(() {
          _withdrawals = withdrawals;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching withdrawals: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processPayout(String withdrawalId, String action) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final res = await _supabase.functions.invoke(
        'process-payout',
        body: {'withdrawal_id': withdrawalId, 'action': action},
      );

      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['message'] ?? 'Processed successfully')),
        );
        _fetchWithdrawals();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Owner Withdrawals',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDarkGreen,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildFilterChip('Pending', 'pending'),
              const SizedBox(width: 8),
              _buildFilterChip('Processing', 'processing'),
              const SizedBox(width: 8),
              _buildFilterChip('Settled', 'success'),
              const SizedBox(width: 8),
              _buildFilterChip('Failed/Rejected', 'failed'),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _withdrawals.isEmpty
                    ? const Center(child: Text('No withdrawals found.'))
                    : ListView.builder(
                        itemCount: _withdrawals.length,
                        itemBuilder: (context, index) {
                          final w = _withdrawals[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Owner: ${w['owner_details']?['owner_name'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        if (w['owner_details']?['business_name'] != null)
                                          Text('${w['owner_details']['business_name']} - ${w['owner_details']['phone']}', style: TextStyle(color: Colors.grey.shade600)),
                                        const SizedBox(height: 8),
                                        Text('Owner ID: ${w['owner_id']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        const SizedBox(height: 8),
                                        Text('Amount: ₹${w['amount']}', style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('Requested: ${w['created_at'] != null ? DateFormat('MMM d, yyyy h:mm a').format(DateTime.parse(w['created_at']).toLocal()) : ''}', style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  if (w['status'] == 'pending') ...[
                                    ElevatedButton(
                                      onPressed: () => _processPayout(w['id'], 'approve'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      child: const Text('Approve & Pay', style: TextStyle(color: Colors.white)),
                                    ),
                                    const SizedBox(width: 12),
                                    TextButton(
                                      onPressed: () => _processPayout(w['id'], 'reject'),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Reject'),
                                    ),
                                  ] else
                                    Chip(label: Text(w['status'].toString().toUpperCase())),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value || (_filter == 'failed' && (value == 'rejected' || value == 'failed'));
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filter = value;
          });
          _fetchWithdrawals();
        }
      },
    );
  }
}
