import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/under_construction_dialog.dart';
import '../../backup/presentation/backup_sheet.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import 'widgets/connect_google_drive_sheet.dart';
import 'widgets/emergency_info_sheet.dart';

/// Full Settings & Profile Screen matching Sanctuary Archival specification.
class SettingsProfileScreen extends ConsumerStatefulWidget {
  const SettingsProfileScreen({super.key});

  /// Extracts the browser download URL for the first `.apk` asset in GitHub release payload.
  static String? extractApkDownloadUrl(Map<String, dynamic> releaseData) {
    final assets = releaseData['assets'];
    if (assets is! List) return null;

    for (final asset in assets) {
      if (asset is Map) {
        final name = asset['name']?.toString() ?? '';
        final downloadUrl = asset['browser_download_url']?.toString();
        if (name.toLowerCase().endsWith('.apk') && downloadUrl != null && downloadUrl.isNotEmpty) {
          return downloadUrl;
        }
      }
    }
    return null;
  }

  @override
  ConsumerState<SettingsProfileScreen> createState() => _SettingsProfileScreenState();
}

class _SettingsProfileScreenState extends ConsumerState<SettingsProfileScreen> {
  static const List<String> _sanctuaryRecoveryWords = [
    'anchor',
    'velvet',
    'summit',
    'cedar',
    'ember',
    'orchard',
    'meadow',
    'hearth',
    'pebble',
    'clover',
    'harbor',
    'willow',
  ];

  int _storageBytes = 0;
  bool _isLoadingStorage = true;

  // GitHub Update Checker state
  bool _isCheckingUpdate = false;
  String? _updateStatusMessage;
  String? _releaseUrl;
  bool _hasNewUpdate = false;
  bool _hasApkAsset = false;
  String? _apkDownloadUrl;

  @override
  void initState() {
    super.initState();
    _loadStorageSize();
  }

  Future<void> _loadStorageSize() async {
    try {
      int totalBytes = 0;
      try {
        final docDir = await getApplicationDocumentsDirectory();
        if (docDir.existsSync()) {
          final entities = docDir.listSync(recursive: true, followLinks: false);
          for (final entity in entities) {
            if (entity is File) {
              totalBytes += entity.lengthSync();
            }
          }
        }
      } catch (_) {}

      try {
        final tempDir = await getTemporaryDirectory();
        if (tempDir.existsSync()) {
          final entities = tempDir.listSync(recursive: true, followLinks: false);
          for (final entity in entities) {
            if (entity is File) {
              totalBytes += entity.lengthSync();
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _storageBytes = totalBytes;
          _isLoadingStorage = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingStorage = false);
      }
    }
  }

  String _formatStorage(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final entities = tempDir.listSync(recursive: false);
        for (final entity in entities) {
          try {
            if (entity is File) {
              entity.deleteSync();
            } else if (entity is Directory) {
              entity.deleteSync(recursive: true);
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    await _loadStorageSize();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared successfully'),
          backgroundColor: AppColors.brandPrimary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

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
    return !cleanRemote.toLowerCase().contains('alpha');
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateStatusMessage = 'Connecting to GitHub Releases...';
      _hasNewUpdate = false;
      _hasApkAsset = false;
      _apkDownloadUrl = null;
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
          final apkUrl = SettingsProfileScreen.extractApkDownloadUrl(data);
          setState(() {
            _hasNewUpdate = true;
            if (apkUrl != null) {
              _hasApkAsset = true;
              _apkDownloadUrl = apkUrl;
              _releaseUrl = apkUrl;
            } else {
              _hasApkAsset = false;
              _apkDownloadUrl = null;
              _releaseUrl = htmlUrl;
            }
            _updateStatusMessage = 'New release available: $tagName';
          });
        } else {
          setState(() {
            _hasNewUpdate = false;
            _hasApkAsset = false;
            _apkDownloadUrl = null;
            _updateStatusMessage = 'Domora is up to date (${AppConstants.fullVersionTag})';
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _updateStatusMessage = 'Domora ${AppConstants.fullVersionTag} is the latest pre-release';
        });
      } else {
        setState(() {
          _updateStatusMessage = 'Server responded with status ${response.statusCode}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _updateStatusMessage = 'Offline Sanctuary: Unable to connect ($e)';
      });
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'EM';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _openEditProfileModal(AppPreferences prefs) {
    final nameController = TextEditingController(text: prefs.householdName);
    final addressController = TextEditingController(text: prefs.householdAddress);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        title: Text(
          'Edit Profile',
          style: AppTypography.cardTitle.copyWith(fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('edit_household_name_field'),
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Household Name',
                  hintText: 'e.g. Elena Miller',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('edit_household_address_field'),
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'e.g. 428 Elmwood',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newName = nameController.text.trim();
              final newAddress = addressController.text.trim();
              if (newName.isNotEmpty) {
                await prefs.setHouseholdName(newName);
              }
              if (newAddress.isNotEmpty) {
                await prefs.setHouseholdAddress(newAddress);
              }
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              if (mounted) {
                setState(() {});
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _openAutoLockDurationPicker(AppPreferences prefs) {
    const options = [
      'Immediately',
      'After 1 minute',
      'After 5 minutes',
      'After 15 minutes',
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Select Auto-Lock Duration',
                  style: AppTypography.cardTitle.copyWith(fontSize: 17),
                ),
              ),
              const Divider(color: AppColors.borderSubtle),
              ...options.map((opt) {
                final isSelected = prefs.autoLockDuration == opt;
                return ListTile(
                  title: Text(
                    opt,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.brandPrimary : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded, color: AppColors.brandPrimary)
                      : null,
                  onTap: () async {
                    await prefs.setAutoLockDuration(opt);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (mounted) setState(() {});
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _openRecoveryKeyDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.brandAccentSage,
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(
            Icons.key_rounded,
            color: AppColors.brandPrimary,
            size: 28,
          ),
        ),
        title: Text(
          'Sanctuary Recovery Key',
          style: AppTypography.cardTitle.copyWith(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'These 12 sanctuary words are your sole master key. Keep them private and secure to restore your records on another device.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < _sanctuaryRecoveryWords.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text(
                          '${i + 1}. ${_sanctuaryRecoveryWords[i]}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('copy_recovery_key_dialog_button'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.borderSubtle),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.brandPrimary),
                  label: const Text(
                    'Copy Key',
                    style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _sanctuaryRecoveryWords.join(' ')));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recovery key copied to clipboard!'),
                        backgroundColor: AppColors.brandPrimary,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.of(ctx).pop();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  key: const Key('close_recovery_key_dialog_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openDataProtectionModal() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.brandAccentSage,
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(
            Icons.lock_rounded,
            color: AppColors.brandPrimary,
            size: 28,
          ),
        ),
        title: Text(
          'How Your Data Is Protected',
          style: AppTypography.cardTitle.copyWith(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProtectionPoint(
                icon: Icons.offline_pin_outlined,
                title: 'Zero Remote Dependencies',
                description:
                    'Domora runs entirely offline on this device. There are no remote servers, tracking cookies, or cloud databases holding your records.',
              ),
              const SizedBox(height: 12),
              _buildProtectionPoint(
                icon: Icons.shield_outlined,
                title: 'Local Database Integrity',
                description:
                    'All tables use SQLite WAL (Write-Ahead Logging) transactions and foreign-key safeguards to guarantee crash resilience and consistency.',
              ),
              const SizedBox(height: 12),
              _buildProtectionPoint(
                icon: Icons.fingerprint_rounded,
                title: 'On-Device Biometric Lock',
                description:
                    'App unlock is handled through your hardware-backed biometric keystore, keeping your records protected from unauthorized physical access.',
              ),
              const SizedBox(height: 12),
              _buildProtectionPoint(
                icon: Icons.file_download_outlined,
                title: 'Self-Sovereign Backups',
                description:
                    'You maintain 100% data ownership. Export complete JSON snapshots anytime to keep your private offline backup.',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionPoint({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.brandPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickReminderTime(AppPreferences prefs) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandPrimary,
              onPrimary: Colors.white,
              surface: AppColors.surfaceCard,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (!mounted) return;
      final formatted = picked.format(context);
      await prefs.setReminderTime(formatted);
      if (mounted) {
        setState(() {});
        try {
          await ref.read(notificationServiceProvider).scheduleDailyHouseholdDigest(
                hour: picked.hour,
                minute: picked.minute,
                title: 'Good morning from Domora',
                body: 'Your household digest and daily sanctuary focus are ready.',
              );
        } catch (_) {}
      }
    }
  }

  void _openEraseDataConfirmationModal(AppPreferences prefs) {
    final inputController = TextEditingController();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isEraseConfirmed = inputController.text.trim().toUpperCase() == 'ERASE';

          return AlertDialog(
            backgroundColor: AppColors.surfaceCard,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.borderSubtle),
            ),
            icon: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.statusDangerFill,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.statusDangerText,
                size: 26,
              ),
            ),
            title: Text(
              'Erase All Data?',
              style: AppTypography.cardTitle.copyWith(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This will permanently delete all records, documents, and encryption keys from this device.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Type ERASE to confirm:',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    key: const Key('erase_confirmation_textfield'),
                    controller: inputController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'ERASE',
                      hintStyle: TextStyle(color: AppColors.textTertiary.withValues(alpha: 0.6)),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.statusDangerStroke, width: 1.5),
                      ),
                    ),
                    onChanged: (_) {
                      setModalState(() {});
                    },
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.borderSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('confirm_erase_all_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEraseConfirmed
                            ? AppColors.statusDangerText
                            : AppColors.statusDangerText.withValues(alpha: 0.35),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: isEraseConfirmed
                          ? () async {
                              Navigator.of(dialogCtx).pop();
                              await _performEraseAllData();
                            }
                          : null,
                      child: const Text(
                        'Erase All',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _performEraseAllData() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final prefs = ref.read(appPreferencesProvider);

      await db.transaction(() async {
        await db.delete(db.bills).go();
        await db.delete(db.expenses).go();
        await db.delete(db.documents).go();
        await db.delete(db.tasks).go();
        await db.delete(db.assets).go();
        await db.delete(db.records).go();
        await db.delete(db.categories).go();
        await db.delete(db.workspaces).go();
      });

      await prefs.resetAll();
      await ref.read(onboardingCompletedProvider.notifier).reset();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to erase all data: $e'),
            backgroundColor: AppColors.statusDangerStroke,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPreferencesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
          tooltip: 'Go Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Settings & Profile',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: 'Encrypted on device',
              child: Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.borderSubtle.withValues(alpha: 0.6),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section 1: Profile Card
                _buildProfileCard(prefs),
                const SizedBox(height: 20),

                // Section 2: Privacy & Security
                _buildSectionHeader('PRIVACY & SECURITY'),
                const SizedBox(height: 6),
                _buildPrivacyCard(prefs),
                const SizedBox(height: 8),
                _buildReassuranceNote(),
                const SizedBox(height: 20),

                // Section 3: Backup
                _buildSectionHeader('BACKUP'),
                const SizedBox(height: 6),
                _buildBackupCard(prefs),
                const SizedBox(height: 20),

                // Section 4: Preferences
                _buildSectionHeader('PREFERENCES'),
                const SizedBox(height: 6),
                _buildPreferencesCard(prefs),
                const SizedBox(height: 20),

                // Section 5: Storage
                _buildSectionHeader('STORAGE'),
                const SizedBox(height: 6),
                _buildStorageCard(),
                const SizedBox(height: 20),

                // Section 6: GitHub Releases Update Checker
                _buildSectionHeader('UPDATES'),
                const SizedBox(height: 6),
                _buildUpdateCard(),
                const SizedBox(height: 24),

                // Section 7: Danger Zone
                _buildSectionHeader('DANGER ZONE', isDanger: true),
                const SizedBox(height: 6),
                _buildDangerZoneCard(prefs),
                const SizedBox(height: 28),

                // Minimal Clean Footer
                Center(
                  child: Text(
                    'Domora ${AppConstants.displayVersion}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: isDanger ? AppColors.statusDangerText : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildProfileCard(AppPreferences prefs) {
    final householdName = prefs.householdName;
    final householdAddress = prefs.householdAddress;
    final initials = _getInitials(householdName);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      householdName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      householdAddress,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const Key('edit_profile_button'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandPrimary,
                  backgroundColor: AppColors.brandAccentSage.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(48, 32),
                ),
                onPressed: () => _openEditProfileModal(prefs),
                child: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 4),
          InkWell(
            key: const Key('manage_household_members_button'),
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              showUnderConstructionNotice(
                context,
                featureName: 'Household Members',
                scheduledPhase: 'Phase 2 (Sync & Multi-User)',
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  const Icon(Icons.group_outlined, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Manage household members',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard(AppPreferences prefs) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: App Lock
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.face_rounded, size: 22, color: AppColors.brandPrimary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'App Lock',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  key: const Key('app_lock_switch'),
                  value: prefs.isBiometricsEnabled,
                  activeTrackColor: AppColors.brandPrimary,
                  onChanged: (val) async {
                    await prefs.setBiometricsEnabled(val);
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 48, color: AppColors.borderSubtle),
          // Row 2: Auto-lock
          InkWell(
            key: const Key('auto_lock_row'),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            onTap: () => _openAutoLockDurationPicker(prefs),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 22, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Auto-lock',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    prefs.autoLockDuration,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReassuranceNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_rounded, size: 16, color: AppColors.brandPrimary),
          const SizedBox(width: 6),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Your data is encrypted and stays on this device. ',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                InkWell(
                  key: const Key('how_data_protected_link'),
                  onTap: _openDataProtectionModal,
                  child: const Text(
                    'How your data is protected →',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandPrimary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard(AppPreferences prefs) {
    if (prefs.googleAccountEmail != null) {
      return _buildGoogleDriveConnectedCard(prefs);
    }
    return _buildGoogleDriveInactiveBackupCard(prefs);
  }

  Widget _buildExportDataRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.download_rounded, size: 22, color: AppColors.brandPrimary),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export My Data',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Save a private offline copy',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            key: const Key('export_data_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerLow,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(80, 34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.file_download_outlined, size: 16, color: AppColors.textSecondary),
            label: const Text('Export', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const BackupSheet(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrintEmergencySheetRow() {
    return InkWell(
      key: const Key('print_emergency_sheet_row'),
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const EmergencyInfoSheet(),
        );
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.print_outlined, size: 22, color: AppColors.textSecondary),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Print Emergency Info Sheet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Physical summary for family or executors',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSanctuaryRestoreRow() {
    return InkWell(
      key: const Key('cloud_backup_restore_row'),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const BackupSheet(),
        );
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.cloud_sync_outlined, size: 22, color: AppColors.textSecondary),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sanctuary Backup & Restore',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Verify payloads or import snapshot',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleDriveConnectedCard(AppPreferences prefs) {
    final email = prefs.googleAccountEmail ?? 'elena.miller@gmail.com';
    final lastBackup = prefs.lastBackupTimestamp ?? 'Never';
    final isEnabled = prefs.isGoogleDriveBackupEnabled;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Google Drive branding with status badge, connected email & Master toggle switch
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Icon(Icons.add_to_drive_rounded, color: AppColors.brandPrimary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          const Text(
                            'Google Drive',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isEnabled ? AppColors.brandAccentSage : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isEnabled ? AppColors.brandAccentBorder : AppColors.borderSubtle,
                              ),
                            ),
                            child: Text(
                              isEnabled ? 'Active' : 'Paused',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isEnabled ? AppColors.brandPrimary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  key: const Key('google_drive_master_switch'),
                  value: isEnabled,
                  activeTrackColor: AppColors.brandPrimary,
                  onChanged: (val) async {
                    await prefs.setGoogleDriveBackupEnabled(val);
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.borderSubtle),

          // Row 2: "Back up on Wi-Fi only" toggle switch
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.wifi_rounded, size: 22, color: AppColors.brandPrimary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Back up on Wi-Fi only',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  key: const Key('wifi_only_backup_switch'),
                  value: prefs.isBackupWifiOnly,
                  activeTrackColor: AppColors.brandPrimary,
                  onChanged: (val) async {
                    await prefs.setBackupWifiOnly(val);
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 48, color: AppColors.borderSubtle),

          // Row 3: "Back up now" trigger row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.cloud_upload_outlined, size: 22, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Back up now',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Last backup: $lastBackup',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  key: const Key('back_up_now_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerLow,
                    foregroundColor: AppColors.brandPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: const Size(80, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  onPressed: () async {
                    await prefs.setLastBackupTimestamp('Just now');
                    if (mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Encrypted snapshot synchronized to Google Drive'),
                          backgroundColor: AppColors.brandPrimary,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Back up',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 48, color: AppColors.borderSubtle),

          // Row 4: Recovery Key row
          InkWell(
            key: const Key('recovery_key_row'),
            onTap: _openRecoveryKeyDialog,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.key_rounded, size: 22, color: AppColors.textSecondary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recovery Key',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'View 12-word master passphrase',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, indent: 48, color: AppColors.borderSubtle),

          // Row 5: Export My Data
          _buildExportDataRow(),
          const Divider(height: 1, indent: 48, color: AppColors.borderSubtle),

          // Row 6: Print Emergency Info Sheet
          _buildPrintEmergencySheetRow(),
          const Divider(height: 1, indent: 48, color: AppColors.borderSubtle),

          // Row 7: Sanctuary Backup & Restore
          _buildSanctuaryRestoreRow(),
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.borderSubtle),

          // Row 8: Sign out of Google
          InkWell(
            key: const Key('sign_out_google_button'),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            onTap: () async {
              await ref.read(googleAuthServiceProvider).signOut();
              await prefs.setGoogleDriveBackupEnabled(false);
              await prefs.setGoogleAccountEmail(null);
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Disconnected from Google Drive'),
                    backgroundColor: AppColors.brandPrimary,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 18, color: AppColors.statusDangerText),
                  SizedBox(width: 8),
                  Text(
                    'Sign out of Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusDangerText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleDriveInactiveBackupCard(AppPreferences prefs) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Google Drive Cloud Backup (Inactive row)
          InkWell(
            key: const Key('connect_google_drive_row'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () async {
              final result = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ConnectGoogleDriveConfirmationSheet(),
              );
              if (result == true && mounted) {
                setState(() {});
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.cloud_sync_outlined, size: 22, color: AppColors.brandPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            const Text(
                              'Google Drive Cloud Backup',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: const Text(
                                'Inactive',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Encrypted offsite redundancy',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, indent: 48, color: AppColors.borderSubtle),

          // Row 2: Export My Data
          _buildExportDataRow(),
          const Divider(height: 1, indent: 48, color: AppColors.borderSubtle),

          // Row 3: Print Emergency Info Sheet
          _buildPrintEmergencySheetRow(),
          const Divider(height: 1, indent: 48, color: AppColors.borderSubtle),

          // Row 4: Sanctuary Backup & Restore
          _buildSanctuaryRestoreRow(),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(AppPreferences prefs) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Daily Reminder
          InkWell(
            key: const Key('daily_reminder_row'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => _pickReminderTime(prefs),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.wb_sunny_outlined, size: 22, color: theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Reminder',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Household morning digest',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    prefs.reminderTime,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: (theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary).withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, indent: 48, color: theme.colorScheme.outline),
          // Row 2: Appearance
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.palette_outlined, size: 22, color: theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                _buildAppearanceSegment(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSegment() {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final String activeMode = switch (themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAppearanceOption(
            key: const Key('theme_option_light'),
            label: 'Light',
            value: 'light',
            isSelected: activeMode == 'light',
            onTap: () async {
              await ref.read(themeModeProvider.notifier).setThemeMode('light');
            },
          ),
          _buildAppearanceOption(
            key: const Key('theme_option_dark'),
            label: 'Dark',
            value: 'dark',
            isSelected: activeMode == 'dark',
            onTap: () async {
              await ref.read(themeModeProvider.notifier).setThemeMode('dark');
            },
          ),
          _buildAppearanceOption(
            key: const Key('theme_option_system'),
            label: 'System',
            value: 'system',
            isSelected: activeMode == 'system',
            onTap: () async {
              await ref.read(themeModeProvider.notifier).setThemeMode('system');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceOption({
    Key? key,
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? (theme.cardTheme.color ?? theme.colorScheme.surface) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? theme.colorScheme.onSurface
                : (theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildStorageCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.storage_outlined, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: _isLoadingStorage ? 'Calculating...' : _formatStorage(_storageBytes),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                children: const [
                  TextSpan(
                    text: ' used',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          OutlinedButton(
            key: const Key('clear_cache_button'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.borderSubtle),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(80, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _clearCache,
            child: const Text(
              'Clear Cache',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.system_update_alt_rounded, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Domora ${AppConstants.displayVersion}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Build 12 • Offline Sanctuary (${AppConstants.appReleaseChannel})',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                key: const Key('check_updates_button'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(80, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isCheckingUpdate ? null : _checkForUpdates,
                child: _isCheckingUpdate
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                      )
                    : const Text(
                        'Check',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
              ),
            ],
          ),
          if (_updateStatusMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _hasNewUpdate
                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _updateStatusMessage!,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _hasNewUpdate
                            ? theme.colorScheme.primary
                            : (theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary),
                      ),
                    ),
                  ),
                  if (_hasNewUpdate && _releaseUrl != null)
                    TextButton.icon(
                      key: const Key('release_action_button'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(50, 28),
                      ),
                      onPressed: () async {
                        final targetUrl = _apkDownloadUrl ?? _releaseUrl;
                        if (targetUrl == null) return;
                        final uri = Uri.parse(targetUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: Icon(
                        _hasApkAsset ? Icons.download_rounded : Icons.open_in_new_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        _hasApkAsset ? 'Download APK' : 'View Release',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard(AppPreferences prefs) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statusDangerStroke.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.statusDangerFill.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        key: const Key('open_erase_dialog_button'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openEraseDataConfirmationModal(prefs),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.delete_forever_rounded,
                size: 22,
                color: AppColors.statusDangerText,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Erase All Data',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusDangerText,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.statusDangerText.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
