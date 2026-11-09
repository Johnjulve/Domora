import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Screen 4: Sanctuary App Lock Screen.
/// Protects the user's private records and vault with biometric authentication,
/// providing an immediate fallback for environments or devices without biometric enrollment.
class AppLockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  final bool autoPrompt;

  const AppLockScreen({
    super.key,
    required this.onUnlocked,
    this.autoPrompt = true,
  });

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.autoPrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _triggerBiometricAuth();
      });
    }
  }

  Future<void> _triggerBiometricAuth() async {
    if (!mounted || _isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final biometricService = ref.read(biometricServiceProvider);
    final success = await biometricService.authenticate(
      localizedReason: 'Scan fingerprint or face to unlock Domora',
    );

    if (!mounted) return;

    setState(() {
      _isAuthenticating = false;
    });

    if (success) {
      widget.onUnlocked();
    } else {
      setState(() {
        _errorMessage = 'Authentication could not be completed. Use Quick Unlock to proceed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Concentric sage circles illustration
              Center(
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brandAccentSage.withValues(alpha: 0.6),
                  ),
                  child: Center(
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandAccentSage,
                      ),
                      child: Center(
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceCard,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.textPrimary.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.fingerprint,
                            size: 44,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Domora is Locked',
                style: AppTypography.pageHeader,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan your fingerprint or face to access your private sanctuary vault',
                style: AppTypography.bodySecondary,
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  key: const Key('lock_error_message'),
                  style: AppTypography.caption.copyWith(color: AppColors.statusDangerStroke),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('unlock_biometrics_button'),
                  onPressed: _isAuthenticating ? null : _triggerBiometricAuth,
                  icon: _isAuthenticating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brandOnPrimary,
                          ),
                        )
                      : const Icon(Icons.fingerprint),
                  label: Text(_isAuthenticating ? 'Authenticating...' : 'Unlock with Biometrics'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('quick_unlock_button'),
                onPressed: widget.onUnlocked,
                child: Text(
                  'Quick Unlock (Alpha Fallback)',
                  style: AppTypography.bodySecondary.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
