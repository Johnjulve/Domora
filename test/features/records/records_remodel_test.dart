import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/core/theme/app_colors.dart';
import 'package:domora/core/theme/app_theme.dart';
import 'package:domora/features/bills/data/bill_repository_impl.dart';
import 'package:domora/features/bills/domain/bill_item.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/categories/domain/category.dart';
import 'package:domora/features/expenses/data/expense_repository_impl.dart';
import 'package:domora/features/expenses/domain/expense_item.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/records/presentation/records_screen.dart';
import 'package:domora/features/records/presentation/widgets/record_section_card.dart';
import 'package:domora/features/tasks/data/task_repository_impl.dart';
import 'package:domora/features/tasks/domain/task_item.dart';
import 'package:domora/features/vault/data/document_repository_impl.dart';
import 'package:domora/features/vault/domain/document_item.dart';
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

  Widget buildHarness({ThemeMode themeMode = ThemeMode.light}) {
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
        home: const RecordsScreen(),
      ),
    );
  }

  Future<void> flush(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> seedMotorcycleWithHistory() async {
    final now = DateTime.utc(2026, 11, 25, 10, 0, 0);
    await recordRepo.createAssetRecord(
      record: Record(
        id: 'asset-moto-1',
        workspaceId: AppConstants.defaultWorkspaceId,
        categoryId: 'cat-vehicles',
        recordType: 'asset',
        title: 'Yamaha NMAX Motorcycle',
        createdAt: now,
        updatedAt: now,
      ),
      asset: const Asset(
        recordId: 'asset-moto-1',
        brand: 'Yamaha',
        model: 'NMAX 155',
        locationDescription: 'Garage',
        purchaseAmountMinor: 15500000,
        purchaseCurrency: 'PHP',
        odometerReading: 15000,
        nextPmsOdometerTarget: 20000,
      ),
    );

    await expenseRepo.createExpenseRecord(
      record: Record(
        id: 'exp-oil-1',
        workspaceId: AppConstants.defaultWorkspaceId,
        recordType: 'expense',
        title: 'Engine Oil',
        createdAt: now,
        updatedAt: now,
      ),
      expense: ExpenseItem(
        recordId: 'exp-oil-1',
        amountMinor: 85000,
        currencyCode: 'PHP',
        transactionDate: now,
        expenseCategory: 'maintenance',
        linkedAssetRecordId: 'asset-moto-1',
      ),
    );

    await taskRepo.createTaskRecord(
      record: Record(
        id: 'task-pms-1',
        workspaceId: AppConstants.defaultWorkspaceId,
        recordType: 'task',
        title: 'Next PMS',
        createdAt: now,
        updatedAt: now,
      ),
      task: TaskItem(
        recordId: 'task-pms-1',
        dueDate: now.add(const Duration(days: 30)),
        priority: 'medium',
        status: 'pending',
        assetRecordId: 'asset-moto-1',
      ),
    );

    await documentRepo.createDocumentRecord(
      record: Record(
        id: 'doc-orcr-1',
        workspaceId: AppConstants.defaultWorkspaceId,
        recordType: 'document',
        title: 'Motorcycle OR/CR',
        createdAt: now,
        updatedAt: now,
      ),
      document: const DocumentItem(
        recordId: 'doc-orcr-1',
        fileName: 'orcr.pdf',
        documentType: 'deed',
        linkedAssetRecordId: 'asset-moto-1',
      ),
    );
  }

  Future<void> seedBillsAndExpenses() async {
    final now = DateTime.utc(2026, 11, 25, 10, 0, 0);
    await billRepo.createBillRecord(
      record: Record(
        id: 'bill-spotify',
        workspaceId: AppConstants.defaultWorkspaceId,
        recordType: 'bill',
        title: 'Spotify',
        createdAt: now,
        updatedAt: now,
      ),
      bill: BillItem(
        recordId: 'bill-spotify',
        utilityType: 'subscription',
        providerName: 'Spotify AB',
        amountDueMinor: 19900,
        currencyCode: 'PHP',
        dueDate: now.add(const Duration(days: 5)),
        paymentStatus: 'unpaid',
      ),
    );

    await billRepo.createBillRecord(
      record: Record(
        id: 'bill-meralco',
        workspaceId: AppConstants.defaultWorkspaceId,
        recordType: 'bill',
        title: 'Meralco',
        createdAt: now,
        updatedAt: now,
      ),
      bill: BillItem(
        recordId: 'bill-meralco',
        utilityType: 'electricity',
        providerName: 'Meralco Power',
        amountDueMinor: 420000,
        currencyCode: 'PHP',
        dueDate: now.add(const Duration(days: 10)),
        paymentStatus: 'paid',
        paidAt: now,
      ),
    );

    // Paid-bill mirror expense (must NOT duplicate as a flat row in Bills & Expenses)
    await expenseRepo.createExpenseRecord(
      record: Record(
        id: 'exp-meralco-mirror',
        workspaceId: AppConstants.defaultWorkspaceId,
        recordType: 'expense',
        title: 'Meralco Payment Mirror',
        createdAt: now,
        updatedAt: now,
      ),
      expense: ExpenseItem(
        recordId: 'exp-meralco-mirror',
        amountMinor: 420000,
        currencyCode: 'PHP',
        transactionDate: now,
        expenseCategory: 'utility',
        linkedBillRecordId: 'bill-meralco',
      ),
    );
  }

  group('resolveBillsExpensesSubCategoryLabel', () {
    test('maps exact custom names, renamed defaults, canonical aliases, and fallback Other', () {
      final now = DateTime.utc(2026, 11, 25);
      final subs = [
        Category(
          id: 'cat-sub-bill',
          workspaceId: AppConstants.defaultWorkspaceId,
          name: 'Bill',
          parentCategoryId: CategoryRepositoryImpl.billsExpensesCategoryId,
          createdAt: now,
        ),
        Category(
          id: 'cat-sub-subscription',
          workspaceId: AppConstants.defaultWorkspaceId,
          name: 'Subscription',
          parentCategoryId: CategoryRepositoryImpl.billsExpensesCategoryId,
          createdAt: now,
        ),
        Category(
          id: 'cat-sub-withdraw-deposit',
          workspaceId: AppConstants.defaultWorkspaceId,
          name: 'Withdraw / Deposit',
          parentCategoryId: CategoryRepositoryImpl.billsExpensesCategoryId,
          createdAt: now,
        ),
        Category(
          id: 'cat-sub-maintenance',
          workspaceId: AppConstants.defaultWorkspaceId,
          name: 'Maintenance',
          parentCategoryId: CategoryRepositoryImpl.billsExpensesCategoryId,
          createdAt: now,
        ),
        Category(
          id: 'cat-sub-general-expense',
          workspaceId: AppConstants.defaultWorkspaceId,
          name: 'General Expense',
          parentCategoryId: CategoryRepositoryImpl.billsExpensesCategoryId,
          createdAt: now,
        ),
        Category(
          id: 'cat-sub-custom-groceries',
          workspaceId: AppConstants.defaultWorkspaceId,
          name: 'Groceries',
          isSystem: false,
          parentCategoryId: CategoryRepositoryImpl.billsExpensesCategoryId,
          createdAt: now,
        ),
      ];

      expect(
        resolveBillsExpensesSubCategoryLabel(rawType: 'electricity', billsExpensesSubCategories: subs),
        'Bill',
      );
      expect(
        resolveBillsExpensesSubCategoryLabel(rawType: 'subscription', billsExpensesSubCategories: subs),
        'Subscription',
      );
      expect(
        resolveBillsExpensesSubCategoryLabel(rawType: 'withdraw_deposit', billsExpensesSubCategories: subs),
        'Withdraw / Deposit',
      );
      expect(
        resolveBillsExpensesSubCategoryLabel(rawType: 'maintenance', billsExpensesSubCategories: subs),
        'Maintenance',
      );
      expect(
        resolveBillsExpensesSubCategoryLabel(rawType: 'purchase', billsExpensesSubCategories: subs),
        'General Expense',
      );
      expect(
        resolveBillsExpensesSubCategoryLabel(rawType: 'groceries', billsExpensesSubCategories: subs),
        'Groceries',
      );
      expect(
        resolveBillsExpensesSubCategoryLabel(rawType: 'unrecognized_type', billsExpensesSubCategories: subs),
        'Other',
      );
    });
  });

  group('Life Records Remodel Widget Tests', () {
    testWidgets('1. Collapsible boxed sections in All view collapse and re-expand on header tap',
        (WidgetTester tester) async {
      await seedMotorcycleWithHistory();
      await seedBillsAndExpenses();

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      // Both Vehicles and Bills & Expenses sections are rendered
      expect(find.byKey(const Key('section_header_cat-vehicles')), findsOneWidget);
      expect(find.byKey(const Key('section_header_cat-bills-expenses')), findsOneWidget);
      expect(find.text('Yamaha NMAX Motorcycle'), findsOneWidget);

      // Tap Vehicles header to collapse
      await tester.tap(find.byKey(const Key('section_header_cat-vehicles')));
      await tester.pumpAndSettle();
      expect(find.text('Yamaha NMAX Motorcycle'), findsNothing);

      // Tap Vehicles header again to re-expand
      await tester.tap(find.byKey(const Key('section_header_cat-vehicles')));
      await tester.pumpAndSettle();
      expect(find.text('Yamaha NMAX Motorcycle'), findsOneWidget);

      await flush(tester);
    });

    testWidgets('2. Asset history nesting hides linked expense/task rows and displays summary pills on parent asset',
        (WidgetTester tester) async {
      await seedMotorcycleWithHistory();

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      // Linked expense, linked task, and document do NOT duplicate as flat rows
      expect(find.text('Engine Oil'), findsNothing);
      expect(find.text('Next PMS'), findsNothing);
      expect(find.text('Motorcycle OR/CR'), findsNothing);

      // Parent Motorcycle card renders with summary metadata pills
      expect(find.byKey(const Key('record_item_asset-moto-1')), findsOneWidget);
      expect(find.text('Yamaha NMAX Motorcycle'), findsOneWidget);
      expect(find.text('1 log'), findsOneWidget);
      expect(find.text('Next PMS: 20000 km'), findsOneWidget);
      expect(find.text('1 paper'), findsOneWidget);

      // Tapping Motorcycle opens AssetDetailSheet
      await tester.tap(find.byKey(const Key('record_item_asset-moto-1')));
      await tester.pumpAndSettle();
      expect(find.byType(AssetDetailSheet), findsOneWidget);
      expect(find.text('Log Maintenance / Expense'), findsOneWidget);

      await flush(tester);
    });

    testWidgets('3. Bills & Expenses groups Spotify and Meralco under sub-category headers without duplicating paid-bill mirror expense',
        (WidgetTester tester) async {
      await seedBillsAndExpenses();

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('section_header_cat-bills-expenses')), findsOneWidget);
      expect(find.byKey(const Key('bills_subgroup_Bill')), findsOneWidget);
      expect(find.byKey(const Key('bills_subgroup_Subscription')), findsOneWidget);
      expect(find.byKey(const Key('bill_item_bill-meralco')), findsOneWidget);
      expect(find.byKey(const Key('bill_item_bill-spotify')), findsOneWidget);
      expect(find.text('1 payment logged'), findsOneWidget);

      // Paid-bill mirror expense is NOT duplicated as a top-level expense row
      expect(find.text('Meralco Payment Mirror'), findsNothing);
      expect(find.byKey(const Key('expense_item_exp-meralco-mirror')), findsNothing);

      await flush(tester);
    });

    testWidgets('4. ManageCategoriesSheet supports adding custom section/sub-category, renaming, and archiving reactively',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      // Scroll horizontal filter bar to reveal Manage chip and tap it
      final horizontalScrollable = find.descendant(
        of: find.byType(ListView).first,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('manage_categories_chip')),
        200,
        scrollable: horizontalScrollable,
      );
      await tester.tap(find.byKey(const Key('manage_categories_chip')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('manage_categories_sheet')), findsOneWidget);

      // Core Bills & Expenses is protected from deletion (no archive button)
      expect(find.byKey(const Key('archive_category_cat-bills-expenses')), findsNothing);

      // 4a. Add custom section "Collectibles"
      await tester.tap(find.byKey(const Key('manage_add_category_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('category_name_input')), 'Collectibles');
      await tester.tap(find.byKey(const Key('category_dialog_confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Collectibles'), findsWidgets);

      // 4b. Rename "Collectibles" -> "Rare Collectibles"
      final createdSections = await categoryRepo.getCategoriesByWorkspace(AppConstants.defaultWorkspaceId);
      final collectibles = createdSections.firstWhere((c) => c.name == 'Collectibles');
      await tester.scrollUntilVisible(
        find.byKey(Key('rename_category_${collectibles.id}')),
        100,
        scrollable: find.descendant(
          of: find.byKey(const Key('manage_categories_sheet')),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.ensureVisible(find.byKey(Key('rename_category_${collectibles.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('rename_category_${collectibles.id}')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('category_name_input')), 'Rare Collectibles');
      await tester.tap(find.byKey(const Key('category_dialog_confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Rare Collectibles'), findsWidgets);

      // 4c. Switch to Bills & Expenses sub-categories tab and add custom sub-category "Insurance"
      await tester.tap(find.byKey(const Key('manage_tab_subcategories')));
      await tester.pumpAndSettle();
      expect(find.text('Withdraw / Deposit'), findsOneWidget);

      await tester.tap(find.byKey(const Key('manage_add_category_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('category_name_input')), 'Insurance');
      await tester.tap(find.byKey(const Key('category_dialog_confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Insurance'), findsOneWidget);

      // 4d. Switch back to Sections and archive "Rare Collectibles"
      await tester.tap(find.byKey(const Key('manage_tab_sections')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(Key('archive_category_${collectibles.id}')),
        100,
        scrollable: find.descendant(
          of: find.byKey(const Key('manage_categories_sheet')),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.ensureVisible(find.byKey(Key('archive_category_${collectibles.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('archive_category_${collectibles.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Archive'));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('manage_category_row_${collectibles.id}')), findsNothing);

      await flush(tester);
    });

    testWidgets('5. Search mode finds nested history items like Engine Oil',
        (WidgetTester tester) async {
      await seedMotorcycleWithHistory();

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      // Hidden in grouped All view
      expect(find.text('Engine Oil'), findsNothing);

      // Search for "Engine Oil"
      await tester.enterText(find.byType(TextField).first, 'Engine Oil');
      await tester.pumpAndSettle();

      final expenseTile = find.byKey(const Key('expense_item_exp-oil-1'));
      expect(expenseTile, findsOneWidget);
      expect(
        find.descendant(of: expenseTile, matching: find.text('Engine Oil')),
        findsOneWidget,
      );

      // Tapping the search result opens ExpenseDetailSheet
      await tester.tap(expenseTile);
      await tester.pumpAndSettle();
      expect(find.text('Transaction Date'), findsOneWidget);

      await flush(tester);
    });

    testWidgets('6. Dark-mode RecordSectionCard badges avoid hardcoded light AppColors.brandAccentSage',
        (WidgetTester tester) async {
      await seedMotorcycleWithHistory();

      await tester.pumpWidget(buildHarness(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      final countBadge = tester.widget<Container>(
        find.byKey(const Key('section_count_cat-vehicles')),
      );
      final decoration = countBadge.decoration! as BoxDecoration;
      expect(decoration.color, isNot(AppColors.brandAccentSage));
      expect(decoration.color, AppTheme.darkBrandSecondary.withValues(alpha: 0.15));

      final countText = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('section_count_cat-vehicles')),
          matching: find.byType(Text),
        ),
      );
      expect(countText.style?.color, AppTheme.darkBrandSecondary);

      await flush(tester);
    });

    testWidgets('7. Duplicate sub-category names do not crash Bills & Expenses and dialog validates duplicates and >100 chars',
        (WidgetTester tester) async {
      await seedBillsAndExpenses();
      // Insert a duplicate-named sub-category directly into DB to verify defensive deduplication
      await categoryRepo.createCategory(
        Category(
          id: 'cat-sub-dup-bill',
          workspaceId: AppConstants.defaultWorkspaceId,
          name: 'Bill',
          isSystem: false,
          parentCategoryId: CategoryRepositoryImpl.billsExpensesCategoryId,
          createdAt: DateTime.utc(2026, 11, 25),
        ),
      );

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      // Renders cleanly with exactly one Bill sub-header and one Meralco tile (no duplicate key crash)
      expect(find.byKey(const Key('bills_subgroup_Bill')), findsOneWidget);
      expect(find.byKey(const Key('bill_item_bill-meralco')), findsOneWidget);

      // Open ManageCategoriesSheet -> Bills & Expenses tab and verify duplicate & >100-char validation
      final horizontalScrollable = find.descendant(
        of: find.byType(ListView).first,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('manage_categories_chip')),
        200,
        scrollable: horizontalScrollable,
      );
      await tester.tap(find.byKey(const Key('manage_categories_chip')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manage_tab_subcategories')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('manage_add_category_button')));
      await tester.pumpAndSettle();

      // Case-insensitive duplicate rejected
      await tester.enterText(find.byKey(const Key('category_name_input')), 'bill');
      await tester.tap(find.byKey(const Key('category_dialog_confirm')));
      await tester.pumpAndSettle();
      expect(find.text('A category with this name already exists'), findsOneWidget);

      // >100 chars rejected
      await tester.enterText(find.byKey(const Key('category_name_input')), 'A' * 101);
      await tester.tap(find.byKey(const Key('category_dialog_confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Name must be 100 characters or fewer'), findsOneWidget);

      await flush(tester);
    });

    testWidgets('8. Soft-deleted parent surfaces orphaned active linked expense/task and zero-cost linked expense stays reachable in AssetDetailSheet',
        (WidgetTester tester) async {
      await seedMotorcycleWithHistory();

      // Soft-delete the parent motorcycle: active Engine Oil expense & Next PMS task must NOT vanish
      await recordRepo.softDeleteRecord('asset-moto-1');

      // Also create a non-vehicle asset with a PHP 0.00 free warranty service log
      final now = DateTime.utc(2026, 11, 25, 11, 0, 0);
      await recordRepo.createAssetRecord(
        record: Record(
          id: 'asset-laptop-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          categoryId: 'cat-electronics',
          recordType: 'asset',
          title: 'Work Laptop',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'asset-laptop-1', brand: 'Lenovo'),
      );
      await expenseRepo.createExpenseRecord(
        record: Record(
          id: 'exp-warranty-0',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'expense',
          title: 'Free Warranty Fan Replacement',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: 'exp-warranty-0',
          amountMinor: 0,
          currencyCode: 'PHP',
          transactionDate: now,
          expenseCategory: 'maintenance',
          linkedAssetRecordId: 'asset-laptop-1',
        ),
      );

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      // Orphaned active expense surfaces in Bills & Expenses; orphaned active task surfaces in Other Records
      expect(find.byKey(const Key('expense_item_exp-oil-1')), findsOneWidget);
      expect(find.byKey(const Key('record_item_task-pms-1')), findsOneWidget);

      // Zero-cost linked expense stays nested under Work Laptop and is reachable inside AssetDetailSheet
      expect(find.text('Free Warranty Fan Replacement'), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const Key('record_item_asset-laptop-1')),
        120,
        scrollable: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ).first,
      );
      await tester.tap(find.byKey(const Key('record_item_asset-laptop-1')));
      await tester.pumpAndSettle();
      expect(find.text('Free Warranty Fan Replacement'), findsOneWidget);

      await flush(tester);
    });

    testWidgets('9. All-view search finds bills by providerName and expenses by paymentMethod',
        (WidgetTester tester) async {
      await seedBillsAndExpenses();
      final now = DateTime.utc(2026, 11, 25, 11, 0, 0);
      await expenseRepo.createExpenseRecord(
        record: Record(
          id: 'exp-groceries-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'expense',
          title: 'Weekly Market Run',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: 'exp-groceries-1',
          amountMinor: 320000,
          currencyCode: 'PHP',
          transactionDate: now,
          paymentMethod: 'bank_transfer',
          expenseCategory: 'purchase',
        ),
      );

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      // Search by bill providerName ("Spotify AB") in All view
      await tester.enterText(find.byType(TextField).first, 'Spotify AB');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bill_item_bill-spotify')), findsOneWidget);
      expect(find.byKey(const Key('bill_item_bill-meralco')), findsNothing);

      // Search by expense paymentMethod ("bank_transfer") in All view
      await tester.enterText(find.byType(TextField).first, 'bank_transfer');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('expense_item_exp-groceries-1')), findsOneWidget);

      await flush(tester);
    });
  });
}
