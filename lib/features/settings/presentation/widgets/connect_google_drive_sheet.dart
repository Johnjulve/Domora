import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/services/app_preferences.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/services/google_sign_in_web_button_stub.dart'
    if (dart.library.js_interop) '../../../../core/services/google_sign_in_web_button_web.dart'
    as google_web_button;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// Modal confirmation bottom sheet (Screen 12) for connecting Google Drive Cloud Redundancy.
///
/// Assures users of Zero-Knowledge encryption, client-side cryptographic isolation,
/// and private sandboxed folder storage before enabling automated backups.
class ConnectGoogleDriveConfirmationSheet extends ConsumerStatefulWidget {
  const ConnectGoogleDriveConfirmationSheet({
    super.key,
    this.webSignInButtonBuilder,
  });

  /// Optional builder override for the Web Google Sign-In button (used in tests).
  final WidgetBuilder? webSignInButtonBuilder;

  @override
  ConsumerState<ConnectGoogleDriveConfirmationSheet> createState() =>
      _ConnectGoogleDriveConfirmationSheetState();
}

class _ConnectGoogleDriveConfirmationSheetState
    extends ConsumerState<ConnectGoogleDriveConfirmationSheet> {
  bool _isLoading = false;
  bool _isWebReady = false;
  bool _hasCompleted = false;
  String? _statusMessage;
  bool _isError = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final authService = ref.read(googleAuthServiceProvider);
    if (authService.usesWebSignInButton) {
      _initWebSignIn(authService);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initWebSignIn(GoogleAuthService authService) async {
    _authSubscription = authService.authenticationEvents.listen(
      (event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _completeSignIn(event.user);
        }
      },
      onError: (Object error) {
        if (!mounted) return;
        final isCanceled = error is GoogleSignInException &&
            error.code == GoogleSignInExceptionCode.canceled;
        setState(() {
          _isLoading = false;
          _statusMessage = isCanceled
              ? 'Google sign-in cancelled or unavailable'
              : GoogleAuthService.formatError(error);
          _isError = !isCanceled;
        });
      },
    );

    try {
      await authService.initialize();
      if (!mounted) return;
      setState(() => _isWebReady = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = GoogleAuthService.formatError(e);
        _isError = true;
      });
    }
  }

  Widget _buildPromiseRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: context.brandAccent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.5,
                  color: context.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _completeSignIn(GoogleSignInAccount account) async {
    if (_hasCompleted) return;
    _hasCompleted = true;

    try {
      ref.read(googleAuthServiceProvider).recordSignedInAccount(account);
      final prefs = ref.read(appPreferencesProvider);
      await prefs.setGoogleAccountEmail(account.email);
      await prefs.setGoogleDriveBackupEnabled(true);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _hasCompleted = false;
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Failed to save Google account settings: $e';
          _isError = true;
        });
      }
    }
  }

  Future<void> _handleConnectGoogleAccount() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isError = false;
    });
    final authService = ref.read(googleAuthServiceProvider);

    final account = await authService.signIn();
    if (account != null) {
      await _completeSignIn(account);
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage =
            authService.lastError ?? 'Google sign-in cancelled or unavailable';
        _isError = authService.lastError != null;
      });
    }
  }

  Widget _buildStatusBanner(BuildContext context) {
    final isDark = context.isDarkMode;
    final Color fillColor;
    final Color borderColor;
    final Color iconColor;
    final Color textColor;

    if (_isError) {
      fillColor = isDark
          ? AppColors.statusDangerStroke.withValues(alpha: 0.14)
          : AppColors.statusDangerFill;
      borderColor = isDark
          ? AppColors.statusDangerStroke.withValues(alpha: 0.45)
          : AppColors.statusDangerStroke;
      iconColor =
          isDark ? AppColors.statusDangerStroke : AppColors.statusDangerText;
      textColor =
          isDark ? AppColors.statusDangerFill : AppColors.statusDangerText;
    } else {
      fillColor = context.surfaceContainerLow;
      borderColor = context.borderSubtle;
      iconColor = context.textSecondary;
      textColor = context.textSecondary;
    }

    return Container(
      key: const Key('google_sign_in_status_banner'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              _isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                fontSize: 12.5,
                color: textColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction(BuildContext context, bool usesWebButton) {
    if (usesWebButton) {
      return Container(
        key: const Key('google_web_sign_in_button'),
        alignment: Alignment.center,
        constraints: const BoxConstraints(minHeight: AppTheme.buttonHeight),
        child: _isWebReady
            ? (widget.webSignInButtonBuilder?.call(context) ??
                google_web_button.renderGoogleSignInWebButton())
            : (_statusMessage == null
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(context.brandAccent),
                    ),
                  )
                : const SizedBox.shrink()),
      );
    }

    return ElevatedButton(
      key: const Key('connect_google_account_button'),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.isDarkMode
            ? AppTheme.darkBrandPrimary
            : AppColors.brandPrimary,
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
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.brandOnPrimary),
              ),
            )
          : const Text(
              'Connect Google Account',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usesWebButton = ref.read(googleAuthServiceProvider).usesWebSignInButton;
    return PopScope(
      canPop: !_isLoading,
      child: Container(
        key: const Key('connect_google_drive_sheet'),
        decoration: BoxDecoration(
          color: Theme.of(context).bottomSheetTheme.backgroundColor ?? context.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
          border: Border(
            top: BorderSide(color: context.borderSubtle),
            left: BorderSide(color: context.borderSubtle),
            right: BorderSide(color: context.borderSubtle),
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
          child: SingleChildScrollView(
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
                    color: context.borderSubtle,
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
                      color: context.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderSubtle),
                    ),
                    child: Icon(
                      Icons.add_to_drive_rounded,
                      color: context.brandAccent,
                      size: 24,
                    ),
                  ),
                  Container(
                    key: const Key('zero_knowledge_badge'),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? AppTheme.darkBrandSecondary.withValues(alpha: 0.15)
                          : AppColors.brandAccentSage,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: context.isDarkMode
                            ? AppTheme.darkBrandSecondary.withValues(alpha: 0.3)
                            : AppColors.brandAccentBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user,
                          size: 14,
                          color: context.brandAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Zero-Knowledge',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.brandAccent,
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
              Text(
                'Back up to Google Drive?',
                style: AppTypography.pageHeader.copyWith(color: context.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Keep household records safely synced across devices while preserving full end-to-end privacy.',
                style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
              ),
              const SizedBox(height: 18),

              // Privacy Card with 3 Promises
              Container(
                decoration: BoxDecoration(
                  color: context.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderSubtle),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    _buildPromiseRow(
                      context,
                      icon: Icons.lock_outline_rounded,
                      title: 'Encrypted before upload',
                      description:
                          'Vault sealed with local private key before leaving this phone.',
                    ),
                    Divider(height: 20, color: context.borderSubtle),
                    _buildPromiseRow(
                      context,
                      icon: Icons.key_rounded,
                      title: 'Only you can read it',
                      description: 'Neither Google nor Domora holds the keys.',
                    ),
                    Divider(height: 20, color: context.borderSubtle),
                    _buildPromiseRow(
                      context,
                      icon: Icons.folder_special_outlined,
                      title: 'Stored in a private app folder',
                      description: 'Isolated sandbox container on your Drive.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Status/Error Banner + Actions
              if (_statusMessage != null) _buildStatusBanner(context),
              _buildPrimaryAction(context, usesWebButton),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('not_now_button'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  foregroundColor: context.textSecondary,
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
      ),
    );
  }
}
