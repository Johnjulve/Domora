import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Shared 4-step horizontal pill progress bar used across onboarding steps.
class OnboardingProgressIndicator extends StatelessWidget {
  final int activeStep;
  final int totalSteps;

  const OnboardingProgressIndicator({
    super.key,
    required this.activeStep,
    this.totalSteps = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            final isCurrentOrPast = index < activeStep;
            return Container(
              width: 24,
              height: 5,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: isCurrentOrPast ? AppColors.brandPrimary : AppColors.surfaceContainerSubtle,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
        Text(
          'STEP $activeStep OF $totalSteps',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

/// Shared category chip badge used across onboarding headers.
class OnboardingCategoryPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const OnboardingCategoryPill({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.brandAccentSage,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brandPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.brandPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
