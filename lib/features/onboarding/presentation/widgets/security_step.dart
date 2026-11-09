import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_shared_widgets.dart';

final onboardingBiometricsEnabledProvider = NotifierProvider<OnboardingBiometricsNotifier, bool>(
  OnboardingBiometricsNotifier.new,
);

class OnboardingBiometricsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setEnabled(bool enabled) => state = enabled;
}

/// Step 3: Biometric security presentation and enrollment.
class SecurityStep extends ConsumerWidget {
  final VoidCallback onContinue;

  const SecurityStep({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricsEnabled = ref.watch(onboardingBiometricsEnabledProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnboardingProgressIndicator(activeStep: 3),
          const SizedBox(height: 16),
          const Center(
            child: OnboardingCategoryPill(icon: Icons.verified_user_outlined, label: 'On-Device Vault'),
          ),
          const SizedBox(height: 10),
          Text(
            'Protect your records',
            style: AppTypography.pageHeader.copyWith(color: context.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Add biometric security so only you can unlock Domora.',
            style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Centered Biometric Illustration
          Center(
            child: GestureDetector(
              onTap: () {
                ref.read(onboardingBiometricsEnabledProvider.notifier).toggle();
                final enabled = ref.read(onboardingBiometricsEnabledProvider);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      enabled
                          ? 'Biometric vault protection enabled'
                          : 'Biometric vault protection disabled',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.isDarkMode
                      ? AppTheme.darkBrandSecondary.withValues(alpha: 0.1)
                      : AppColors.brandAccentSage.withValues(alpha: 0.6),
                ),
                child: Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.isDarkMode
                          ? AppTheme.darkBrandSecondary.withValues(alpha: 0.2)
                          : AppColors.brandAccentSage,
                    ),
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: biometricsEnabled
                              ? (context.isDarkMode ? AppTheme.darkBrandPrimary : AppColors.brandPrimary)
                              : context.surfaceCard,
                          boxShadow: [
                            BoxShadow(
                              color: context.textPrimary.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          biometricsEnabled ? Icons.check_circle : Icons.fingerprint,
                          size: 44,
                          color: biometricsEnabled
                              ? AppColors.brandOnPrimary
                              : context.brandAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Security Features Card
          Card(
            color: context.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              side: BorderSide(color: context.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSecurityRow(
                    context: context,
                    icon: Icons.timer_off_outlined,
                    title: 'Instant app lock',
                    description: 'Locks immediately when you switch apps or close your screen.',
                  ),
                  Divider(height: 24, color: context.borderSubtle),
                  _buildSecurityRow(
                    context: context,
                    icon: Icons.shield_outlined,
                    title: 'Hardware protected',
                    description: "Biometrics stay strictly inside your phone's Secure Enclave.",
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Archival Badge Preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.folder_special_outlined, size: 20, color: context.brandAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Vault Encryption Ready',
                      style: AppTypography.cardTitle.copyWith(color: context.textPrimary),
                    ),
                  ],
                ),
                Text(
                  'AES-256',
                  style: AppTypography.badge.copyWith(
                    color: context.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.isDarkMode ? AppTheme.darkBrandPrimary : AppColors.brandPrimary,
              foregroundColor: AppColors.brandOnPrimary,
            ),
            onPressed: () {
              ref.read(onboardingBiometricsEnabledProvider.notifier).setEnabled(true);
              onContinue();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fingerprint, size: 20),
                const SizedBox(width: 8),
                Text(biometricsEnabled ? 'Biometrics Enabled • Continue' : 'Turn on Biometrics'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              ref.read(onboardingBiometricsEnabledProvider.notifier).setEnabled(false);
              onContinue();
            },
            child: Text(
              'Skip for now',
              style: AppTypography.bodySecondary.copyWith(
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.borderSubtle),
          ),
          child: Icon(icon, color: context.brandAccent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.cardTitle.copyWith(color: context.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.caption.copyWith(color: context.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
