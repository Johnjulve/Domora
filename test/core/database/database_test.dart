import 'package:domora/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase Foundation Tests', () {
    test('Can create a workspace and retrieve it', () async {
      final now = DateTime.utc(2026, 11, 4, 12, 0, 0);
      const workspaceId = 'ws-test-1';

      await db.into(db.workspaces).insert(
            WorkspacesCompanion.insert(
              id: workspaceId,
              name: 'My Household',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final workspaces = await db.select(db.workspaces).get();
      expect(workspaces.length, 1);
      expect(workspaces.first.id, workspaceId);
      expect(workspaces.first.name, 'My Household');
      expect(workspaces.first.workspaceType, 'personal');
      expect(workspaces.first.deletedAt, isNull);
    });

    test('Can create universal Record and linked specialized Asset entity', () async {
      final now = DateTime.utc(2026, 11, 4, 12, 0, 0);
      const workspaceId = 'ws-test-2';
      const recordId = 'rec-asset-1';

      // 1. Create parent workspace
      await db.into(db.workspaces).insert(
            WorkspacesCompanion.insert(
              id: workspaceId,
              name: 'Personal',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 2. Create Universal Record
      await db.into(db.records).insert(
            RecordsCompanion.insert(
              id: recordId,
              workspaceId: workspaceId,
              recordType: 'asset',
              title: 'MacBook Pro M3',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 3. Create Asset specialized entity linked by recordId
      // 15000000 minor units = 150,000.00 PHP
      await db.into(db.assets).insert(
            AssetsCompanion.insert(
              recordId: recordId,
              brand: const Value('Apple'),
              model: const Value('MacBook Pro 16"'),
              serialNumber: const Value('C02XYZ123'),
              purchaseAmountMinor: const Value(15000000),
            ),
          );

      // Verify Record query
      final record = await (db.select(db.records)..where((r) => r.id.equals(recordId))).getSingle();
      expect(record.title, 'MacBook Pro M3');
      expect(record.recordType, 'asset');
      expect(record.deletedAt, isNull);

      // Verify Asset query
      final asset = await (db.select(db.assets)..where((a) => a.recordId.equals(recordId))).getSingle();
      expect(asset.brand, 'Apple');
      expect(asset.purchaseAmountMinor, 15000000);
      expect(asset.purchaseCurrency, 'PHP');
    });

    test('Foreign key constraint violation throws SqliteException on orphan record', () async {
      final now = DateTime.utc(2026, 11, 4, 12, 0, 0);

      expect(
        () async => await db.into(db.records).insert(
              RecordsCompanion.insert(
                id: 'orphan-rec',
                workspaceId: 'non-existent-workspace-id',
                recordType: 'asset',
                title: 'Orphan Record',
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('Cascading delete: Deleting a workspace deletes its records and assets', () async {
      final now = DateTime.utc(2026, 11, 4, 12, 0, 0);
      const workspaceId = 'ws-to-delete';
      const recordId = 'rec-cascade';

      await db.into(db.workspaces).insert(
            WorkspacesCompanion.insert(
              id: workspaceId,
              name: 'Temporary Workspace',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.records).insert(
            RecordsCompanion.insert(
              id: recordId,
              workspaceId: workspaceId,
              recordType: 'asset',
              title: 'Temporary Asset',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.assets).insert(
            AssetsCompanion.insert(
              recordId: recordId,
              brand: const Value('TestBrand'),
            ),
          );

      // Ensure records exist
      expect((await db.select(db.records).get()).length, 1);
      expect((await db.select(db.assets).get()).length, 1);

      // Delete workspace
      await (db.delete(db.workspaces)..where((w) => w.id.equals(workspaceId))).go();

      // Ensure foreign key cascade cleaned up records and assets
      expect((await db.select(db.records).get()).isEmpty, isTrue);
      expect((await db.select(db.assets).get()).isEmpty, isTrue);
    });

    test('Soft deletion filtering behaves correctly', () async {
      final now = DateTime.utc(2026, 11, 4, 12, 0, 0);
      const workspaceId = 'ws-soft-del';

      await db.into(db.workspaces).insert(
            WorkspacesCompanion.insert(
              id: workspaceId,
              name: 'Soft Delete Test Workspace',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Insert active record
      await db.into(db.records).insert(
            RecordsCompanion.insert(
              id: 'active-rec',
              workspaceId: workspaceId,
              recordType: 'asset',
              title: 'Active Asset',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Insert soft-deleted record
      await db.into(db.records).insert(
            RecordsCompanion.insert(
              id: 'deleted-rec',
              workspaceId: workspaceId,
              recordType: 'asset',
              title: 'Deleted Asset',
              createdAt: now,
              updatedAt: now,
              deletedAt: Value(now),
            ),
          );

      // Query active records only
      final activeRecords = await (db.select(db.records)
            ..where((r) => r.workspaceId.equals(workspaceId) & r.deletedAt.isNull()))
          .get();

      expect(activeRecords.length, 1);
      expect(activeRecords.first.id, 'active-rec');

      // Query all including soft-deleted
      final allRecords = await (db.select(db.records)..where((r) => r.workspaceId.equals(workspaceId))).get();
      expect(allRecords.length, 2);
    });
 
    test('Can create universal Record and linked specialized Bill entity', () async {
      final now = DateTime.utc(2026, 11, 7, 12, 0, 0);
      const workspaceId = 'ws-test-bills';
      const recordId = 'rec-bill-1';

      await db.into(db.workspaces).insert(
            WorkspacesCompanion.insert(
              id: workspaceId,
              name: 'Personal',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.records).insert(
            RecordsCompanion.insert(
              id: recordId,
              workspaceId: workspaceId,
              recordType: 'bill',
              title: 'Meralco Electric Bill',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.bills).insert(
            BillsCompanion.insert(
              recordId: recordId,
              amountDueMinor: 250000,
              providerName: const Value('Meralco'),
              utilityType: const Value('electricity'),
              dueDate: Value(now.add(const Duration(days: 7))),
            ),
          );

      final bills = await db.select(db.bills).get();
      expect(bills.length, 1);
      expect(bills.first.recordId, recordId);
      expect(bills.first.amountDueMinor, 250000);
      expect(bills.first.providerName, 'Meralco');
      expect(bills.first.utilityType, 'electricity');
      expect(bills.first.paymentStatus, 'unpaid');
    });
  });
}