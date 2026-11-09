import 'package:domora/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

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

    test('Can create universal Record, Asset with warrantyExpiryDate, and Custom Field Definitions/Values', () async {
      final now = DateTime.utc(2026, 11, 9, 12, 0, 0);
      const workspaceId = 'ws-test-fields';
      const recordId = 'rec-asset-fields-1';
      const fieldDefId = 'fdef-color-1';
      const fieldValueId = 'fval-color-1';

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
              recordType: 'asset',
              title: 'Herman Miller Embody Chair',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final warranty = DateTime.utc(2038, 11, 9, 12, 0, 0);
      await db.into(db.assets).insert(
            AssetsCompanion.insert(
              recordId: recordId,
              brand: const Value('Herman Miller'),
              model: const Value('Embody'),
              condition: const Value('Mint'),
              warrantyExpiryDate: Value(warranty),
            ),
          );

      await db.into(db.fieldDefinitions).insert(
            FieldDefinitionsCompanion.insert(
              id: fieldDefId,
              workspaceId: workspaceId,
              fieldKey: 'Fabric Color',
              label: 'Fabric Color',
              createdAt: now,
            ),
          );

      await db.into(db.fieldValues).insert(
            FieldValuesCompanion.insert(
              id: fieldValueId,
              recordId: recordId,
              fieldDefinitionId: fieldDefId,
              valueText: 'Sync Dark Carbon',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final asset = await (db.select(db.assets)..where((a) => a.recordId.equals(recordId))).getSingle();
      expect(asset.brand, 'Herman Miller');
      expect(asset.warrantyExpiryDate?.toUtc(), warranty);

      final fieldVal = await (db.select(db.fieldValues)..where((v) => v.id.equals(fieldValueId))).getSingle();
      expect(fieldVal.valueText, 'Sync Dark Carbon');
      expect(fieldVal.fieldDefinitionId, fieldDefId);

      // Verify cascading delete: deleting record deletes its asset and field values
      await (db.delete(db.records)..where((r) => r.id.equals(recordId))).go();
      expect(await (db.select(db.assets)..where((a) => a.recordId.equals(recordId))).get(), isEmpty);
      expect(await (db.select(db.fieldValues)..where((v) => v.id.equals(fieldValueId))).get(), isEmpty);
    });

    test('Drift migration onUpgrade from v7 to v8 executes without error, preserves data and adds new schema elements', () async {
      // 1. Initialize an in-memory SQLite database at schema v7
      final rawDb = sqlite3.openInMemory();
      rawDb.execute('''
        CREATE TABLE workspaces (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          workspace_type TEXT NOT NULL DEFAULT 'personal',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER
        );
        CREATE TABLE categories (
          id TEXT NOT NULL PRIMARY KEY,
          workspace_id TEXT NOT NULL,
          name TEXT NOT NULL,
          icon_key TEXT,
          color_hex TEXT,
          is_system INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL
        );
        CREATE TABLE records (
          id TEXT NOT NULL PRIMARY KEY,
          workspace_id TEXT NOT NULL,
          category_id TEXT,
          record_type TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          status TEXT NOT NULL DEFAULT 'active',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          archived_at INTEGER,
          deleted_at INTEGER
        );
        CREATE TABLE assets (
          record_id TEXT NOT NULL PRIMARY KEY,
          purchase_date INTEGER,
          purchase_amount_minor INTEGER,
          purchase_currency TEXT DEFAULT 'PHP',
          brand TEXT,
          model TEXT,
          serial_number TEXT,
          condition TEXT,
          location_description TEXT,
          acquired_from TEXT,
          disposed_at INTEGER,
          odometer_reading INTEGER,
          pms_distance_interval_km INTEGER,
          pms_time_interval_months INTEGER,
          next_pms_due_date INTEGER,
          next_pms_odometer_target INTEGER
        );
        CREATE TABLE tasks (
          record_id TEXT NOT NULL PRIMARY KEY,
          due_date INTEGER,
          priority TEXT NOT NULL DEFAULT 'medium',
          status TEXT NOT NULL DEFAULT 'pending',
          completed_at INTEGER,
          recurrence_rule TEXT
        );
        CREATE TABLE documents (
          record_id TEXT NOT NULL PRIMARY KEY,
          file_name TEXT NOT NULL,
          file_path TEXT NOT NULL,
          file_size_bytes INTEGER NOT NULL,
          mime_type TEXT NOT NULL,
          notes TEXT,
          captured_at INTEGER
        );
        CREATE TABLE expenses (
          record_id TEXT NOT NULL PRIMARY KEY,
          amount_minor INTEGER NOT NULL,
          currency TEXT NOT NULL DEFAULT 'PHP',
          expense_category TEXT NOT NULL DEFAULT 'other',
          expense_date INTEGER NOT NULL,
          vendor TEXT,
          receipt_document_id TEXT,
          is_tax_deductible INTEGER NOT NULL DEFAULT 0,
          odometer_reading INTEGER,
          linked_bill_record_id TEXT
        );
        CREATE TABLE bills (
          record_id TEXT NOT NULL PRIMARY KEY,
          provider_name TEXT,
          account_number TEXT,
          amount_due_minor INTEGER NOT NULL,
          due_date INTEGER,
          billing_period_start INTEGER,
          billing_period_end INTEGER,
          payment_status TEXT NOT NULL DEFAULT 'unpaid',
          paid_date INTEGER,
          paid_amount_minor INTEGER,
          is_recurring INTEGER NOT NULL DEFAULT 0,
          recurrence_interval TEXT,
          auto_pay_enabled INTEGER NOT NULL DEFAULT 0,
          utility_type TEXT
        );
        PRAGMA user_version = 7;
      ''');

      // Seed pre-existing v7 data
      final epochMillis = DateTime.utc(2026, 11, 4).millisecondsSinceEpoch;
      rawDb.execute('''
        INSERT INTO workspaces (id, name, created_at, updated_at)
        VALUES ('ws-v7', 'Legacy Workspace', $epochMillis, $epochMillis);

        INSERT INTO categories (id, workspace_id, name, icon_key, color_hex, is_system, created_at)
        VALUES ('cat-v7', 'ws-v7', 'Legacy Category', 'folder', '#123456', 1, $epochMillis);

        INSERT INTO records (id, workspace_id, category_id, record_type, title, created_at, updated_at)
        VALUES ('rec-v7', 'ws-v7', 'cat-v7', 'asset', 'Legacy Vehicle', $epochMillis, $epochMillis);

        INSERT INTO assets (record_id, brand, model, odometer_reading)
        VALUES ('rec-v7', 'Toyota', 'Vios', 15000);
      ''');

      // 2. Open via AppDatabase, which will execute onUpgrade from 7 to 8
      final migratedDb = AppDatabase.forTesting(NativeDatabase.opened(rawDb));

      // Verify categories preserved and gained archivedAt (null)
      final category = await (migratedDb.select(migratedDb.categories)..where((c) => c.id.equals('cat-v7'))).getSingle();
      expect(category.name, 'Legacy Category');
      expect(category.archivedAt, isNull);

      // Verify assets preserved and gained warrantyExpiryDate (null)
      final asset = await (migratedDb.select(migratedDb.assets)..where((a) => a.recordId.equals('rec-v7'))).getSingle();
      expect(asset.brand, 'Toyota');
      expect(asset.model, 'Vios');
      expect(asset.odometerReading, 15000);
      expect(asset.warrantyExpiryDate, isNull);

      // Verify new tables FieldDefinitions and FieldValues can be queried and inserted
      await migratedDb.into(migratedDb.fieldDefinitions).insert(
            FieldDefinitionsCompanion.insert(
              id: 'fdef-v8',
              workspaceId: 'ws-v7',
              fieldKey: 'Engine No',
              label: 'Engine Number',
              createdAt: DateTime.utc(2026, 11, 9),
            ),
          );

      final defs = await migratedDb.select(migratedDb.fieldDefinitions).get();
      expect(defs.length, 1);
      expect(defs.first.fieldKey, 'Engine No');

      await migratedDb.close();
    });
  });
}
