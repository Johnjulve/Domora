import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/features/bills/data/bill_repository_impl.dart';
import 'package:domora/features/bills/domain/bill_item.dart';
import 'package:domora/features/expenses/data/expense_repository_impl.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase db;
  late WorkspaceRepositoryImpl workspaceRepo;
  late RecordRepositoryImpl recordRepo;
  late ExpenseRepositoryImpl expenseRepo;
  late BillRepositoryImpl billRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    workspaceRepo = WorkspaceRepositoryImpl(db);
    recordRepo = RecordRepositoryImpl(db);
    expenseRepo = ExpenseRepositoryImpl(db);
    billRepo = BillRepositoryImpl(db);

    await workspaceRepo.getOrCreateDefaultWorkspace();
  });

  tearDown(() async {
    await db.close();
  });

  group('BillRepositoryImpl Tests', () {
    test('Can create a bill record linked to an asset and retrieve it', () async {
      final now = DateTime.now().toUtc();

      // Seed property asset
      await recordRepo.createAssetRecord(
        record: Record(
          id: 'asset-condo',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Makati Condo Unit 14B',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'asset-condo', brand: 'Ayala Land'),
      );

      // Create bill
      final created = await billRepo.createBillRecord(
        record: Record(
          id: 'bill-meralco-oct',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Meralco Electric Bill - Oct',
          description: 'Includes AC summer rate adjustment',
          createdAt: now,
          updatedAt: now,
        ),
        bill: BillItem(
          recordId: 'bill-meralco-oct',
          utilityType: UtilityType.electricity.value,
          providerName: 'Meralco',
          accountNumber: '1092837465',
          billingPeriodStart: now.subtract(const Duration(days: 30)),
          billingPeriodEnd: now,
          dueDate: now.add(const Duration(days: 7)),
          amountDueMinor: 385050, // PHP 3,850.50
          currencyCode: 'PHP',
          paymentStatus: 'unpaid',
          linkedAssetRecordId: 'asset-condo',
        ),
      );

      expect(created.record.id, equals('bill-meralco-oct'));
      expect(created.bill.amountDueMinor, equals(385050));
      expect(created.bill.formattedAmountDue, equals('PHP 3850.50'));
      expect(created.bill.providerName, equals('Meralco'));
      expect(created.linkedAssetRecord?.title, equals('Makati Condo Unit 14B'));
      expect(created.bill.paymentStatus, equals('unpaid'));
      expect(created.bill.isPastDue, isFalse);
    });

    test('markBillAsPaid automatically logs utility expense and bridges relationships', () async {
      final now = DateTime.now().toUtc();

      // Create initial unpaid bill
      await billRepo.createBillRecord(
        record: Record(
          id: 'bill-water-nov',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Manila Water Nov',
          createdAt: now,
          updatedAt: now,
        ),
        bill: BillItem(
          recordId: 'bill-water-nov',
          utilityType: UtilityType.water.value,
          providerName: 'Manila Water',
          dueDate: now.add(const Duration(days: 3)),
          amountDueMinor: 65000, // PHP 650.00
          currencyCode: 'PHP',
          paymentStatus: 'unpaid',
        ),
      );

      // Verify no expenses exist initially
      final initialExpenses = await expenseRepo.watchExpensesByWorkspace(
        AppConstants.defaultWorkspaceId,
      ).first;
      expect(initialExpenses, isEmpty);

      // Mark bill as paid
      final paidTimestamp = DateTime.now().toUtc();
      final paidBill = await billRepo.markBillAsPaid(
        billRecordId: 'bill-water-nov',
        paidAt: paidTimestamp,
        paymentMethod: 'e_wallet',
      );

      // Verify bill status updated
      expect(paidBill.bill.paymentStatus, equals('paid'));
      expect(paidBill.bill.paidAt, isNotNull);
      expect(paidBill.bill.linkedExpenseRecordId, isNotNull);

      // Verify Expense was automatically created
      final expensesAfter = await expenseRepo.watchExpensesByWorkspace(
        AppConstants.defaultWorkspaceId,
      ).first;
      expect(expensesAfter.length, equals(1));

      final createdExpense = expensesAfter.first;
      expect(createdExpense.record.title, contains('Paid: Manila Water Nov'));
      expect(createdExpense.expense.amountMinor, equals(65000));
      expect(createdExpense.expense.expenseCategory, equals('utility'));
      expect(createdExpense.expense.paymentMethod, equals('e_wallet'));
      expect(createdExpense.expense.linkedBillRecordId, equals('bill-water-nov'));

      // Verify workspace total expenses reflects the paid utility bill
      final totalExpenses = await expenseRepo.watchTotalWorkspaceExpenses(
        AppConstants.defaultWorkspaceId,
      ).first;
      expect(totalExpenses, equals(65000));
    });

    test('watchUpcomingBillsByWorkspace sorts by due date and filters paid bills', () async {
      final now = DateTime.now().toUtc();

      // Bill 1: Due in 2 days
      await billRepo.createBillRecord(
        record: Record(
          id: 'bill-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Internet Fiber',
          createdAt: now,
          updatedAt: now,
        ),
        bill: BillItem(
          recordId: 'bill-1',
          utilityType: UtilityType.internet.value,
          dueDate: now.add(const Duration(days: 2)),
          amountDueMinor: 189900,
        ),
      );

      // Bill 2: Due in 10 days
      await billRepo.createBillRecord(
        record: Record(
          id: 'bill-2',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Electricity',
          createdAt: now,
          updatedAt: now,
        ),
        bill: BillItem(
          recordId: 'bill-2',
          utilityType: UtilityType.electricity.value,
          dueDate: now.add(const Duration(days: 10)),
          amountDueMinor: 420000,
        ),
      );

      // Bill 3: Already paid bill
      await billRepo.createBillRecord(
        record: Record(
          id: 'bill-3',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Water Bill',
          createdAt: now,
          updatedAt: now,
        ),
        bill: BillItem(
          recordId: 'bill-3',
          utilityType: UtilityType.water.value,
          dueDate: now.add(const Duration(days: 5)),
          amountDueMinor: 50000,
          paymentStatus: 'paid',
        ),
      );

      final upcoming = await billRepo.watchUpcomingBillsByWorkspace(
        AppConstants.defaultWorkspaceId,
      ).first;

      // Only unpaid bills are returned
      expect(upcoming.length, equals(2));
      // First is due sooner (bill-1)
      expect(upcoming.first.record.id, equals('bill-1'));
      expect(upcoming.last.record.id, equals('bill-2'));
    });

    test('watchTotalUnpaidBillsAmount calculates sum of unpaid obligations accurately', () async {
      final now = DateTime.now().toUtc();

      await billRepo.createBillRecord(
        record: Record(
          id: 'bill-a',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Bill A',
          createdAt: now,
          updatedAt: now,
        ),
        bill: const BillItem(
          recordId: 'bill-a',
          amountDueMinor: 100000, // 1000.00
          paymentStatus: 'unpaid',
        ),
      );

      await billRepo.createBillRecord(
        record: Record(
          id: 'bill-b',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Bill B',
          createdAt: now,
          updatedAt: now,
        ),
        bill: const BillItem(
          recordId: 'bill-b',
          amountDueMinor: 250000, // 2500.00
          paymentStatus: 'unpaid',
        ),
      );

      final totalUnpaid = await billRepo.watchTotalUnpaidBillsAmount(
        AppConstants.defaultWorkspaceId,
      ).first;
      expect(totalUnpaid, equals(350000));
    });

    test('softDeleteBillRecord hides bill from active stream', () async {
      final now = DateTime.now().toUtc();

      await billRepo.createBillRecord(
        record: Record(
          id: 'bill-trash',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Trash to Delete',
          createdAt: now,
          updatedAt: now,
        ),
        bill: const BillItem(
          recordId: 'bill-trash',
          amountDueMinor: 9900,
        ),
      );

      final before = await billRepo.watchBillsByWorkspace(AppConstants.defaultWorkspaceId).first;
      expect(before.length, equals(1));

      await billRepo.softDeleteBillRecord('bill-trash');

      final after = await billRepo.watchBillsByWorkspace(AppConstants.defaultWorkspaceId).first;
      expect(after, isEmpty);
    });

    test('BillItem isDueToday and isPastDueAt date boundary logic works correctly', () {
      final now = DateTime(2026, 11, 7, 14, 30);
      final todayMidnight = DateTime(2026, 11, 7, 0, 0);
      final yesterday = DateTime(2026, 11, 6, 0, 0);
      final tomorrow = DateTime(2026, 11, 8, 0, 0);

      final billDueToday = BillItem(
        recordId: 'bill-today',
        utilityType: 'electricity',
        amountDueMinor: 100000,
        currencyCode: 'PHP',
        dueDate: todayMidnight,
        paymentStatus: 'unpaid',
      );

      final billDueYesterday = BillItem(
        recordId: 'bill-yesterday',
        utilityType: 'water',
        amountDueMinor: 50000,
        currencyCode: 'PHP',
        dueDate: yesterday,
        paymentStatus: 'unpaid',
      );

      final billDueTomorrow = BillItem(
        recordId: 'bill-tomorrow',
        utilityType: 'internet',
        amountDueMinor: 150000,
        currencyCode: 'PHP',
        dueDate: tomorrow,
        paymentStatus: 'unpaid',
      );

      expect(billDueToday.isDueToday(now), isTrue);
      expect(billDueToday.isPastDueAt(now), isFalse);

      expect(billDueYesterday.isDueToday(now), isFalse);
      expect(billDueYesterday.isPastDueAt(now), isTrue);

      expect(billDueTomorrow.isDueToday(now), isFalse);
      expect(billDueTomorrow.isPastDueAt(now), isFalse);

      // Paused and cancelled bills are never past due
      final pausedBill = billDueYesterday.copyWith(paymentStatus: BillPaymentStatus.paused.value);
      final cancelledBill = billDueYesterday.copyWith(paymentStatus: BillPaymentStatus.cancelled.value);
      expect(pausedBill.isPaused, isTrue);
      expect(pausedBill.isPastDueAt(now), isFalse);
      expect(cancelledBill.isCancelled, isTrue);
      expect(cancelledBill.isPastDueAt(now), isFalse);

      // daysUntilDue calendar-day math
      expect(billDueYesterday.daysUntilDue(now), equals(-1));
      expect(billDueToday.daysUntilDue(now), equals(0));
      expect(billDueTomorrow.daysUntilDue(now), equals(1));
    });

    test('BillRecurrenceCycle.advanceDate handles weekly, month-end clamping, leap years, quarterly, semi-annual, annual, and preserves UTC/local', () {
      // Weekly
      final monUtc = DateTime.utc(2026, 3, 2, 9, 30);
      final nextWeek = BillRecurrenceCycle.weekly.advanceDate(monUtc);
      expect(nextWeek, equals(DateTime.utc(2026, 3, 9, 9, 30)));
      expect(nextWeek.isUtc, isTrue);

      // Monthly: Jan 31 -> Feb 28 (non-leap year 2026)
      final jan31NonLeap = DateTime.utc(2026, 1, 31, 8, 0);
      expect(
        BillRecurrenceCycle.monthly.advanceDate(jan31NonLeap),
        equals(DateTime.utc(2026, 2, 28, 8, 0)),
      );

      // Monthly: Jan 31 -> Feb 29 (leap year 2028)
      final jan31Leap = DateTime(2028, 1, 31, 8, 0);
      final feb29 = BillRecurrenceCycle.monthly.advanceDate(jan31Leap);
      expect(feb29, equals(DateTime(2028, 2, 29, 8, 0)));
      expect(feb29.isUtc, isFalse);

      // Quarterly: Nov 30 -> Feb 28 next year
      expect(
        BillRecurrenceCycle.quarterly.advanceDate(DateTime.utc(2026, 11, 30)),
        equals(DateTime.utc(2027, 2, 28)),
      );

      // Semi-annual: Aug 31 -> Feb 28 next year
      expect(
        BillRecurrenceCycle.semiAnnual.advanceDate(DateTime.utc(2026, 8, 31)),
        equals(DateTime.utc(2027, 2, 28)),
      );

      // Annual: Feb 29 (leap) -> Feb 28 next year
      expect(
        BillRecurrenceCycle.annual.advanceDate(DateTime.utc(2028, 2, 29)),
        equals(DateTime.utc(2029, 2, 28)),
      );
    });

    test('Drift v9 to v10 migration preserves existing bills and enables recurrenceCycle and autoLogPayment', () async {
      final rawDb = sqlite3.openInMemory();
      rawDb.execute('''
        CREATE TABLE workspaces (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          workspace_type TEXT NOT NULL DEFAULT 'personal',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          archived_at INTEGER,
          deleted_at INTEGER
        );
        CREATE TABLE categories (
          id TEXT NOT NULL PRIMARY KEY,
          workspace_id TEXT NOT NULL REFERENCES workspaces (id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          icon_key TEXT,
          color_hex TEXT,
          is_system INTEGER NOT NULL DEFAULT 1,
          parent_category_id TEXT REFERENCES categories (id) ON DELETE CASCADE,
          created_at INTEGER NOT NULL,
          archived_at INTEGER
        );
        CREATE TABLE records (
          id TEXT NOT NULL PRIMARY KEY,
          workspace_id TEXT NOT NULL REFERENCES workspaces (id) ON DELETE CASCADE,
          category_id TEXT REFERENCES categories (id) ON DELETE SET NULL,
          record_type TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          status TEXT NOT NULL DEFAULT 'active',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          archived_at INTEGER,
          deleted_at INTEGER
        );
        CREATE TABLE bills (
          record_id TEXT NOT NULL PRIMARY KEY REFERENCES records (id) ON DELETE CASCADE,
          utility_type TEXT NOT NULL DEFAULT 'utility',
          provider_name TEXT,
          account_number TEXT,
          billing_period_start INTEGER,
          billing_period_end INTEGER,
          due_date INTEGER,
          amount_due_minor INTEGER NOT NULL,
          currency_code TEXT NOT NULL DEFAULT 'PHP',
          payment_status TEXT NOT NULL DEFAULT 'unpaid',
          paid_at INTEGER,
          linked_asset_record_id TEXT REFERENCES records (id) ON DELETE SET NULL,
          linked_expense_record_id TEXT REFERENCES records (id) ON DELETE SET NULL
        );
        PRAGMA user_version = 9;
      ''');

      final epochSec = DateTime.utc(2026, 11, 1).millisecondsSinceEpoch ~/ 1000;
      rawDb.execute('''
        INSERT INTO workspaces (id, name, created_at, updated_at)
        VALUES ('ws-v9', 'Legacy v9 Workspace', $epochSec, $epochSec);

        INSERT INTO records (id, workspace_id, record_type, title, created_at, updated_at)
        VALUES ('bill-v9', 'ws-v9', 'bill', 'Legacy Internet Bill', $epochSec, $epochSec);

        INSERT INTO bills (record_id, utility_type, amount_due_minor, due_date)
        VALUES ('bill-v9', 'internet', 199900, $epochSec);
      ''');

      final migratedDb = AppDatabase.forTesting(NativeDatabase.opened(rawDb));
      addTearDown(migratedDb.close);
      final migratedRepo = BillRepositoryImpl(migratedDb);

      final legacy = await migratedRepo.getBillById('bill-v9');
      expect(legacy, isNotNull);
      expect(legacy!.record.title, equals('Legacy Internet Bill'));
      expect(legacy.bill.recurrenceCycle, isNull);
      expect(legacy.bill.autoLogPayment, isFalse);

      // Update legacy bill to recurring with autoLogPayment
      final updated = await migratedRepo.updateBillRecord(
        record: legacy.record,
        bill: legacy.bill.copyWith(
          recurrenceCycle: BillRecurrenceCycle.monthly.value,
          autoLogPayment: true,
        ),
      );
      expect(updated.bill.recurrenceCycle, equals('monthly'));
      expect(updated.bill.autoLogPayment, isTrue);
    });

    test('processDueSubscriptions auto-logs multiple due cycles idempotently and skips paused, cancelled, manual, and one-time bills', () async {
      final created = DateTime.utc(2026, 1, 1);

      // 1. Auto-log monthly subscription due Jan 1 -> running on Mar 5 should log Jan 1, Feb 1, Mar 1 (3 cycles)
      await billRepo.createBillRecord(
        record: Record(
          id: 'sub-spotify',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Spotify Family',
          createdAt: created,
          updatedAt: created,
        ),
        bill: BillItem(
          recordId: 'sub-spotify',
          utilityType: UtilityType.subscription.value,
          dueDate: DateTime.utc(2026, 1, 1),
          amountDueMinor: 23900,
          recurrenceCycle: BillRecurrenceCycle.monthly.value,
          autoLogPayment: true,
        ),
      );

      // 2. Paused auto-log subscription (must be skipped)
      await billRepo.createBillRecord(
        record: Record(
          id: 'sub-paused',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Paused Gym',
          createdAt: created,
          updatedAt: created,
        ),
        bill: BillItem(
          recordId: 'sub-paused',
          utilityType: UtilityType.subscription.value,
          dueDate: DateTime.utc(2026, 1, 1),
          amountDueMinor: 150000,
          paymentStatus: BillPaymentStatus.paused.value,
          recurrenceCycle: BillRecurrenceCycle.monthly.value,
          autoLogPayment: true,
        ),
      );

      // 3. Cancelled subscription (must be skipped)
      await billRepo.createBillRecord(
        record: Record(
          id: 'sub-cancelled',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Old Streaming',
          createdAt: created,
          updatedAt: created,
        ),
        bill: BillItem(
          recordId: 'sub-cancelled',
          utilityType: UtilityType.subscription.value,
          dueDate: DateTime.utc(2026, 1, 1),
          amountDueMinor: 50000,
          paymentStatus: BillPaymentStatus.cancelled.value,
          recurrenceCycle: BillRecurrenceCycle.monthly.value,
          autoLogPayment: false,
        ),
      );

      // 4. Manual recurring bill (autoLogPayment: false -> must be skipped)
      await billRepo.createBillRecord(
        record: Record(
          id: 'bill-manual-rec',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Manual Rent',
          createdAt: created,
          updatedAt: created,
        ),
        bill: BillItem(
          recordId: 'bill-manual-rec',
          utilityType: UtilityType.rent.value,
          dueDate: DateTime.utc(2026, 1, 1),
          amountDueMinor: 2500000,
          recurrenceCycle: BillRecurrenceCycle.monthly.value,
          autoLogPayment: false,
        ),
      );

      // 5. One-time bill (even if passed autoLogPayment: true -> coerced to false & skipped)
      await billRepo.createBillRecord(
        record: Record(
          id: 'bill-onetime',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'One-Time Permit',
          createdAt: created,
          updatedAt: created,
        ),
        bill: BillItem(
          recordId: 'bill-onetime',
          utilityType: UtilityType.other.value,
          dueDate: DateTime.utc(2026, 1, 1),
          amountDueMinor: 50000,
          autoLogPayment: true,
        ),
      );

      final referenceNow = DateTime.utc(2026, 3, 5, 10, 0);
      final loggedFirstRun = await billRepo.processDueSubscriptions(
        AppConstants.defaultWorkspaceId,
        now: referenceNow,
      );
      expect(loggedFirstRun, equals(3));

      // Verify Spotify advanced to Apr 1 and logged 3 subscription expenses
      final spotifyAfter = await billRepo.getBillById('sub-spotify');
      expect(spotifyAfter!.bill.dueDate, equals(DateTime.utc(2026, 4, 1)));
      expect(spotifyAfter.bill.paymentStatus, equals('unpaid'));
      expect(spotifyAfter.bill.paidAt, equals(DateTime.utc(2026, 3, 1)));

      final history = await billRepo.watchPaymentHistoryForBill('sub-spotify').first;
      expect(history.length, equals(3));
      expect(history.every((e) => e.expense.expenseCategory == 'subscription'), isTrue);
      expect(
        history.map((e) => e.expense.transactionDate).toList(),
        equals([
          DateTime.utc(2026, 3, 1),
          DateTime.utc(2026, 2, 1),
          DateTime.utc(2026, 1, 1),
        ]),
      );

      // Running again on the same date is 100% idempotent
      final loggedSecondRun = await billRepo.processDueSubscriptions(
        AppConstants.defaultWorkspaceId,
        now: referenceNow,
      );
      expect(loggedSecondRun, equals(0));
      expect((await billRepo.watchPaymentHistoryForBill('sub-spotify').first).length, equals(3));

      // Verify skipped bills untouched
      expect((await billRepo.watchPaymentHistoryForBill('sub-paused').first), isEmpty);
      expect((await billRepo.watchPaymentHistoryForBill('sub-cancelled').first), isEmpty);
      expect((await billRepo.watchPaymentHistoryForBill('bill-manual-rec').first), isEmpty);
      expect((await billRepo.watchPaymentHistoryForBill('bill-onetime').first), isEmpty);
    });

    test('Manual markBillAsPaid records Paid late description, advances recurring dueDate, and appears in watchPaymentHistoryForBill', () async {
      final created = DateTime.utc(2026, 5, 1);
      await billRepo.createBillRecord(
        record: Record(
          id: 'bill-manual-late',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'PLDT Fiber',
          createdAt: created,
          updatedAt: created,
        ),
        bill: BillItem(
          recordId: 'bill-manual-late',
          utilityType: UtilityType.internet.value,
          dueDate: DateTime.utc(2026, 5, 10),
          billingPeriodStart: DateTime.utc(2026, 4, 10),
          billingPeriodEnd: DateTime.utc(2026, 5, 10),
          amountDueMinor: 169900,
          recurrenceCycle: BillRecurrenceCycle.monthly.value,
          autoLogPayment: false,
        ),
      );

      // Pay 5 days late on May 15
      final paidLateDate = DateTime.utc(2026, 5, 15, 14, 0);
      final updated = await billRepo.markBillAsPaid(
        billRecordId: 'bill-manual-late',
        paidAt: paidLateDate,
        paymentMethod: 'e_wallet',
      );

      expect(updated.bill.paymentStatus, equals('unpaid'));
      expect(updated.bill.dueDate, equals(DateTime.utc(2026, 6, 10)));
      expect(updated.bill.billingPeriodStart, equals(DateTime.utc(2026, 5, 10)));
      expect(updated.bill.billingPeriodEnd, equals(DateTime.utc(2026, 6, 10)));
      expect(updated.bill.paidAt, equals(paidLateDate));

      final history = await billRepo.watchPaymentHistoryForBill('bill-manual-late').first;
      expect(history.length, equals(1));
      expect(history.single.expense.transactionDate, equals(paidLateDate));
      expect(history.single.expense.expenseCategory, equals('utility'));
      expect(history.single.record.description, contains('Paid late (due 2026-05-10)'));
    });

    test('pauseSubscription, cancelSubscription, and resumeSubscription update obligations and never back-charge missed months', () async {
      final created = DateTime.utc(2025, 1, 1);
      final oldPastDue = DateTime.utc(2025, 6, 1);

      await billRepo.createBillRecord(
        record: Record(
          id: 'sub-cloud',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Cloud Storage 2TB',
          createdAt: created,
          updatedAt: created,
        ),
        bill: BillItem(
          recordId: 'sub-cloud',
          utilityType: UtilityType.subscription.value,
          dueDate: oldPastDue,
          amountDueMinor: 49900,
          recurrenceCycle: BillRecurrenceCycle.monthly.value,
          autoLogPayment: true,
        ),
      );

      // Active initially -> shows in upcoming & unpaid total
      expect((await billRepo.watchUpcomingBillsByWorkspace(AppConstants.defaultWorkspaceId).first).length, equals(1));
      expect(await billRepo.watchTotalUnpaidBillsAmount(AppConstants.defaultWorkspaceId).first, equals(49900));

      // Pause -> removed from upcoming & unpaid total, preserves autoLogPayment, rejects markBillAsPaid
      final paused = await billRepo.pauseSubscription('sub-cloud');
      expect(paused.bill.isPaused, isTrue);
      expect(paused.bill.autoLogPayment, isTrue);
      expect(await billRepo.watchUpcomingBillsByWorkspace(AppConstants.defaultWorkspaceId).first, isEmpty);
      expect(await billRepo.watchTotalUnpaidBillsAmount(AppConstants.defaultWorkspaceId).first, equals(0));
      await expectLater(
        billRepo.markBillAsPaid(billRecordId: 'sub-cloud', paidAt: DateTime.now().toUtc()),
        throwsA(isA<StateError>()),
      );

      // Cancel -> sets cancelled & disables autoLogPayment
      final cancelled = await billRepo.cancelSubscription('sub-cloud');
      expect(cancelled.bill.isCancelled, isTrue);
      expect(cancelled.bill.autoLogPayment, isFalse);

      // Resume without explicit nextDueDate -> stored dueDate is in the past, so advances forward from today (never back-charged!)
      final todayUtc = DateTime.now().toUtc();
      final resumed = await billRepo.resumeSubscription(
        billRecordId: 'sub-cloud',
        autoLogPayment: true,
      );
      expect(resumed.bill.paymentStatus, equals('unpaid'));
      expect(resumed.bill.autoLogPayment, isTrue);
      expect(resumed.bill.dueDate, isNotNull);
      expect(resumed.bill.dueDate!.isAfter(DateTime.utc(todayUtc.year, todayUtc.month, todayUtc.day)), isTrue);

      // Running processDueSubscriptions today logs 0 missed months!
      final autoLogged = await billRepo.processDueSubscriptions(
        AppConstants.defaultWorkspaceId,
        now: todayUtc,
      );
      expect(autoLogged, equals(0));
    });

    test('Local DateTime dueDate round-trips as UTC calendar midnight without timezone shift and is due today (not late)', () async {
      final now = DateTime.now().toUtc();
      final localDue = DateTime(2026, 5, 10);

      final created = await billRepo.createBillRecord(
        record: Record(
          id: 'bill-local-date',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Local Date Water Bill',
          createdAt: now,
          updatedAt: now,
        ),
        bill: BillItem(
          recordId: 'bill-local-date',
          utilityType: UtilityType.water.value,
          dueDate: localDue,
          amountDueMinor: 50000,
        ),
      );

      expect(created.bill.dueDate, equals(DateTime.utc(2026, 5, 10)));
      final sameDayMorning = DateTime(2026, 5, 10, 9, 0);
      expect(created.bill.isDueToday(sameDayMorning), isTrue);
      expect(created.bill.isPastDueAt(sameDayMorning), isFalse);
      expect(created.bill.daysUntilDue(sameDayMorning), equals(0));

      // Paying on May 10 morning is NOT late
      await billRepo.markBillAsPaid(
        billRecordId: 'bill-local-date',
        paidAt: sameDayMorning,
      );
      final history = await billRepo.watchPaymentHistoryForBill('bill-local-date').first;
      expect(history.single.record.description, isNot(contains('Paid late')));
    });

    test('Paused/cancelled one-time bills reject markBillAsPaid, null-dueDate coerces autoLogPayment to false, and resume clears stale billing periods', () async {
      final now = DateTime.utc(2026, 1, 1);

      // One-time bill cancelled -> markBillAsPaid must throw StateError
      await billRepo.createBillRecord(
        record: Record(
          id: 'bill-onetime-cancel',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Cancelled Permit',
          createdAt: now,
          updatedAt: now,
        ),
        bill: const BillItem(
          recordId: 'bill-onetime-cancel',
          amountDueMinor: 10000,
        ),
      );
      await billRepo.cancelSubscription('bill-onetime-cancel');
      await expectLater(
        billRepo.markBillAsPaid(billRecordId: 'bill-onetime-cancel', paidAt: now),
        throwsA(isA<StateError>()),
      );

      // Recurring bill with null dueDate coerces autoLogPayment to false
      final noDueBill = await billRepo.createBillRecord(
        record: Record(
          id: 'bill-no-due',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'No Due Date Sub',
          createdAt: now,
          updatedAt: now,
        ),
        bill: const BillItem(
          recordId: 'bill-no-due',
          amountDueMinor: 19900,
          recurrenceCycle: 'monthly',
          autoLogPayment: true,
        ),
      );
      expect(noDueBill.bill.autoLogPayment, isFalse);

      // Resuming a paused bill with stale 2025 billingPeriod clears stale period dates when dueDate shifts
      await billRepo.createBillRecord(
        record: Record(
          id: 'bill-stale-period',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Stale Period Sub',
          createdAt: DateTime.utc(2025, 1, 1),
          updatedAt: DateTime.utc(2025, 1, 1),
        ),
        bill: BillItem(
          recordId: 'bill-stale-period',
          amountDueMinor: 29900,
          dueDate: DateTime.utc(2025, 2, 1),
          billingPeriodStart: DateTime.utc(2025, 1, 1),
          billingPeriodEnd: DateTime.utc(2025, 2, 1),
          recurrenceCycle: 'monthly',
          autoLogPayment: true,
        ),
      );
      await billRepo.pauseSubscription('bill-stale-period');
      final resumed = await billRepo.resumeSubscription(billRecordId: 'bill-stale-period');
      expect(resumed.bill.billingPeriodStart, isNull);
      expect(resumed.bill.billingPeriodEnd, isNull);
    });
  });
}
