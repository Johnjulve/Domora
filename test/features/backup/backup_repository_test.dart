import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/features/backup/data/backup_repository_impl.dart';
import 'package:domora/features/backup/domain/backup_manifest.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/expenses/data/expense_repository_impl.dart';
import 'package:domora/features/expenses/domain/expense_item.dart';
import 'package:domora/features/bills/data/bill_repository_impl.dart';
import 'package:domora/features/bills/domain/bill_item.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/tasks/data/task_repository_impl.dart';
import 'package:domora/features/tasks/domain/task_item.dart';
import 'package:domora/features/vault/data/document_repository_impl.dart';
import 'package:domora/features/vault/domain/document_item.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';

void main() {
  late AppDatabase db;
  late WorkspaceRepositoryImpl workspaceRepo;
  late CategoryRepositoryImpl categoryRepo;
  late RecordRepositoryImpl recordRepo;
  late TaskRepositoryImpl taskRepo;
  late DocumentRepositoryImpl documentRepo;
  late ExpenseRepositoryImpl expenseRepo;
  late BillRepositoryImpl billRepo;
  late BackupRepositoryImpl backupRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    workspaceRepo = WorkspaceRepositoryImpl(db);
    categoryRepo = CategoryRepositoryImpl(db);
    recordRepo = RecordRepositoryImpl(db);
    taskRepo = TaskRepositoryImpl(db);
    documentRepo = DocumentRepositoryImpl(db);
    expenseRepo = ExpenseRepositoryImpl(db);
    billRepo = BillRepositoryImpl(db);
    backupRepo = BackupRepositoryImpl(db);

    final ws = await workspaceRepo.getOrCreateDefaultWorkspace();
    await categoryRepo.seedDefaultCategories(ws.id);
  });

  tearDown(() async {
    await db.close();
  });

  group('BackupRepositoryImpl Export & Validation Tests', () {
    test('createBackup captures all tables and computes valid SHA-256 checksum', () async {
      final now = DateTime.now().toUtc();

      // Seed 1 Asset
      await recordRepo.createAssetRecord(
        record: Record(
          id: 'asset-generator',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Honda Generator EU2200i',
          description: 'Portable inverter generator',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(
          recordId: 'asset-generator',
          brand: 'Honda',
          model: 'EU2200i',
          serialNumber: 'HN12345',
          condition: 'Excellent',
          purchaseAmountMinor: 6500000,
          purchaseCurrency: 'PHP',
          locationDescription: 'Garage Shelf B',
        ),
      );

      // Seed 1 Task linked to asset
      await taskRepo.createTaskRecord(
        record: Record(
          id: 'task-oil-change',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'task',
          title: 'Generator 50hr Oil Service',
          createdAt: now,
          updatedAt: now,
        ),
        task: TaskItem(
          recordId: 'task-oil-change',
          priority: 'high',
          status: 'pending',
          dueDate: now.add(const Duration(days: 7)),
          recurrenceRule: 'monthly',
          assetRecordId: 'asset-generator',
        ),
      );

      // Seed 1 Document linked to asset
      await documentRepo.createDocumentRecord(
        record: Record(
          id: 'doc-manual',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'document',
          title: 'Generator User Manual PDF',
          createdAt: now,
          updatedAt: now,
        ),
        document: const DocumentItem(
          recordId: 'doc-manual',
          fileName: 'eu2200i_manual.pdf',
          filePath: '/vault/docs/eu2200i_manual.pdf',
          documentType: 'manual',
          fileSizeBytes: 2048500,
          mimeType: 'application/pdf',
          linkedAssetRecordId: 'asset-generator',
        ),
      );

      // Seed 1 Expense linked to asset and task
      await expenseRepo.createExpenseRecord(
        record: Record(
          id: 'expense-oil',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'expense',
          title: 'Synthetic 10W-30 Oil',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: 'expense-oil',
          amountMinor: 85000,
          currencyCode: 'PHP',
          transactionDate: now,
          paymentMethod: 'cash',
          expenseCategory: 'maintenance',
          linkedAssetRecordId: 'asset-generator',
          linkedTaskRecordId: 'task-oil-change',
        ),
      );

      // Seed 1 Bill linked to asset
      await billRepo.createBillRecord(
        record: Record(
          id: 'bill-generator-fuel',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Generator Fuel Reserve',
          createdAt: now,
          updatedAt: now,
        ),
        bill: BillItem(
          recordId: 'bill-generator-fuel',
          utilityType: 'utility',
          amountDueMinor: 150000,
          currencyCode: 'PHP',
          paymentStatus: 'unpaid',
          linkedAssetRecordId: 'asset-generator',
        ),
      );

      // Execute createBackup
      final payload = await backupRepo.createBackup(AppConstants.defaultWorkspaceId);

      // Verify Manifest
      expect(payload.manifest.version, equals(BackupManifest.currentFormatVersion));
      expect(payload.manifest.workspaceId, equals(AppConstants.defaultWorkspaceId));
      expect(payload.manifest.counts.workspaces, equals(1));
      expect(payload.manifest.counts.categories, equals(7)); // 7 default categories seeded
      expect(payload.manifest.counts.records, equals(5)); // asset, task, doc, expense, bill
      expect(payload.manifest.counts.assets, equals(1));
      expect(payload.manifest.counts.tasks, equals(1));
      expect(payload.manifest.counts.documents, equals(1));
      expect(payload.manifest.counts.expenses, equals(1));
      expect(payload.manifest.counts.bills, equals(1));
      expect(payload.manifest.counts.totalItems, equals(18));

      // Verify SHA-256 Checksum integrity
      final rawDataMap = (payload.toJson()['data'] as Map<String, dynamic>);
      final recomputed = BackupPayload.computeChecksum(rawDataMap);
      expect(payload.manifest.payloadChecksum, equals(recomputed));
    });

    test('exportBackupToJson returns formatted JSON string with manifest and data', () async {
      final jsonString = await backupRepo.exportBackupToJson(AppConstants.defaultWorkspaceId);
      expect(jsonString, isNotEmpty);

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(decoded.containsKey('manifest'), isTrue);
      expect(decoded.containsKey('data'), isTrue);

      final manifest = decoded['manifest'] as Map<String, dynamic>;
      expect(manifest['workspaceId'], equals(AppConstants.defaultWorkspaceId));
      expect(manifest['payloadChecksum'], isNotEmpty);
    });

    test('validateBackup verifies untampered backup successfully', () async {
      final jsonString = await backupRepo.exportBackupToJson(AppConstants.defaultWorkspaceId);
      final validation = await backupRepo.validateBackup(jsonString);

      expect(validation.isValid, isTrue);
      expect(validation.status, equals(BackupValidationStatus.valid));
      expect(validation.manifest, isNotNull);
      expect(validation.payload, isNotNull);
      expect(validation.errorMessage, isNull);
    });

    test('validateBackup rejects tampered data with corrupted status', () async {
      final jsonString = await backupRepo.exportBackupToJson(AppConstants.defaultWorkspaceId);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      // Tamper with data: inject modified category name without updating manifest checksum
      final data = decoded['data'] as Map<String, dynamic>;
      final categories = data['categories'] as List<dynamic>;
      categories[0]['name'] = 'HACKED CATEGORY';

      final tamperedJson = jsonEncode(decoded);
      final validation = await backupRepo.validateBackup(tamperedJson);

      expect(validation.isValid, isFalse);
      expect(validation.status, equals(BackupValidationStatus.corrupted));
      expect(validation.errorMessage, contains('Cryptographic checksum mismatch'));
    });

    test('validateBackup rejects unsupported future version', () async {
      final jsonString = await backupRepo.exportBackupToJson(AppConstants.defaultWorkspaceId);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      // Tamper manifest version
      final manifest = decoded['manifest'] as Map<String, dynamic>;
      manifest['version'] = 999;

      final modifiedJson = jsonEncode(decoded);
      final validation = await backupRepo.validateBackup(modifiedJson);

      expect(validation.isValid, isFalse);
      expect(validation.status, equals(BackupValidationStatus.unsupportedVersion));
      expect(validation.errorMessage, contains('Archive format version 999 is not supported'));
    });

    test('validateBackup rejects malformed JSON string', () async {
      final validation = await backupRepo.validateBackup('NOT_A_VALID_JSON{[');

      expect(validation.isValid, isFalse);
      expect(validation.status, equals(BackupValidationStatus.corrupted));
      expect(validation.errorMessage, contains('Failed to parse backup archive'));
    });

    test('validateBackup rejects missing manifest or data section', () async {
      final missingSectionsJson = jsonEncode({'version': 1, 'items': []});
      final validation = await backupRepo.validateBackup(missingSectionsJson);

      expect(validation.isValid, isFalse);
      expect(validation.status, equals(BackupValidationStatus.missingData));
      expect(validation.errorMessage, contains('missing required "manifest" or "data" sections'));
    });
  });

  group('BackupRepositoryImpl Atomic Restore Tests', () {
    test('restoreBackup restores complete dataset into a fresh database', () async {
      final now = DateTime.now().toUtc();

      // Seed source DB with rich dataset
      await recordRepo.createAssetRecord(
        record: Record(
          id: 'asset-fridge',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Samsung French Door Refrigerator',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(
          recordId: 'asset-fridge',
          brand: 'Samsung',
          model: 'RF28R7351SR',
          condition: 'New',
          purchaseAmountMinor: 12500000,
          purchaseCurrency: 'PHP',
          locationDescription: 'Main Kitchen',
        ),
      );

      await taskRepo.createTaskRecord(
        record: Record(
          id: 'task-filter',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'task',
          title: 'Replace Refrigerator Water Filter',
          createdAt: now,
          updatedAt: now,
        ),
        task: TaskItem(
          recordId: 'task-filter',
          priority: 'medium',
          status: 'pending',
          dueDate: now.add(const Duration(days: 180)),
          recurrenceRule: 'yearly',
          assetRecordId: 'asset-fridge',
        ),
      );

      await expenseRepo.createExpenseRecord(
        record: Record(
          id: 'expense-filter-cartridge',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'expense',
          title: 'Samsung HAF-QIN Water Filter',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: 'expense-filter-cartridge',
          amountMinor: 250000,
          currencyCode: 'PHP',
          transactionDate: now,
          paymentMethod: 'card',
          expenseCategory: 'maintenance',
          linkedAssetRecordId: 'asset-fridge',
          linkedTaskRecordId: 'task-filter',
        ),
      );

      await billRepo.createBillRecord(
        record: Record(
          id: 'bill-appliance-insurance',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Appliance Extended Warranty Bill',
          createdAt: now,
          updatedAt: now,
        ),
        bill: const BillItem(
          recordId: 'bill-appliance-insurance',
          utilityType: 'insurance',
          amountDueMinor: 120000,
          linkedAssetRecordId: 'asset-fridge',
        ),
      );

      // Create backup from source DB
      final backupJson = await backupRepo.exportBackupToJson(AppConstants.defaultWorkspaceId);

      // Set up Target Clean Database
      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      final backupRepo2 = BackupRepositoryImpl(db2);
      final recordRepo2 = RecordRepositoryImpl(db2);
      final taskRepo2 = TaskRepositoryImpl(db2);
      final expenseRepo2 = ExpenseRepositoryImpl(db2);
      final billRepo2 = BillRepositoryImpl(db2);

      // Validate & Restore in Target DB
      final val = await backupRepo2.validateBackup(backupJson);
      expect(val.isValid, isTrue);

      await backupRepo2.restoreBackup(val.payload!, clearExisting: true);

      // Verify all tables populated in Target DB
      final restoredRecords = await recordRepo2.watchActiveRecordsByWorkspace(
        AppConstants.defaultWorkspaceId,
      ).first;
      expect(restoredRecords.length, equals(4)); // asset, task, expense, bill

      final restoredBills = await billRepo2.watchBillsByWorkspace(
        AppConstants.defaultWorkspaceId,
      ).first;
      expect(restoredBills.length, equals(1));
      expect(restoredBills.first.record.title, equals('Appliance Extended Warranty Bill'));
      expect(restoredBills.first.bill.amountDueMinor, equals(120000));
      expect(restoredBills.first.bill.linkedAssetRecordId, equals('asset-fridge'));

      final restoredTasks = await taskRepo2.watchTasksByWorkspace(
        AppConstants.defaultWorkspaceId,
      ).first;
      expect(restoredTasks.length, equals(1));
      expect(restoredTasks.first.record.title, equals('Replace Refrigerator Water Filter'));
      expect(restoredTasks.first.task.assetRecordId, equals('asset-fridge'));

      final restoredExpenses = await expenseRepo2.watchExpensesByWorkspace(
        AppConstants.defaultWorkspaceId,
      ).first;
      expect(restoredExpenses.length, equals(1));
      expect(restoredExpenses.first.expense.amountMinor, equals(250000));
      expect(restoredExpenses.first.expense.linkedAssetRecordId, equals('asset-fridge'));

      await db2.close();
    });

    test('restoreBackup transaction rolls back atomically on failure, preserving state', () async {
      final now = DateTime.now().toUtc();

      // Seed an initial record in db
      await recordRepo.createAssetRecord(
        record: Record(
          id: 'initial-record',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Initial Sacred Record',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'initial-record', brand: 'Domora Native'),
      );

      // Craft an invalid payload where a task references a non-existent foreign key or invalid type to trigger crash
      final payload = BackupPayload(
        manifest: BackupManifest(
          version: 1,
          appVersion: '0.1.0',
          exportedAt: now,
          workspaceId: AppConstants.defaultWorkspaceId,
          workspaceName: 'Default',
          counts: const BackupCounts(
            workspaces: 1,
            categories: 0,
            records: 1,
            assets: 0,
            tasks: 1,
            documents: 0,
            expenses: 0,
          ),
          payloadChecksum: 'test',
        ),
        workspaces: [
          {
            'id': AppConstants.defaultWorkspaceId,
            'name': 'Default',
            'workspaceType': 'personal',
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          }
        ],
        categories: [],
        records: [
          {
            'id': 'corrupt-record',
            'workspaceId': AppConstants.defaultWorkspaceId,
            'recordType': 'task',
            'title': 'Corrupted Task Record',
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          }
        ],
        assets: [],
        tasks: [
          // Malformed date that fails DateTime.parse inside restore loop
          {
            'recordId': 'corrupt-record',
            'priority': 'high',
            'status': 'pending',
            'dueDate': 'INVALID_NOT_A_DATE',
          }
        ],
        documents: [],
        expenses: [],
      );

      // Attempt restore: should throw FormatException from DateTime.parse
      expect(
        () async => await backupRepo.restoreBackup(payload, clearExisting: false),
        throwsA(isA<FormatException>()),
      );

      // Verify atomic rollback: 'initial-record' still exists safely in db!
      final recordsAfter = await recordRepo.watchActiveRecordsByWorkspace(
        AppConstants.defaultWorkspaceId,
      ).first;
      expect(recordsAfter.any((r) => r.record.id == 'initial-record'), isTrue);
    });

    test('restoreBackup round-trips warrantyExpiryDate, archivedAt, custom field definitions and values', () async {
      final now = DateTime.utc(2026, 11, 8, 10, 0, 0);
      final warrantyDate = DateTime.utc(2028, 11, 8, 10, 0, 0);

      // Create asset with warrantyExpiryDate and custom fields
      await recordRepo.createAssetRecord(
        record: Record(
          id: 'asset-macbook',
          workspaceId: AppConstants.defaultWorkspaceId,
          categoryId: 'cat-electronics',
          recordType: 'asset',
          title: 'MacBook Pro 16 M3 Max',
          description: 'Personal work machine with AppleCare+',
          createdAt: now,
          updatedAt: now,
        ),
        asset: Asset(
          recordId: 'asset-macbook',
          brand: 'Apple',
          model: 'MacBook Pro 16"',
          warrantyExpiryDate: warrantyDate,
          purchaseAmountMinor: 25000000,
          purchaseCurrency: 'PHP',
        ),
        customFields: {
          'Color': 'Space Black',
          'Memory': '64GB Unified',
        },
      );

      // Archive a category
      await categoryRepo.archiveCategory('cat-family');

      // Export
      final exportedJson = await backupRepo.exportBackupToJson(AppConstants.defaultWorkspaceId);

      // Verify validation passes
      final validation = await backupRepo.validateBackup(exportedJson);
      expect(validation.isValid, isTrue);
      expect(validation.payload!.fieldDefinitions.length, greaterThanOrEqualTo(2));
      expect(validation.payload!.fieldValues.length, greaterThanOrEqualTo(2));

      // Restore to target fresh database
      final dbTarget = AppDatabase.forTesting(NativeDatabase.memory());
      final targetBackupRepo = BackupRepositoryImpl(dbTarget);
      final targetRecordRepo = RecordRepositoryImpl(dbTarget);
      final targetCategoryRepo = CategoryRepositoryImpl(dbTarget);

      await targetBackupRepo.restoreBackup(validation.payload!, clearExisting: true);

      // Verify asset and warrantyExpiryDate
      final restored = await targetRecordRepo.getRecordWithAsset('asset-macbook');
      expect(restored, isNotNull);
      expect(restored!.asset?.warrantyExpiryDate, equals(warrantyDate));
      expect(restored.record.description, equals('Personal work machine with AppleCare+'));

      // Verify custom fields
      final fields = await targetRecordRepo.getCustomFieldsForRecord('asset-macbook');
      expect(fields.length, equals(2));
      final colorField = fields.firstWhere((f) => f.definition.fieldKey == 'Color');
      expect(colorField.value.valueText, equals('Space Black'));
      final memField = fields.firstWhere((f) => f.definition.fieldKey == 'Memory');
      expect(memField.value.valueText, equals('64GB Unified'));

      // Verify category archived state
      final activeCategories = await targetCategoryRepo.getCategoriesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(activeCategories.any((c) => c.id == 'cat-family'), isFalse);

      await dbTarget.close();
    });
  });
}
