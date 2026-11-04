import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/navigation/app_shell.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
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
        categoryRepositoryProvider.overrideWithValue(CategoryRepositoryImpl(inMemoryDb)),
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

    testWidgets('Real-time search filters records list immediately', (WidgetTester tester) async {
      final repo = RecordRepositoryImpl(inMemoryDb);
      final wsRepo = WorkspaceRepositoryImpl(inMemoryDb);
      await wsRepo.getOrCreateDefaultWorkspace();

      final now = DateTime.now().toUtc();
      await repo.createAssetRecord(
        record: Record(
          id: 'tv-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Sony Bravia TV',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'tv-1', brand: 'Sony', model: 'Bravia'),
      );
      await repo.createAssetRecord(
        record: Record(
          id: 'v-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Dyson V15 Vacuum',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'v-1', brand: 'Dyson', model: 'V15'),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Both are displayed initially
      expect(find.text('Sony Bravia TV'), findsOneWidget);
      expect(find.text('Dyson V15 Vacuum'), findsOneWidget);

      // Search for 'vacuum'
      await tester.enterText(find.byType(TextField).first, 'vacuum');
      await tester.pumpAndSettle();

      // Only Dyson appears
      expect(find.text('Dyson V15 Vacuum'), findsOneWidget);
      expect(find.text('Sony Bravia TV'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Both appear again
      expect(find.text('Sony Bravia TV'), findsOneWidget);
      expect(find.text('Dyson V15 Vacuum'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Tapping asset card opens inspection sheet with soft-delete action', (WidgetTester tester) async {
      final repo = RecordRepositoryImpl(inMemoryDb);
      final wsRepo = WorkspaceRepositoryImpl(inMemoryDb);
      await wsRepo.getOrCreateDefaultWorkspace();

      final now = DateTime.now().toUtc();
      await repo.createAssetRecord(
        record: Record(
          id: 'del-item-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Coffee Machine',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(
          recordId: 'del-item-1',
          brand: 'Breville',
          model: 'Barista Touch',
          serialNumber: 'SN-BREV-123',
          condition: 'Mint',
          locationDescription: 'Kitchen Counter',
          purchaseAmountMinor: 4800000,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap card to open detail sheet
      await tester.tap(find.text('Coffee Machine'));
      await tester.pumpAndSettle();

      // Verify detail sheet attributes within the bottom sheet
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('Breville')), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('Barista Touch')), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('SN-BREV-123')), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('Kitchen Counter')), findsOneWidget);

      // Tap Move to Trash button
      await tester.tap(find.text('Move to Trash'));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Move to Trash?'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.widgetWithText(ElevatedButton, 'Move to Trash'));
      await tester.pumpAndSettle();

      // Item is removed from the active screen
      expect(find.text('Coffee Machine'), findsNothing);

      // Verify soft deletion in Drift SQLite database (deletedAt is set, row is not hard deleted)
      final recordsInDb = await inMemoryDb.select(inMemoryDb.records).get();
      expect(recordsInDb.length, 1);
      expect(recordsInDb.first.deletedAt, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
