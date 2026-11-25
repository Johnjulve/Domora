import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../records/domain/record.dart';
import '../domain/expense_item.dart';
import '../domain/expense_repository.dart';

/// Drift-backed SQLite implementation of [ExpenseRepository].
class ExpenseRepositoryImpl implements ExpenseRepository {
  final AppDatabase _db;

  const ExpenseRepositoryImpl(this._db);

  @override
  Future<void> createExpenseRecord({
    required Record record,
    required ExpenseItem expense,
  }) async {
    return _db.transaction(() async {
      final now = DateTime.now().toUtc();
      final stampedRecord = record.copyWith(
        recordType: 'expense',
        updatedAt: now,
      );
      final syncedExpense = expense.copyWith(recordId: record.id);

      await _db.into(_db.records).insert(_toRecordCompanion(stampedRecord));
      await _db.into(_db.expenses).insert(_toExpenseCompanion(syncedExpense));

      // Auto-update linked asset's latest odometer reading if mileage was recorded in this service log
      // Guard against historical backfilling overwriting a higher current odometer reading
      if (syncedExpense.linkedAssetRecordId != null && syncedExpense.odometerReading != null) {
        final currentAsset = await (_db.select(_db.assets)
              ..where((a) => a.recordId.equals(syncedExpense.linkedAssetRecordId!)))
            .getSingleOrNull();

        if (currentAsset != null &&
            (currentAsset.odometerReading == null || syncedExpense.odometerReading! > currentAsset.odometerReading!)) {
          await (_db.update(_db.assets)..where((a) => a.recordId.equals(syncedExpense.linkedAssetRecordId!)))
              .write(AssetsCompanion(
                odometerReading: Value(syncedExpense.odometerReading),
              ));
        }
      }
    });
  }

  @override
  Future<void> linkTaskToExpense({
    required String expenseRecordId,
    required String taskRecordId,
  }) async {
    await _db.transaction(() async {
      final activeExpense = await (_db.select(_db.records)
            ..where(
              (r) =>
                  r.id.equals(expenseRecordId) &
                  r.recordType.equals('expense') &
                  r.deletedAt.isNull(),
            ))
          .getSingleOrNull();
      if (activeExpense == null) {
        throw StateError('Active expense record not found: $expenseRecordId');
      }

      final activeTask = await (_db.select(_db.records)
            ..where(
              (r) =>
                  r.id.equals(taskRecordId) &
                  r.recordType.equals('task') &
                  r.deletedAt.isNull(),
            ))
          .getSingleOrNull();
      if (activeTask == null) {
        throw StateError('Active task record not found: $taskRecordId');
      }
      if (activeExpense.workspaceId != activeTask.workspaceId) {
        throw StateError('Cannot link task and expense from different workspaces');
      }

      final now = DateTime.now().toUtc();
      await (_db.update(_db.expenses)..where((e) => e.recordId.equals(expenseRecordId))).write(
        ExpensesCompanion(linkedTaskRecordId: Value(taskRecordId)),
      );
      await (_db.update(_db.records)..where((r) => r.id.equals(expenseRecordId))).write(
        RecordsCompanion(updatedAt: Value(now)),
      );
    });
  }

  @override
  Future<void> softDeleteExpense(
    String recordId, {
    List<String> linkedTaskRecordIdsToDelete = const [],
    bool clearAssetNextPmsTarget = false,
  }) async {
    await _db.transaction(() async {
      final activeExpense = await (_db.select(_db.records)
            ..where(
              (r) =>
                  r.id.equals(recordId) &
                  r.recordType.equals('expense') &
                  r.deletedAt.isNull(),
            ))
          .getSingleOrNull();
      if (activeExpense == null) return;

      final now = DateTime.now().toUtc();
      final expenseRow = await (_db.select(_db.expenses)
            ..where((e) => e.recordId.equals(recordId)))
          .getSingleOrNull();

      await (_db.update(_db.records)..where((r) => r.id.equals(recordId))).write(
        RecordsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final uniqueTaskIds = linkedTaskRecordIdsToDelete.toSet().toList();
      if (uniqueTaskIds.isNotEmpty) {
        await (_db.update(_db.records)
              ..where(
                (r) =>
                    r.id.isIn(uniqueTaskIds) &
                    r.workspaceId.equals(activeExpense.workspaceId) &
                    r.recordType.equals('task') &
                    r.deletedAt.isNull(),
              ))
            .write(
          RecordsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }

      final linkedAssetId = expenseRow?.linkedAssetRecordId;
      if (clearAssetNextPmsTarget && linkedAssetId != null) {
        await _clearAssetNextPmsIfNoneRemaining(linkedAssetId, now);
      }
    });
  }

  Future<void> _clearAssetNextPmsIfNoneRemaining(String assetRecordId, DateTime now) async {
    final remainingPmsQuery = _db.select(_db.records).join([
      innerJoin(_db.tasks, _db.tasks.recordId.equalsExp(_db.records.id)),
    ])
      ..where(
        _db.records.recordType.equals('task') &
            _db.records.deletedAt.isNull() &
            _db.tasks.assetRecordId.equals(assetRecordId) &
            _db.tasks.status.equals('pending') &
            _db.records.title.like('Next PMS%'),
      );

    final remaining = await remainingPmsQuery.get();
    if (remaining.isNotEmpty) return;

    await (_db.update(_db.assets)..where((a) => a.recordId.equals(assetRecordId))).write(
      const AssetsCompanion(
        nextPmsOdometerTarget: Value(null),
        nextPmsDueDate: Value(null),
      ),
    );
    await (_db.update(_db.records)
          ..where((r) => r.id.equals(assetRecordId) & r.deletedAt.isNull()))
        .write(RecordsCompanion(updatedAt: Value(now)));
  }

  @override
  Stream<List<RecordWithExpense>> watchExpensesByWorkspace(
    String workspaceId, {
    String? category,
    String? linkedAssetRecordId,
    String? linkedTaskRecordId,
  }) {
    final query = _buildExpensesQuery(
      workspaceId,
      category: category,
      linkedAssetRecordId: linkedAssetRecordId,
      linkedTaskRecordId: linkedTaskRecordId,
    );
    return query.watch().map(_mapRowsToRecordsWithExpenses);
  }

  @override
  Future<List<RecordWithExpense>> getExpensesByWorkspace(
    String workspaceId, {
    String? category,
    String? linkedAssetRecordId,
    String? linkedTaskRecordId,
  }) async {
    final query = _buildExpensesQuery(
      workspaceId,
      category: category,
      linkedAssetRecordId: linkedAssetRecordId,
      linkedTaskRecordId: linkedTaskRecordId,
    );
    final rows = await query.get();
    return _mapRowsToRecordsWithExpenses(rows);
  }

  @override
  Stream<int> watchTotalExpensesByAsset(String assetRecordId) {
    final expenseRecords = _db.records;
    final expensesTable = _db.expenses;

    final query = _db.selectOnly(expensesTable).join([
      innerJoin(expenseRecords, expenseRecords.id.equalsExp(expensesTable.recordId)),
    ]);

    final sumAmount = expensesTable.amountMinor.sum();
    query.addColumns([sumAmount]);

    query.where(
      expenseRecords.deletedAt.isNull() &
          expenseRecords.recordType.equals('expense') &
          expensesTable.linkedAssetRecordId.equals(assetRecordId),
    );

    return query.watchSingleOrNull().map((row) => row?.read(sumAmount) ?? 0);
  }

  @override
  Stream<int> watchTotalWorkspaceExpenses(String workspaceId) {
    final expenseRecords = _db.records;
    final expensesTable = _db.expenses;

    final query = _db.selectOnly(expensesTable).join([
      innerJoin(expenseRecords, expenseRecords.id.equalsExp(expensesTable.recordId)),
    ]);

    final sumAmount = expensesTable.amountMinor.sum();
    query.addColumns([sumAmount]);

    query.where(
      expenseRecords.workspaceId.equals(workspaceId) &
          expenseRecords.deletedAt.isNull() &
          expenseRecords.recordType.equals('expense'),
    );

    return query.watchSingleOrNull().map((row) => row?.read(sumAmount) ?? 0);
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildExpensesQuery(
    String workspaceId, {
    String? category,
    String? linkedAssetRecordId,
    String? linkedTaskRecordId,
  }) {
    final expenseRecords = _db.records;
    final expensesTable = _db.expenses;
    final assetRecords = _db.alias(_db.records, 'asset_records');
    final taskRecords = _db.alias(_db.records, 'task_records');

    final query = _db.select(expenseRecords).join([
      innerJoin(expensesTable, expensesTable.recordId.equalsExp(expenseRecords.id)),
      leftOuterJoin(
        assetRecords,
        assetRecords.id.equalsExp(expensesTable.linkedAssetRecordId) &
            assetRecords.deletedAt.isNull(),
      ),
      leftOuterJoin(
        taskRecords,
        taskRecords.id.equalsExp(expensesTable.linkedTaskRecordId) &
            taskRecords.deletedAt.isNull(),
      ),
    ]);

    Expression<bool> predicate = expenseRecords.workspaceId.equals(workspaceId) &
        expenseRecords.deletedAt.isNull() &
        expenseRecords.recordType.equals('expense');

    if (category != null && category.isNotEmpty) {
      predicate = predicate & expensesTable.expenseCategory.equals(category);
    }

    if (linkedAssetRecordId != null && linkedAssetRecordId.isNotEmpty) {
      predicate = predicate & expensesTable.linkedAssetRecordId.equals(linkedAssetRecordId);
    }

    if (linkedTaskRecordId != null && linkedTaskRecordId.isNotEmpty) {
      predicate = predicate & expensesTable.linkedTaskRecordId.equals(linkedTaskRecordId);
    }

    query.where(predicate);

    query.orderBy([
      OrderingTerm(
        expression: expensesTable.transactionDate,
        mode: OrderingMode.desc,
      ),
      OrderingTerm(
        expression: expenseRecords.createdAt,
        mode: OrderingMode.desc,
      ),
    ]);

    return query;
  }

  List<RecordWithExpense> _mapRowsToRecordsWithExpenses(List<TypedResult> rows) {
    final assetRecords = _db.alias(_db.records, 'asset_records');
    final taskRecords = _db.alias(_db.records, 'task_records');

    return rows.map((row) {
      final recordEntity = row.readTable(_db.records);
      final expenseEntity = row.readTable(_db.expenses);
      final linkedAssetEntity = row.readTableOrNull(assetRecords);
      final linkedTaskEntity = row.readTableOrNull(taskRecords);

      return RecordWithExpense(
        record: _toDomainRecord(recordEntity),
        expense: _toDomainExpense(expenseEntity),
        linkedAssetTitle: linkedAssetEntity?.title,
        linkedTaskTitle: linkedTaskEntity?.title,
      );
    }).toList();
  }

  Record _toDomainRecord(RecordEntity entity) {
    return Record(
      id: entity.id,
      workspaceId: entity.workspaceId,
      categoryId: entity.categoryId,
      recordType: entity.recordType,
      title: entity.title,
      description: entity.description,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      archivedAt: entity.archivedAt,
      deletedAt: entity.deletedAt,
    );
  }

  ExpenseItem _toDomainExpense(ExpenseEntity entity) {
    return ExpenseItem(
      recordId: entity.recordId,
      amountMinor: entity.amountMinor,
      currencyCode: entity.currencyCode,
      transactionDate: entity.transactionDate,
      paymentMethod: entity.paymentMethod,
      expenseCategory: entity.expenseCategory,
      linkedAssetRecordId: entity.linkedAssetRecordId,
      linkedTaskRecordId: entity.linkedTaskRecordId,
      linkedBillRecordId: entity.linkedBillRecordId,
      odometerReading: entity.odometerReading,
    );
  }

  RecordsCompanion _toRecordCompanion(Record record) {
    return RecordsCompanion(
      id: Value(record.id),
      workspaceId: Value(record.workspaceId),
      categoryId: Value(record.categoryId),
      recordType: Value(record.recordType),
      title: Value(record.title),
      description: Value(record.description),
      status: Value(record.status),
      createdAt: Value(record.createdAt),
      updatedAt: Value(record.updatedAt),
      archivedAt: Value(record.archivedAt),
      deletedAt: Value(record.deletedAt),
    );
  }

  ExpensesCompanion _toExpenseCompanion(ExpenseItem expense) {
    return ExpensesCompanion(
      recordId: Value(expense.recordId),
      amountMinor: Value(expense.amountMinor),
      currencyCode: Value(expense.currencyCode),
      transactionDate: Value(expense.transactionDate),
      paymentMethod: Value(expense.paymentMethod),
      expenseCategory: Value(expense.expenseCategory),
      linkedAssetRecordId: Value(expense.linkedAssetRecordId),
      linkedTaskRecordId: Value(expense.linkedTaskRecordId),
      linkedBillRecordId: Value(expense.linkedBillRecordId),
      odometerReading: Value(expense.odometerReading),
    );
  }
}
