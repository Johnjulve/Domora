import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_preferences.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// Modal confirmation bottom sheet (Screen 12) for connecting Google Drive Cloud Redundancy.
///
/// Assures users of Zero-Knowledge encryption, client-side cryptographic isolation,
/// and private sandboxed folder storage before enabling automated backups.
class ConnectGoogleDriveConfirmationSheet extends ConsumerStatefulWidget {
  const ConnectGoogleDriveConfirmationSheet({super.key});

  @override
  ConsumerState<ConnectGoogleDriveConfirmationSheet> createState() =>
      _ConnectGoogleDriveConfirmationSheetState();
}

class _ConnectGoogleDriveConfirmationSheetState
    extends ConsumerState<ConnectGoogleDriveConfirmationSheet> {
  bool _isLoading = false;

  Widget _buildPromiseRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: AppColors.brandPrimary),
        ),
        const SizedBox(width: 12),
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
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleConnectGoogleAccount() async {
    setState(() => _isLoading = true);

    try {
      final account = await ref.read(googleAuthServiceProvider).signIn();
      if (account != null) {
        final prefs = ref.read(appPreferencesProvider);
        await prefs.setGoogleAccountEmail(account.email);
        await prefs.setGoogleDriveBackupEnabled(true);
        if (mounted) {
          Navigator.pop(context, true);
        }
        return;
      }
    } catch (_) {
      // Handled by user feedback below
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-in cancelled or unavailable'),
          backgroundColor: AppColors.brandPrimary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: Container(
        key: const Key('connect_google_drive_sheet'),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle),
            left: BorderSide(color: AppColors.borderSubtle),
            right: BorderSide(color: AppColors.borderSubtle),
          ),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sanctuary Grab Handle (36x4)
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: Google Drive icon + Zero-Knowledge security badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: const Icon(
                      Icons.add_to_drive_rounded,
                      color: AppColors.brandPrimary,
                      size: 24,
                    ),
                  ),
                  Container(
                    key: const Key('zero_knowledge_badge'),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandAccentSage,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.brandAccentBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user, size: 14, color: AppColors.brandPrimary),
                        SizedBox(width: 4),
                        Text(
                          'Zero-Knowledge',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Headline & Subtext
              const Text(
                'Back up to Google Drive?',
                style: AppTypography.pageHeader,
              ),
              const SizedBox(height: 6),
              const Text(
                'Keep household records safely synced across devices while preserving full end-to-end privacy.',
                style: AppTypography.bodySecondary,
              ),
              const SizedBox(height: 18),

              // Privacy Card with 3 Promises
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    _buildPromiseRow(
                      icon: Icons.lock_outline_rounded,
                      title: 'Encrypted before upload',
                      description:
                          'Vault sealed with local private key before leaving this phone.',
                    ),
                    const Divider(height: 20, color: AppColors.borderSubtle),
                    _buildPromiseRow(
                      icon: Icons.key_rounded,
                      title: 'Only you can read it',
                      description: 'Neither Google nor Domora holds the keys.',
                    ),
                    const Divider(height: 20, color: AppColors.borderSubtle),
                    _buildPromiseRow(
                      icon: Icons.folder_special_outlined,
                      title: 'Stored in a private app folder',
                      description: 'Isolated sandbox container on your Drive.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actions: Connect Google Account (Primary) & Not now (Secondary)
              ElevatedButton(
                key: const Key('connect_google_account_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: AppColors.brandOnPrimary,
                  minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                  ),
                ),
                onPressed: _isLoading ? null : _handleConnectGoogleAccount,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandOnPrimary),
                        ),
                      )
                    : const Text(
                        'Connect Google Account',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('not_now_button'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  foregroundColor: AppColors.textSecondary,
                ),
                onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                child: const Text(
                  'Not now',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
