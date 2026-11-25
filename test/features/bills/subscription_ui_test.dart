import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/core/theme/app_theme.dart';
import 'package:domora/features/bills/data/bill_repository_impl.dart';
import 'package:domora/features/bills/domain/bill_item.dart';
import 'package:domora/features/bills/presentation/add_bill_sheet.dart';
import 'package:domora/features/bills/presentation/bill_detail_sheet.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/expenses/data/expense_repository_impl.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/records/presentation/records_screen.dart';
import 'package:domora/features/tasks/data/task_repository_impl.dart';
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

  String isoDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<RecordWithBill> seedBill({
    required String id,
    required String title,
    String utilityType = 'subscription',
    String? providerName,
    required DateTime dueDate,
    int amountDueMinor = 54900,
    String paymentStatus = 'unpaid',
    String? recurrenceCycle = 'monthly',
    bool autoLogPayment = false,
  }) async {
    final now = DateTime.now().toUtc();
    final record = Record(
      id: id,
      workspaceId: AppConstants.defaultWorkspaceId,
      recordType: 'bill',
      title: title,
      createdAt: now,
      updatedAt: now,
    );
    final bill = BillItem(
      recordId: id,
      utilityType: utilityType,
      providerName: providerName,
      dueDate: dueDate,
      amountDueMinor: amountDueMinor,
      currencyCode: 'PHP',
      paymentStatus: paymentStatus,
      recurrenceCycle: recurrenceCycle,
      autoLogPayment: autoLogPayment,
    );
    await billRepo.createBillRecord(record: record, bill: bill);
    return RecordWithBill(record: record, bill: bill);
  }

  group('AddBillSheet Subscription Controls & Overdue Badge', () {
    testWidgets(
      'selecting Subscription defaults coverage to Monthly + Auto-log ON, allows switching to Annual + Manual, and shows Overdue badge for past due dates',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildApp(
            const Scaffold(
              body: AddBillSheet(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially Electricity -> One-time, Auto-log switch hidden
        expect(find.byKey(const Key('bill_recurrence_dropdown')), findsOneWidget);
        expect(
          tester
              .state<FormFieldState<BillRecurrenceCycle>>(
                find.byKey(const Key('bill_recurrence_dropdown')),
              )
              .value,
          BillRecurrenceCycle.none,
        );
        expect(find.byKey(const Key('bill_auto_log_switch')), findsNothing);
        expect(find.byKey(const Key('bill_due_date_overdue_badge')), findsNothing);

        // Select Subscription in Category / Type dropdown
        await tester.tap(find.byKey(const Key('bill_type_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Subscription').last);
        await tester.pumpAndSettle();

        // Defaults to Monthly and Auto-log ON (assert actual selected value, not just IndexedStack item)
        expect(
          tester
              .state<FormFieldState<BillRecurrenceCycle>>(
                find.byKey(const Key('bill_recurrence_dropdown')),
              )
              .value,
          BillRecurrenceCycle.monthly,
        );
        final autoLogSwitch = tester.widget<Switch>(
          find.byKey(const Key('bill_auto_log_switch')),
        );
        expect(autoLogSwitch.value, isTrue);

        // Switch coverage to Annual (12 months) and turn Auto-log OFF
        await tester.tap(find.byKey(const Key('bill_recurrence_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Annual (12 months)').last);
        await tester.pumpAndSettle();
        expect(
          tester
              .state<FormFieldState<BillRecurrenceCycle>>(
                find.byKey(const Key('bill_recurrence_dropdown')),
              )
              .value,
          BillRecurrenceCycle.annual,
        );

        await tester.tap(find.byKey(const Key('bill_auto_log_switch')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Switch>(find.byKey(const Key('bill_auto_log_switch'))).value,
          isFalse,
        );

        // Pick a past Due Date via date picker input mode
        await tester.ensureVisible(find.textContaining('Due Date:'));
        await tester.tap(find.textContaining('Due Date:'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).last, '01/15/2025');
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Inline Overdue badge appears
        expect(find.byKey(const Key('bill_due_date_overdue_badge')), findsOneWidget);
        expect(find.text('Overdue'), findsOneWidget);

        // Fill title & amount and save
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Bill Title *'),
          'iCloud+ 2TB Annual',
        );
        await tester.enterText(
          find.byKey(const Key('bill_amount_due_field')),
          '5990.00',
        );

        await tester.ensureVisible(find.text('Save Bill'));
        await tester.tap(find.text('Save Bill'));
        await tester.pumpAndSettle();

        // Verify persisted row in Drift
        final bills = await db.select(db.bills).get();
        expect(bills, hasLength(1));
        expect(bills.first.utilityType, 'subscription');
        expect(bills.first.recurrenceCycle, 'annual');
        expect(bills.first.autoLogPayment, isFalse);

        await flush(tester);
      },
    );
  });

  group('BillDetailSheet Manual Late Payment & Payment History', () {
    testWidgets(
      'shows actual paid date picker + late warning, advances cycle, and updates payment history with Manual + Paid late badges',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.now();
        final pastDue = DateTime.utc(now.year, now.month, now.day).subtract(
          const Duration(days: 5),
        );
        final expectedNextDue = BillRecurrenceCycle.monthly.advanceDate(pastDue);

        final seeded = await seedBill(
          id: 'bill-manual-late-1',
          title: 'Fiber Internet',
          utilityType: 'internet',
          providerName: 'PLDT',
          dueDate: pastDue,
          amountDueMinor: 169900,
          recurrenceCycle: 'monthly',
          autoLogPayment: false,
        );

        await tester.pumpWidget(
          buildApp(
            Scaffold(
              body: BillDetailSheet(item: seeded),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Monthly'), findsOneWidget);
        expect(find.text('Manual'), findsOneWidget);
        expect(find.text('No payments logged yet.'), findsOneWidget);
        expect(find.text('Log Payment & Advance Cycle'), findsOneWidget);

        // Open confirm payment dialog
        await tester.ensureVisible(find.byKey(const Key('bill_log_payment_button')));
        await tester.tap(find.byKey(const Key('bill_log_payment_button')));
        await tester.pumpAndSettle();

        expect(find.text('Confirm Payment'), findsOneWidget);
        expect(find.byKey(const Key('bill_paid_date_picker')), findsOneWidget);
        expect(find.byKey(const Key('bill_late_payment_warning')), findsOneWidget);
        expect(
          find.textContaining('Paid past due date (${isoDate(pastDue)})'),
          findsOneWidget,
        );

        // Confirm payment
        await tester.tap(find.text('Mark Paid & Log Expense'));
        await tester.pumpAndSettle();

        // Reactive UI update: sheet stays open, due date advances, history shows Manual + Paid late
        // and exact today's calendar date (no UTC+8 off-by-one shift) in Last Paid On + Payment History
        final todayIso = isoDate(DateTime.now());
        expect(find.byKey(const Key('bill_payment_history_section')), findsOneWidget);
        expect(find.textContaining(isoDate(expectedNextDue)), findsOneWidget);
        expect(find.text('Last Paid On'), findsOneWidget);
        expect(find.text(todayIso), findsAtLeastNWidgets(2));
        expect(
          find.descendant(
            of: find.byKey(const Key('bill_payment_history_section')),
            matching: find.text(todayIso),
          ),
          findsOneWidget,
        );
        expect(find.text('Paid late'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('bill_payment_history_section')),
            matching: find.text('Manual'),
          ),
          findsOneWidget,
        );

        await flush(tester);
      },
    );

    testWidgets(
      'uses high-contrast primary/onPrimary tokens in Dark Mode and displays custom sub-category label',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.now();
        final seeded = await seedBill(
          id: 'bill-dark-custom-1',
          title: 'Tower B Dues',
          utilityType: 'Condo Dues',
          dueDate: DateTime.utc(now.year, now.month, now.day).add(const Duration(days: 5)),
          amountDueMinor: 420000,
          recurrenceCycle: 'monthly',
          autoLogPayment: false,
        );

        await tester.pumpWidget(
          buildApp(
            Scaffold(body: BillDetailSheet(item: seeded)),
            themeMode: ThemeMode.dark,
          ),
        );
        await tester.pumpAndSettle();

        // Custom utilityType label displayed instead of 'Other Utility'
        expect(find.text('Condo Dues'), findsOneWidget);
        expect(find.text('Other Utility'), findsNothing);

        final darkScheme = AppTheme.darkTheme.colorScheme;
        final logBtn = tester.widget<ElevatedButton>(
          find.byKey(const Key('bill_log_payment_button')),
        );
        expect(logBtn.style?.backgroundColor?.resolve({}), equals(darkScheme.primary));
        expect(logBtn.style?.foregroundColor?.resolve({}), equals(darkScheme.onPrimary));

        await tester.ensureVisible(find.byKey(const Key('bill_log_payment_button')));
        await tester.tap(find.byKey(const Key('bill_log_payment_button')));
        await tester.pumpAndSettle();

        final confirmBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Mark Paid & Log Expense'),
        );
        expect(confirmBtn.style?.backgroundColor?.resolve({}), equals(darkScheme.primary));
        expect(confirmBtn.style?.foregroundColor?.resolve({}), equals(darkScheme.onPrimary));

        await flush(tester);
      },
    );
  });

  group('AddBillSheet Immediate Auto-Log Catch-Up', () {
    testWidgets(
      'immediately catches up a newly created past-due Auto-log subscription',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildApp(
            const Scaffold(
              body: AddBillSheet(initialUtilityType: 'subscription'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Pick a past date (1 month ago via input mode)
        final now = DateTime.now();
        final pastDate = DateTime(now.year, now.month - 1, 10);
        final usDate =
            '${pastDate.month.toString().padLeft(2, '0')}/${pastDate.day.toString().padLeft(2, '0')}/${pastDate.year}';

        await tester.ensureVisible(find.textContaining('Due Date:'));
        await tester.tap(find.textContaining('Due Date:'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).last, usDate);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Bill Title *'),
          'YouTube Premium',
        );
        await tester.enterText(
          find.byKey(const Key('bill_amount_due_field')),
          '189.00',
        );
        await tester.ensureVisible(find.text('Save Bill'));
        await tester.tap(find.text('Save Bill'));
        await tester.pumpAndSettle();

        final bills = await db.select(db.bills).get();
        expect(bills, hasLength(1));
        final linkedExpenses = await (db.select(db.expenses)
              ..where((e) => e.linkedBillRecordId.equals(bills.first.recordId)))
            .get();
        expect(linkedExpenses, isNotEmpty);

        await flush(tester);
      },
    );
  });

  group('BillDetailSheet Pause, Resume & Cancel Lifecycle', () {
    testWidgets(
      'transitions subscription through Pause -> Resume -> Cancel reactively',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.now();
        final nextWeek = DateTime.utc(now.year, now.month, now.day).add(
          const Duration(days: 7),
        );

        final seeded = await seedBill(
          id: 'bill-sub-lifecycle-1',
          title: 'Netflix Premium',
          utilityType: 'subscription',
          providerName: 'Netflix',
          dueDate: nextWeek,
          amountDueMinor: 54900,
          recurrenceCycle: 'monthly',
          autoLogPayment: true,
        );

        await tester.pumpWidget(
          buildApp(
            Scaffold(
              body: BillDetailSheet(item: seeded),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Active state
        expect(
          find.descendant(
            of: find.byKey(const Key('bill_detail_status_pill')),
            matching: find.text('UNPAID'),
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('pause_subscription_button')), findsOneWidget);
        expect(find.byKey(const Key('cancel_subscription_button')), findsOneWidget);
        expect(find.byKey(const Key('resume_subscription_button')), findsNothing);

        // Pause
        await tester.ensureVisible(find.byKey(const Key('pause_subscription_button')));
        await tester.tap(find.byKey(const Key('pause_subscription_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ElevatedButton, 'Pause'));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byKey(const Key('bill_detail_status_pill')),
            matching: find.text('PAUSED'),
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('bill_log_payment_button')), findsNothing);
        expect(find.byKey(const Key('resume_subscription_button')), findsOneWidget);

        // Resume
        await tester.ensureVisible(find.byKey(const Key('resume_subscription_button')));
        await tester.tap(find.byKey(const Key('resume_subscription_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('resume_next_due_picker')), findsOneWidget);
        expect(find.byKey(const Key('resume_auto_log_switch')), findsOneWidget);
        await tester.tap(find.byKey(const Key('resume_subscription_confirm')));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byKey(const Key('bill_detail_status_pill')),
            matching: find.text('UNPAID'),
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('bill_log_payment_button')), findsOneWidget);
        expect(find.byKey(const Key('cancel_subscription_button')), findsOneWidget);

        // Cancel
        await tester.ensureVisible(find.byKey(const Key('cancel_subscription_button')));
        await tester.tap(find.byKey(const Key('cancel_subscription_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel Subscription'));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byKey(const Key('bill_detail_status_pill')),
            matching: find.text('CANCELLED'),
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('bill_log_payment_button')), findsNothing);
        expect(find.byKey(const Key('resume_subscription_button')), findsOneWidget);

        await flush(tester);
      },
    );
  });

  group('RecordsScreen Auto-Log Catch-Up & Renewal Warning Pills', () {
    testWidgets(
      'auto-logs due subscription cycles without top-level duplication and renders Paused, Cancelled, Due in 3d, and Overdue by 4d pills',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.now();
        final todayUtc = DateTime.utc(now.year, now.month, now.day);
        final twoMonthsAgo = DateTime.utc(now.year, now.month - 2, now.day);

        await seedBill(
          id: 'bill-auto-1',
          title: 'Spotify Family',
          utilityType: 'subscription',
          dueDate: twoMonthsAgo,
          amountDueMinor: 23900,
          recurrenceCycle: 'monthly',
          autoLogPayment: true,
        );
        await seedBill(
          id: 'bill-paused-1',
          title: 'Gym Membership',
          utilityType: 'subscription',
          dueDate: todayUtc.add(const Duration(days: 10)),
          amountDueMinor: 250000,
          paymentStatus: 'paused',
          recurrenceCycle: 'monthly',
          autoLogPayment: false,
        );
        await seedBill(
          id: 'bill-cancelled-1',
          title: 'Old Streaming Plan',
          utilityType: 'subscription',
          dueDate: todayUtc.add(const Duration(days: 15)),
          amountDueMinor: 39900,
          paymentStatus: 'cancelled',
          recurrenceCycle: 'monthly',
          autoLogPayment: false,
        );
        await seedBill(
          id: 'bill-soon-1',
          title: 'Water Utility',
          utilityType: 'water',
          dueDate: todayUtc.add(const Duration(days: 3)),
          amountDueMinor: 65000,
          recurrenceCycle: 'monthly',
          autoLogPayment: false,
        );
        await seedBill(
          id: 'bill-overdue-1',
          title: 'Electric Utility',
          utilityType: 'electricity',
          dueDate: todayUtc.subtract(const Duration(days: 4)),
          amountDueMinor: 320000,
          recurrenceCycle: 'monthly',
          autoLogPayment: false,
        );

        await tester.pumpWidget(buildApp(const RecordsScreen()));
        await tester.pumpAndSettle();

        // Auto-log catch-up created mirror expenses linked to bill-auto-1
        final linkedExpenses = await (db.select(db.expenses)
              ..where((e) => e.linkedBillRecordId.equals('bill-auto-1')))
            .get();
        expect(linkedExpenses.length, greaterThanOrEqualTo(3));

        // Expand Bills & Expenses section (first section is expanded by default, check pills)
        expect(find.text('Spotify Family'), findsOneWidget);
        expect(
          find.textContaining('${linkedExpenses.length} payments logged'),
          findsOneWidget,
        );
        // Auto-logged mirror expenses must NOT appear as standalone top-level expense tiles
        for (final exp in linkedExpenses) {
          expect(find.byKey(Key('expense_item_${exp.recordId}')), findsNothing);
        }

        // Verify renewal & status warning pills
        expect(
          find.descendant(
            of: find.byKey(const Key('bill_status_pill_bill-paused-1')),
            matching: find.text('Paused'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('bill_status_pill_bill-cancelled-1')),
            matching: find.text('Cancelled'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('bill_status_pill_bill-soon-1')),
            matching: find.text('Due in 3d'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('bill_status_pill_bill-overdue-1')),
            matching: find.text('Overdue by 4d'),
          ),
          findsOneWidget,
        );

        await flush(tester);
      },
    );
  });
}
