import 'package:domora/core/theme/app_colors.dart';
import 'package:domora/core/theme/app_theme.dart';
import 'package:domora/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sanctuary Archival Design System Tests', () {
    test('AppColors matches Sanctuary Archival token specification', () {
      expect(AppColors.surfaceCanvas, const Color(0xFFFAF9F6));
      expect(AppColors.brandPrimary, const Color(0xFF1E4B38));
      expect(AppColors.brandAccentSage, const Color(0xFFEAF2EC));
      expect(AppColors.textPrimary, const Color(0xFF1A201C));
      expect(AppColors.borderSubtle, const Color(0xFFEBE8E1));
    });

    test('AppTypography provides calibrated hierarchy', () {
      expect(AppTypography.displayHero.fontSize, 30);
      expect(AppTypography.displayHero.fontWeight, FontWeight.w700);
      expect(AppTypography.pageHeader.fontSize, 24);
      expect(AppTypography.sectionTitle.fontSize, 20);
      expect(AppTypography.cardTitle.fontSize, 16);
      expect(AppTypography.bodyPrimary.fontSize, 15);
      expect(AppTypography.bodySecondary.fontSize, 13);
      expect(AppTypography.badge.fontSize, 11);
    });

    test('AppTheme builds valid ThemeData matching Sanctuary specifications', () {
      final theme = AppTheme.lightTheme;

      expect(theme.scaffoldBackgroundColor, AppColors.surfaceCanvas);
      expect(theme.colorScheme.primary, AppColors.brandPrimary);
      expect(theme.colorScheme.surface, AppColors.surfaceCanvas);
      expect(theme.cardTheme.color, AppColors.surfaceCard);
      expect(theme.cardTheme.elevation, 0);

      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(cardShape.borderRadius, BorderRadius.circular(18));
      expect(cardShape.side.color, AppColors.borderSubtle);

      expect(theme.bottomSheetTheme.modalBarrierColor, AppColors.scrimOverlay);
      expect(theme.textTheme.bodyLarge?.fontSize, 15);
      expect(theme.textTheme.titleMedium?.fontSize, 16);
    });
  });
}
