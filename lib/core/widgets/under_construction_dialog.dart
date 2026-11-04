import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Displays an explicit notice for workflows that are actively under construction,
/// ensuring zero silent or inert UI actions.
void showUnderConstructionNotice(
  BuildContext context, {
  required String featureName,
  required String scheduledPhase,
}) {
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
          Icons.construction_rounded,
          color: AppColors.brandPrimary,
          size: 28,
        ),
      ),
      title: Text(
        'Feature Under Construction',
        style: AppTypography.cardTitle.copyWith(fontSize: 18),
        textAlign: TextAlign.center,
      ),
      content: Text(
        '$featureName is currently scheduled for implementation in $scheduledPhase.',
        style: AppTypography.bodyPrimary,
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 44),
          ),
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Understood'),
        ),
      ],
    ),
  );
}
