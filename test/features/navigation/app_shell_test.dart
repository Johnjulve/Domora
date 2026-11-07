import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/core/theme/app_theme.dart';
import 'package:domora/core/widgets/under_construction_dialog.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/navigation/app_shell.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/tasks/data/task_repository_impl.dart';
import 'package:domora/features/tasks/domain/task_item.dart';
import 'package:domora/features/today/presentation/today_screen.dart';
import 'package:domora/features/vault/data/document_repository_impl.dart';
import 'package:domora/features/expenses/data/expense_repository_impl.dart';
import 'package:domora/features/backup/data/backup_repository_impl.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';

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
        taskRepositoryProvider.overrideWithValue(TaskRepositoryImpl(inMemoryDb)),
        documentRepositoryProvider.overrideWithValue(DocumentRepositoryImpl(inMemoryDb)),
        expenseRepositoryProvider.overrideWithValue(ExpenseRepositoryImpl(inMemoryDb)),
        backupRepositoryProvider.overrideWithValue(BackupRepositoryImpl(inMemoryDb)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AppShell(),
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
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text("Today's Focus & Deadlines"), findsOneWidget);

      // Tap Vault tab
      await tester.tap(find.text('Vault'));
      await tester.pumpAndSettle();
      expect(find.text('Document Vault'), findsOneWidget);
      expect(find.text('Encrypted Vault Empty'), findsOneWidget);

      // Tap Tasks tab
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();
      expect(find.text('Tasks & Cadence'), findsOneWidget);
      expect(find.text('All Caught Up'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('showUnderConstructionNotice renders notice dialog explicitly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showUnderConstructionNotice(
                    context,
                    featureName: 'Cloud Sync',
                    scheduledPhase: 'Stage 6',
                  ),
                  child: const Text('Trigger Notice'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap button to trigger notice
      await tester.tap(find.text('Trigger Notice'));
      await tester.pumpAndSettle();

      // Interactive dialog appears with clear explanation
      expect(find.text('Feature Under Construction'), findsOneWidget);
      expect(find.textContaining('Stage 6'), findsOneWidget);

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

    testWidgets('Tasks tab: can create task, toggle completion, and filter by status', (WidgetTester tester) async {
      final wsRepo = WorkspaceRepositoryImpl(inMemoryDb);
      await wsRepo.getOrCreateDefaultWorkspace();

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Tasks tab
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      // Shows empty state initially
      expect(find.text('All Caught Up'), findsOneWidget);

      // Tap "Add First Task"
      await tester.tap(find.text('Add First Task'));
      await tester.pumpAndSettle();

      // Modal bottom sheet opens
      expect(find.text('New Task / Responsibility'), findsOneWidget);

      // Enter task title
      await tester.enterText(find.widgetWithText(TextFormField, 'Task Title *'), 'Clean AC Air Filter');

      // Save task
      await tester.tap(find.text('Save Task'));
      await tester.pumpAndSettle();

      // Modal closes, task card is displayed in Pending list
      expect(find.text('New Task / Responsibility'), findsNothing);
      expect(find.text('Clean AC Air Filter'), findsOneWidget);
      expect(find.text('MEDIUM'), findsOneWidget);

      // Toggle task completion via radio button
      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pumpAndSettle();

      // In Pending view, task disappears because it is completed
      expect(find.text('Clean AC Air Filter'), findsNothing);
      expect(find.text('All Caught Up'), findsOneWidget);

      // Switch filter to "Completed"
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // Completed task is present with checked icon
      expect(find.text('Clean AC Air Filter'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Today tab: displays live metrics, focus tasks, quick actions, and recent activity', (WidgetTester tester) async {
      final wsRepo = WorkspaceRepositoryImpl(inMemoryDb);
      final taskRepo = TaskRepositoryImpl(inMemoryDb);
      await wsRepo.getOrCreateDefaultWorkspace();

      // Seed an overdue task
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await taskRepo.createTaskRecord(
        record: Record(
          id: 'urgent-task',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'task',
          title: 'Pay Electricity Bill',
          createdAt: yesterday,
          updatedAt: yesterday,
        ),
        task: TaskItem(
          recordId: 'urgent-task',
          dueDate: yesterday,
          priority: 'urgent',
          status: 'pending',
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Today tab
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // Verify Metrics are rendered with live data
      expect(find.text('Pending Tasks'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Total Assets'), findsOneWidget);

      // Verify Overdue task is displayed under Today Focus
      expect(find.text("Today's Focus & Deadlines"), findsOneWidget);
      expect(find.text('Pay Electricity Bill'), findsWidgets);
      expect(find.text('OVERDUE'), findsOneWidget);

      // Check off the task directly from the Today dashboard
      final radioFinder = find.widgetWithIcon(IconButton, Icons.radio_button_unchecked).first;
      await tester.ensureVisible(radioFinder);
      await tester.pumpAndSettle();
      await tester.tap(radioFinder);
      await tester.pumpAndSettle();

      // The overdue task is completed and the calm reassurance card displays
      expect(find.text("You're all caught up"), findsOneWidget);

      // Test Quick Action: tap "Add Asset" button
      await tester.tap(find.text('Add Asset'));
      await tester.pumpAndSettle();

      // Modal bottom sheet opens
      expect(find.text('New Asset Record'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Asset Title *'), 'MacBook Pro M3');
      await tester.tap(find.text('Save Asset Record'));
      await tester.pumpAndSettle();

      // Recent updates list displays the newly saved asset on TodayScreen
      expect(find.text('Recent Records Activity'), findsOneWidget);
      expect(find.descendant(of: find.byType(TodayScreen), matching: find.text('MacBook Pro M3')), findsOneWidget);
      expect(find.descendant(of: find.byType(TodayScreen), matching: find.text('ASSET')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Today tab metrics remain isolated from transient filters on Tasks and Records tabs', (WidgetTester tester) async {
      final wsRepo = WorkspaceRepositoryImpl(inMemoryDb);
      final taskRepo = TaskRepositoryImpl(inMemoryDb);
      final recordRepo = RecordRepositoryImpl(inMemoryDb);
      await wsRepo.getOrCreateDefaultWorkspace();

      final now = DateTime.now().toUtc();
      // Seed 1 active asset
      await recordRepo.createAssetRecord(
        record: Record(
          id: 'test-car',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Toyota Camry',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'test-car', brand: 'Toyota'),
      );

      // Seed 1 pending overdue task
      final yesterday = now.subtract(const Duration(days: 2));
      await taskRepo.createTaskRecord(
        record: Record(
          id: 'task-service',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'task',
          title: 'Oil Change',
          createdAt: yesterday,
          updatedAt: yesterday,
        ),
        task: TaskItem(
          recordId: 'task-service',
          dueDate: yesterday,
          priority: 'urgent',
          status: 'pending',
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Today tab -> 1 asset, 1 pending task, 1 overdue
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      expect(find.text('Oil Change'), findsWidgets);
      expect(find.text('OVERDUE'), findsOneWidget);

      // Switch to Tasks tab and select "Completed" filter chip
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      expect(find.text('No Completed Tasks'), findsOneWidget);

      // Switch to Records tab and enter a search query that yields no matches
      await tester.tap(find.text('Records'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'NonExistentProduct');
      await tester.pumpAndSettle();
      expect(find.text('No Matching Records'), findsOneWidget);

      // Return to Today tab -> metrics and focus must remain intact and completely isolated!
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      expect(find.text('Pending Tasks'), findsOneWidget);
      expect(find.text('Total Assets'), findsOneWidget);
      expect(find.text('Oil Change'), findsWidgets);
      expect(find.text('OVERDUE'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Vault tab: can create document, view details, filter by category, and soft-delete', (WidgetTester tester) async {
      final wsRepo = WorkspaceRepositoryImpl(inMemoryDb);
      await wsRepo.getOrCreateDefaultWorkspace();

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Vault tab
      await tester.tap(find.text('Vault'));
      await tester.pumpAndSettle();

      // Empty state card
      expect(find.text('Encrypted Vault Empty'), findsOneWidget);

      // Tap Add First Document
      await tester.tap(find.text('Add First Document'));
      await tester.pumpAndSettle();

      // New Vault Document modal
      expect(find.text('New Vault Document'), findsOneWidget);

      // Fill fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Document Title *'), 'Samsung Refrigerator Warranty');
      await tester.enterText(find.widgetWithText(TextFormField, 'File Name *'), 'warranty.pdf');
      await tester.enterText(find.widgetWithText(TextFormField, 'File Size (KB)'), '1024');

      // Save document
      await tester.tap(find.text('Save Document'));
      await tester.pumpAndSettle();

      // Modal closes, document card rendered
      expect(find.text('New Vault Document'), findsNothing);
      expect(find.text('Samsung Refrigerator Warranty'), findsOneWidget);
      expect(find.text('WARRANTY'), findsOneWidget);
      expect(find.text('warranty.pdf • 1.0 MB'), findsOneWidget);

      // Switch to Warranty filter chip -> still visible
      await tester.tap(find.text('Warranty'));
      await tester.pumpAndSettle();
      expect(find.text('Samsung Refrigerator Warranty'), findsOneWidget);

      // Switch to Receipt filter chip -> empty state rendered
      await tester.tap(find.text('Receipt'));
      await tester.pumpAndSettle();
      expect(find.text('Samsung Refrigerator Warranty'), findsNothing);
      expect(find.text('No Matching Documents'), findsOneWidget);

      // Switch back to All filter chip
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('Samsung Refrigerator Warranty'), findsOneWidget);

      // Tap document card to open detail sheet
      await tester.tap(find.text('Samsung Refrigerator Warranty'));
      await tester.pumpAndSettle();

      // Verify detail sheet attributes
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('warranty.pdf')), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('WARRANTY')), findsOneWidget);

      // Tap Move to Trash button
      await tester.tap(find.text('Move to Trash'));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Move to Trash?'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.widgetWithText(ElevatedButton, 'Move to Trash'));
      await tester.pumpAndSettle();

      // SnackBar confirmation appears
      expect(find.text('Moved "Samsung Refrigerator Warranty" to trash'), findsOneWidget);

      // Document is removed from active vault view
      expect(find.text('Samsung Refrigerator Warranty'), findsNothing);
      expect(find.text('Encrypted Vault Empty'), findsOneWidget);

      // Verify soft deletion directly in Drift SQLite database
      final docsInDb = await inMemoryDb.select(inMemoryDb.records).get();
      expect(docsInDb.length, 1);
      expect(docsInDb.first.deletedAt, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
    testWidgets('Expenses workflow: log maintenance expense on asset, verify TCO rollup and Today dashboard', (WidgetTester tester) async {
      final wsRepo = WorkspaceRepositoryImpl(inMemoryDb);
      final recordRepo = RecordRepositoryImpl(inMemoryDb);
      await wsRepo.getOrCreateDefaultWorkspace();

      // Seed an asset with purchase price PHP 25,000 (2,500,000 minor units)
      final now = DateTime.now().toUtc();
      await recordRepo.createAssetRecord(
        record: Record(
          id: 'asset-generator-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Honda Generator EU2200i',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(
          recordId: 'asset-generator-1',
          brand: 'Honda',
          purchaseAmountMinor: 2500000,
          purchaseCurrency: 'PHP',
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Starts at Records tab, asset is visible
      expect(find.text('Honda Generator EU2200i'), findsOneWidget);

      // Tap the asset to inspect
      await tester.tap(find.text('Honda Generator EU2200i'));
      await tester.pumpAndSettle();

      // Verify Estimated Value is displayed
      expect(find.text('PHP 25000.00'), findsOneWidget);
      expect(find.text('Log Maintenance / Expense'), findsOneWidget);

      // Tap Log Maintenance / Expense
      await tester.tap(find.text('Log Maintenance / Expense'));
      await tester.pumpAndSettle();

      // AddExpenseSheet opens with linked asset
      expect(find.text('Log Expense / Maintenance'), findsOneWidget);

      // Fill in expense details: Title, Amount, Category
      await tester.enterText(find.widgetWithText(TextFormField, 'Expense Title *'), 'Synthetic Oil & Spark Plug');
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount (PHP) *'), '1250.00');

      // Submit the form
      await tester.tap(find.text('Save Expense'));
      await tester.pumpAndSettle();

      // SnackBar feedback appears
      expect(find.text('Logged expense: Synthetic Oil & Spark Plug (PHP 1250.00)'), findsOneWidget);

      // AssetDetailSheet beneath is revealed and reactively updated with Maintenance Costs and Total Ownership Cost (25,000 + 1,250 = 26,250)
      expect(find.text('Maintenance Costs'), findsOneWidget);
      expect(find.text('PHP 1250.00'), findsOneWidget);
      expect(find.text('Total Ownership Cost'), findsOneWidget);
      expect(find.text('PHP 26250.00'), findsOneWidget);

      // Close sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Switch to Today tab
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // Verify dashboard metrics reflect the recorded expense
      expect(find.text('Recorded Expenses'), findsOneWidget);
      expect(find.text('PHP 1250.00'), findsOneWidget);

      // Verify Recent Records Activity shows the expense
      expect(find.text('Synthetic Oil & Spark Plug'), findsOneWidget);
      expect(find.text('EXPENSE'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Tapping Sanctuary badge opens Sanctuary Archival sheet, exports backup and validates payload', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Navigate to Today screen
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // Tap Sanctuary badge
      expect(find.text('Sanctuary'), findsOneWidget);
      await tester.tap(find.text('Sanctuary'));
      await tester.pumpAndSettle();

      // Sanctuary Archival bottom sheet is displayed
      expect(find.text('Sanctuary Archival'), findsOneWidget);
      expect(find.text('Export Vault'), findsOneWidget);
      expect(find.text('Restore Vault'), findsOneWidget);
      expect(find.text('Current Vault State'), findsOneWidget);

      // Tap 'Create Backup Archive'
      await tester.tap(find.text('Create Backup Archive'));
      await tester.pumpAndSettle();

      // Verify Archive results card appears with checksum
      expect(find.text('Archive Generated & Verified'), findsOneWidget);
      expect(find.text('Copy JSON'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);

      // Switch to 'Restore Vault' tab
      await tester.tap(find.text('Restore Vault'));
      await tester.pumpAndSettle();

      expect(find.text('Validate Archive Integrity'), findsOneWidget);

      // Enter invalid json
      await tester.enterText(find.widgetWithText(TextField, 'Backup Archive JSON *'), 'CORRUPTED_JSON_DATA');
      await tester.tap(find.text('Validate Archive Integrity'));
      await tester.pumpAndSettle();

      // Error banner is displayed
      expect(find.text('Archive Rejected: CORRUPTED'), findsOneWidget);

      // Dismiss sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}