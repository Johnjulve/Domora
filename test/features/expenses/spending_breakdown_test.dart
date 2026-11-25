import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/core/theme/app_theme.dart';
import 'package:domora/features/bills/data/bill_repository_impl.dart';
import 'package:domora/features/bills/domain/bill_item.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/categories/domain/category.dart';
import 'package:domora/features/expenses/data/expense_repository_impl.dart';
import 'package:domora/features/expenses/domain/expense_item.dart';
import 'package:domora/features/expenses/domain/spending_breakdown.dart';
import 'package:domora/features/expenses/presentation/spending_breakdown_sheet.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/tasks/data/task_repository_impl.dart';
import 'package:domora/features/today/presentation/today_screen.dart';
import 'package:domora/features/vault/data/document_repository_impl.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('SpendingBreakdown.compute Unit Tests', () {
    final now = DateTime.utc(2026, 11, 25);

    final topLevelCategories = [
      Category(
        id: 'cat-vehicles',
        workspaceId: 'ws-1',
        name: 'Vehicles',
        iconKey: 'directions_car',
        colorHex: '#2E7D5B',
        createdAt: now,
      ),
      Category(
        id: 'cat-appliances',
        workspaceId: 'ws-1',
        name: 'Appliances',
        iconKey: 'kitchen',
        colorHex: '#92400E',
        createdAt: now,
      ),
      Category(
        id: CategoryRepositoryImpl.billsExpensesCategoryId,
        workspaceId: 'ws-1',
        name: 'Bills & Expenses',
        iconKey: 'receipt_long',
        colorHex: '#1E4B38',
        createdAt: now,
      ),
    ];

    final subCategories = [
      Category(
        id: 'cat-sub-bill',
        workspaceId: 'ws-1',
        parentCategoryId: CategoryRepositoryImpl.billsExpensesCategoryId,
        name: 'Bill',
        iconKey: 'receipt_long',
        colorHex: '#1E4B38',
        createdAt: now,
      ),
      Category(
        id: 'cat-sub-subscription',
        workspaceId: 'ws-1',
        parentCategoryId: CategoryRepositoryImpl.billsExpensesCategoryId,
        name: 'Subscription',
        iconKey: 'autorenew',
        colorHex: '#1E4B38',
        createdAt: now,
      ),
      Category(
        id: 'cat-sub-withdraw-deposit',
        workspaceId: 'ws-1',
        parentCategoryId: CategoryRepositoryImpl.billsExpensesCategoryId,
        name: 'Withdraw / Deposit',
        iconKey: 'swap_horiz',
        colorHex: '#1E4B38',
        createdAt: now,
      ),
      Category(
        id: 'cat-sub-groceries',
        workspaceId: 'ws-1',
        parentCategoryId: CategoryRepositoryImpl.billsExpensesCategoryId,
        name: 'Groceries',
        iconKey: 'payments',
        colorHex: '#1E4B38',
        createdAt: now,
      ),
    ];

    final assets = [
      RecordWithAsset(
        record: Record(
          id: 'veh-1',
          workspaceId: 'ws-1',
          categoryId: 'cat-vehicles',
          recordType: 'asset',
          title: 'Honda V4',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'veh-1'),
      ),
      RecordWithAsset(
        record: Record(
          id: 'app-1',
          workspaceId: 'ws-1',
          categoryId: 'cat-appliances',
          recordType: 'asset',
          title: 'Split AC',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'app-1'),
      ),
    ];

    final bills = [
      RecordWithBill(
        record: Record(
          id: 'bill-netflix',
          workspaceId: 'ws-1',
          categoryId: 'cat-sub-subscription',
          recordType: 'bill',
          title: 'Netflix',
          createdAt: now,
          updatedAt: now,
        ),
        bill: const BillItem(
          recordId: 'bill-netflix',
          utilityType: 'subscription',
          amountDueMinor: 54900,
        ),
      ),
      RecordWithBill(
        record: Record(
          id: 'bill-power',
          workspaceId: 'ws-1',
          categoryId: 'cat-sub-bill',
          recordType: 'bill',
          title: 'Meralco',
          createdAt: now,
          updatedAt: now,
        ),
        bill: const BillItem(
          recordId: 'bill-power',
          utilityType: 'electricity',
          amountDueMinor: 250000,
        ),
      ),
    ];

    RecordWithExpense makeExpense({
      required String id,
      required int amountMinor,
      required DateTime date,
      String category = 'other',
      String? categoryId,
      String? linkedAssetId,
      String? linkedBillId,
    }) {
      return RecordWithExpense(
        record: Record(
          id: id,
          workspaceId: 'ws-1',
          categoryId: categoryId,
          recordType: 'expense',
          title: 'Expense $id',
          createdAt: date,
          updatedAt: date,
        ),
        expense: ExpenseItem(
          recordId: id,
          amountMinor: amountMinor,
          transactionDate: date,
          expenseCategory: category,
          linkedAssetRecordId: linkedAssetId,
          linkedBillRecordId: linkedBillId,
        ),
      );
    }

    test('groups asset-linked expenses under asset categories and bills/standalone under Bills & Expenses sub-categories', () {
      final expenses = [
        makeExpense(
          id: 'e1',
          amountMinor: 150000,
          date: DateTime.utc(2026, 11, 5),
          category: 'maintenance',
          linkedAssetId: 'veh-1',
        ),
        makeExpense(
          id: 'e2',
          amountMinor: 50000,
          date: DateTime.utc(2026, 11, 10),
          category: 'service',
          linkedAssetId: 'app-1',
        ),
        makeExpense(
          id: 'e3',
          amountMinor: 250000,
          date: DateTime.utc(2026, 11, 12),
          category: 'utility',
          linkedBillId: 'bill-power',
        ),
        makeExpense(
          id: 'e4',
          amountMinor: 54900,
          date: DateTime.utc(2026, 11, 15),
          category: 'subscription',
          linkedBillId: 'bill-netflix',
        ),
        makeExpense(
          id: 'e5',
          amountMinor: 100000,
          date: DateTime.utc(2026, 11, 18),
          category: 'withdraw',
          categoryId: 'cat-sub-withdraw-deposit',
        ),
        makeExpense(
          id: 'e6',
          amountMinor: 80000,
          date: DateTime.utc(2026, 11, 20),
          category: 'Groceries',
          categoryId: 'cat-sub-groceries',
        ),
      ];

      final breakdown = SpendingBreakdown.compute(
        expenses: expenses,
        activeAssets: assets,
        topLevelCategories: topLevelCategories,
        billsExpensesSubCategories: subCategories,
        bills: bills,
        range: SpendingTimeRange.thisMonth,
        now: now,
      );

      expect(breakdown.totalMinor, 684900);
      expect(breakdown.expenseCount, 6);
      expect(breakdown.categories.map((c) => c.name).toList(), [
        'Bills & Expenses',
        'Vehicles',
        'Appliances',
      ]);

      final billsSummary = breakdown.categories.first;
      expect(billsSummary.totalMinor, 484900);
      expect(billsSummary.subCategories.map((s) => s.name).toList(), [
        'Bill',
        'Withdraw / Deposit',
        'Groceries',
        'Subscription',
      ]);

      final vehicleSummary = breakdown.categories[1];
      expect(vehicleSummary.totalMinor, 150000);
      expect(vehicleSummary.subCategories.first.name, 'Honda V4 • Maintenance & Repairs');

      final applianceSummary = breakdown.categories[2];
      expect(applianceSummary.totalMinor, 50000);
      expect(applianceSummary.subCategories.first.name, 'Split AC • Professional Service');
    });

    test('filters accurately across thisMonth, last3Months (including year boundary), thisYear, and allTime', () {
      final expenses = [
        makeExpense(id: 'cur', amountMinor: 10000, date: DateTime.utc(2026, 1, 10)),
        makeExpense(id: 'prev1', amountMinor: 20000, date: DateTime.utc(2025, 12, 15)),
        makeExpense(id: 'prev2', amountMinor: 30000, date: DateTime.utc(2025, 11, 1)),
        makeExpense(id: 'older', amountMinor: 40000, date: DateTime.utc(2025, 10, 31)),
      ];
      final janNow = DateTime.utc(2026, 1, 20);

      final thisMonth = SpendingBreakdown.compute(
        expenses: expenses,
        activeAssets: const [],
        topLevelCategories: topLevelCategories,
        billsExpensesSubCategories: subCategories,
        bills: const [],
        range: SpendingTimeRange.thisMonth,
        now: janNow,
      );
      expect(thisMonth.totalMinor, 10000);
      expect(thisMonth.expenseCount, 1);

      final last3Months = SpendingBreakdown.compute(
        expenses: expenses,
        activeAssets: const [],
        topLevelCategories: topLevelCategories,
        billsExpensesSubCategories: subCategories,
        bills: const [],
        range: SpendingTimeRange.last3Months,
        now: janNow,
      );
      // Jan 2026 + Dec 2025 + Nov 2025 (excludes Oct 31 2025)
      expect(last3Months.totalMinor, 60000);
      expect(last3Months.expenseCount, 3);

      final thisYear = SpendingBreakdown.compute(
        expenses: expenses,
        activeAssets: const [],
        topLevelCategories: topLevelCategories,
        billsExpensesSubCategories: subCategories,
        bills: const [],
        range: SpendingTimeRange.thisYear,
        now: janNow,
      );
      expect(thisYear.totalMinor, 10000);

      final allTime = SpendingBreakdown.compute(
        expenses: expenses,
        activeAssets: const [],
        topLevelCategories: topLevelCategories,
        billsExpensesSubCategories: subCategories,
        bills: const [],
        range: SpendingTimeRange.allTime,
        now: janNow,
      );
      expect(allTime.totalMinor, 100000);
      expect(allTime.expenseCount, 4);
    });

    test('returns zero total and empty categories when no expenses exist', () {
      final breakdown = SpendingBreakdown.compute(
        expenses: const [],
        activeAssets: const [],
        topLevelCategories: topLevelCategories,
        billsExpensesSubCategories: subCategories,
        bills: const [],
        range: SpendingTimeRange.thisMonth,
        now: now,
      );
      expect(breakdown.totalMinor, 0);
      expect(breakdown.expenseCount, 0);
      expect(breakdown.categories, isEmpty);
      expect(breakdown.currencies, isEmpty);
      expect(breakdown.hasMixedCurrencies, isFalse);
    });

    test('tracks distinct currencies and flags hasMixedCurrencies when multiple currencies are combined', () {
      final phpExpense = makeExpense(
        id: 'php-1',
        amountMinor: 50000,
        date: DateTime.utc(2026, 11, 10),
      );
      final usdExpense = RecordWithExpense(
        record: Record(
          id: 'usd-1',
          workspaceId: 'ws-1',
          recordType: 'expense',
          title: 'Cloud Storage',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: 'usd-1',
          amountMinor: 1000,
          currencyCode: 'USD',
          transactionDate: DateTime.utc(2026, 11, 12),
          expenseCategory: 'subscription',
        ),
      );

      final mixed = SpendingBreakdown.compute(
        expenses: [phpExpense, usdExpense],
        activeAssets: const [],
        topLevelCategories: topLevelCategories,
        billsExpensesSubCategories: subCategories,
        bills: const [],
        range: SpendingTimeRange.thisMonth,
        now: now,
      );
      expect(mixed.hasMixedCurrencies, isTrue);
      expect(mixed.currencies, equals(['PHP', 'USD']));
      expect(mixed.totalMinor, 51000);
    });
  });

  group('SpendingBreakdownSheet & TodayScreen Widget Tests', () {
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

    Widget buildApp(Widget home, {ThemeMode themeMode = ThemeMode.light}) {
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
          home: home,
        ),
      );
    }

    Future<void> flush(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets(
      'tapping today_spent_summary_card on TodayScreen opens SpendingBreakdownSheet with donut chart, expandable categories, and reactive range switching',
      (tester) async {
        tester.view.physicalSize = const Size(540, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.now();
        final todayUtc = DateTime.utc(now.year, now.month, now.day);
        final lastYearUtc = DateTime.utc(now.year - 1, 6, 15);

        await recordRepo.createAssetRecord(
          record: Record(
            id: 'veh-nmax',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-vehicles',
            recordType: 'asset',
            title: 'Yamaha NMAX',
            createdAt: todayUtc,
            updatedAt: todayUtc,
          ),
          asset: const Asset(recordId: 'veh-nmax', brand: 'Yamaha'),
        );

        await expenseRepo.createExpenseRecord(
          record: Record(
            id: 'exp-oil-cur',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'expense',
            title: 'Engine Oil',
            createdAt: todayUtc,
            updatedAt: todayUtc,
          ),
          expense: ExpenseItem(
            recordId: 'exp-oil-cur',
            amountMinor: 120000,
            transactionDate: todayUtc,
            expenseCategory: 'maintenance',
            linkedAssetRecordId: 'veh-nmax',
          ),
        );
        await expenseRepo.createExpenseRecord(
          record: Record(
            id: 'exp-sub-cur',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-sub-subscription',
            recordType: 'expense',
            title: 'Netflix',
            createdAt: todayUtc,
            updatedAt: todayUtc,
          ),
          expense: ExpenseItem(
            recordId: 'exp-sub-cur',
            amountMinor: 54900,
            transactionDate: todayUtc,
            expenseCategory: 'subscription',
          ),
        );
        await expenseRepo.createExpenseRecord(
          record: Record(
            id: 'exp-old-year',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-sub-bill',
            recordType: 'expense',
            title: 'Old Electric Bill',
            createdAt: lastYearUtc,
            updatedAt: lastYearUtc,
          ),
          expense: ExpenseItem(
            recordId: 'exp-old-year',
            amountMinor: 300000,
            transactionDate: lastYearUtc,
            expenseCategory: 'utility',
          ),
        );

        await tester.pumpWidget(buildApp(const TodayScreen()));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('today_spent_summary_card')), findsOneWidget);
        await tester.tap(find.byKey(const Key('today_spent_summary_card')));
        await tester.pumpAndSettle();

        // Sheet opens with donut chart & This Month total (1,200 + 549 = 1,749.00)
        expect(find.byKey(const Key('spending_breakdown_sheet')), findsOneWidget);
        expect(find.byKey(const Key('spending_donut_chart')), findsOneWidget);
        expect(find.text('PHP 1,749.00'), findsOneWidget);
        expect(find.byKey(const Key('spending_category_cat-vehicles')), findsOneWidget);
        expect(find.byKey(const Key('spending_category_cat-bills-expenses')), findsOneWidget);

        // Top category (Vehicles) is auto-expanded showing sub-category
        expect(find.text('Yamaha NMAX • Maintenance & Repairs'), findsOneWidget);
        expect(find.text('PHP 1,200.00'), findsWidgets);

        // Expand Bills & Expenses to reveal Subscription sub-category
        await tester.tap(find.byKey(const Key('spending_category_toggle_cat-bills-expenses')));
        await tester.pumpAndSettle();
        expect(find.text('Subscription'), findsOneWidget);
        expect(find.text('PHP 549.00'), findsWidgets);

        // Switch range from This Month -> All Time (adds PHP 3,000.00 -> PHP 4,749.00)
        await tester.tap(find.byKey(const Key('spending_range_allTime')));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byKey(const Key('spending_donut_chart')),
            matching: find.text('PHP 4,749.00'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('spending_category_cat-bills-expenses')),
            matching: find.text('Bill'),
          ),
          findsOneWidget,
        );
        expect(find.text('PHP 3,000.00'), findsOneWidget);

        await flush(tester);
      },
    );

    testWidgets(
      'offers 1-tap View All Time shortcut when current month is empty and renders without overflow at 360x800 in Light and Dark mode',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.now();
        final oldDate = DateTime.utc(now.year - 1, 3, 10);
        await expenseRepo.createExpenseRecord(
          record: Record(
            id: 'exp-only-old',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-sub-bill',
            recordType: 'expense',
            title: 'Last Year Internet Bill',
            createdAt: oldDate,
            updatedAt: oldDate,
          ),
          expense: ExpenseItem(
            recordId: 'exp-only-old',
            amountMinor: 169900,
            transactionDate: oldDate,
            expenseCategory: 'utility',
          ),
        );

        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          await tester.pumpWidget(
            buildApp(
              const Scaffold(body: SpendingBreakdownSheet()),
              themeMode: mode,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('spending_breakdown_empty')), findsOneWidget);
          expect(find.byKey(const Key('spending_view_all_time_button')), findsOneWidget);

          await tester.tap(find.byKey(const Key('spending_view_all_time_button')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('PHP 1,699.00'), findsWidgets);

          await flush(tester);
        }
      },
    );

    testWidgets(
      'surfaces mixed-currency notice, formats <1% shares honestly, and shows error + Retry when a stream fails',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.now();
        final todayUtc = DateTime.utc(now.year, now.month, now.day);

        await recordRepo.createAssetRecord(
          record: Record(
            id: 'veh-tiny',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-vehicles',
            recordType: 'asset',
            title: 'Scooter',
            createdAt: todayUtc,
            updatedAt: todayUtc,
          ),
          asset: const Asset(recordId: 'veh-tiny'),
        );
        // Tiny 0.4% slice (400 minor vs 100,000 minor) + mixed currency (PHP + USD)
        await expenseRepo.createExpenseRecord(
          record: Record(
            id: 'exp-big-php',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-sub-bill',
            recordType: 'expense',
            title: 'Large Rent',
            createdAt: todayUtc,
            updatedAt: todayUtc,
          ),
          expense: ExpenseItem(
            recordId: 'exp-big-php',
            amountMinor: 10000000,
            currencyCode: 'PHP',
            transactionDate: todayUtc,
            expenseCategory: 'utility',
          ),
        );
        await expenseRepo.createExpenseRecord(
          record: Record(
            id: 'exp-tiny-usd',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'expense',
            title: 'Wash Token',
            createdAt: todayUtc,
            updatedAt: todayUtc,
          ),
          expense: ExpenseItem(
            recordId: 'exp-tiny-usd',
            amountMinor: 40000,
            currencyCode: 'USD',
            transactionDate: todayUtc,
            expenseCategory: 'maintenance',
            linkedAssetRecordId: 'veh-tiny',
          ),
        );

        await tester.pumpWidget(
          buildApp(const Scaffold(body: SpendingBreakdownSheet())),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('spending_mixed_currency_notice')), findsOneWidget);
        expect(find.textContaining('PHP, USD'), findsOneWidget);
        expect(find.textContaining('<1%'), findsOneWidget);

        await flush(tester);

        // Error state + Retry button
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              workspaceRepositoryProvider.overrideWithValue(WorkspaceRepositoryImpl(db)),
              categoryRepositoryProvider.overrideWithValue(categoryRepo),
              recordRepositoryProvider.overrideWithValue(recordRepo),
              billRepositoryProvider.overrideWithValue(billRepo),
              expenseRepositoryProvider.overrideWithValue(expenseRepo),
              taskRepositoryProvider.overrideWithValue(taskRepo),
              documentRepositoryProvider.overrideWithValue(documentRepo),
              dashboardExpensesStreamProvider.overrideWith(
                (ref) => Stream<List<RecordWithExpense>>.error(Exception('stream failure')),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(body: SpendingBreakdownSheet()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('spending_breakdown_error')), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        await flush(tester);
      },
    );
  });
}
