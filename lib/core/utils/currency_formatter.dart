import 'package:flutter/services.dart';

import '../constants/app_constants.dart';

/// Centralized, integer-precision currency formatting and parsing utilities.
///
/// All minor-unit formatting uses integer arithmetic (`~/ 100` and `% 100`) to
/// avoid IEEE-754 floating-point drift.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final RegExp _thousandsPattern = RegExp(r'\B(?=(\d{3})+(?!\d))');
  static final RegExp _validMajorPattern = RegExp(r'^(?:\d+(?:\.\d{1,2})?|\.\d{1,2})$');

  /// Maximum whole-unit value that can safely be multiplied by 100 in 64-bit signed int.
  static const int _maxWholeUnits = 92233720368547757;

  /// Formats integer minor units with thousands separators and two decimals,
  /// without a currency prefix (e.g. `1200000` -> `'12,000.00'`, `-123456` -> `'-1,234.56'`).
  static String formatMinorNumber(int amountMinor) {
    final isNegative = amountMinor < 0;
    final absMinor = amountMinor.abs();
    final whole = absMinor ~/ 100;
    final cents = (absMinor % 100).toString().padLeft(2, '0');
    final formattedWhole = _insertCommas(whole.toString());
    return isNegative ? '-$formattedWhole.$cents' : '$formattedWhole.$cents';
  }

  /// Formats integer minor units with currency prefix and thousands separators.
  ///
  /// Positive/zero example: `1200000` -> `'PHP 12,000.00'`.
  /// Negative example: `-123456` -> `'-PHP 1,234.56'`.
  /// When [currencyCode] is empty/whitespace, falls back to [formatMinorNumber].
  static String formatMinor(
    int amountMinor, {
    String currencyCode = AppConstants.defaultCurrency,
  }) {
    final code = currencyCode.trim();
    if (code.isEmpty) {
      return formatMinorNumber(amountMinor);
    }
    if (amountMinor < 0) {
      return '-$code ${formatMinorNumber(amountMinor.abs())}';
    }
    return '$code ${formatMinorNumber(amountMinor)}';
  }

  /// Parses a user-entered major-unit string (with optional thousands commas)
  /// into exact integer minor units, or returns `null` if empty or invalid.
  ///
  /// Accepts clean non-negative decimals matching `^\d+(\.\d{1,2})?$` or `^\.\d{1,2}$`
  /// after trimming whitespace and stripping commas.
  static int? parseMajorToMinor(String raw) {
    final cleaned = raw.trim().replaceAll(',', '');
    if (cleaned.isEmpty || !_validMajorPattern.hasMatch(cleaned)) {
      return null;
    }

    final parts = cleaned.split('.');
    final wholePart = parts[0].isEmpty ? 0 : int.tryParse(parts[0]);
    if (wholePart == null || wholePart > _maxWholeUnits) {
      return null;
    }

    final fracRaw = parts.length == 2 ? parts[1] : '';
    final fracPart = int.tryParse(fracRaw.padRight(2, '0'));
    if (fracPart == null) {
      return null;
    }

    return wholePart * 100 + fracPart;
  }

  static String _insertCommas(String digits) {
    if (digits.length <= 3) return digits;
    return digits.replaceAll(_thousandsPattern, ',');
  }
}

/// Live-formats currency input with thousands commas while enforcing at most
/// two decimal digits and preserving cursor position across edits and pastes.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final RegExp _allowedInputPattern = RegExp(r'^\d*\.?\d{0,2}$');

  const ThousandsSeparatorInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final rawCursor = newValue.selection.baseOffset;
    final clampedCursor =
        (rawCursor < 0 || rawCursor > newValue.text.length) ? newValue.text.length : rawCursor;

    final afterComma = _adjustCommaDeletion(oldValue, newValue, clampedCursor);
    final trimmed = _trimOuterWhitespace(afterComma.text, afterComma.cursor);
    if (trimmed.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final nonCommasBeforeCursor = _countNonCommas(trimmed.text, trimmed.cursor);
    final stripped = trimmed.text.replaceAll(',', '');
    if (!_allowedInputPattern.hasMatch(stripped)) {
      return oldValue;
    }

    final formatted = _formatRawDecimal(stripped);
    final mappedCursor = _offsetForNonCommaCount(formatted, nonCommasBeforeCursor);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: mappedCursor),
    );
  }

  /// Handles Backspace or forward-Delete directly targeting a separator comma.
  ({String text, int cursor}) _adjustCommaDeletion(
    TextEditingValue oldValue,
    TextEditingValue newValue,
    int cursorOffset,
  ) {
    final text = newValue.text;
    final isSingleCharDeletion = oldValue.text.length == text.length + 1 &&
        oldValue.selection.isCollapsed &&
        newValue.selection.isCollapsed &&
        cursorOffset < oldValue.text.length &&
        oldValue.text[cursorOffset] == ',';
    if (!isSingleCharDeletion) {
      return (text: text, cursor: cursorOffset);
    }

    if (oldValue.selection.baseOffset == cursorOffset + 1 && cursorOffset > 0) {
      return (
        text: text.substring(0, cursorOffset - 1) + text.substring(cursorOffset),
        cursor: cursorOffset - 1,
      );
    }

    if (oldValue.selection.baseOffset == cursorOffset && cursorOffset < text.length) {
      return (
        text: text.substring(0, cursorOffset) + text.substring(cursorOffset + 1),
        cursor: cursorOffset,
      );
    }

    return (text: text, cursor: cursorOffset);
  }

  ({String text, int cursor}) _trimOuterWhitespace(String text, int cursorOffset) {
    final leadingTrimmed = text.trimLeft();
    final leadingSpaces = text.length - leadingTrimmed.length;
    final trimmed = leadingTrimmed.trimRight();
    final adjustedCursor = (cursorOffset - leadingSpaces).clamp(0, trimmed.length);
    return (text: trimmed, cursor: adjustedCursor);
  }

  String _formatRawDecimal(String stripped) {
    final dotIndex = stripped.indexOf('.');
    if (dotIndex == -1) {
      return CurrencyFormatter._insertCommas(stripped);
    }
    final intPart = stripped.substring(0, dotIndex);
    final decPart = stripped.substring(dotIndex + 1);
    return '${CurrencyFormatter._insertCommas(intPart)}.$decPart';
  }

  int _countNonCommas(String text, int upToIndex) {
    var count = 0;
    for (var i = 0; i < upToIndex && i < text.length; i++) {
      if (text[i] != ',') count++;
    }
    return count;
  }

  int _offsetForNonCommaCount(String formatted, int targetCount) {
    if (targetCount <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (formatted[i] != ',') {
        seen++;
        if (seen == targetCount) {
          return i + 1;
        }
      }
    }
    return formatted.length;
  }
}
