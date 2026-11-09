import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Central theme configuration for Domora implementing the Sanctuary Archival design system.
class AppTheme {
  AppTheme._();

  static const double cardRadius = 18.0;
  static const double buttonHeight = 54.0;
  static const double inputRadius = 14.0;
  static const double sheetRadius = 24.0;

  // Sanctuary Archival Dark Palette Tokens
  static const Color darkSurfaceCanvas = Color(0xFF121614);
  static const Color darkSurfaceCard = Color(0xFF1A201C);
  static const Color darkSurfaceContainerLow = Color(0xFF222925);
  static const Color darkBorderSubtle = Color(0xFF2B342F);
  static const Color darkBrandPrimary = Color(0xFF3E8563);
  static const Color darkBrandSecondary = Color(0xFF86CCA4);
  static const Color darkTextPrimary = Color(0xFFF4F5F4);
  static const Color darkTextSecondary = Color(0xFFA1ACA4);
  static const Color darkTextTertiary = Color(0xFF748078);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      cardColor: AppColors.surfaceCard,
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
      textTheme: TextTheme(
        displayLarge: AppTypography.displayHero.copyWith(color: AppColors.textPrimary),
        headlineMedium: AppTypography.pageHeader.copyWith(color: AppColors.textPrimary),
        titleLarge: AppTypography.sectionTitle.copyWith(color: AppColors.textPrimary),
        titleMedium: AppTypography.cardTitle.copyWith(color: AppColors.textPrimary),
        bodyLarge: AppTypography.bodyPrimary.copyWith(color: AppColors.textPrimary),
        bodyMedium: AppTypography.bodySecondary.copyWith(color: AppColors.textSecondary),
        bodySmall: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        labelSmall: AppTypography.badge,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surfaceCard,
        modalBarrierColor: AppColors.scrimOverlay,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        titleTextStyle: AppTypography.cardTitle.copyWith(color: AppColors.textPrimary),
        contentTextStyle: AppTypography.bodyPrimary.copyWith(color: AppColors.textPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceCanvas,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.pageHeader.copyWith(color: AppColors.textPrimary),
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
        hintStyle: AppTypography.bodySecondary.copyWith(color: AppColors.textSecondary),
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

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      cardColor: darkSurfaceCard,
      fontFamily: 'Plus Jakarta Sans',
      fontFamilyFallback: const [
        '-apple-system',
        'BlinkMacSystemFont',
        'Segoe UI',
        'Roboto',
        'sans-serif',
      ],
      scaffoldBackgroundColor: darkSurfaceCanvas,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: darkBrandPrimary,
        onPrimary: Colors.white,
        secondary: darkBrandSecondary,
        onSecondary: darkSurfaceCanvas,
        surface: darkSurfaceCard,
        onSurface: darkTextPrimary,
        error: AppColors.statusDangerStroke,
        onError: Colors.white,
        outline: darkBorderSubtle,
        surfaceContainerHighest: darkSurfaceContainerLow,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayHero.copyWith(color: darkTextPrimary),
        headlineMedium: AppTypography.pageHeader.copyWith(color: darkTextPrimary),
        titleLarge: AppTypography.sectionTitle.copyWith(color: darkTextPrimary),
        titleMedium: AppTypography.cardTitle.copyWith(color: darkTextPrimary),
        bodyLarge: AppTypography.bodyPrimary.copyWith(color: darkTextPrimary),
        bodyMedium: AppTypography.bodySecondary.copyWith(color: darkTextSecondary),
        bodySmall: AppTypography.caption.copyWith(color: darkTextTertiary),
        labelSmall: AppTypography.badge.copyWith(color: darkBrandSecondary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurfaceCard,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: darkSurfaceCard,
        modalBarrierColor: AppColors.scrimOverlay,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: darkBorderSubtle, width: 1),
        ),
        titleTextStyle: AppTypography.cardTitle.copyWith(color: darkTextPrimary),
        contentTextStyle: AppTypography.bodyPrimary.copyWith(color: darkTextPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceCanvas,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.pageHeader.copyWith(color: darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: darkBorderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkBrandPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(buttonHeight),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          minimumSize: const Size.fromHeight(buttonHeight),
          side: const BorderSide(color: darkBorderSubtle, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: darkBorderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: darkBorderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: darkBrandPrimary, width: 1.5),
        ),
        hintStyle: AppTypography.bodySecondary.copyWith(color: darkTextSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurfaceCard,
        selectedItemColor: darkBrandSecondary,
        unselectedItemColor: darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

/// Convenient BuildContext extension for contextual Sanctuary Archival theme colors.
extension SanctuaryThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get surfaceCanvas => Theme.of(this).scaffoldBackgroundColor;
  Color get surfaceCard => Theme.of(this).cardColor;
  Color get textPrimary => isDarkMode ? AppTheme.darkTextPrimary : AppColors.textPrimary;
  Color get textSecondary => isDarkMode ? AppTheme.darkTextSecondary : AppColors.textSecondary;
  Color get textTertiary => isDarkMode ? AppTheme.darkTextTertiary : AppColors.textTertiary;
  Color get borderSubtle => isDarkMode ? AppTheme.darkBorderSubtle : AppColors.borderSubtle;
  Color get surfaceContainerLow => isDarkMode ? AppTheme.darkSurfaceContainerLow : AppColors.surfaceContainerLow;
  Color get brandAccent => isDarkMode ? AppTheme.darkBrandSecondary : AppColors.brandPrimary;
}
