import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_shared_widgets.dart';

/// Step 1: Explains Domora's offline-first zero-knowledge architecture.
class HowItWorksStep extends StatelessWidget {
  final VoidCallback onContinue;

  const HowItWorksStep({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnboardingProgressIndicator(activeStep: 1),
          const SizedBox(height: 16),
          const OnboardingCategoryPill(icon: Icons.verified_user_outlined, label: 'Zero-Knowledge Architecture'),
          const SizedBox(height: 10),
          const Text('How Domora works', style: AppTypography.pageHeader),
          const SizedBox(height: 4),
          const Text(
            'A private home for the details that matter most.',
            style: AppTypography.bodySecondary,
          ),
          const SizedBox(height: 20),

          // 3 Architecture Cards
          const _InfoFeatureCard(
            icon: Icons.folder_outlined,
            title: 'Keep everything together',
            badge: 'Archive',
            description: 'Homes, vehicles, pets, warranties, and vital records organized in one serene place.',
          ),
          const SizedBox(height: 12),
          const _InfoFeatureCard(
            icon: Icons.notifications_active_outlined,
            title: 'Never miss a date',
            badge: 'Automated',
            description: 'Automatic alerts for policy renewals, routine maintenance, and seasonal life tasks.',
          ),
          const SizedBox(height: 12),
          const _InfoFeatureCard(
            icon: Icons.key_outlined,
            title: 'Private by design',
            badge: 'On-Device',
            badgeBgColor: AppColors.brandAccentSage,
            badgeTextColor: AppColors.brandPrimary,
            description: 'Encrypted directly on your phone. Only you hold the cryptographic key to read records.',
          ),
          const SizedBox(height: 20),

          // Offline Pill
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 8, color: AppColors.brandPrimary),
                  const SizedBox(width: 6),
                  Text(
                    'Offline-capable & hardware-isolated key vault',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: onContinue,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Continue'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'No personal cloud account required to begin.',
              style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String badge;
  final String description;
  final Color? badgeBgColor;
  final Color? badgeTextColor;

  const _InfoFeatureCard({
    required this.icon,
    required this.title,
    required this.badge,
    required this.description,
    this.badgeBgColor,
    this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.brandPrimary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: AppTypography.cardTitle),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBgColor ?? AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge,
                          style: AppTypography.badge.copyWith(
                            color: badgeTextColor ?? AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTypography.bodySecondary.copyWith(fontSize: 13),
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
