import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../categories/domain/category.dart';
import '../../records/domain/record.dart';
import '../domain/bill_item.dart';
import '../domain/bill_repository.dart';

/// Drift SQLite implementation of [BillRepository].
class BillRepositoryImpl implements BillRepository {
  final AppDatabase _db;
  final Uuid _uuid;

  const BillRepositoryImpl(this._db, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  @override
  Future<RecordWithBill> createBillRecord({
    required Record record,
    required BillItem bill,
  }) async {
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
              createdAt: Value(record.createdAt),
              updatedAt: Value(record.updatedAt),
            ),
          );

      await _db.into(_db.bills).insert(
            BillsCompanion(
              recordId: Value(record.id),
              utilityType: Value(bill.utilityType),
              providerName: Value(bill.providerName),
              accountNumber: Value(bill.accountNumber),
              billingPeriodStart: Value(bill.billingPeriodStart),
              billingPeriodEnd: Value(bill.billingPeriodEnd),
              dueDate: Value(bill.dueDate),
              amountDueMinor: Value(bill.amountDueMinor),
              currencyCode: Value(bill.currencyCode),
              paymentStatus: Value(bill.paymentStatus),
              paidAt: Value(bill.paidAt),
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
          billingPeriodStart: Value(bill.billingPeriodStart),
          billingPeriodEnd: Value(bill.billingPeriodEnd),
          dueDate: Value(bill.dueDate),
          amountDueMinor: Value(bill.amountDueMinor),
          currencyCode: Value(bill.currencyCode),
          paymentStatus: Value(bill.paymentStatus),
          paidAt: Value(bill.paidAt),
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

      // If already has a linked expense, just update status
      String? expenseRecordId = existing.bill.linkedExpenseRecordId;

      if (expenseRecordId == null) {
        // Automated Transactional Bridge: create the expense record to prevent double entry
        expenseRecordId = _uuid.v4();
        final expenseTitle = 'Paid: ${existing.record.title}';
        final providerInfo = existing.bill.providerName != null
            ? ' (${existing.bill.providerName})'
            : '';

        await _db.into(_db.records).insert(
              RecordsCompanion(
                id: Value(expenseRecordId),
                workspaceId: Value(existing.record.workspaceId),
                categoryId: Value(existing.record.categoryId),
                recordType: const Value('expense'),
                title: Value(expenseTitle),
                description: Value(
                  'Automated payment log for ${existing.record.title}$providerInfo',
                ),
                status: const Value('active'),
                createdAt: Value(paidAt),
                updatedAt: Value(paidAt),
              ),
            );

        await _db.into(_db.expenses).insert(
              ExpensesCompanion(
                recordId: Value(expenseRecordId),
                amountMinor: Value(existing.bill.amountDueMinor),
                currencyCode: Value(existing.bill.currencyCode),
                transactionDate: Value(paidAt),
                paymentMethod: Value(paymentMethod ?? 'bank_transfer'),
                expenseCategory: const Value('utility'),
                linkedAssetRecordId: Value(existing.bill.linkedAssetRecordId),
                linkedBillRecordId: Value(billRecordId),
              ),
            );
      }

      // Update Bill to paid
      await (_db.update(_db.bills)..where((b) => b.recordId.equals(billRecordId))).write(
        BillsCompanion(
          paymentStatus: const Value('paid'),
          paidAt: Value(paidAt),
          linkedExpenseRecordId: Value(expenseRecordId),
        ),
      );

      // Touch parent record updatedAt for sync auditing
      await (_db.update(_db.records)..where((r) => r.id.equals(billRecordId))).write(
        RecordsCompanion(
          updatedAt: Value(paidAt),
        ),
      );

      final updated = await getBillById(billRecordId);
      return updated!;
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
    final cutoff = DateTime.now().add(window);

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
        billingPeriodStart: billEntity.billingPeriodStart,
        billingPeriodEnd: billEntity.billingPeriodEnd,
        dueDate: billEntity.dueDate,
        amountDueMinor: billEntity.amountDueMinor,
        currencyCode: billEntity.currencyCode,
        paymentStatus: billEntity.paymentStatus,
        paidAt: billEntity.paidAt,
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
              createdAt: categoryEntity.createdAt,
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
