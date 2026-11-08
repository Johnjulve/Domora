import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../backup/presentation/backup_sheet.dart';
import '../../settings/presentation/settings_profile_screen.dart';

/// Modal bottom sheet presenting App Info, Preferences, and Network Update Checking.
class SettingsSheet extends ConsumerStatefulWidget {
  const SettingsSheet({super.key});

  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<SettingsSheet> {
  bool _isCheckingUpdate = false;
  String? _updateStatusMessage;
  String? _releaseUrl;
  bool _hasNewUpdate = false;
  bool _checkFailed = false;

  int? _extractAlphaNumber(String tag) {
    final match = RegExp(r'alpha\.(\d+)', caseSensitive: false).firstMatch(tag);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  bool _isTagNewer(String remoteTag) {
    final cleanRemote = remoteTag.replaceAll(RegExp(r'^v'), '').trim();
    final cleanCurrent = '${AppConstants.appVersion}-${AppConstants.appReleaseChannel}';
    if (cleanRemote.isEmpty || cleanRemote == cleanCurrent) return false;

    final remoteAlpha = _extractAlphaNumber(cleanRemote);
    final currentAlpha = _extractAlphaNumber(AppConstants.appReleaseChannel);

    if (remoteAlpha != null && currentAlpha != null) {
      return remoteAlpha > currentAlpha;
    }
    // If remote has no 'alpha' tag (e.g. beta or stable v0.1.0/v1.0.0), it is a higher release tier
    return !cleanRemote.toLowerCase().contains('alpha');
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateStatusMessage = 'Connecting to GitHub Releases...';
      _checkFailed = false;
      _hasNewUpdate = false;
    });

    try {
      final uri = Uri.parse('https://api.github.com/repos/Johnjulve/Domora/releases/latest');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tagName = data['tag_name'] as String? ?? '';
        final htmlUrl = data['html_url'] as String? ?? 'https://github.com/Johnjulve/Domora/releases';

        if (_isTagNewer(tagName)) {
          setState(() {
            _hasNewUpdate = true;
            _releaseUrl = htmlUrl;
            _updateStatusMessage = 'New release available: $tagName';
          });
        } else {
          setState(() {
            _hasNewUpdate = false;
            _updateStatusMessage = 'Domora is up to date (${AppConstants.fullVersionTag})';
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _updateStatusMessage = 'Domora ${AppConstants.fullVersionTag} is the latest pre-release';
        });
      } else {
        setState(() {
          _checkFailed = true;
          _updateStatusMessage = 'Update server responded with status ${response.statusCode}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkFailed = true;
        _updateStatusMessage = 'Offline Sanctuary: Unable to connect to GitHub ($e)';
      });
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  Future<void> _launchReleaseUrl() async {
    if (_releaseUrl == null) return;
    final uri = Uri.parse(_releaseUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_outlined, color: AppColors.brandPrimary),
                    SizedBox(width: 8),
                    Text('Settings & Preferences', style: AppTypography.sectionTitle),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // App Identity & Info Card
            Card(
              margin: EdgeInsets.zero,
              color: AppColors.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.brandAccentSage,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.brandAccentBorder),
                          ),
                          child: const Icon(Icons.shield_outlined, color: AppColors.brandPrimary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${AppConstants.appName} ${AppConstants.fullVersionTag}',
                                style: AppTypography.cardTitle.copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Personal & Household Sanctuary OS',
                                style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _buildInfoRow('Architecture', 'Offline-First • Local SQLite (Drift v7)'),
                    _buildInfoRow('Data Ownership', '100% On-Device • Zero Mandatory Cloud'),
                    _buildInfoRow('Default Currency', 'PHP (Philippine Peso)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Network Software Update Card
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.system_update_outlined, size: 18, color: AppColors.brandPrimary),
                            SizedBox(width: 8),
                            Text('Software Updates', style: AppTypography.cardTitle),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandAccentSage,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.brandAccentBorder),
                          ),
                          child: Text(
                            AppConstants.appReleaseChannel,
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Checks GitHub releases repository for new builds, security updates, and offline engine patches.',
                      style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                    ),
                    if (_updateStatusMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _hasNewUpdate
                              ? AppColors.statusSuccessFill
                              : _checkFailed
                                  ? AppColors.statusDangerFill
                                  : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _hasNewUpdate
                                ? AppColors.statusSuccessStroke
                                : _checkFailed
                                    ? AppColors.statusDangerStroke
                                    : AppColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _hasNewUpdate
                                  ? Icons.download_for_offline_outlined
                                  : _checkFailed
                                      ? Icons.wifi_off_outlined
                                      : Icons.check_circle_outline,
                              size: 16,
                              color: _hasNewUpdate
                                  ? AppColors.statusSuccessText
                                  : _checkFailed
                                      ? AppColors.statusDangerText
                                      : AppColors.brandPrimary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _updateStatusMessage!,
                                style: AppTypography.caption.copyWith(
                                  color: _hasNewUpdate
                                      ? AppColors.statusSuccessText
                                      : _checkFailed
                                          ? AppColors.statusDangerText
                                          : AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _isCheckingUpdate ? null : _checkForUpdates,
                            icon: _isCheckingUpdate
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPrimary),
                                  )
                                : const Icon(Icons.sync, size: 18),
                            label: Text(_isCheckingUpdate ? 'Checking...' : 'Check for Updates'),
                          ),
                        ),
                        if (_hasNewUpdate) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _launchReleaseUrl,
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Download'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Full Settings & Profile Screen Shortcut
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.manage_accounts_outlined, color: AppColors.brandPrimary),
                title: const Text('Settings & Profile', style: AppTypography.cardTitle),
                subtitle: Text(
                  'Manage household profile, biometrics, preferences, storage, and danger zone.',
                  style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsProfileScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Sanctuary Archival & Recovery Shortcut
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.archive_outlined, color: AppColors.brandPrimary),
                title: const Text('Sanctuary Archival & Backup', style: AppTypography.cardTitle),
                subtitle: Text(
                  'Export or restore encrypted JSON snapshot and verify cryptographic SHA-256 fingerprint.',
                  style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    isDismissible: false,
                    enableDrag: false,
                    builder: (_) => const BackupSheet(),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.textTertiary)),
          Text(value, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
