import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Step 0: Welcome presentation screen.
class WelcomeStep extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onOpenBackupSheet;

  const WelcomeStep({
    super.key,
    required this.onGetStarted,
    required this.onOpenBackupSheet,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Brand Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.eco,
                  color: AppColors.brandOnPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Domora',
                style: AppTypography.pageHeader.copyWith(
                  color: AppColors.brandPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Hero Visual Card
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brandHover,
                  AppColors.brandPrimary,
                  Color(0xFF265A44),
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.cottage_outlined,
                    size: 90,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                // Top-right Vault badge
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield, size: 14, color: AppColors.brandPrimary),
                        const SizedBox(width: 4),
                        Text(
                          'VAULT',
                          style: AppTypography.badge.copyWith(
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom-left Sanctuary label
                Positioned(
                  bottom: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.spa, size: 14, color: AppColors.brandPrimary),
                        const SizedBox(width: 6),
                        Text(
                          'Living Sanctuary',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Headline & Description
          const Text(
            'Your home & life, in one safe place',
            style: AppTypography.pageHeader,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'A calm, private archive for everything about your property, health, warranties, and vital records.',
            style: AppTypography.bodyPrimary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Feature Highlights Badges
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _FeatureBadge(icon: Icons.lock_outline, label: '100% on-device encryption'),
              _FeatureBadge(icon: Icons.visibility_off_outlined, label: 'Zero cloud tracking'),
            ],
          ),
          const SizedBox(height: 36),

          // Action Buttons
          ElevatedButton(
            onPressed: onGetStarted,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Get Started'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onOpenBackupSheet,
            child: Text(
              'I already have a backup',
              style: AppTypography.bodySecondary.copyWith(
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                'Private and encrypted. Only you can see your data.',
                style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brandPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.brandPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
