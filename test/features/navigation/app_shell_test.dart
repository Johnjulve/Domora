import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/features/navigation/app_shell.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase inMemoryDb;

  setUp(() {
    inMemoryDb = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await inMemoryDb.close();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(inMemoryDb),
        workspaceRepositoryProvider.overrideWithValue(WorkspaceRepositoryImpl(inMemoryDb)),
        recordRepositoryProvider.overrideWithValue(RecordRepositoryImpl(inMemoryDb)),
      ],
      child: const MaterialApp(
        home: AppShell(),
      ),
    );
  }

  group('AppShell & Navigation Tests', () {
    testWidgets('Can navigate across all 4 bottom tabs', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Starts at Records
      expect(find.text('Life Records'), findsOneWidget);

      // Tap Today tab
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.text('Daily Rhythm & Insights'), findsOneWidget);

      // Tap Vault tab
      await tester.tap(find.text('Vault'));
      await tester.pumpAndSettle();
      expect(find.text('Encrypted Document Storage'), findsOneWidget);

      // Tap Tasks tab
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();
      expect(find.text('Maintenance & Domestic Cadence'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Noticeable in-progress feedback dialog triggers on unfinished features', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Go to Vault tab
      await tester.tap(find.text('Vault'));
      await tester.pumpAndSettle();

      // Tap in-progress notice button
      await tester.tap(find.text('View Vault Schedule'));
      await tester.pumpAndSettle();

      // Verify notice dialog appears with explicit phase attribution
      expect(find.text('Feature Under Construction'), findsOneWidget);
      expect(find.textContaining('Stage 3 & Stage 5'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();
      expect(find.text('Feature Under Construction'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Validation shows error when submitting blank title in asset sheet', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Add First Asset
      await tester.tap(find.text('Add First Asset'));
      await tester.pumpAndSettle();

      // Tap Save without entering title
      await tester.tap(find.text('Save Asset Record'));
      await tester.pumpAndSettle();

      // Validation feedback appears (no silent return)
      expect(find.text('Title is required'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Cold boot automatically seeds default workspace and creates asset record live', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // On Records tab
      expect(find.text('No Life Records Yet'), findsOneWidget);

      // Tap "Add First Asset" button
      await tester.tap(find.text('Add First Asset'));
      await tester.pumpAndSettle();

      // Modal bottom sheet appears
      expect(find.text('New Asset Record'), findsOneWidget);

      // Enter asset details
      await tester.enterText(find.widgetWithText(TextFormField, 'Asset Title *'), 'Sony OLED TV');
      await tester.enterText(find.widgetWithText(TextFormField, 'Brand'), 'Sony');
      await tester.enterText(find.widgetWithText(TextFormField, 'Model'), 'Bravia 65');
      await tester.enterText(find.widgetWithText(TextFormField, 'Purchase Amount (PHP)'), '65000');
      await tester.enterText(find.widgetWithText(TextFormField, 'Location'), 'Family Den');

      // Save record
      await tester.tap(find.text('Save Asset Record'));
      await tester.pumpAndSettle();

      // Modal closes and live record item is rendered
      expect(find.text('New Asset Record'), findsNothing);
      expect(find.text('Sony OLED TV'), findsOneWidget);
      expect(find.text('Value: PHP 65000.00'), findsOneWidget);

      // Verify directly in Drift SQLite database
      final recordsInDb = await inMemoryDb.select(inMemoryDb.records).get();
      expect(recordsInDb.length, 1);
      expect(recordsInDb.first.title, 'Sony OLED TV');
      expect(recordsInDb.first.workspaceId, AppConstants.defaultWorkspaceId);

      final assetsInDb = await inMemoryDb.select(inMemoryDb.assets).get();
      expect(assetsInDb.length, 1);
      expect(assetsInDb.first.brand, 'Sony');
      expect(assetsInDb.first.purchaseAmountMinor, 6500000);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
