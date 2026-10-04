import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cricket_admin_panel/common/responsive/admin_page_scaffold.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';
import 'package:cricket_admin_panel/common/widgets/admin_state_view.dart';
import 'package:cricket_admin_panel/common/widgets/shimmer_placeholder.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/common/services/admin_supabase_client.dart';
import 'package:cricket_admin_panel/common/services/firebase_remote_config_sync_service.dart';
import 'widgets/config_widgets.dart';

/// Remote configuration for the owner and user apps.
///
/// The 24 upserts, their keys and values, the payload published to Firebase and
/// the validation rules are unchanged. What changed: the duplicated
/// `remoteConfigParams` map is now built in one place so the save path and the
/// publish path cannot drift, and the fixed `340px` card grid is responsive.
///
/// Note: this screen talks to Supabase through [AdminSupabaseClient] rather
/// than a cubit, unlike every other screen in the app. That is preserved here
/// to avoid changing behaviour.
class AppConfigScreen extends StatefulWidget {
  const AppConfigScreen({super.key});

  @override
  State<AppConfigScreen> createState() => _AppConfigScreenState();
}

class _AppConfigScreenState extends State<AppConfigScreen> {
  final _platformFeeCtrl = TextEditingController();
  final _commissionRateCtrl = TextEditingController();
  bool _commissionIsPercentage = true;
  bool _underMaintenance = false;
  bool _userUnderMaintenance = false;

  // Customer Booking Fees & Taxes
  final _convenienceFeeCtrl = TextEditingController(text: '20');
  bool _convenienceFeeIsFree = true;
  final _gstRateCtrl = TextEditingController(text: '0');
  bool _gstIsPercentage = true;
  bool _gstIsFree = false;

  final _androidMinVersionCtrl = TextEditingController();
  final _iosMinVersionCtrl = TextEditingController();
  final _androidStoreUrlCtrl = TextEditingController();
  final _iosStoreUrlCtrl = TextEditingController();

  final _userAndroidMinVersionCtrl = TextEditingController();
  final _userIosMinVersionCtrl = TextEditingController();
  final _userAndroidStoreUrlCtrl = TextEditingController();
  final _userIosStoreUrlCtrl = TextEditingController();

  String? _serviceAccountJson;
  String? _firebaseToken;

  // Cancellation & Coin Recovery Policy
  final _tier1HoursCtrl = TextEditingController(text: '24');
  final _tier1PercentCtrl = TextEditingController(text: '100');
  final _tier2HoursCtrl = TextEditingController(text: '12');
  final _tier2PercentCtrl = TextEditingController(text: '75');
  final _tier3HoursCtrl = TextEditingController(text: '3');
  final _tier3PercentCtrl = TextEditingController(text: '50');
  final _tier4PercentCtrl = TextEditingController(text: '25');
  final _coinExpiryDaysCtrl = TextEditingController(text: '60');
  final _maxCoinRedemptionCtrl = TextEditingController(text: '40');

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _platformFeeCtrl.dispose();
    _commissionRateCtrl.dispose();
    _convenienceFeeCtrl.dispose();
    _gstRateCtrl.dispose();
    _androidMinVersionCtrl.dispose();
    _iosMinVersionCtrl.dispose();
    _androidStoreUrlCtrl.dispose();
    _iosStoreUrlCtrl.dispose();
    _userAndroidMinVersionCtrl.dispose();
    _userIosMinVersionCtrl.dispose();
    _userAndroidStoreUrlCtrl.dispose();
    _userIosStoreUrlCtrl.dispose();

    _tier1HoursCtrl.dispose();
    _tier1PercentCtrl.dispose();
    _tier2HoursCtrl.dispose();
    _tier2PercentCtrl.dispose();
    _tier3HoursCtrl.dispose();
    _tier3PercentCtrl.dispose();
    _tier4PercentCtrl.dispose();
    _coinExpiryDaysCtrl.dispose();
    _maxCoinRedemptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final rows = await Supabase.instance.client
          .from('app_config')
          .select('key, value');

      for (final row in rows as List<dynamic>) {
        final key = row['key']?.toString();
        final val = row['value']?.toString() ?? '';
        switch (key) {
          case 'platform_fee':
          case 'convenience_fee':
            _convenienceFeeCtrl.text = val;
            _platformFeeCtrl.text = val;
            break;
          case 'commission_rate':
            _commissionRateCtrl.text = val;
            break;
          case 'commission_is_percentage':
            _commissionIsPercentage = val == 'true' || val == '1';
            break;
          case 'convenience_fee_is_free':
          case 'platform_fee_is_free':
            _convenienceFeeIsFree = val == 'true' || val == '1';
            break;
          case 'gst_rate':
            _gstRateCtrl.text = val;
            break;
          case 'gst_is_percentage':
            _gstIsPercentage = val == 'true' || val == '1';
            break;
          case 'gst_is_free':
            _gstIsFree = val == 'true' || val == '1';
            break;
          case 'android_min_version':
            _androidMinVersionCtrl.text = val;
            break;
          case 'ios_min_version':
            _iosMinVersionCtrl.text = val;
            break;
          case 'android_store_url':
            _androidStoreUrlCtrl.text = val;
            break;
          case 'ios_store_url':
            _iosStoreUrlCtrl.text = val;
            break;
          case 'user_android_min_version':
            _userAndroidMinVersionCtrl.text = val;
            break;
          case 'user_ios_min_version':
            _userIosMinVersionCtrl.text = val;
            break;
          case 'user_android_store_url':
            _userAndroidStoreUrlCtrl.text = val;
            break;
          case 'user_ios_store_url':
            _userIosStoreUrlCtrl.text = val;
            break;
          case 'owner_app_maintenance':
            _underMaintenance = val == 'true' || val == '1';
            break;
          case 'user_app_maintenance':
            _userUnderMaintenance = val == 'true' || val == '1';
            break;
          case 'firebase_service_account':
            _serviceAccountJson = val;
            break;
          case 'firebase_token':
            _firebaseToken = val;
            break;
          case 'cancellation_tier1_hours':
            _tier1HoursCtrl.text = val;
            break;
          case 'cancellation_tier1_percent':
            _tier1PercentCtrl.text = val;
            break;
          case 'cancellation_tier2_hours':
            _tier2HoursCtrl.text = val;
            break;
          case 'cancellation_tier2_percent':
            _tier2PercentCtrl.text = val;
            break;
          case 'cancellation_tier3_hours':
            _tier3HoursCtrl.text = val;
            break;
          case 'cancellation_tier3_percent':
            _tier3PercentCtrl.text = val;
            break;
          case 'cancellation_tier4_percent':
            _tier4PercentCtrl.text = val;
            break;
          case 'coin_expiry_days':
            _coinExpiryDaysCtrl.text = val;
            break;
          case 'max_coin_redemption_percent':
            _maxCoinRedemptionCtrl.text = val;
            break;
        }
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to load config: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// The Firebase Remote Config payload.
  ///
  /// Previously written out twice, verbatim, once in [_save] and once in
  /// [_publishToFirebase]. Sharing it removes the chance of the two paths
  /// drifting apart. The keys and values are unchanged.
  Map<String, String> _buildRemoteConfigParams({
    required double platformFee,
    required double commissionRate,
    required double convenienceFee,
    required double gstRate,
  }) {
    final userAndroidVersion = _userAndroidMinVersionCtrl.text.trim();

    return {
      'platform_fee': platformFee.toString(),
      'commission_rate': commissionRate.toString(),
      'commission_is_percentage': _commissionIsPercentage.toString(),
      'convenience_fee': convenienceFee.toString(),
      'convenience_fee_is_free': _convenienceFeeIsFree.toString(),
      'platform_fee_is_free': _convenienceFeeIsFree.toString(),
      'gst_rate': gstRate.toString(),
      'gst_is_percentage': _gstIsPercentage.toString(),
      'gst_is_free': _gstIsFree.toString(),
      'is_gst_enabled': (!_gstIsFree).toString(),
      'user_app_maintenance': _userUnderMaintenance.toString(),
      'owner_app_maintenance': _underMaintenance.toString(),
      'user_android_min_version': userAndroidVersion,
      'user_ios_min_version': _userIosMinVersionCtrl.text.trim(),
      'user_android_store_url': _userAndroidStoreUrlCtrl.text.trim(),
      'user_ios_store_url': _userIosStoreUrlCtrl.text.trim(),
      'owner_android_min_version': _androidMinVersionCtrl.text.trim(),
      'owner_ios_min_version': _iosMinVersionCtrl.text.trim(),
      'owner_android_store_url': _androidStoreUrlCtrl.text.trim(),
      'owner_ios_store_url': _iosStoreUrlCtrl.text.trim(),
      'is_under_maintenance': _userUnderMaintenance.toString(),
      'required_version':
          userAndroidVersion.isNotEmpty ? userAndroidVersion : '1.0.0',
      'cancellation_tier1_hours': _tier1HoursCtrl.text.trim().isEmpty ? '24' : _tier1HoursCtrl.text.trim(),
      'cancellation_tier1_percent': _tier1PercentCtrl.text.trim().isEmpty ? '100' : _tier1PercentCtrl.text.trim(),
      'cancellation_tier2_hours': _tier2HoursCtrl.text.trim().isEmpty ? '12' : _tier2HoursCtrl.text.trim(),
      'cancellation_tier2_percent': _tier2PercentCtrl.text.trim().isEmpty ? '75' : _tier2PercentCtrl.text.trim(),
      'cancellation_tier3_hours': _tier3HoursCtrl.text.trim().isEmpty ? '3' : _tier3HoursCtrl.text.trim(),
      'cancellation_tier3_percent': _tier3PercentCtrl.text.trim().isEmpty ? '50' : _tier3PercentCtrl.text.trim(),
      'cancellation_tier4_percent': _tier4PercentCtrl.text.trim().isEmpty ? '25' : _tier4PercentCtrl.text.trim(),
      'coin_expiry_days': _coinExpiryDaysCtrl.text.trim().isEmpty ? '60' : _coinExpiryDaysCtrl.text.trim(),
      'max_coin_redemption_percent': _maxCoinRedemptionCtrl.text.trim().isEmpty ? '40' : _maxCoinRedemptionCtrl.text.trim(),
    };
  }

  Future<void> _save() async {
    String stripNonNumeric(String s) => s.replaceAll(RegExp(r'[^0-9.]'), '');

    final convClean = stripNonNumeric(_convenienceFeeCtrl.text);
    final cClean = stripNonNumeric(_commissionRateCtrl.text);
    final gstClean = stripNonNumeric(_gstRateCtrl.text);

    final convText = convClean.isEmpty ? '20' : convClean;
    final cText = cClean.isEmpty ? '0' : cClean;
    final gstText = gstClean.isEmpty ? '0' : gstClean;

    final platformFee = double.tryParse(convText) ?? 20.0;
    final commissionRate = double.tryParse(cText);
    final convenienceFee = platformFee;
    final gstRate = double.tryParse(gstText) ?? 0.0;

    if (commissionRate == null) {
      _showSnack('Please enter valid numbers for fee fields.', isError: true);
      return;
    }
    if (platformFee < 0 ||
        commissionRate < 0 ||
        convenienceFee < 0 ||
        gstRate < 0) {
      _showSnack('Fee values must be ≥ 0.', isError: true);
      return;
    }
    if (_commissionIsPercentage && commissionRate > 100) {
      _showSnack('Percentage commission cannot exceed 100%.', isError: true);
      return;
    }
    if (_gstIsPercentage && gstRate > 100) {
      _showSnack('Percentage GST cannot exceed 100%.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final client = AdminSupabaseClient.client;
      await Future.wait([
        client
            .from('app_config')
            .upsert({'key': 'platform_fee', 'value': platformFee.toString()},
                onConflict: 'key'),
        client
            .from('app_config')
            .upsert(
                {'key': 'commission_rate', 'value': commissionRate.toString()},
                onConflict: 'key'),
        client
            .from('app_config')
            .upsert({
              'key': 'commission_is_percentage',
              'value': _commissionIsPercentage.toString(),
            }, onConflict: 'key'),
        client
            .from('app_config')
            .upsert({'key': 'convenience_fee', 'value': convenienceFee.toString()},
                onConflict: 'key'),
        client
            .from('app_config')
            .upsert({
              'key': 'convenience_fee_is_free',
              'value': _convenienceFeeIsFree.toString(),
            }, onConflict: 'key'),
        client
            .from('app_config')
            .upsert({
              'key': 'platform_fee_is_free',
              'value': _convenienceFeeIsFree.toString(),
            }, onConflict: 'key'),
        client
            .from('app_config')
            .upsert({'key': 'gst_rate', 'value': gstRate.toString()},
                onConflict: 'key'),
        client
            .from('app_config')
            .upsert({
              'key': 'gst_is_percentage',
              'value': _gstIsPercentage.toString(),
            }, onConflict: 'key'),
        client
            .from('app_config')
            .upsert({'key': 'gst_is_free', 'value': _gstIsFree.toString()},
                onConflict: 'key'),
        client
            .from('app_config')
            .upsert({'key': 'is_gst_enabled', 'value': (!_gstIsFree).toString()},
                onConflict: 'key'),
        client
            .from('app_config')
            .upsert(
                {'key': 'android_min_version', 'value': _androidMinVersionCtrl.text.trim()},
                onConflict: 'key'),
        client
            .from('app_config')
            .upsert(
                {'key': 'ios_min_version', 'value': _iosMinVersionCtrl.text.trim()},
                onConflict: 'key'),
        client
            .from('app_config')
            .upsert(
                {'key': 'android_store_url', 'value': _androidStoreUrlCtrl.text.trim()},
                onConflict: 'key'),
        client
            .from('app_config')
            .upsert(
                {'key': 'ios_store_url', 'value': _iosStoreUrlCtrl.text.trim()},
                onConflict: 'key'),
        client
            .from('app_config')
            .upsert({
              'key': 'user_android_min_version',
              'value': _userAndroidMinVersionCtrl.text.trim(),
            }, onConflict: 'key'),
        client
            .from('app_config')
            .upsert({
              'key': 'user_ios_min_version',
              'value': _userIosMinVersionCtrl.text.trim(),
            }, onConflict: 'key'),
        client
            .from('app_config')
            .upsert({
              'key': 'user_android_store_url',
              'value': _userAndroidStoreUrlCtrl.text.trim(),
            }, onConflict: 'key'),
        client
            .from('app_config')
            .upsert({
              'key': 'user_ios_store_url',
              'value': _userIosStoreUrlCtrl.text.trim(),
            }, onConflict: 'key'),
        client
            .from('app_config')
            .upsert({
              'key': 'owner_app_maintenance',
              'value': _underMaintenance.toString(),
            }, onConflict: 'key'),
        client
            .from('app_config')
            .upsert({
              'key': 'user_app_maintenance',
              'value': _userUnderMaintenance.toString(),
            }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'cancellation_tier1_hours',
          'value': _tier1HoursCtrl.text.trim().isEmpty ? '24' : _tier1HoursCtrl.text.trim(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'cancellation_tier1_percent',
          'value': _tier1PercentCtrl.text.trim().isEmpty ? '100' : _tier1PercentCtrl.text.trim(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'cancellation_tier2_hours',
          'value': _tier2HoursCtrl.text.trim().isEmpty ? '12' : _tier2HoursCtrl.text.trim(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'cancellation_tier2_percent',
          'value': _tier2PercentCtrl.text.trim().isEmpty ? '75' : _tier2PercentCtrl.text.trim(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'cancellation_tier3_hours',
          'value': _tier3HoursCtrl.text.trim().isEmpty ? '3' : _tier3HoursCtrl.text.trim(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'cancellation_tier3_percent',
          'value': _tier3PercentCtrl.text.trim().isEmpty ? '50' : _tier3PercentCtrl.text.trim(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'cancellation_tier4_percent',
          'value': _tier4PercentCtrl.text.trim().isEmpty ? '25' : _tier4PercentCtrl.text.trim(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'coin_expiry_days',
          'value': _coinExpiryDaysCtrl.text.trim().isEmpty ? '60' : _coinExpiryDaysCtrl.text.trim(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'max_coin_redemption_percent',
          'value': _maxCoinRedemptionCtrl.text.trim().isEmpty ? '40' : _maxCoinRedemptionCtrl.text.trim(),
        }, onConflict: 'key'),
      ]);

      final syncResult = await FirebaseRemoteConfigSyncService.publishToFirebase(
        parameters: _buildRemoteConfigParams(
          platformFee: platformFee,
          commissionRate: commissionRate,
          convenienceFee: convenienceFee,
          gstRate: gstRate,
        ),
        serviceAccountJsonString: _serviceAccountJson,
        accessToken: _firebaseToken,
      );

      if (mounted) {
        _showSnack(
          syncResult.success
              ? 'Configuration saved successfully.'
              : syncResult.message,
          isError: !syncResult.success,
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.red.shade700 : AppColors.primaryDarkGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool get _busy => _loading || _saving;

  @override
  Widget build(BuildContext context) {
    final isCompact = AdminBreakpoints.isCompact(context);

    return AdminPageScaffold(
      title: 'App Configuration',
      subtitle: _loading
          ? 'Loading…'
          : 'Read by the owner and user apps on each cold start',
      actions: [
        if (isCompact)
          IconButton(
            tooltip: 'Save changes',
            onPressed: _busy ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save changes'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
      child: _loading
          ? const ShimmerPage(
              children: [
                ShimmerConfigGrid(count: 3),
                SizedBox(height: 26),
                ShimmerConfigGrid(count: 2),
                SizedBox(height: 26),
                ShimmerConfigGrid(count: 2),
              ],
            )
          : RefreshIndicator(
              onRefresh: _loadConfig,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _sectionFees(context),
                  const SizedBox(height: 26),
                  _sectionCancellationPolicy(context),
                  const SizedBox(height: 26),
                  _sectionAppStatus(context),
                  const SizedBox(height: 26),
                  _sectionOwnerForceUpdate(context),
                  const SizedBox(height: 26),
                  _sectionUserForceUpdate(context),
                  const SizedBox(height: 20),
                  if (isCompact)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _save,
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text('Save changes'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryDarkGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _sectionFees(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ConfigSectionHeader(
          title: 'Fee settings',
          description:
              'These values are read by the owner and user apps on each '
              'cold start.',
        ),
        ConfigCardGrid(
          cards: [
            // --- Commission ---
            ConfigCard(
              icon: Icons.percent_rounded,
              iconColor: AppColors.accentOrange,
              title: 'Commission',
              description: _commissionIsPercentage
                  ? 'Deducted as a percentage of the gross booking amount.'
                  : 'Deducted as a flat amount from every booking.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConfigChoiceToggle(
                    options: const [
                      (label: 'Percentage', icon: Icons.percent_rounded),
                      (label: 'Flat amount', icon: Icons.payments_outlined),
                    ],
                    selectedIndex: _commissionIsPercentage ? 0 : 1,
                    onChanged: (index) => setState(
                      () => _commissionIsPercentage = index == 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConfigNumberField(
                    controller: _commissionRateCtrl,
                    hint: '0',
                    prefix: _commissionIsPercentage ? '%' : '₹',
                    isDecimal: true,
                  ),
                ],
              ),
            ),

            // --- Platform fee ---
            ConfigCard(
              icon: Icons.receipt_long_rounded,
              iconColor: AppColors.primaryDarkGreen,
              title: 'Platform fee (user app)',
              description: _convenienceFeeIsFree
                  ? 'Currently waived. Players are not charged a platform fee.'
                  : 'Charged to the player on every booking.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConfigChoiceToggle(
                    options: const [
                      (label: 'Charge fee', icon: Icons.attach_money_rounded),
                      (label: 'Free', icon: Icons.money_off_outlined),
                    ],
                    selectedIndex: _convenienceFeeIsFree ? 1 : 0,
                    onChanged: (index) =>
                        setState(() => _convenienceFeeIsFree = index == 1),
                  ),
                  const SizedBox(height: 12),
                  ConfigNumberField(
                    controller: _convenienceFeeCtrl,
                    hint: '20',
                    prefix: '₹',
                    isDecimal: true,
                  ),
                ],
              ),
            ),

            // --- GST ---
            ConfigCard(
              icon: Icons.request_quote_rounded,
              iconColor: Colors.blue.shade700,
              title: 'GST (taxes)',
              description: _gstIsFree
                  ? 'GST is not applied to any booking.'
                  : 'Applied on top of the booking amount.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConfigChoiceToggle(
                    options: const [
                      (label: 'Percentage', icon: Icons.percent_rounded),
                      (label: 'Flat amount', icon: Icons.payments_outlined),
                    ],
                    selectedIndex: _gstIsPercentage ? 0 : 1,
                    onChanged: (index) =>
                        setState(() => _gstIsPercentage = index == 0),
                  ),
                  const SizedBox(height: 10),
                  ConfigNumberField(
                    controller: _gstRateCtrl,
                    hint: '0',
                    prefix: _gstIsPercentage ? '%' : '₹',
                    isDecimal: true,
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: _gstIsFree,
                    onChanged: (v) => setState(() => _gstIsFree = v),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('GST is free'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionCancellationPolicy(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ConfigSectionHeader(
          title: 'Cancellation & Coin Recovery Policy',
          description:
              'Dynamic cancellation rules based on time remaining before slot start. '
              'Any changes saved here automatically synchronize in realtime to User and Owner apps.',
        ),
        ConfigCardGrid(
          cards: [
            // --- Tier 1 (Early) ---
            ConfigCard(
              icon: Icons.schedule_rounded,
              iconColor: AppColors.primaryDarkGreen,
              title: 'Tier 1: Early Cancellation',
              description: 'Applies when cancelled well in advance of the booking start time.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Cutoff Hours (More than)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ConfigNumberField(
                    controller: _tier1HoursCtrl,
                    hint: '24',
                    prefix: '≥ Hours',
                    isDecimal: true,
                  ),
                  const SizedBox(height: 12),
                  const Text('Coin Recovery %', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ConfigNumberField(
                    controller: _tier1PercentCtrl,
                    hint: '100',
                    prefix: '%',
                    isDecimal: true,
                  ),
                ],
              ),
            ),

            // --- Tier 2 (Medium) ---
            ConfigCard(
              icon: Icons.timer_outlined,
              iconColor: Colors.blue.shade600,
              title: 'Tier 2: Medium Cancellation',
              description: 'Applies between Tier 2 and Tier 1 cutoff hours.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Cutoff Hours (Between Tier 2 and 1)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ConfigNumberField(
                    controller: _tier2HoursCtrl,
                    hint: '12',
                    prefix: '≥ Hours',
                    isDecimal: true,
                  ),
                  const SizedBox(height: 12),
                  const Text('Coin Recovery %', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ConfigNumberField(
                    controller: _tier2PercentCtrl,
                    hint: '75',
                    prefix: '%',
                    isDecimal: true,
                  ),
                ],
              ),
            ),

            // --- Tier 3 (Late) ---
            ConfigCard(
              icon: Icons.alarm_on_rounded,
              iconColor: AppColors.accentOrange,
              title: 'Tier 3: Late Cancellation',
              description: 'Applies between Tier 3 and Tier 2 cutoff hours.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Cutoff Hours (Between Tier 3 and 2)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ConfigNumberField(
                    controller: _tier3HoursCtrl,
                    hint: '3',
                    prefix: '≥ Hours',
                    isDecimal: true,
                  ),
                  const SizedBox(height: 12),
                  const Text('Coin Recovery %', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ConfigNumberField(
                    controller: _tier3PercentCtrl,
                    hint: '50',
                    prefix: '%',
                    isDecimal: true,
                  ),
                ],
              ),
            ),

            // --- Tier 4 (Last-Minute) ---
            ConfigCard(
              icon: Icons.running_with_errors_rounded,
              iconColor: Colors.red.shade600,
              title: 'Tier 4: Last-Minute (< Tier 3)',
              description: 'Applies when cancelled with less than Tier 3 cutoff hours remaining.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Coin Recovery % for < Tier 3 Hours', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ConfigNumberField(
                    controller: _tier4PercentCtrl,
                    hint: '25',
                    prefix: '%',
                    isDecimal: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No-show players receive 0% refund and full payout goes to the owner.',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // --- Coin Rules & Validity ---
            ConfigCard(
              icon: Icons.monetization_on_rounded,
              iconColor: Colors.amber.shade700,
              title: 'Coin Rules & Validity',
              description: 'Control coin lifespan and limits for booking redemptions.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Coin Validity / Expiry Duration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ConfigNumberField(
                    controller: _coinExpiryDaysCtrl,
                    hint: '60',
                    prefix: 'Days',
                    isDecimal: false,
                  ),
                  const SizedBox(height: 12),
                  const Text('Max Coin Redemption Per Booking', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ConfigNumberField(
                    controller: _maxCoinRedemptionCtrl,
                    hint: '40',
                    prefix: '%',
                    isDecimal: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionAppStatus(BuildContext context) {
    final anyMaintenance = _underMaintenance || _userUnderMaintenance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ConfigSectionHeader(
          title: 'App status',
          description:
              'Controls visibility and access in the owner and user apps.',
        ),
        ConfigCautionBanner(
          isActive: anyMaintenance,
          message: anyMaintenance
              ? 'At least one app is in maintenance mode. Users of that app '
                  'see a non-dismissible dialog and cannot proceed until this '
                  'is switched off.'
              : '',
        ),
        if (anyMaintenance) const SizedBox(height: 12),
        ConfigCardGrid(
          maxColumns: 2,
          cards: [
            ConfigCard(
              icon: Icons.build_circle_rounded,
              iconColor: Colors.red.shade600,
              title: 'Owner app — under maintenance',
              description:
                  'Shows a non-dismissible maintenance dialog to all owners on '
                  'the next cold start.',
              child: ConfigMaintenanceRow(
                value: _underMaintenance,
                onChanged: (v) => setState(() => _underMaintenance = v),
              ),
            ),
            ConfigCard(
              icon: Icons.build_circle_rounded,
              iconColor: Colors.red.shade600,
              title: 'User app — under maintenance',
              description:
                  'Shows a non-dismissible maintenance dialog to all users on '
                  'the next cold start.',
              child: ConfigMaintenanceRow(
                value: _userUnderMaintenance,
                onChanged: (v) => setState(() => _userUnderMaintenance = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionOwnerForceUpdate(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ConfigSectionHeader(
          title: 'Owner app — force update',
          description:
              'If the installed owner app is below the minimum, a '
              'non-dismissible update dialog is shown.',
        ),
        ConfigCardGrid(
          maxColumns: 2,
          cards: [
            ConfigCard(
              icon: Icons.android_rounded,
              iconColor: const Color(0xFF3DDC84),
              title: 'Android',
              description: 'Minimum version required to run the owner app.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConfigTextField(
                    controller: _androidMinVersionCtrl,
                    label: 'Min version',
                    hint: '1.0.0',
                  ),
                  const SizedBox(height: 12),
                  ConfigTextField(
                    controller: _androidStoreUrlCtrl,
                    label: 'Play Store URL',
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
            ConfigCard(
              icon: Icons.apple_rounded,
              iconColor: const Color(0xFF9AA0A6),
              title: 'iOS',
              description: 'Minimum version required to run the owner app.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConfigTextField(
                    controller: _iosMinVersionCtrl,
                    label: 'Min version',
                    hint: '1.0.0',
                  ),
                  const SizedBox(height: 12),
                  ConfigTextField(
                    controller: _iosStoreUrlCtrl,
                    label: 'App Store URL',
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionUserForceUpdate(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ConfigSectionHeader(
          title: 'User app — force update',
          description:
              'If the installed user app is below the minimum, a '
              'non-dismissible update dialog is shown.',
        ),
        ConfigCardGrid(
          maxColumns: 2,
          cards: [
            ConfigCard(
              icon: Icons.android_rounded,
              iconColor: const Color(0xFF3DDC84),
              title: 'Android',
              description: 'Minimum version required to run the user app.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConfigTextField(
                    controller: _userAndroidMinVersionCtrl,
                    label: 'Min version',
                    hint: '1.0.0',
                  ),
                  const SizedBox(height: 12),
                  ConfigTextField(
                    controller: _userAndroidStoreUrlCtrl,
                    label: 'Play Store URL',
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
            ConfigCard(
              icon: Icons.apple_rounded,
              iconColor: const Color(0xFF9AA0A6),
              title: 'iOS',
              description: 'Minimum version required to run the user app.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConfigTextField(
                    controller: _userIosMinVersionCtrl,
                    label: 'Min version',
                    hint: '1.0.0',
                  ),
                  const SizedBox(height: 12),
                  ConfigTextField(
                    controller: _userIosStoreUrlCtrl,
                    label: 'App Store URL',
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
