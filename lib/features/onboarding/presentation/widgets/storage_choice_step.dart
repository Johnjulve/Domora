import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/under_construction_dialog.dart';
import 'onboarding_shared_widgets.dart';

final onboardingStorageChoiceProvider = NotifierProvider<OnboardingStorageChoiceNotifier, String>(
  OnboardingStorageChoiceNotifier.new,
);

class OnboardingStorageChoiceNotifier extends Notifier<String> {
  @override
  String build() => 'offline';

  void setChoice(String choice) => state = choice;
}

/// Step 2: Storage preference selection (Google Drive Cloud Backup vs Offline On-Device Vault).
class StorageChoiceStep extends ConsumerWidget {
  final VoidCallback onContinue;

  const StorageChoiceStep({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode = ref.watch(onboardingStorageChoiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnboardingProgressIndicator(activeStep: 2),
          const SizedBox(height: 16),
          const OnboardingCategoryPill(icon: Icons.shield_outlined, label: 'Zero-Knowledge Architecture'),
          const SizedBox(height: 10),
          const Text('How would you like to start?', style: AppTypography.pageHeader),
          const SizedBox(height: 4),
          const Text(
            "Choose whether you'd like private cloud backup or complete offline-only storage.",
            style: AppTypography.bodySecondary,
          ),
          const SizedBox(height: 20),

          // Option 1: Continue without an account (Offline - Functional Default)
          _StorageOptionCard(
            isSelected: selectedMode == 'offline',
            onTap: () => ref.read(onboardingStorageChoiceProvider.notifier).setChoice('offline'),
            icon: Icons.phone_android_outlined,
            title: 'Continue without an account',
            badge: 'Active & Offline',
            description: 'Your data stays strictly on this device. Complete isolation with zero external cloud sync.',
            perks: const ['100% on-device sandboxed storage', 'Private SQLite database'],
          ),
          const SizedBox(height: 14),

          // Option 2: Continue with Google (Scheduled for Phase 2)
          _StorageOptionCard(
            isSelected: selectedMode == 'google',
            onTap: () {
              ref.read(onboardingStorageChoiceProvider.notifier).setChoice('google');
              showUnderConstructionNotice(
                context,
                featureName: 'Google Drive Cloud Backup',
                scheduledPhase: 'Phase 2',
              );
            },
            icon: Icons.cloud_sync_outlined,
            title: 'Continue with Google',
            badge: 'Scheduled for Phase 2',
            badgeBgColor: AppColors.statusWarningFill,
            badgeTextColor: AppColors.statusWarningText,
            description: 'Automated encrypted vault synchronization with your personal Google Drive storage.',
            perks: const ['Automatic sync', 'End-to-end encrypted backup'],
          ),
          const SizedBox(height: 18),

          // Helper note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.tune, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                'You can configure backup preferences anytime in Settings.',
                style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: () {
              if (selectedMode == 'google') {
                showUnderConstructionNotice(
                  context,
                  featureName: 'Google Drive Cloud Backup',
                  scheduledPhase: 'Phase 2',
                );
              } else {
                onContinue();
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(selectedMode == 'google' ? 'Continue with Google (Phase 2)' : 'Continue Offline'),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageOptionCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String? badge;
  final Color? badgeBgColor;
  final Color? badgeTextColor;
  final String description;
  final List<String> perks;

  const _StorageOptionCard({
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.title,
    this.badge,
    this.badgeBgColor,
    this.badgeTextColor,
    required this.description,
    required this.perks,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : AppColors.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: AppColors.brandPrimary, size: 22),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBgColor ?? AppColors.brandAccentSage,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge!,
                          style: AppTypography.badge.copyWith(
                            color: badgeTextColor ?? AppColors.brandPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.brandPrimary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.brandPrimary : AppColors.borderSubtle,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: AppColors.brandOnPrimary)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: AppTypography.cardTitle),
            const SizedBox(height: 4),
            Text(description, style: AppTypography.bodySecondary.copyWith(fontSize: 13)),
            const Divider(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: perks.map((perk) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: AppColors.brandPrimary),
                    const SizedBox(width: 4),
                    Text(perk, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
