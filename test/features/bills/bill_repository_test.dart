import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/features/bills/data/bill_repository_impl.dart';
import 'package:domora/features/bills/domain/bill_item.dart';
import 'package:domora/features/expenses/data/expense_repository_impl.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';

void main() {
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
    });
  });
}
