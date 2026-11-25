import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../categories/domain/category.dart';
import '../../expenses/domain/expense_item.dart';
import '../../records/domain/record.dart';
import '../domain/bill_item.dart';
import '../domain/bill_repository.dart';

class _BillPaymentExpense {
  final String workspaceId;
  final String? categoryId;
  final String billRecordId;
  final String billTitle;
  final String description;
  final int amountMinor;
  final String currencyCode;
  final DateTime transactionDate;
  final String paymentMethod;
  final String expenseCategory;
  final String? linkedAssetRecordId;

  const _BillPaymentExpense({
    required this.workspaceId,
    required this.categoryId,
    required this.billRecordId,
    required this.billTitle,
    required this.description,
    required this.amountMinor,
    required this.currencyCode,
    required this.transactionDate,
    required this.paymentMethod,
    required this.expenseCategory,
    required this.linkedAssetRecordId,
  });
}

/// Drift SQLite implementation of [BillRepository].
class BillRepositoryImpl implements BillRepository {
  static const int maxAutoLogCyclesPerRun = 24;

  final AppDatabase _db;
  final Uuid _uuid;

  const BillRepositoryImpl(this._db, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  String? _normalizeRecurrenceCycle(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty || trimmed == BillRecurrenceCycle.none.value) {
      return null;
    }
    final parsed = BillRecurrenceCycle.fromString(trimmed);
    if (!parsed.isRecurring) {
      throw ArgumentError.value(raw, 'recurrenceCycle', 'Unsupported recurrence cycle');
    }
    return parsed.value;
  }

  DateTime _calendarDate(DateTime dt) => DateTime.utc(dt.year, dt.month, dt.day);

  DateTime? _normalizeCalendarDate(DateTime? dt) => dt == null ? null : _calendarDate(dt);

  String _formatIsoDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _expenseCategoryForUtilityType(String utilityType) {
    return utilityType == UtilityType.subscription.value ? 'subscription' : 'utility';
  }

  Future<String> _insertLinkedBillExpense(_BillPaymentExpense payment) async {
    final expenseRecordId = _uuid.v4();
    final txDateUtc = payment.transactionDate.toUtc();
    await _db.into(_db.records).insert(
          RecordsCompanion(
            id: Value(expenseRecordId),
            workspaceId: Value(payment.workspaceId),
            categoryId: Value(payment.categoryId),
            recordType: const Value('expense'),
            title: Value('Paid: ${payment.billTitle}'),
            description: Value(payment.description),
            status: const Value('active'),
            createdAt: Value(txDateUtc),
            updatedAt: Value(txDateUtc),
          ),
        );

    await _db.into(_db.expenses).insert(
          ExpensesCompanion(
            recordId: Value(expenseRecordId),
            amountMinor: Value(payment.amountMinor),
            currencyCode: Value(payment.currencyCode),
            transactionDate: Value(txDateUtc),
            paymentMethod: Value(payment.paymentMethod),
            expenseCategory: Value(payment.expenseCategory),
            linkedAssetRecordId: Value(payment.linkedAssetRecordId),
            linkedBillRecordId: Value(payment.billRecordId),
          ),
        );

    return expenseRecordId;
  }

  @override
  Future<RecordWithBill> createBillRecord({
    required Record record,
    required BillItem bill,
  }) async {
    final normalizedCycle = _normalizeRecurrenceCycle(bill.recurrenceCycle);
    final normalizedDueDate = _normalizeCalendarDate(bill.dueDate);
    final effectiveAutoLog =
        normalizedCycle != null && normalizedDueDate != null && bill.autoLogPayment;

    return _db.transaction(() async {
      await _db.into(_db.records).insert(
            RecordsCompanion(
              id: Value(record.id),
              workspaceId: Value(record.workspaceId),
              categoryId: Value(record.categoryId),
              recordType: const Value('bill'),
              title: Value(record.title),
              description: Value(record.description),
              status: Value(record.status),
              createdAt: Value(record.createdAt.toUtc()),
              updatedAt: Value(record.updatedAt.toUtc()),
            ),
          );

      await _db.into(_db.bills).insert(
            BillsCompanion(
              recordId: Value(record.id),
              utilityType: Value(bill.utilityType),
              providerName: Value(bill.providerName),
              accountNumber: Value(bill.accountNumber),
              billingPeriodStart: Value(_normalizeCalendarDate(bill.billingPeriodStart)),
              billingPeriodEnd: Value(_normalizeCalendarDate(bill.billingPeriodEnd)),
              dueDate: Value(normalizedDueDate),
              amountDueMinor: Value(bill.amountDueMinor),
              currencyCode: Value(bill.currencyCode),
              paymentStatus: Value(bill.paymentStatus),
              paidAt: Value(bill.paidAt?.toUtc()),
              recurrenceCycle: Value(normalizedCycle),
              autoLogPayment: Value(effectiveAutoLog),
              linkedAssetRecordId: Value(bill.linkedAssetRecordId),
              linkedExpenseRecordId: Value(bill.linkedExpenseRecordId),
            ),
          );

      final fetched = await getBillById(record.id);
      return fetched!;
    });
  }

  @override
  Future<RecordWithBill> updateBillRecord({
    required Record record,
    required BillItem bill,
  }) async {
    final normalizedCycle = _normalizeRecurrenceCycle(bill.recurrenceCycle);
    final normalizedDueDate = _normalizeCalendarDate(bill.dueDate);
    final effectiveAutoLog =
        normalizedCycle != null && normalizedDueDate != null && bill.autoLogPayment;

    return _db.transaction(() async {
      await (_db.update(_db.records)..where((r) => r.id.equals(record.id))).write(
        RecordsCompanion(
          title: Value(record.title),
          description: Value(record.description),
          categoryId: Value(record.categoryId),
          status: Value(record.status),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

      await (_db.update(_db.bills)..where((b) => b.recordId.equals(bill.recordId))).write(
        BillsCompanion(
          utilityType: Value(bill.utilityType),
          providerName: Value(bill.providerName),
          accountNumber: Value(bill.accountNumber),
          billingPeriodStart: Value(_normalizeCalendarDate(bill.billingPeriodStart)),
          billingPeriodEnd: Value(_normalizeCalendarDate(bill.billingPeriodEnd)),
          dueDate: Value(normalizedDueDate),
          amountDueMinor: Value(bill.amountDueMinor),
          currencyCode: Value(bill.currencyCode),
          paymentStatus: Value(bill.paymentStatus),
          paidAt: Value(bill.paidAt?.toUtc()),
          recurrenceCycle: Value(normalizedCycle),
          autoLogPayment: Value(effectiveAutoLog),
          linkedAssetRecordId: Value(bill.linkedAssetRecordId),
          linkedExpenseRecordId: Value(bill.linkedExpenseRecordId),
        ),
      );

      final fetched = await getBillById(record.id);
      return fetched!;
    });
  }

  @override
  Future<RecordWithBill> markBillAsPaid({
    required String billRecordId,
    required DateTime paidAt,
    String? paymentMethod,
  }) async {
    return _db.transaction(() async {
      final existing = await getBillById(billRecordId);
      if (existing == null) {
        throw ArgumentError('Bill with record ID $billRecordId not found');
      }
      if (existing.bill.isPaused || existing.bill.isCancelled) {
        throw StateError(
          'Cannot mark ${existing.bill.paymentStatus} bill "$billRecordId" as paid; resume it first.',
        );
      }

      final paidAtUtc = paidAt.toUtc();
      final dueDate = existing.bill.dueDate;
      final isLate = dueDate != null && _calendarDate(paidAt).isAfter(_calendarDate(dueDate));
      final providerInfo = existing.bill.providerName != null
          ? ' (${existing.bill.providerName})'
          : '';
      final description = isLate
          ? 'Manual payment for ${existing.record.title} — Paid late (due ${_formatIsoDate(dueDate)})'
          : 'Manual payment for ${existing.record.title}$providerInfo';

      final shouldInsertExpense =
          existing.bill.isRecurring || existing.bill.linkedExpenseRecordId == null;
      final expenseRecordId = shouldInsertExpense
          ? await _insertLinkedBillExpense(
              _BillPaymentExpense(
                workspaceId: existing.record.workspaceId,
                categoryId: existing.record.categoryId,
                billRecordId: billRecordId,
                billTitle: existing.record.title,
                description: description,
                amountMinor: existing.bill.amountDueMinor,
                currencyCode: existing.bill.currencyCode,
                transactionDate: paidAtUtc,
                paymentMethod: paymentMethod ?? 'bank_transfer',
                expenseCategory: _expenseCategoryForUtilityType(existing.bill.utilityType),
                linkedAssetRecordId: existing.bill.linkedAssetRecordId,
              ),
            )
          : existing.bill.linkedExpenseRecordId!;

      final companion = _buildPaidBillCompanion(
        bill: existing.bill,
        paidAtUtc: paidAtUtc,
        expenseRecordId: expenseRecordId,
      );
      await (_db.update(_db.bills)..where((b) => b.recordId.equals(billRecordId))).write(companion);
      await (_db.update(_db.records)..where((r) => r.id.equals(billRecordId))).write(
        RecordsCompanion(updatedAt: Value(paidAtUtc)),
      );

      return (await getBillById(billRecordId))!;
    });
  }

  BillsCompanion _buildPaidBillCompanion({
    required BillItem bill,
    required DateTime paidAtUtc,
    required String expenseRecordId,
  }) {
    if (!bill.isRecurring) {
      return BillsCompanion(
        paymentStatus: const Value('paid'),
        paidAt: Value(paidAtUtc),
        linkedExpenseRecordId: Value(expenseRecordId),
      );
    }

    final cycle = bill.recurrenceCycleEnum;
    final nextDue = bill.dueDate != null ? cycle.advanceDate(bill.dueDate!) : null;
    final nextPeriodStart =
        bill.billingPeriodStart != null ? cycle.advanceDate(bill.billingPeriodStart!) : null;
    final nextPeriodEnd =
        bill.billingPeriodEnd != null ? cycle.advanceDate(bill.billingPeriodEnd!) : null;

    return BillsCompanion(
      paymentStatus: const Value('unpaid'),
      dueDate: Value(nextDue),
      billingPeriodStart: Value(nextPeriodStart),
      billingPeriodEnd: Value(nextPeriodEnd),
      paidAt: Value(paidAtUtc),
      linkedExpenseRecordId: Value(expenseRecordId),
    );
  }

  @override
  Future<int> processDueSubscriptions(String workspaceId, {DateTime? now}) async {
    final referenceDate = now ?? DateTime.now();
    final referenceDay = _calendarDate(referenceDate);
    final updatedAtUtc = referenceDate.toUtc();

    return _db.transaction(() async {
      final candidateQuery = _db.select(_db.records).join([
        innerJoin(_db.bills, _db.bills.recordId.equalsExp(_db.records.id)),
      ])
        ..where(_db.records.workspaceId.equals(workspaceId))
        ..where(_db.records.recordType.equals('bill'))
        ..where(_db.records.deletedAt.isNull())
        ..where(_db.bills.autoLogPayment.equals(true))
        ..where(_db.bills.recurrenceCycle.isNotNull())
        ..where(_db.bills.paymentStatus.isIn(['unpaid', 'overdue']))
        ..where(_db.bills.dueDate.isNotNull());

      final rows = await candidateQuery.get();
      var totalNewlyLogged = 0;

      for (final row in rows) {
        final rec = row.readTable(_db.records);
        final billEntity = row.readTable(_db.bills);
        final cycle = BillRecurrenceCycle.fromString(billEntity.recurrenceCycle);
        if (!cycle.isRecurring || billEntity.dueDate == null) continue;

        totalNewlyLogged += await _processSingleDueBill(
          rec: rec,
          billEntity: billEntity,
          cycle: cycle,
          referenceDay: referenceDay,
          updatedAtUtc: updatedAtUtc,
        );
      }

      return totalNewlyLogged;
    });
  }

  Future<int> _processSingleDueBill({
    required RecordEntity rec,
    required BillEntity billEntity,
    required BillRecurrenceCycle cycle,
    required DateTime referenceDay,
    required DateTime updatedAtUtc,
  }) async {
    var cycleDueDate = _calendarDate(billEntity.dueDate!.toUtc());
    if (cycleDueDate.isAfter(referenceDay)) return 0;

    final existingExpenses = await (_db.select(_db.expenses).join([
      innerJoin(_db.records, _db.records.id.equalsExp(_db.expenses.recordId)),
    ])
          ..where(_db.expenses.linkedBillRecordId.equals(rec.id))
          ..where(_db.records.deletedAt.isNull()))
        .get();

    final loggedDateKeys = {
      for (final r in existingExpenses)
        _formatIsoDate(r.readTable(_db.expenses).transactionDate.toUtc()),
    };

    var periodStart = _normalizeCalendarDate(billEntity.billingPeriodStart?.toUtc());
    var periodEnd = _normalizeCalendarDate(billEntity.billingPeriodEnd?.toUtc());
    String? lastExpenseId;
    DateTime? lastLoggedDueDate;
    var cyclesProcessed = 0;
    var newlyLogged = 0;
    final expenseCategory = _expenseCategoryForUtilityType(billEntity.utilityType);

    while (!cycleDueDate.isAfter(referenceDay) && cyclesProcessed < maxAutoLogCyclesPerRun) {
      final dateKey = _formatIsoDate(cycleDueDate);
      if (!loggedDateKeys.contains(dateKey)) {
        final expenseId = await _insertLinkedBillExpense(
          _BillPaymentExpense(
            workspaceId: rec.workspaceId,
            categoryId: rec.categoryId,
            billRecordId: rec.id,
            billTitle: rec.title,
            description: 'Auto-logged payment for ${rec.title} (due $dateKey)',
            amountMinor: billEntity.amountDueMinor,
            currencyCode: billEntity.currencyCode,
            transactionDate: cycleDueDate,
            paymentMethod: 'auto_debit',
            expenseCategory: expenseCategory,
            linkedAssetRecordId: billEntity.linkedAssetRecordId,
          ),
        );
        loggedDateKeys.add(dateKey);
        lastExpenseId = expenseId;
        lastLoggedDueDate = cycleDueDate;
        newlyLogged++;
      }

      cycleDueDate = cycle.advanceDate(cycleDueDate);
      periodStart = periodStart != null ? cycle.advanceDate(periodStart) : null;
      periodEnd = periodEnd != null ? cycle.advanceDate(periodEnd) : null;
      cyclesProcessed++;
    }

    if (cyclesProcessed == 0) return 0;

    await (_db.update(_db.bills)..where((b) => b.recordId.equals(rec.id))).write(
      BillsCompanion(
        dueDate: Value(cycleDueDate),
        billingPeriodStart: Value(periodStart),
        billingPeriodEnd: Value(periodEnd),
        paymentStatus: const Value('unpaid'),
        paidAt: lastLoggedDueDate != null ? Value(lastLoggedDueDate) : const Value.absent(),
        linkedExpenseRecordId:
            lastExpenseId != null ? Value(lastExpenseId) : const Value.absent(),
      ),
    );
    await (_db.update(_db.records)..where((r) => r.id.equals(rec.id))).write(
      RecordsCompanion(updatedAt: Value(updatedAtUtc)),
    );

    return newlyLogged;
  }

  @override
  Future<RecordWithBill> pauseSubscription(String billRecordId) async {
    return _db.transaction(() async {
      final existing = await getBillById(billRecordId);
      if (existing == null) {
        throw ArgumentError('Bill with record ID $billRecordId not found');
      }
      final now = DateTime.now().toUtc();
      await (_db.update(_db.bills)..where((b) => b.recordId.equals(billRecordId))).write(
        const BillsCompanion(paymentStatus: Value('paused')),
      );
      await (_db.update(_db.records)..where((r) => r.id.equals(billRecordId))).write(
        RecordsCompanion(updatedAt: Value(now)),
      );
      return (await getBillById(billRecordId))!;
    });
  }

  @override
  Future<RecordWithBill> cancelSubscription(String billRecordId) async {
    return _db.transaction(() async {
      final existing = await getBillById(billRecordId);
      if (existing == null) {
        throw ArgumentError('Bill with record ID $billRecordId not found');
      }
      final now = DateTime.now().toUtc();
      await (_db.update(_db.bills)..where((b) => b.recordId.equals(billRecordId))).write(
        const BillsCompanion(
          paymentStatus: Value('cancelled'),
          autoLogPayment: Value(false),
        ),
      );
      await (_db.update(_db.records)..where((r) => r.id.equals(billRecordId))).write(
        RecordsCompanion(updatedAt: Value(now)),
      );
      return (await getBillById(billRecordId))!;
    });
  }

  @override
  Future<RecordWithBill> resumeSubscription({
    required String billRecordId,
    DateTime? nextDueDate,
    bool? autoLogPayment,
  }) async {
    return _db.transaction(() async {
      final existing = await getBillById(billRecordId);
      if (existing == null) {
        throw ArgumentError('Bill with record ID $billRecordId not found');
      }
      final nowLocal = DateTime.now();
      final nowUtc = nowLocal.toUtc();
      final today = _calendarDate(nowLocal);

      DateTime? resolvedDueDate = _normalizeCalendarDate(nextDueDate) ?? existing.bill.dueDate;
      if (nextDueDate == null &&
          resolvedDueDate != null &&
          _calendarDate(resolvedDueDate).isBefore(today)) {
        // Advance forward from today so paused/cancelled months are never back-charged.
        resolvedDueDate = existing.bill.isRecurring
            ? existing.bill.recurrenceCycleEnum.advanceDate(today)
            : today;
      }

      final dueDateChanged = resolvedDueDate != existing.bill.dueDate;
      final effectiveAutoLog = autoLogPayment == null
          ? (resolvedDueDate == null ? const Value(false) : const Value<bool>.absent())
          : Value(existing.bill.isRecurring && resolvedDueDate != null && autoLogPayment);

      await (_db.update(_db.bills)..where((b) => b.recordId.equals(billRecordId))).write(
        BillsCompanion(
          paymentStatus: const Value('unpaid'),
          dueDate: Value(resolvedDueDate),
          billingPeriodStart: dueDateChanged ? const Value(null) : const Value.absent(),
          billingPeriodEnd: dueDateChanged ? const Value(null) : const Value.absent(),
          autoLogPayment: effectiveAutoLog,
        ),
      );
      await (_db.update(_db.records)..where((r) => r.id.equals(billRecordId))).write(
        RecordsCompanion(updatedAt: Value(nowUtc)),
      );
      return (await getBillById(billRecordId))!;
    });
  }

  @override
  Stream<List<RecordWithExpense>> watchPaymentHistoryForBill(String billRecordId) {
    final query = _db.select(_db.records).join([
      innerJoin(_db.expenses, _db.expenses.recordId.equalsExp(_db.records.id)),
    ])
      ..where(_db.records.recordType.equals('expense'))
      ..where(_db.records.deletedAt.isNull())
      ..where(_db.expenses.linkedBillRecordId.equals(billRecordId))
      ..orderBy([
        OrderingTerm(expression: _db.expenses.transactionDate, mode: OrderingMode.desc),
        OrderingTerm(expression: _db.records.createdAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final rec = row.readTable(_db.records);
        final exp = row.readTable(_db.expenses);
        return RecordWithExpense(
          record: Record(
            id: rec.id,
            workspaceId: rec.workspaceId,
            categoryId: rec.categoryId,
            recordType: rec.recordType,
            title: rec.title,
            description: rec.description,
            status: rec.status,
            createdAt: rec.createdAt.toUtc(),
            updatedAt: rec.updatedAt.toUtc(),
            archivedAt: rec.archivedAt?.toUtc(),
            deletedAt: rec.deletedAt?.toUtc(),
          ),
          expense: ExpenseItem(
            recordId: exp.recordId,
            amountMinor: exp.amountMinor,
            currencyCode: exp.currencyCode,
            transactionDate: exp.transactionDate.toUtc(),
            paymentMethod: exp.paymentMethod,
            expenseCategory: exp.expenseCategory,
            linkedAssetRecordId: exp.linkedAssetRecordId,
            linkedTaskRecordId: exp.linkedTaskRecordId,
            linkedBillRecordId: exp.linkedBillRecordId,
            odometerReading: exp.odometerReading,
          ),
        );
      }).toList();
    });
  }

  @override
  Future<RecordWithBill?> getBillById(String recordId) async {
    final assetRecordTable = _db.alias(_db.records, 'asset_rec');
    final expenseRecordTable = _db.alias(_db.records, 'expense_rec');

    final query = _db.select(_db.records).join([
      innerJoin(_db.bills, _db.bills.recordId.equalsExp(_db.records.id)),
      leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.records.categoryId)),
      leftOuterJoin(
        assetRecordTable,
        assetRecordTable.id.equalsExp(_db.bills.linkedAssetRecordId) &
            assetRecordTable.deletedAt.isNull(),
      ),
      leftOuterJoin(
        expenseRecordTable,
        expenseRecordTable.id.equalsExp(_db.bills.linkedExpenseRecordId) &
            expenseRecordTable.deletedAt.isNull(),
      ),
    ])
      ..where(_db.records.id.equals(recordId))
      ..where(_db.records.deletedAt.isNull());

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return _mapRowToRecordWithBill(row, assetRecordTable, expenseRecordTable);
  }

  @override
  Stream<List<RecordWithBill>> watchBillsByWorkspace(
    String workspaceId, {
    String? paymentStatus,
    String? utilityType,
  }) {
    final assetRecordTable = _db.alias(_db.records, 'asset_rec');
    final expenseRecordTable = _db.alias(_db.records, 'expense_rec');

    final query = _db.select(_db.records).join([
      innerJoin(_db.bills, _db.bills.recordId.equalsExp(_db.records.id)),
      leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.records.categoryId)),
      leftOuterJoin(
        assetRecordTable,
        assetRecordTable.id.equalsExp(_db.bills.linkedAssetRecordId) &
            assetRecordTable.deletedAt.isNull(),
      ),
      leftOuterJoin(
        expenseRecordTable,
        expenseRecordTable.id.equalsExp(_db.bills.linkedExpenseRecordId) &
            expenseRecordTable.deletedAt.isNull(),
      ),
    ])
      ..where(_db.records.workspaceId.equals(workspaceId))
      ..where(_db.records.recordType.equals('bill'))
      ..where(_db.records.deletedAt.isNull());

    if (paymentStatus != null) {
      query.where(_db.bills.paymentStatus.equals(paymentStatus));
    }

    if (utilityType != null) {
      query.where(_db.bills.utilityType.equals(utilityType));
    }

    query.orderBy([
      OrderingTerm(expression: _db.bills.dueDate, mode: OrderingMode.asc),
      OrderingTerm(expression: _db.records.createdAt, mode: OrderingMode.desc),
    ]);

    return query.watch().map((rows) =>
        rows.map((row) => _mapRowToRecordWithBill(row, assetRecordTable, expenseRecordTable)).toList());
  }

  @override
  Stream<List<RecordWithBill>> watchUpcomingBillsByWorkspace(
    String workspaceId, {
    Duration window = const Duration(days: 30),
  }) {
    final assetRecordTable = _db.alias(_db.records, 'asset_rec');
    final expenseRecordTable = _db.alias(_db.records, 'expense_rec');
    final cutoff = _calendarDate(DateTime.now()).add(window);

    final query = _db.select(_db.records).join([
      innerJoin(_db.bills, _db.bills.recordId.equalsExp(_db.records.id)),
      leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.records.categoryId)),
      leftOuterJoin(
        assetRecordTable,
        assetRecordTable.id.equalsExp(_db.bills.linkedAssetRecordId) &
            assetRecordTable.deletedAt.isNull(),
      ),
      leftOuterJoin(
        expenseRecordTable,
        expenseRecordTable.id.equalsExp(_db.bills.linkedExpenseRecordId) &
            expenseRecordTable.deletedAt.isNull(),
      ),
    ])
      ..where(_db.records.workspaceId.equals(workspaceId))
      ..where(_db.records.recordType.equals('bill'))
      ..where(_db.records.deletedAt.isNull())
      ..where(_db.bills.paymentStatus.isIn(['unpaid', 'overdue']))
      ..where(_db.bills.dueDate.isNull() | _db.bills.dueDate.isSmallerOrEqualValue(cutoff));

    query.orderBy([
      OrderingTerm(expression: _db.bills.dueDate, mode: OrderingMode.asc),
    ]);

    return query.watch().map((rows) =>
        rows.map((row) => _mapRowToRecordWithBill(row, assetRecordTable, expenseRecordTable)).toList());
  }

  @override
  Stream<int> watchTotalUnpaidBillsAmount(String workspaceId) {
    final billsTable = _db.bills;
    final recordsTable = _db.records;

    final query = _db.selectOnly(billsTable).join([
      innerJoin(recordsTable, recordsTable.id.equalsExp(billsTable.recordId)),
    ]);

    final sumAmount = billsTable.amountDueMinor.sum();
    query.addColumns([sumAmount]);
    query.where(
      recordsTable.workspaceId.equals(workspaceId) &
          recordsTable.recordType.equals('bill') &
          recordsTable.deletedAt.isNull() &
          billsTable.paymentStatus.isIn(['unpaid', 'overdue']),
    );

    return query.watchSingleOrNull().map((row) {
      if (row == null) return 0;
      return row.read(sumAmount) ?? 0;
    });
  }

  @override
  Future<void> softDeleteBillRecord(String recordId) async {
    await (_db.update(_db.records)..where((r) => r.id.equals(recordId))).write(
      RecordsCompanion(
        deletedAt: Value(DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  RecordWithBill _mapRowToRecordWithBill(
    TypedResult row,
    $RecordsTable assetRecordTable,
    $RecordsTable expenseRecordTable,
  ) {
    final rec = row.readTable(_db.records);
    final billEntity = row.readTable(_db.bills);
    final categoryEntity = row.readTableOrNull(_db.categories);
    final assetRecordEntity = row.readTableOrNull(assetRecordTable);
    final expenseRecordEntity = row.readTableOrNull(expenseRecordTable);

    return RecordWithBill(
      record: Record(
        id: rec.id,
        workspaceId: rec.workspaceId,
        categoryId: rec.categoryId,
        recordType: rec.recordType,
        title: rec.title,
        description: rec.description,
        status: rec.status,
        createdAt: rec.createdAt,
        updatedAt: rec.updatedAt,
        archivedAt: rec.archivedAt,
        deletedAt: rec.deletedAt,
      ),
      bill: BillItem(
        recordId: billEntity.recordId,
        utilityType: billEntity.utilityType,
        providerName: billEntity.providerName,
        accountNumber: billEntity.accountNumber,
        billingPeriodStart: billEntity.billingPeriodStart?.toUtc(),
        billingPeriodEnd: billEntity.billingPeriodEnd?.toUtc(),
        dueDate: billEntity.dueDate?.toUtc(),
        amountDueMinor: billEntity.amountDueMinor,
        currencyCode: billEntity.currencyCode,
        paymentStatus: billEntity.paymentStatus,
        paidAt: billEntity.paidAt?.toUtc(),
        recurrenceCycle: billEntity.recurrenceCycle,
        autoLogPayment: billEntity.autoLogPayment,
        linkedAssetRecordId: billEntity.linkedAssetRecordId,
        linkedExpenseRecordId: billEntity.linkedExpenseRecordId,
      ),
      category: categoryEntity != null
          ? Category(
              id: categoryEntity.id,
              workspaceId: categoryEntity.workspaceId,
              name: categoryEntity.name,
              iconKey: categoryEntity.iconKey,
              colorHex: categoryEntity.colorHex,
              isSystem: categoryEntity.isSystem,
              parentCategoryId: categoryEntity.parentCategoryId,
              createdAt: categoryEntity.createdAt.toUtc(),
              archivedAt: categoryEntity.archivedAt?.toUtc(),
            )
          : null,
      linkedAssetRecord: assetRecordEntity != null
          ? Record(
              id: assetRecordEntity.id,
              workspaceId: assetRecordEntity.workspaceId,
              categoryId: assetRecordEntity.categoryId,
              recordType: assetRecordEntity.recordType,
              title: assetRecordEntity.title,
              description: assetRecordEntity.description,
              status: assetRecordEntity.status,
              createdAt: assetRecordEntity.createdAt,
              updatedAt: assetRecordEntity.updatedAt,
              archivedAt: assetRecordEntity.archivedAt,
              deletedAt: assetRecordEntity.deletedAt,
            )
          : null,
      linkedExpenseRecord: expenseRecordEntity != null
          ? Record(
              id: expenseRecordEntity.id,
              workspaceId: expenseRecordEntity.workspaceId,
              categoryId: expenseRecordEntity.categoryId,
              recordType: expenseRecordEntity.recordType,
              title: expenseRecordEntity.title,
              description: expenseRecordEntity.description,
              status: expenseRecordEntity.status,
              createdAt: expenseRecordEntity.createdAt,
              updatedAt: expenseRecordEntity.updatedAt,
              archivedAt: expenseRecordEntity.archivedAt,
              deletedAt: expenseRecordEntity.deletedAt,
            )
          : null,
    );
  }
}
