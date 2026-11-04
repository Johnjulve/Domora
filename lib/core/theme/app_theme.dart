import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Central theme configuration for Domora implementing the Sanctuary Archival design system.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const cardRadius = 18.0;
    const buttonHeight = 54.0;
    const inputRadius = 14.0;
    const sheetRadius = 24.0;

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Plus Jakarta Sans',
      fontFamilyFallback: const [
        '-apple-system',
        'BlinkMacSystemFont',
        'Segoe UI',
        'Roboto',
        'sans-serif',
      ],
      scaffoldBackgroundColor: AppColors.surfaceCanvas,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.brandPrimary,
        onPrimary: AppColors.brandOnPrimary,
        secondary: AppColors.brandAccentSage,
        onSecondary: AppColors.brandPrimary,
        surface: AppColors.surfaceCanvas,
        onSurface: AppColors.textPrimary,
        error: AppColors.statusDangerStroke,
        onError: Colors.white,
        outline: AppColors.borderSubtle,
        surfaceContainerHighest: AppColors.surfaceContainerLow,
      ),
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayHero,
        headlineMedium: AppTypography.pageHeader,
        titleLarge: AppTypography.sectionTitle,
        titleMedium: AppTypography.cardTitle,
        bodyLarge: AppTypography.bodyPrimary,
        bodyMedium: AppTypography.bodySecondary,
        bodySmall: AppTypography.caption,
        labelSmall: AppTypography.badge,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceCard,
        modalBackgroundColor: AppColors.surfaceCard,
        modalBarrierColor: AppColors.scrimOverlay,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceCanvas,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.pageHeader,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: AppColors.brandOnPrimary,
          minimumSize: const Size.fromHeight(buttonHeight),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(), // Pill button geometry
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(buttonHeight),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
        ),
        hintStyle: AppTypography.bodySecondary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceCard,
        selectedItemColor: AppColors.brandPrimary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceContainerSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
