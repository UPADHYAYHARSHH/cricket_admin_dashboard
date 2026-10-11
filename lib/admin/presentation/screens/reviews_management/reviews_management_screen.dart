import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cricket_admin_panel/common/responsive/admin_page_scaffold.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/widgets/shimmer_placeholder.dart';
import '../../blocs/reviews/reviews_management_cubit.dart';
import '../../blocs/reviews/reviews_management_state.dart';

class ReviewsManagementScreen extends StatefulWidget {
  const ReviewsManagementScreen({super.key});

  @override
  State<ReviewsManagementScreen> createState() => _ReviewsManagementScreenState();
}

class _ReviewsManagementScreenState extends State<ReviewsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int? _selectedRating; // null means All

  @override
  void initState() {
    super.initState();
    context.read<ReviewsManagementCubit>().fetchReviews();
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

  void _setRatingFilter(int? rating) {
    if (_selectedRating == rating) return;
    setState(() => _selectedRating = rating);
  }

  bool _matchesFilter(Map<String, dynamic> r, String query, int? ratingFilter) {
    final rating = (r['rating'] as num?)?.round() ?? 0;
    if (ratingFilter != null && rating != ratingFilter) {
      return false;
    }

    if (query.isEmpty) return true;
    final needle = query.toLowerCase();

    final user = r['users'] as Map<String, dynamic>?;
    final userName = (user?['name'] ?? '').toString().toLowerCase();
    final username = (user?['username'] ?? '').toString().toLowerCase();
    final location = r['locations'] as Map<String, dynamic>?;
    final locName = (location?['name'] ?? '').toString().toLowerCase();
    final reviewText = (r['review_text'] ?? '').toString().toLowerCase();

    return userName.contains(needle) ||
        username.contains(needle) ||
        locName.contains(needle) ||
        reviewText.contains(needle);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  void _confirmDeleteReview(Map<String, dynamic> r, ReviewsManagementCubit cubit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete / Moderate Review'),
        content: const Text(
          'Are you sure you want to permanently delete this review? The turf rating and total review counts will automatically update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await cubit.deleteReview(
                r['id'].toString(),
                r['location_id']?.toString() ?? '',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review removed successfully.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showMediaDialog(List mediaUrls) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Attached Review Media'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: mediaUrls.map((url) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url.toString(),
                    width: 230,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 230,
                      height: 160,
                      color: Colors.grey.shade200,
                      child: const Center(child: Icon(Icons.broken_image_rounded)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReviewsManagementCubit>();

    return BlocBuilder<ReviewsManagementCubit, ReviewsManagementState>(
      builder: (context, state) {
        final List<Map<String, dynamic>>? reviews =
            state is ReviewsManagementLoaded ? state.reviews : null;

        return AdminPageScaffold(
          title: 'Reviews & Moderation',
          subtitle: reviews == null
              ? 'Loading reviews...'
              : '${reviews.length} customer reviews',
          actions: [
            IconButton(
              tooltip: 'Refresh reviews',
              onPressed: state is ReviewsManagementLoading
                  ? null
                  : () => cubit.fetchReviews(),
              icon: state is ReviewsManagementLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
          child: _buildBody(context, state, reviews, cubit),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReviewsManagementState state,
    List<Map<String, dynamic>>? reviews,
    ReviewsManagementCubit cubit,
  ) {
    if (state is ReviewsManagementError) {
      return AdminStateView(
        icon: Icons.error_outline_rounded,
        title: 'Could not load reviews',
        message: state.message,
        actionLabel: 'Retry',
        onAction: () => cubit.fetchReviews(),
      );
    }

    if (reviews == null) {
      return const ShimmerPage(
        children: [
          ShimmerSurface(child: ShimmerTable(rows: 8, columns: 5)),
        ],
      );
    }

    if (reviews.isEmpty) {
      return AdminStateView(
        icon: Icons.rate_review_outlined,
        title: 'No reviews found',
        message: 'No user reviews submitted yet.',
        actionLabel: 'Refresh',
        onAction: () => cubit.fetchReviews(),
      );
    }

    final filtered = reviews
        .where((r) => _matchesFilter(r, _query, _selectedRating))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Search ---
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _searchController,
            onChanged: _setQuery,
            decoration: InputDecoration(
              hintText: 'Search by customer, venue location, or review comment...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _setQuery('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        // --- Rating Filter Chips ---
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Stars', null, reviews.length),
                _buildFilterChip('5 ★', 5, reviews.where((r) => (r['rating'] as num?)?.round() == 5).length),
                _buildFilterChip('4 ★', 4, reviews.where((r) => (r['rating'] as num?)?.round() == 4).length),
                _buildFilterChip('3 ★', 3, reviews.where((r) => (r['rating'] as num?)?.round() == 3).length),
                _buildFilterChip('2 ★ (Low)', 2, reviews.where((r) => (r['rating'] as num?)?.round() == 2).length, color: Colors.orange),
                _buildFilterChip('1 ★ (Critical)', 1, reviews.where((r) => (r['rating'] as num?)?.round() == 1).length, color: Colors.red),
              ],
            ),
          ),
        ),

        // --- Table or Empty View ---
        if (filtered.isEmpty)
          const Expanded(
            child: Center(child: Text('No reviews match your selected filter.')),
          )
        else
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowColor: WidgetStateProperty.all(
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    columns: const [
                      DataColumn(label: Text('Venue / Location', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Rating', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Review Comment', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Media', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filtered.map((r) {
                      final user = r['users'] as Map<String, dynamic>?;
                      final userName = user?['name']?.toString() ?? 'User';
                      final username = user?['username']?.toString() ?? '';

                      final location = r['locations'] as Map<String, dynamic>?;
                      final locName = location?['name']?.toString() ?? '-';
                      final city = location?['city']?.toString() ?? '';

                      final rating = (r['rating'] as num?)?.toDouble() ?? 0.0;
                      final reviewText = r['review_text']?.toString() ?? '';
                      final media = r['media_urls'] as List? ?? [];

                      return DataRow(
                        cells: [
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(locName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (city.isNotEmpty)
                                  Text(city, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (username.isNotEmpty)
                                  Text('@$username', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 280,
                              child: Text(
                                reviewText.isNotEmpty ? reviewText : 'No comment provided',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            media.isNotEmpty
                                ? OutlinedButton.icon(
                                    icon: const Icon(Icons.image_outlined, size: 16),
                                    label: Text('${media.length} photos'),
                                    onPressed: () => _showMediaDialog(media),
                                  )
                                : const Text('-'),
                          ),
                          DataCell(Text(_formatDate(r['created_at']))),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                              tooltip: 'Delete / Moderate Review',
                              onPressed: () => _confirmDeleteReview(r, cubit),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int? rating, int count, {Color? color}) {
    final chipColor = color ?? const Color(0xFF0B8457);
    final isSelected = _selectedRating == rating;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.2,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : chipColor,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : chipColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : chipColor,
                ),
              ),
            ),
          ],
        ),
        selected: isSelected,
        selectedColor: chipColor,
        backgroundColor: chipColor.withValues(alpha: 0.08),
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isSelected ? chipColor : chipColor.withValues(alpha: 0.3)),
        ),
        onSelected: (_) => _setRatingFilter(rating),
      ),
    );
  }
}
