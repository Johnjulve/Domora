import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/core/theme/app_theme.dart';
import 'package:domora/features/bills/data/bill_repository_impl.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/categories/domain/category.dart';
import 'package:domora/features/expenses/data/expense_repository_impl.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/presentation/records_screen.dart';
import 'package:domora/features/tasks/data/task_repository_impl.dart';
import 'package:domora/features/vault/data/document_repository_impl.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase db;
  late CategoryRepositoryImpl categoryRepo;
  late RecordRepositoryImpl recordRepo;
  late BillRepositoryImpl billRepo;
  late ExpenseRepositoryImpl expenseRepo;
  late TaskRepositoryImpl taskRepo;
  late DocumentRepositoryImpl documentRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final wsRepo = WorkspaceRepositoryImpl(db);
    categoryRepo = CategoryRepositoryImpl(db);
    recordRepo = RecordRepositoryImpl(db);
    billRepo = BillRepositoryImpl(db);
    expenseRepo = ExpenseRepositoryImpl(db);
    taskRepo = TaskRepositoryImpl(db);
    documentRepo = DocumentRepositoryImpl(db);

    await wsRepo.getOrCreateDefaultWorkspace();
    await categoryRepo.seedDefaultCategories(AppConstants.defaultWorkspaceId);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildHarness({Widget? home, ThemeMode themeMode = ThemeMode.light}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        workspaceRepositoryProvider.overrideWithValue(WorkspaceRepositoryImpl(db)),
        categoryRepositoryProvider.overrideWithValue(categoryRepo),
        recordRepositoryProvider.overrideWithValue(recordRepo),
        billRepositoryProvider.overrideWithValue(billRepo),
        expenseRepositoryProvider.overrideWithValue(expenseRepo),
        taskRepositoryProvider.overrideWithValue(taskRepo),
        documentRepositoryProvider.overrideWithValue(documentRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: home ?? const RecordsScreen(),
      ),
    );
  }

  Future<void> flush(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('Pass 3 — Unified Quick Add, Decluttered Forms, Vehicle PMS & Family Template', () {
    testWidgets('1. Single + button opens QuickAddRecordSheet with Money & Service and Items & Collections groups',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      // Split AppBar bill button is gone; only unified '+' button exists
      expect(find.byTooltip('Add Utility Bill'), findsNothing);
      expect(find.byKey(const Key('records_quick_add_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('records_quick_add_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quick_add_record_sheet')), findsOneWidget);
      expect(find.text('MONEY & SERVICE'), findsOneWidget);
      expect(find.text('ITEMS & COLLECTIONS'), findsOneWidget);
      expect(find.byKey(const Key('quick_add_expense')), findsOneWidget);
      expect(find.byKey(const Key('quick_add_bill')), findsOneWidget);
      expect(find.byKey(const Key('quick_add_maintenance')), findsOneWidget);
      expect(find.byKey(const Key('quick_add_vehicle')), findsOneWidget);
      expect(find.byKey(const Key('quick_add_appliance')), findsOneWidget);
      expect(find.byKey(const Key('quick_add_other_section')), findsOneWidget);

      await flush(tester);
    });

    testWidgets('2. Vehicle quick-add pre-selects Vehicles, uses clean month labels, and has zero overflow at 360x800',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('records_quick_add_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick_add_vehicle')));
      await tester.pumpAndSettle();

      expect(find.text('Add Vehicle'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'VIN / Serial'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Current Odometer (km)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Parking / Garage'), findsOneWidget);
      expect(find.text('6 months'), findsOneWidget);
      expect(find.text('Every 6 mos'), findsNothing);

      // Open PMS Time Limit dropdown to verify 3 months / 6 months / 12 months
      await tester.ensureVisible(find.byKey(const Key('vehicle_pms_time_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('vehicle_pms_time_dropdown')));
      await tester.pumpAndSettle();
      expect(find.text('3 months'), findsWidgets);
      expect(find.text('6 months'), findsWidgets);
      expect(find.text('12 months'), findsWidgets);

      expect(tester.takeException(), isNull);
      await flush(tester);
    });

    testWidgets('3. cat-bills-expenses is excluded from AddAssetSheet Category dropdown',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildHarness(home: const Scaffold(body: AddAssetSheet())));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('asset_category_dropdown')));
      await tester.pumpAndSettle();

      expect(find.text('Vehicles'), findsWidgets);
      expect(find.text('Family'), findsWidgets);
      expect(find.text('Bills & Expenses'), findsNothing);

      await flush(tester);
    });

    testWidgets('4. Family quick-add renders Family Member template, hides asset fields, and saves cleanly to FieldValues',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('records_quick_add_button')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('quick_add_other_section')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick_add_other_section')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('quick_add_section_cat-family')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick_add_section_cat-family')));
      await tester.pumpAndSettle();

      // Family Member template visible
      expect(find.text('Add Family Member'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Full Name *'), findsOneWidget);
      expect(find.byKey(const Key('family_relationship_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('family_blood_type_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('family_birthdate_picker')), findsOneWidget);
      expect(find.byKey(const Key('family_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('family_id_number_field')), findsOneWidget);
      expect(find.byKey(const Key('family_medical_notes_field')), findsOneWidget);

      // Asset-specific fields hidden
      expect(find.widgetWithText(TextFormField, 'Brand'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Model'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Serial No.'), findsNothing);
      expect(find.text('Condition'), findsNothing);
      expect(find.textContaining('Purchase Amount'), findsNothing);
      expect(find.text('Warranty, Dates & Notes'), findsNothing);

      // Enter Family Member details and save
      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name *'), 'Maria Santos');
      await tester.enterText(find.byKey(const Key('family_phone_field')), '+63 917 555 0199');
      await tester.enterText(find.byKey(const Key('family_id_number_field')), 'PH-123456789');
      await tester.enterText(find.byKey(const Key('family_medical_notes_field')), 'No known allergies');

      await tester.ensureVisible(find.text('Save Family Member'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Family Member'));
      await tester.pumpAndSettle();

      // Verify persisted cleanly to Records + FieldValues with no ghost asset fields
      final records = await recordRepo.getActiveRecordsByWorkspace(AppConstants.defaultWorkspaceId);
      expect(records, hasLength(1));
      final saved = records.single;
      expect(saved.record.title, 'Maria Santos');
      expect(saved.record.categoryId, 'cat-family');
      expect(saved.asset?.brand, isNull);
      expect(saved.asset?.condition, isNull);
      expect(saved.asset?.purchaseAmountMinor, isNull);

      final customFields = await recordRepo.getCustomFieldsForRecord(saved.record.id);
      final fieldMap = {for (final cf in customFields) cf.definition.label: cf.value.valueText};
      expect(fieldMap['Relationship'], 'Spouse');
      expect(fieldMap['Blood Type'], 'Unknown');
      expect(fieldMap['Contact / Emergency Phone'], '+63 917 555 0199');
      expect(fieldMap['ID / Insurance / PhilHealth No.'], 'PH-123456789');
      expect(fieldMap['Medical Notes & Allergies'], 'No known allergies');

      // Open AssetDetailSheet on Maria Santos -> Medical Notes rendered once (no duplicate Notes / Description row)
      await tester.tap(find.byKey(Key('record_item_${saved.record.id}')));
      await tester.pumpAndSettle();
      expect(find.text('Medical Notes & Allergies'), findsOneWidget);
      expect(find.text('No known allergies'), findsOneWidget);
      expect(find.text('Notes / Description'), findsNothing);

      await flush(tester);
    });

    testWidgets('5. AddBillSheet and AddExpenseSheet show custom Bills & Expenses sub-categories and collapse secondary drawers',
        (WidgetTester tester) async {
      // Create a custom sub-category under Bills & Expenses
      await categoryRepo.createCategory(
        Category(
          id: 'cat-sub-condo-dues',
          workspaceId: AppConstants.defaultWorkspaceId,
          name: 'Condo Dues',
          isSystem: false,
          parentCategoryId: CategoryRepositoryImpl.billsExpensesCategoryId,
          createdAt: DateTime.utc(2026, 11, 25),
        ),
      );

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      // 5a. Open Bill / Subscription via Quick Add
      await tester.tap(find.byKey(const Key('records_quick_add_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick_add_bill')));
      await tester.pumpAndSettle();

      // Secondary fields collapsed by default
      expect(find.widgetWithText(TextFormField, 'Provider / Issuer'), findsNothing);
      expect(find.byKey(const Key('billing_period_start_card')), findsNothing);

      // Custom sub-category and Withdraw / Deposit appear in Type dropdown
      await tester.tap(find.byKey(const Key('bill_type_dropdown')));
      await tester.pumpAndSettle();
      final dropdownScrollable = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.text('Withdraw / Deposit'),
        120,
        scrollable: dropdownScrollable,
      );
      expect(find.text('Withdraw / Deposit'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Condo Dues'),
        -120,
        scrollable: dropdownScrollable,
      );
      expect(find.text('Condo Dues'), findsWidgets);
      await tester.tap(find.text('Condo Dues').last);
      await tester.pumpAndSettle();

      // Toggling drawer reveals secondary fields
      await tester.tap(find.byKey(const Key('bill_more_details_toggle')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Provider / Issuer'), findsOneWidget);
      expect(find.byKey(const Key('billing_period_start_card')), findsOneWidget);

      // Close AddBillSheet
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      // 5b. Open Expense via Quick Add
      await tester.tap(find.byKey(const Key('records_quick_add_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick_add_expense')));
      await tester.pumpAndSettle();

      expect(find.text('Log Expense'), findsOneWidget);
      // Payment Method & Notes collapsed by default
      expect(find.text('Payment Method'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Notes / Description (Optional)'), findsNothing);

      // Custom sub-category appears in Category dropdown
      await tester.tap(find.byKey(const Key('expense_category_dropdown')));
      await tester.pumpAndSettle();
      expect(find.text('Condo Dues'), findsWidgets);
      expect(find.text('Withdraw / Deposit'), findsWidgets);
      await tester.tap(find.text('Condo Dues').last);
      await tester.pumpAndSettle();

      // Toggling drawer reveals Payment Method & Notes
      await tester.tap(find.byKey(const Key('expense_more_details_toggle')));
      await tester.pumpAndSettle();
      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Notes / Description (Optional)'), findsOneWidget);

      await flush(tester);
    });

    testWidgets('6. Archiving cat-vehicles hides Vehicle from QuickAddRecordSheet and prevents AddAssetSheet from persisting archived categoryId',
        (WidgetTester tester) async {
      await categoryRepo.archiveCategory('cat-vehicles');

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('records_quick_add_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('quick_add_vehicle')), findsNothing);
      expect(find.byKey(const Key('quick_add_appliance')), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      // Opening AddAssetSheet with archived initialCategoryId falls back cleanly to General / Uncategorized
      await tester.pumpWidget(
        buildHarness(
          home: const Scaffold(body: AddAssetSheet(initialCategoryId: 'cat-vehicles')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Asset Record'), findsOneWidget);
      expect(find.text('Add Vehicle'), findsNothing);

      await tester.enterText(find.widgetWithText(TextFormField, 'Asset Title *'), 'Fallback Item');
      await tester.ensureVisible(find.text('Save Asset Record'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Asset Record'));
      await tester.pumpAndSettle();

      final savedRecords = await recordRepo.getActiveRecordsByWorkspace(AppConstants.defaultWorkspaceId);
      expect(savedRecords, hasLength(1));
      expect(savedRecords.single.record.categoryId, isNull);

      await flush(tester);
    });

    testWidgets('7. Built-in Bill and Expense types attach matching active subCategoryId to Record.categoryId',
        (WidgetTester tester) async {
      await categoryRepo.createCategory(
        Category(
          id: 'cat-sub-custom-insurance',
          workspaceId: AppConstants.defaultWorkspaceId,
          name: 'Insurance',
          isSystem: false,
          parentCategoryId: CategoryRepositoryImpl.billsExpensesCategoryId,
          createdAt: DateTime.utc(2026, 11, 25),
        ),
      );

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      // Save an Insurance bill via QuickAdd -> Bill / Subscription
      await tester.tap(find.byKey(const Key('records_quick_add_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick_add_bill')));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Bill Title *'), 'Health Plan');
      await tester.tap(find.byKey(const Key('bill_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Insurance').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount Due *'), '1500');
      await tester.ensureVisible(find.text('Save Bill'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Bill'));
      await tester.pumpAndSettle();

      final billRecords = await (db.select(db.records)..where((r) => r.recordType.equals('bill'))).get();
      expect(billRecords, hasLength(1));
      expect(billRecords.single.categoryId, 'cat-sub-custom-insurance');

      // Save a Maintenance expense via QuickAdd -> Maintenance
      await tester.tap(find.byKey(const Key('records_quick_add_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick_add_maintenance')));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Expense Title *'), 'Brake Pad Service');
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount (PHP) *'), '950');
      await tester.ensureVisible(find.text('Save Expense'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Expense'));
      await tester.pumpAndSettle();

      final expenses = await expenseRepo.getExpensesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(expenses, hasLength(1));
      expect(expenses.single.record.categoryId, 'cat-sub-maintenance');

      await flush(tester);
    });
  });
}
