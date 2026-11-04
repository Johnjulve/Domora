import 'package:flutter/material.dart';

/// Centralized color palette and semantic design tokens for Domora (Sanctuary Archival aesthetic).
class AppColors {
  AppColors._();

  // Surfaces & Canvas
  static const Color surfaceCanvas = Color(0xFFFAF9F6); // Warm parchment canvas
  static const Color surfaceCard = Color(0xFFFFFFFF); // Elevated crisp card surface
  static const Color surfaceContainerLow = Color(0xFFF4F4F0); // Input backdrops, secondary containers
  static const Color surfaceContainerSubtle = Color(0xFFEFECE6); // Dividers and subtle states
  static const Color scrimOverlay = Color(0x66000000); // 40% modal sheet scrim

  // Brand & Accents
  static const Color brandPrimary = Color(0xFF1E4B38); // Deep pine / forest green
  static const Color brandHover = Color(0xFF163A2B); // Pressed button state
  static const Color brandOnPrimary = Color(0xFFFFFFFF);
  static const Color brandAccentSage = Color(0xFFEAF2EC); // Reassurance badges, highlight tags
  static const Color brandAccentBorder = Color(0xFFCFDFD5); // Outlines for security badges

  // Content Neutrals & Text
  static const Color textPrimary = Color(0xFF1A201C); // Page titles, row headlines
  static const Color textSecondary = Color(0xFF5D6860); // Descriptions, secondary metadata
  static const Color textTertiary = Color(0xFF8C9790); // Inactive captions, footnotes
  static const Color borderSubtle = Color(0xFFEBE8E1); // 1px hairline borders

  // Semantic Status Tokens
  static const Color statusSuccessFill = Color(0xFFE8F5EE);
  static const Color statusSuccessStroke = Color(0xFF2E7D5B);
  static const Color statusSuccessText = Color(0xFF1E4B38);

  static const Color statusWarningFill = Color(0xFFFEF3C7);
  static const Color statusWarningStroke = Color(0xFFF59E0B);
  static const Color statusWarningText = Color(0xFF92400E);

  static const Color statusDangerFill = Color(0xFFFDE8E8);
  static const Color statusDangerStroke = Color(0xFFF87171);
  static const Color statusDangerText = Color(0xFFB91C1C);
}
