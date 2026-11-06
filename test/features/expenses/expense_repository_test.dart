import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/features/expenses/data/expense_repository_impl.dart';
import 'package:domora/features/expenses/domain/expense_item.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/tasks/data/task_repository_impl.dart';
import 'package:domora/features/tasks/domain/task_item.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';

void main() {
  late AppDatabase db;
  late WorkspaceRepositoryImpl workspaceRepo;
  late RecordRepositoryImpl recordRepo;
  late TaskRepositoryImpl taskRepo;
  late ExpenseRepositoryImpl expenseRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    workspaceRepo = WorkspaceRepositoryImpl(db);
    recordRepo = RecordRepositoryImpl(db);
    taskRepo = TaskRepositoryImpl(db);
    expenseRepo = ExpenseRepositoryImpl(db);

    await workspaceRepo.getOrCreateDefaultWorkspace();
  });

  tearDown(() async {
    await db.close();
  });

  group('ExpenseRepositoryImpl Tests', () {
    test('Can create an expense record linked to an asset and retrieve it', () async {
      final now = DateTime.now().toUtc();

      // Seed asset
      await recordRepo.createAssetRecord(
        record: Record(
          id: 'asset-generator',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Honda Generator EU2200i',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'asset-generator', brand: 'Honda'),
      );

      // Create expense
      await expenseRepo.createExpenseRecord(
        record: Record(
          id: 'expense-oil-service',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'expense',
          title: 'Oil Change & Spark Plug',
          description: 'Synthetic 10W-30 oil and NGK spark plug',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: 'expense-oil-service',
          amountMinor: 85000, // PHP 850.00
          currencyCode: 'PHP',
          transactionDate: now,
          paymentMethod: 'cash',
          expenseCategory: 'maintenance',
          linkedAssetRecordId: 'asset-generator',
        ),
      );

      final expenses = await expenseRepo.getExpensesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(expenses.length, 1);

      final item = expenses.first;
      expect(item.record.title, 'Oil Change & Spark Plug');
      expect(item.expense.amountMinor, 85000);
      expect(item.expense.formattedAmount, 'PHP 850.00');
      expect(item.expense.expenseCategory, 'maintenance');
      expect(item.linkedAssetTitle, 'Honda Generator EU2200i');
    });

    test('Filter by category returns only matching expenses', () async {
      final now = DateTime.now().toUtc();

      await expenseRepo.createExpenseRecord(
        record: Record(
          id: 'exp-maint',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'expense',
          title: 'Brake Pad Replacement',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: 'exp-maint',
          amountMinor: 350000,
          transactionDate: now,
          expenseCategory: 'maintenance',
        ),
      );

      await expenseRepo.createExpenseRecord(
        record: Record(
          id: 'exp-util',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'expense',
          title: 'Meralco Electric Bill',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: 'exp-util',
          amountMinor: 642000,
          transactionDate: now,
          expenseCategory: 'utility',
        ),
      );

      final maintenanceOnly = await expenseRepo.getExpensesByWorkspace(
        AppConstants.defaultWorkspaceId,
        category: 'maintenance',
      );
      expect(maintenanceOnly.length, 1);
      expect(maintenanceOnly.first.record.title, 'Brake Pad Replacement');

      final utilityOnly = await expenseRepo.getExpensesByWorkspace(
        AppConstants.defaultWorkspaceId,
        category: 'utility',
      );
      expect(utilityOnly.length, 1);
      expect(utilityOnly.first.record.title, 'Meralco Electric Bill');
    });

    test('softDeleteExpense sets deletedAt and excludes expense from active list', () async {
      final now = DateTime.now().toUtc();

      await expenseRepo.createExpenseRecord(
        record: Record(
          id: 'exp-del',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'expense',
          title: 'Accidental Entry',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: 'exp-del',
          amountMinor: 50000,
          transactionDate: now,
        ),
      );

      var expenses = await expenseRepo.getExpensesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(expenses.length, 1);

      await expenseRepo.softDeleteExpense('exp-del');

      expenses = await expenseRepo.getExpensesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(expenses, isEmpty);

      final rawRecord = await (db.select(db.records)..where((r) => r.id.equals('exp-del'))).getSingle();
      expect(rawRecord.deletedAt, isNotNull);
    });

    test('Deleting an asset cascades setNull on linked expense linkedAssetRecordId', () async {
      final now = DateTime.now().toUtc();

      await recordRepo.createAssetRecord(
        record: Record(
          id: 'parent-car',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Mazda CX-5',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'parent-car', brand: 'Mazda'),
      );

      await expenseRepo.createExpenseRecord(
        record: Record(
          id: 'exp-oil',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'expense',
          title: 'Mazda 10k PMS',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: 'exp-oil',
          amountMinor: 750000,
          transactionDate: now,
          linkedAssetRecordId: 'parent-car',
        ),
      );

      var expenses = await expenseRepo.getExpensesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(expenses.first.linkedAssetTitle, 'Mazda CX-5');

      // Hard delete the asset record
      await (db.delete(db.records)..where((r) => r.id.equals('parent-car'))).go();

      expenses = await expenseRepo.getExpensesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(expenses.length, 1);
      expect(expenses.first.expense.linkedAssetRecordId, isNull);
      expect(expenses.first.linkedAssetTitle, isNull);
    });

    test('Soft-deleting an asset immediately decouples linkedAssetTitle from active expense query', () async {
      final now = DateTime.now().toUtc();

      await recordRepo.createAssetRecord(
        record: Record(
          id: 'soft-del-asset',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Espresso Machine',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'soft-del-asset', brand: 'Gaggia'),
      );

      await expenseRepo.createExpenseRecord(
        record: Record(
          id: 'exp-descaling',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'expense',
          title: 'Descaling Kit',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: 'exp-descaling',
          amountMinor: 65000,
          transactionDate: now,
          linkedAssetRecordId: 'soft-del-asset',
        ),
      );

      var expenses = await expenseRepo.getExpensesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(expenses.first.linkedAssetTitle, 'Espresso Machine');

      await recordRepo.softDeleteRecord('soft-del-asset');

      expenses = await expenseRepo.getExpensesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(expenses.length, 1);
      expect(expenses.first.linkedAssetTitle, isNull);
    });

    test('watchTotalExpensesByAsset correctly aggregates active expenses for a specific asset', () async {
      final now = DateTime.now().toUtc();

      await recordRepo.createAssetRecord(
        record: Record(
          id: 'asset-car-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Honda City',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'asset-car-1', brand: 'Honda'),
      );

      // Add 2 expenses to asset-car-1 (PHP 1,000 + PHP 2,500 = PHP 3,500 = 350000 minor units)
      await expenseRepo.createExpenseRecord(
        record: Record(
          id: 'exp-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'expense',
          title: 'Car Wash & Wax',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: 'exp-1',
          amountMinor: 100000,
          transactionDate: now,
          linkedAssetRecordId: 'asset-car-1',
        ),
      );

      await expenseRepo.createExpenseRecord(
        record: Record(
          id: 'exp-2',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'expense',
          title: 'Tire Rotation',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: 'exp-2',
          amountMinor: 250000,
          transactionDate: now,
          linkedAssetRecordId: 'asset-car-1',
        ),
      );

      // Add expense to another asset
      await expenseRepo.createExpenseRecord(
        record: Record(
          id: 'exp-other',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'expense',
          title: 'House Paint',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: 'exp-other',
          amountMinor: 500000,
          transactionDate: now,
        ),
      );

      final totalCarExpenses = await expenseRepo.watchTotalExpensesByAsset('asset-car-1').first;
      expect(totalCarExpenses, 350000); // exactly 350,000 minor units = PHP 3,500.00
    });

    test('watchTotalWorkspaceExpenses aggregates all active expenses across the workspace', () async {
      final now = DateTime.now().toUtc();

      await expenseRepo.createExpenseRecord(
        record: Record(
          id: 'ws-exp-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'expense',
          title: 'Groceries',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: 'ws-exp-1',
          amountMinor: 420000, // PHP 4,200
          transactionDate: now,
        ),
      );

      await expenseRepo.createExpenseRecord(
        record: Record(
          id: 'ws-exp-2',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'expense',
          title: 'Wi-Fi Internet',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: 'ws-exp-2',
          amountMinor: 189900, // PHP 1,899
          transactionDate: now,
        ),
      );

      final total = await expenseRepo.watchTotalWorkspaceExpenses(AppConstants.defaultWorkspaceId).first;
      expect(total, 609900); // PHP 6,099.00
    });

    test('Can link an expense to a task and populate linkedTaskTitle', () async {
      final now = DateTime.now().toUtc();

      await taskRepo.createTaskRecord(
        record: Record(
          id: 'task-plumb-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'task',
          title: 'Fix Kitchen Sink',
          createdAt: now,
          updatedAt: now,
        ),
        task: const TaskItem(
          recordId: 'task-plumb-1',
          priority: 'High',
          status: 'pending',
        ),
      );

      await expenseRepo.createExpenseRecord(
        record: Record(
          id: 'exp-pipe-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'expense',
          title: 'Replacement P-Trap & Sealant',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: 'exp-pipe-1',
          amountMinor: 85000, // PHP 850.00
          transactionDate: now,
          linkedTaskRecordId: 'task-plumb-1',
        ),
      );

      final expenses = await expenseRepo.getExpensesByWorkspace(AppConstants.defaultWorkspaceId);
      final linkedExpense = expenses.firstWhere((e) => e.record.id == 'exp-pipe-1');
      expect(linkedExpense.linkedTaskTitle, 'Fix Kitchen Sink');
      expect(linkedExpense.expense.linkedTaskRecordId, 'task-plumb-1');
    });
  });
}
