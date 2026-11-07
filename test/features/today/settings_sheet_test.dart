import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:domora/features/today/presentation/settings_sheet.dart';

void main() {
  Widget buildTestSettingsSheet() {
    return const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SettingsSheet(),
        ),
      ),
    );
  }

  testWidgets('SettingsSheet displays app version, architecture, and update action', (tester) async {
    await tester.pumpWidget(buildTestSettingsSheet());
    await tester.pumpAndSettle();

    // App identity
    expect(find.text('Settings & Preferences'), findsOneWidget);
    expect(find.textContaining('Domora v0.1.0-alpha.10'), findsOneWidget);
    expect(find.text('Personal & Household Sanctuary OS'), findsOneWidget);

    // Architecture rows
    expect(find.text('Offline-First • Local SQLite (Drift v7)'), findsOneWidget);
    expect(find.text('100% On-Device • Zero Mandatory Cloud'), findsOneWidget);

    // Software updates card
    expect(find.text('Software Updates'), findsOneWidget);
    expect(find.text('Check for Updates'), findsOneWidget);

    // Sanctuary Archival shortcut
    expect(find.text('Sanctuary Archival & Backup'), findsOneWidget);
  });
}
