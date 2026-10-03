import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';
import 'package:cricket_admin_panel/common/utils/formatters.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/widgets/shimmer_placeholder.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import '../../blocs/locations/location_management_cubit.dart';
import 'widgets/location_detail_widgets.dart';

/// Grounds and booking history for a single location.
///
/// The data loading, the ground availability guard and
/// `toggleGroundAvailable` are unchanged. What changed: `intl` and the
/// deprecated `withOpacity` calls are gone, ids are read with `toString()`
/// instead of a hard `as String` cast, the booking table has a phone layout,
/// and each tab reports totals.
class LocationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> location;
  final String ownerName;
  final VoidCallback? onBack;

  const LocationDetailScreen({
    super.key,
    required this.location,
    required this.ownerName,
    this.onBack,
  });

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _grounds = [];
  List<Map<String, dynamic>> _bookings = [];

  bool get _locationIsLive =>
      widget.location['is_active'] != false &&
      widget.location['documents_verified'] == true;

  String get _locationId => widget.location['id']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cubit = context.read<LocationManagementCubit>();
      final results = await Future.wait([
        cubit.fetchGroundsForLocation(_locationId),
        cubit.fetchBookingHistory(_locationId),
      ]);
      if (!mounted) return;
      setState(() {
        _grounds = results[0];
        _bookings = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleGround(String groundId, bool value) async {
    if (value && !_locationIsLive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Approve and activate the location before enabling its grounds.',
          ),
          backgroundColor: AppColors.accentOrange,
        ),
      );
      return;
    }

    if (groundId.isEmpty) return;

    await context.read<LocationManagementCubit>().toggleGroundAvailable(
          groundId,
          value,
        );
    if (!mounted) return;
    setState(() {
      _grounds = _grounds
          .map((g) => g['id']?.toString() == groundId
              ? {...g, 'is_available': value}
              : g)
          .toList();
    });
  }

  int get _availableGrounds =>
      _grounds.where((g) => g['is_available'] != false).length;

  int get _bookingRevenue => _bookings.fold<int>(
        0,
        (sum, b) => sum + asInt(b['amount'] ?? b['total_amount']),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVerified = widget.location['documents_verified'] == true;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back to locations',
            onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (widget.location['address'] as String?)?.trim().isNotEmpty == true
                    ? (widget.location['address'] as String).trim()
                    : 'Location',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                widget.ownerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Grounds'),
              Tab(text: 'Bookings'),
            ],
          ),
        ),
        body: _buildBody(context, isVerified),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isVerified) {
    if (_loading) {
      return const ShimmerPage(
        children: [
          ShimmerTileGrid(count: 3),
          SizedBox(height: 14),
          ShimmerCardList(count: 3, lineCount: 3, avatar: false),
        ],
      );
    }

    if (_error != null) {
      return AdminStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load this location',
        message: _error,
        actionLabel: 'Retry',
        onAction: _load,
        tone: AdminStateTone.error,
      );
    }

    return Column(
      children: [
        if (!_locationIsLive) LocationVisibilityBanner(isVerified: isVerified),
        Expanded(
          child: TabBarView(
            children: [
              _buildGroundsTab(context),
              _buildBookingsTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroundsTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AdminBreakpoints.pagePadding(context),
          14,
          AdminBreakpoints.pagePadding(context),
          24,
        ),
        children: [
          LocationDetailSummary(
            tiles: [
              (
                label: 'Total grounds',
                value: '${_grounds.length}',
                icon: Icons.sports_cricket_rounded,
                color: AppColors.primaryDarkGreen
              ),
              (
                label: 'Bookable',
                value: '$_availableGrounds',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.primaryLightGreen
              ),
              (
                label: 'Disabled',
                value: '${_grounds.length - _availableGrounds}',
                icon: Icons.pause_circle_outline_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_grounds.isEmpty)
            AdminSurface(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: LocationTabEmpty(
                icon: Icons.sports_cricket_outlined,
                title: 'No grounds yet',
                message: 'The owner has not added any grounds at this venue.',
              ),
            )
          else
            for (final ground in _grounds) ...[
              GroundCard(ground: ground, onToggle: _toggleGround),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _buildBookingsTab(BuildContext context) {
    final useTable = AdminBreakpoints.hasTableSpace(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AdminBreakpoints.pagePadding(context),
          14,
          AdminBreakpoints.pagePadding(context),
          24,
        ),
        children: [
          LocationDetailSummary(
            tiles: [
              (
                label: 'Bookings',
                value: '${_bookings.length}',
                icon: Icons.event_available_rounded,
                color: AppColors.primaryDarkGreen
              ),
              (
                label: 'Booking value',
                value: '₹${formatInr(_bookingRevenue)}',
                icon: Icons.payments_rounded,
                color: AppColors.goldenYellow
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_bookings.isEmpty)
            AdminSurface(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: LocationTabEmpty(
                icon: Icons.event_busy_outlined,
                title: 'No bookings yet',
                message: 'Bookings made at this venue will be listed here.',
              ),
            )
          else if (useTable)
            LocationBookingTable(bookings: _bookings)
          else
            Column(
              children: [
                for (final booking in _bookings) ...[
                  LocationBookingCard(booking: booking),
                  const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
