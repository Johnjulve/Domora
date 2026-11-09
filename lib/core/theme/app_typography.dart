import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography hierarchy for Domora following the Sanctuary Archival design specification.
class AppTypography {
  AppTypography._();

  static const String _fontFamily = 'Plus Jakarta Sans';
  static const List<String> _fontFamilyFallback = [
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  static const TextStyle displayHero = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.7,
  );

  static const TextStyle pageHeader = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.5,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle bodyPrimary = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.5,
    color: AppColors.brandPrimary,
  );
}
