import 'package:domora/core/utils/currency_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyFormatter.formatMinor & formatMinorNumber', () {
    test('formats zero, small cents, hundreds, thousands, and millions with integer precision', () {
      expect(CurrencyFormatter.formatMinor(0), 'PHP 0.00');
      expect(CurrencyFormatter.formatMinor(5), 'PHP 0.05');
      expect(CurrencyFormatter.formatMinor(50), 'PHP 0.50');
      expect(CurrencyFormatter.formatMinor(99), 'PHP 0.99');
      expect(CurrencyFormatter.formatMinor(85000), 'PHP 850.00');
      expect(CurrencyFormatter.formatMinor(385050), 'PHP 3,850.50');
      expect(CurrencyFormatter.formatMinor(1200000), 'PHP 12,000.00');
      expect(CurrencyFormatter.formatMinor(123456789), 'PHP 1,234,567.89');

      expect(CurrencyFormatter.formatMinorNumber(1200000), '12,000.00');
      expect(CurrencyFormatter.formatMinorNumber(0), '0.00');
    });

    test('formats negative minor values consistently and supports custom currency codes', () {
      expect(CurrencyFormatter.formatMinor(-123456), '-PHP 1,234.56');
      expect(CurrencyFormatter.formatMinor(-5), '-PHP 0.05');
      expect(CurrencyFormatter.formatMinorNumber(-123456), '-1,234.56');

      expect(CurrencyFormatter.formatMinor(1200000, currencyCode: 'USD'), 'USD 12,000.00');
      expect(CurrencyFormatter.formatMinor(250050, currencyCode: 'EUR'), 'EUR 2,500.50');
      expect(CurrencyFormatter.formatMinor(-9999, currencyCode: 'USD'), '-USD 99.99');
      expect(CurrencyFormatter.formatMinor(1200000, currencyCode: ''), '12,000.00');
      expect(CurrencyFormatter.formatMinor(-123456, currencyCode: '   '), '-1,234.56');
    });
  });

  group('CurrencyFormatter.parseMajorToMinor', () {
    test('parses plain, comma-formatted, and exact-decimal values without float drift', () {
      expect(CurrencyFormatter.parseMajorToMinor('0'), 0);
      expect(CurrencyFormatter.parseMajorToMinor('0.00'), 0);
      expect(CurrencyFormatter.parseMajorToMinor('19.99'), 1999);
      expect(CurrencyFormatter.parseMajorToMinor('12000'), 1200000);
      expect(CurrencyFormatter.parseMajorToMinor('12,000.5'), 1200050);
      expect(CurrencyFormatter.parseMajorToMinor('12,000.50'), 1200050);
      expect(CurrencyFormatter.parseMajorToMinor('1,234,567.89'), 123456789);
      expect(CurrencyFormatter.parseMajorToMinor('.50'), 50);
      expect(CurrencyFormatter.parseMajorToMinor('.5'), 50);
      expect(CurrencyFormatter.parseMajorToMinor('  3,450.50  '), 345050);
    });

    test('rejects empty, negative, malformed, >2 decimal, and overflowing inputs', () {
      expect(CurrencyFormatter.parseMajorToMinor(''), isNull);
      expect(CurrencyFormatter.parseMajorToMinor('   '), isNull);
      expect(CurrencyFormatter.parseMajorToMinor('-10.00'), isNull);
      expect(CurrencyFormatter.parseMajorToMinor('+10.00'), isNull);
      expect(CurrencyFormatter.parseMajorToMinor('12.345'), isNull);
      expect(CurrencyFormatter.parseMajorToMinor('12.'), isNull);
      expect(CurrencyFormatter.parseMajorToMinor('.'), isNull);
      expect(CurrencyFormatter.parseMajorToMinor('12.3.4'), isNull);
      expect(CurrencyFormatter.parseMajorToMinor('12abc'), isNull);
      expect(CurrencyFormatter.parseMajorToMinor('PHP 1200'), isNull);
      expect(CurrencyFormatter.parseMajorToMinor('999999999999999999999'), isNull);
    });
  });

  group('ThousandsSeparatorInputFormatter', () {
    late ThousandsSeparatorInputFormatter formatter;

    setUp(() {
      formatter = const ThousandsSeparatorInputFormatter();
    });

    TextEditingValue applyEdit(
      String oldText,
      int oldCursor,
      String newText,
      int newCursor,
    ) {
      return formatter.formatEditUpdate(
        TextEditingValue(
          text: oldText,
          selection: TextSelection.collapsed(offset: oldCursor),
        ),
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newCursor),
        ),
      );
    }

    test('formats integers and decimals live while typing', () {
      final r1 = applyEdit('1200', 4, '12000', 5);
      expect(r1.text, '12,000');
      expect(r1.selection.baseOffset, 6);

      final r2 = applyEdit('12,000', 6, '12,000.', 7);
      expect(r2.text, '12,000.');
      expect(r2.selection.baseOffset, 7);

      final r3 = applyEdit('12,000.', 7, '12,000.5', 8);
      expect(r3.text, '12,000.5');
      expect(r3.selection.baseOffset, 8);

      final r4 = applyEdit('12,000.5', 8, '12,000.50', 9);
      expect(r4.text, '12,000.50');
      expect(r4.selection.baseOffset, 9);
    });

    test('accepts pasting comma-formatted numbers with outer whitespace and clearing text', () {
      final pasted = applyEdit('', 0, '1,234,567.89', 12);
      expect(pasted.text, '1,234,567.89');
      expect(pasted.selection.baseOffset, 12);

      final pastedRaw = applyEdit('', 0, '1234567.89', 10);
      expect(pastedRaw.text, '1,234,567.89');
      expect(pastedRaw.selection.baseOffset, 12);

      final pastedWithSpaces = applyEdit('', 0, ' 12,000.50 ', 11);
      expect(pastedWithSpaces.text, '12,000.50');
      expect(pastedWithSpaces.selection.baseOffset, 9);

      final innerSpace = applyEdit('1,200', 5, '12 34', 5);
      expect(innerSpace.text, '1,200');

      final cleared = applyEdit('12,000', 6, '', 0);
      expect(cleared.text, '');
      expect(cleared.selection.baseOffset, 0);
    });

    test('preserves cursor accuracy during mid-string insertion, deletion, and comma backspace/forward-delete', () {
      // Insert '5' between '1' and '2' in '12,000' -> '152,000', cursor after '5' (index 2)
      final midInsert = applyEdit('12,000', 1, '152,000', 2);
      expect(midInsert.text, '152,000');
      expect(midInsert.selection.baseOffset, 2);

      // Insert '0' after '1' in '1,234' -> '10,234', cursor after '0' (index 2)
      final crossGroupInsert = applyEdit('1,234', 1, '10,234', 2);
      expect(crossGroupInsert.text, '10,234');
      expect(crossGroupInsert.selection.baseOffset, 2);

      // Insert '9' at start of '123,456' -> '9,123,456', cursor after '9' (index 1)
      final leadingInsert = applyEdit('123,456', 0, '9123,456', 1);
      expect(leadingInsert.text, '9,123,456');
      expect(leadingInsert.selection.baseOffset, 1);

      // Delete '1' at start of '1,234.56' -> '234.56', cursor at 0
      final leadingDelete = applyEdit('1,234.56', 1, ',234.56', 0);
      expect(leadingDelete.text, '234.56');
      expect(leadingDelete.selection.baseOffset, 0);

      // Backspace over comma in '12,345' (cursor 3 -> 2) deletes '2' -> '1,345', cursor at 1
      final commaBackspace = applyEdit('12,345', 3, '12345', 2);
      expect(commaBackspace.text, '1,345');
      expect(commaBackspace.selection.baseOffset, 1);

      // Forward-delete over comma in '12,345' (cursor 2 -> 2) deletes '3' -> '1,245', cursor at 3
      final commaForwardDelete = applyEdit('12,345', 2, '12345', 2);
      expect(commaForwardDelete.text, '1,245');
      expect(commaForwardDelete.selection.baseOffset, 3);
    });

    test('rejects >2 decimal digits, multiple dots, and non-numeric characters', () {
      final thirdDecimal = applyEdit('12,000.50', 9, '12,000.501', 10);
      expect(thirdDecimal.text, '12,000.50');
      expect(thirdDecimal.selection.baseOffset, 9);

      final secondDot = applyEdit('12,000.5', 8, '12,000.5.', 9);
      expect(secondDot.text, '12,000.5');

      final letters = applyEdit('1,200', 5, '1,200a', 6);
      expect(letters.text, '1,200');

      final negative = applyEdit('', 0, '-50', 3);
      expect(negative.text, '');
    });
  });
}
