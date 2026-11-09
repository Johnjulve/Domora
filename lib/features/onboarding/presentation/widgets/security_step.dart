import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
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
          const Text(
            'Protect your records',
            style: AppTypography.pageHeader,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Add biometric security so only you can unlock Domora.',
            style: AppTypography.bodySecondary,
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
                          color: biometricsEnabled ? AppColors.brandPrimary : AppColors.surfaceCard,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPrimary.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          biometricsEnabled ? Icons.check_circle : Icons.fingerprint,
                          size: 44,
                          color: biometricsEnabled ? AppColors.brandOnPrimary : AppColors.brandPrimary,
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSecurityRow(
                    icon: Icons.timer_off_outlined,
                    title: 'Instant app lock',
                    description: 'Locks immediately when you switch apps or close your screen.',
                  ),
                  const Divider(height: 24),
                  _buildSecurityRow(
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
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.folder_special_outlined, size: 20, color: AppColors.brandPrimary),
                    SizedBox(width: 8),
                    Text('Vault Encryption Ready', style: AppTypography.cardTitle),
                  ],
                ),
                Text(
                  'AES-256',
                  style: AppTypography.badge.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
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
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityRow({
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
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.brandPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.cardTitle),
              const SizedBox(height: 2),
              Text(description, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
