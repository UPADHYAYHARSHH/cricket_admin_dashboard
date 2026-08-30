import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/services/admin_supabase_client.dart';
import '../../../../common/services/firebase_remote_config_sync_service.dart';

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

  final _androidMinVersionCtrl = TextEditingController();
  final _iosMinVersionCtrl = TextEditingController();
  final _androidStoreUrlCtrl = TextEditingController();
  final _iosStoreUrlCtrl = TextEditingController();

  final _userAndroidMinVersionCtrl = TextEditingController();
  final _userIosMinVersionCtrl = TextEditingController();
  final _userAndroidStoreUrlCtrl = TextEditingController();
  final _userIosStoreUrlCtrl = TextEditingController();

  final _serviceAccountCtrl = TextEditingController();
  final _firebaseTokenCtrl = TextEditingController();

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
    _androidMinVersionCtrl.dispose();
    _iosMinVersionCtrl.dispose();
    _androidStoreUrlCtrl.dispose();
    _iosStoreUrlCtrl.dispose();
    _userAndroidMinVersionCtrl.dispose();
    _userIosMinVersionCtrl.dispose();
    _userAndroidStoreUrlCtrl.dispose();
    _userIosStoreUrlCtrl.dispose();
    _serviceAccountCtrl.dispose();
    _firebaseTokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
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
            _platformFeeCtrl.text = val;
            break;
          case 'commission_rate':
            _commissionRateCtrl.text = val;
            break;
          case 'commission_is_percentage':
            _commissionIsPercentage = val == 'true' || val == '1';
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
            _serviceAccountCtrl.text = val;
            break;
          case 'firebase_token':
            _firebaseTokenCtrl.text = val;
            break;
        }
      }
      if (_serviceAccountCtrl.text.isEmpty) {
        _serviceAccountCtrl.text = FirebaseRemoteConfigSyncService.defaultServiceAccountJson;
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to load config: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    String stripNonNumeric(String s) => s.replaceAll(RegExp(r'[^0-9.]'), '');
    
    final pClean = stripNonNumeric(_platformFeeCtrl.text);
    final cClean = stripNonNumeric(_commissionRateCtrl.text);
    
    final pText = pClean.isEmpty ? '0' : pClean;
    final cText = cClean.isEmpty ? '0' : cClean;
    
    final platformFee = double.tryParse(pText);
    final commissionRate = double.tryParse(cText);

    if (platformFee == null || commissionRate == null) {
      _showSnack('Please enter valid numbers for fee fields.', isError: true);
      return;
    }
    if (platformFee < 0 || commissionRate < 0) {
      _showSnack('Fee values must be ≥ 0.', isError: true);
      return;
    }
    if (_commissionIsPercentage && commissionRate > 100) {
      _showSnack('Percentage commission cannot exceed 100%.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final client = AdminSupabaseClient.client;
      await Future.wait([
        client.from('app_config').upsert({
          'key': 'platform_fee',
          'value': platformFee.toString(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'commission_rate',
          'value': commissionRate.toString(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'commission_is_percentage',
          'value': _commissionIsPercentage.toString(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'android_min_version',
          'value': _androidMinVersionCtrl.text.trim(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'ios_min_version',
          'value': _iosMinVersionCtrl.text.trim(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'android_store_url',
          'value': _androidStoreUrlCtrl.text.trim(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'ios_store_url',
          'value': _iosStoreUrlCtrl.text.trim(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'user_android_min_version',
          'value': _userAndroidMinVersionCtrl.text.trim(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'user_ios_min_version',
          'value': _userIosMinVersionCtrl.text.trim(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'user_android_store_url',
          'value': _userAndroidStoreUrlCtrl.text.trim(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'user_ios_store_url',
          'value': _userIosStoreUrlCtrl.text.trim(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'owner_app_maintenance',
          'value': _underMaintenance.toString(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'user_app_maintenance',
          'value': _userUnderMaintenance.toString(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'firebase_service_account',
          'value': _serviceAccountCtrl.text.trim(),
        }, onConflict: 'key'),
        client.from('app_config').upsert({
          'key': 'firebase_token',
          'value': _firebaseTokenCtrl.text.trim(),
        }, onConflict: 'key'),
      ]);

      // Publish directly to Firebase Remote Config REST API
      final Map<String, String> remoteConfigParams = {
        'platform_fee': platformFee.toString(),
        'commission_rate': commissionRate.toString(),
        'commission_is_percentage': _commissionIsPercentage.toString(),
        'user_app_maintenance': _userUnderMaintenance.toString(),
        'owner_app_maintenance': _underMaintenance.toString(),
        'user_android_min_version': _userAndroidMinVersionCtrl.text.trim(),
        'user_ios_min_version': _userIosMinVersionCtrl.text.trim(),
        'user_android_store_url': _userAndroidStoreUrlCtrl.text.trim(),
        'user_ios_store_url': _userIosStoreUrlCtrl.text.trim(),
        'owner_android_min_version': _androidMinVersionCtrl.text.trim(),
        'owner_ios_min_version': _iosMinVersionCtrl.text.trim(),
        'owner_android_store_url': _androidStoreUrlCtrl.text.trim(),
        'owner_ios_store_url': _iosStoreUrlCtrl.text.trim(),
        'is_under_maintenance': _userUnderMaintenance.toString(),
        'required_version': _userAndroidMinVersionCtrl.text.trim().isNotEmpty
            ? _userAndroidMinVersionCtrl.text.trim()
            : '1.0.0',
      };

      final syncResult = await FirebaseRemoteConfigSyncService.publishToFirebase(
        parameters: remoteConfigParams,
        serviceAccountJsonString: _serviceAccountCtrl.text.trim(),
        accessToken: _firebaseTokenCtrl.text.trim(),
      );

      if (mounted) {
        _showSnack(syncResult.message, isError: !syncResult.success);
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publishToFirebase() async {
    String stripNonNumeric(String s) => s.replaceAll(RegExp(r'[^0-9.]'), '');
    final pClean = stripNonNumeric(_platformFeeCtrl.text);
    final cClean = stripNonNumeric(_commissionRateCtrl.text);
    
    final platformFee = double.tryParse(pClean) ?? 0.0;
    final commissionRate = double.tryParse(cClean) ?? 0.0;

    setState(() => _saving = true);
    try {
      final Map<String, String> remoteConfigParams = {
        'platform_fee': platformFee.toString(),
        'commission_rate': commissionRate.toString(),
        'commission_is_percentage': _commissionIsPercentage.toString(),
        'user_app_maintenance': _userUnderMaintenance.toString(),
        'owner_app_maintenance': _underMaintenance.toString(),
        'user_android_min_version': _userAndroidMinVersionCtrl.text.trim(),
        'user_ios_min_version': _userIosMinVersionCtrl.text.trim(),
        'user_android_store_url': _userAndroidStoreUrlCtrl.text.trim(),
        'user_ios_store_url': _userIosStoreUrlCtrl.text.trim(),
        'owner_android_min_version': _androidMinVersionCtrl.text.trim(),
        'owner_ios_min_version': _iosMinVersionCtrl.text.trim(),
        'owner_android_store_url': _androidStoreUrlCtrl.text.trim(),
        'owner_ios_store_url': _iosStoreUrlCtrl.text.trim(),
        'is_under_maintenance': _userUnderMaintenance.toString(),
        'required_version': _userAndroidMinVersionCtrl.text.trim().isNotEmpty
            ? _userAndroidMinVersionCtrl.text.trim()
            : '1.0.0',
      };

      final result = await FirebaseRemoteConfigSyncService.publishToFirebase(
        parameters: remoteConfigParams,
        serviceAccountJsonString: _serviceAccountCtrl.text.trim(),
        accessToken: _firebaseTokenCtrl.text.trim(),
      );

      if (mounted) {
        _showSnack(result.message, isError: !result.success);
      }
    } catch (e) {
      if (mounted) _showSnack('Publish Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? Colors.red.shade700
            : AppColors.primaryDarkGreen,
        behavior: SnackBarBehavior.floating,
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
                onPressed: () => context
                    .findRootAncestorStateOfType<ScaffoldState>()
                    ?.openDrawer(),
              ),
        title: Text(
          'App Configuration',
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: (_loading || _saving) ? null : _save,
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
              label: const Text('Save Changes'),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fee Settings',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'These values are read by owner and user apps on each cold-start.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _ConfigCard(
                        width: isDesktop ? 340 : double.infinity,
                        icon: HugeIcons.strokeRoundedMoneyBag01,
                        iconColor: AppColors.primaryDarkGreen,
                        title: 'Platform Fee',
                        description:
                            'Flat ₹ amount deducted from every booking before the owner is paid.',
                        child: _NumericInput(
                          controller: _platformFeeCtrl,
                          prefix: '₹',
                          hint: '25',
                        ),
                      ),
                      _ConfigCard(
                        width: isDesktop ? 340 : double.infinity,
                        icon: HugeIcons.strokeRoundedDiscount01,
                        iconColor: AppColors.accentOrange,
                        title: 'Commission',
                        description: _commissionIsPercentage
                            ? 'Deducted as a percentage of the gross booking amount.'
                            : 'Deducted as a flat ₹ amount from every booking.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type toggle
                            Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.06,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _TypeChip(
                                    label: '% Percentage',
                                    selected: _commissionIsPercentage,
                                    onTap: () => setState(
                                      () => _commissionIsPercentage = true,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  _TypeChip(
                                    label: '₹ Flat Amount',
                                    selected: !_commissionIsPercentage,
                                    onTap: () => setState(
                                      () => _commissionIsPercentage = false,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _NumericInput(
                              controller: _commissionRateCtrl,
                              prefix: _commissionIsPercentage ? null : '₹',
                              suffix: _commissionIsPercentage ? '%' : null,
                              hint: _commissionIsPercentage ? '0' : '0',
                              isDecimal: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'App Status',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Controls visibility and access in the owner app.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _ConfigCard(
                        width: isDesktop ? 340 : double.infinity,
                        icon: HugeIcons.strokeRoundedTools,
                        iconColor: Colors.red.shade600,
                        title: 'Owner App — Under Maintenance',
                        description:
                            'When enabled, a non-dismissible maintenance dialog is shown to all owners on the next app cold-start. Owners cannot use the app until this is turned off.',
                        child: Row(
                          children: [
                            Switch(
                              value: _underMaintenance,
                              onChanged: (v) =>
                                  setState(() => _underMaintenance = v),
                              activeThumbColor: AppColors.primaryDarkGreen,
                            ),
                            const SizedBox(width: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                _underMaintenance
                                    ? 'Maintenance ON'
                                    : 'Maintenance OFF',
                                key: ValueKey(_underMaintenance),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _underMaintenance
                                      ? Colors.red.shade600
                                      : AppColors.primaryDarkGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ConfigCard(
                        width: isDesktop ? 340 : double.infinity,
                        icon: HugeIcons.strokeRoundedTools,
                        iconColor: Colors.red.shade600,
                        title: 'User App — Under Maintenance',
                        description:
                            'When enabled, a non-dismissible maintenance dialog is shown to all users on the next app cold-start. Users cannot use the app until this is turned off.',
                        child: Row(
                          children: [
                            Switch(
                              value: _userUnderMaintenance,
                              onChanged: (v) =>
                                  setState(() => _userUnderMaintenance = v),
                              activeThumbColor: AppColors.primaryDarkGreen,
                            ),
                            const SizedBox(width: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                _userUnderMaintenance
                                    ? 'Maintenance ON'
                                    : 'Maintenance OFF',
                                key: ValueKey(_userUnderMaintenance),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _userUnderMaintenance
                                      ? Colors.red.shade600
                                      : AppColors.primaryDarkGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Owner App — Force Update',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'If the owner app version is below the minimum, a non-dismissible update dialog is shown.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _ConfigCard(
                        width: isDesktop ? 340 : double.infinity,
                        icon: HugeIcons.strokeRoundedAndroid,
                        iconColor: const Color(0xFF3DDC84),
                        title: 'Android',
                        description:
                            'Minimum version required to run the owner app on Android.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TextInput(
                              controller: _androidMinVersionCtrl,
                              hint: '1.0.0',
                              label: 'Min Version',
                            ),
                            const SizedBox(height: 14),
                            _TextInput(
                              controller: _androidStoreUrlCtrl,
                              hint:
                                  'https://play.google.com/store/apps/details?id=...',
                              label: 'Play Store URL',
                            ),
                          ],
                        ),
                      ),
                      _ConfigCard(
                        width: isDesktop ? 340 : double.infinity,
                        icon: HugeIcons.strokeRoundedApple,
                        iconColor: Colors.grey.shade700,
                        title: 'iOS',
                        description:
                            'Minimum version required to run the owner app on iOS.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TextInput(
                              controller: _iosMinVersionCtrl,
                              hint: '1.0.0',
                              label: 'Min Version',
                            ),
                            const SizedBox(height: 14),
                            _TextInput(
                              controller: _iosStoreUrlCtrl,
                              hint: 'https://apps.apple.com/app/id...',
                              label: 'App Store URL',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'User App — Force Update',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'If the user app version is below the minimum, a non-dismissible update dialog is shown.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _ConfigCard(
                        width: isDesktop ? 340 : double.infinity,
                        icon: HugeIcons.strokeRoundedAndroid,
                        iconColor: const Color(0xFF3DDC84),
                        title: 'Android',
                        description:
                            'Minimum version required to run the user app on Android.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TextInput(
                              controller: _userAndroidMinVersionCtrl,
                              hint: '1.0.0',
                              label: 'Min Version',
                            ),
                            const SizedBox(height: 14),
                            _TextInput(
                              controller: _userAndroidStoreUrlCtrl,
                              hint:
                                  'https://play.google.com/store/apps/details?id=...',
                              label: 'Play Store URL',
                            ),
                          ],
                        ),
                      ),
                      _ConfigCard(
                        width: isDesktop ? 340 : double.infinity,
                        icon: HugeIcons.strokeRoundedApple,
                        iconColor: Colors.grey.shade700,
                        title: 'iOS',
                        description:
                            'Minimum version required to run the user app on iOS.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TextInput(
                              controller: _userIosMinVersionCtrl,
                              hint: '1.0.0',
                              label: 'Min Version',
                            ),
                            const SizedBox(height: 14),
                            _TextInput(
                              controller: _userIosStoreUrlCtrl,
                              hint: 'https://apps.apple.com/app/id...',
                              label: 'App Store URL',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Firebase Remote Config Sync',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Publish all configuration parameters directly to Firebase Remote Config (project: box-cricket-df427) to update User & Owner mobile apps in real-time.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_sync_rounded,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Firebase Project: box-cricket-df427',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Remote Config parameters synced: is_under_maintenance, required_version, platform_fee, commission_rate, user_app_maintenance, owner_app_maintenance, store URLs & min versions.',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.help_outline_rounded, size: 16, color: Colors.blue),
                                  SizedBox(width: 6),
                                  Text(
                                    'How to get your Service Account JSON (One-Time Setup):',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '1. Open Firebase Console → Project Settings (⚙️) → Service Accounts tab.\n'
                                '2. Click "Generate New Private Key" button to download your .json file.\n'
                                '3. Copy the entire content of that .json file and paste it into the box below.\n'
                                '4. Click "Publish All Variables" (It will be saved permanently).',
                                style: TextStyle(fontSize: 11, color: Colors.blue.shade900, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _serviceAccountCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Firebase Service Account JSON',
                            hintText: 'Paste your service account JSON key here (e.g. {"type": "service_account", "project_id": "box-cricket-df427", ...})',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _firebaseTokenCtrl,
                          decoration: const InputDecoration(
                            labelText: 'OAuth Access Token (Optional)',
                            hintText: 'Bearer token if using custom token auth...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            FilledButton.icon(
                              onPressed: (_loading || _saving) ? null : _publishToFirebase,
                              icon: const Icon(Icons.publish_rounded, size: 18),
                              label: const Text('Publish All Variables to Firebase Remote Config'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryDarkGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Fee changes take effect on the owner app\'s next cold-start. '
                            'Maintenance mode activates immediately after the owner relaunches the app.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final double width;
  final dynamic icon;
  final Color iconColor;
  final String title;
  final String description;
  final Widget child;

  const _ConfigCard({
    required this.width,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: HugeIcon(icon: icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDarkGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : theme.colorScheme.onSurface.withOpacity(0.55),
          ),
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;

  const _TextInput({
    required this.controller,
    required this.hint,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            filled: true,
            fillColor: theme.colorScheme.onSurface.withOpacity(0.04),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primaryDarkGreen,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NumericInput extends StatelessWidget {
  final TextEditingController controller;
  final String? prefix;
  final String? suffix;
  final String hint;
  final bool isDecimal;

  const _NumericInput({
    required this.controller,
    this.prefix,
    this.suffix,
    required this.hint,
    this.isDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            isDecimal ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
          ),
        ],
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          prefixText: prefix,
          suffixText: suffix,
          hintText: hint,
          hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primaryDarkGreen,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
