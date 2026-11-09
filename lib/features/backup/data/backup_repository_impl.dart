import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../domain/backup_manifest.dart';
import '../domain/backup_repository.dart';

/// Drift-backed implementation of [BackupRepository] for exporting, validating, and restoring archives.
class BackupRepositoryImpl implements BackupRepository {
  final AppDatabase _db;

  const BackupRepositoryImpl(this._db);

  @override
  Future<BackupPayload> createBackup(String workspaceId) async {
    // 1. Fetch workspace
    final workspaceRows = await (_db.select(_db.workspaces)
          ..where((w) => w.id.equals(workspaceId)))
        .get();

    final workspace = workspaceRows.isNotEmpty ? workspaceRows.first : null;
    final workspaceName = workspace?.name ?? AppConstants.defaultWorkspaceName;

    // 2. Fetch categories
    final categoryRows = await (_db.select(_db.categories)
          ..where((c) => c.workspaceId.equals(workspaceId)))
        .get();

    // 3. Fetch records
    final recordRows = await (_db.select(_db.records)
          ..where((r) => r.workspaceId.equals(workspaceId)))
        .get();

    final recordIds = recordRows.map((r) => r.id).toSet();

    // 4. Fetch specialized entities linked to these records
    final assetRows = recordIds.isEmpty
        ? <AssetEntity>[]
        : await (_db.select(_db.assets)
              ..where((a) => a.recordId.isIn(recordIds)))
            .get();

    final taskRows = recordIds.isEmpty
        ? <TaskEntity>[]
        : await (_db.select(_db.tasks)
              ..where((t) => t.recordId.isIn(recordIds)))
            .get();

    final documentRows = recordIds.isEmpty
        ? <DocumentEntity>[]
        : await (_db.select(_db.documents)
              ..where((d) => d.recordId.isIn(recordIds)))
            .get();

    final expenseRows = recordIds.isEmpty
        ? <ExpenseEntity>[]
        : await (_db.select(_db.expenses)
              ..where((e) => e.recordId.isIn(recordIds)))
            .get();

    final billRows = recordIds.isEmpty
        ? <BillEntity>[]
        : await (_db.select(_db.bills)
              ..where((b) => b.recordId.isIn(recordIds)))
            .get();

    // 5. Fetch custom field definitions and values
    final fieldDefRows = await (_db.select(_db.fieldDefinitions)
          ..where((f) => f.workspaceId.equals(workspaceId)))
        .get();

    final fieldValueRows = recordIds.isEmpty
        ? <FieldValueEntity>[]
        : await (_db.select(_db.fieldValues)
              ..where((v) => v.recordId.isIn(recordIds)))
            .get();

    // 6. Serialize into normalized Map representations
    final workspacesJson = workspaceRows.map((w) => {
          'id': w.id,
          'name': w.name,
          'workspaceType': w.workspaceType,
          'createdAt': w.createdAt.toIso8601String(),
          'updatedAt': w.updatedAt.toIso8601String(),
          'archivedAt': w.archivedAt?.toIso8601String(),
          'deletedAt': w.deletedAt?.toIso8601String(),
        }).toList();

    final categoriesJson = categoryRows.map((c) => {
          'id': c.id,
          'workspaceId': c.workspaceId,
          'name': c.name,
          'iconKey': c.iconKey,
          'colorHex': c.colorHex,
          'isSystem': c.isSystem,
          'createdAt': c.createdAt.toIso8601String(),
          'archivedAt': c.archivedAt?.toIso8601String(),
        }).toList();

    final recordsJson = recordRows.map((r) => {
          'id': r.id,
          'workspaceId': r.workspaceId,
          'categoryId': r.categoryId,
          'recordType': r.recordType,
          'title': r.title,
          'description': r.description,
          'status': r.status,
          'createdAt': r.createdAt.toIso8601String(),
          'updatedAt': r.updatedAt.toIso8601String(),
          'archivedAt': r.archivedAt?.toIso8601String(),
          'deletedAt': r.deletedAt?.toIso8601String(),
        }).toList();

    final assetsJson = assetRows.map((a) => {
          'recordId': a.recordId,
          'brand': a.brand,
          'model': a.model,
          'serialNumber': a.serialNumber,
          'condition': a.condition,
          'purchaseDate': a.purchaseDate?.toIso8601String(),
          'purchaseAmountMinor': a.purchaseAmountMinor,
          'purchaseCurrency': a.purchaseCurrency,
          'locationDescription': a.locationDescription,
          'acquiredFrom': a.acquiredFrom,
          'disposedAt': a.disposedAt?.toIso8601String(),
          'odometerReading': a.odometerReading,
          'pmsDistanceIntervalKm': a.pmsDistanceIntervalKm,
          'pmsTimeIntervalMonths': a.pmsTimeIntervalMonths,
          'nextPmsDueDate': a.nextPmsDueDate?.toIso8601String(),
          'nextPmsOdometerTarget': a.nextPmsOdometerTarget,
          'warrantyExpiryDate': a.warrantyExpiryDate?.toIso8601String(),
        }).toList();

    final tasksJson = taskRows.map((t) => {
          'recordId': t.recordId,
          'priority': t.priority,
          'status': t.status,
          'dueDate': t.dueDate?.toIso8601String(),
          'completedAt': t.completedAt?.toIso8601String(),
          'recurrenceRule': t.recurrenceRule,
          'assetRecordId': t.assetRecordId,
        }).toList();

    final documentsJson = documentRows.map((d) => {
          'recordId': d.recordId,
          'fileName': d.fileName,
          'filePath': d.filePath,
          'documentType': d.documentType,
          'fileSizeBytes': d.fileSizeBytes,
          'mimeType': d.mimeType,
          'linkedAssetRecordId': d.linkedAssetRecordId,
        }).toList();

    final expensesJson = expenseRows.map((e) => {
          'recordId': e.recordId,
          'amountMinor': e.amountMinor,
          'currencyCode': e.currencyCode,
          'transactionDate': e.transactionDate.toIso8601String(),
          'paymentMethod': e.paymentMethod,
          'expenseCategory': e.expenseCategory,
          'linkedAssetRecordId': e.linkedAssetRecordId,
          'linkedTaskRecordId': e.linkedTaskRecordId,
          'linkedBillRecordId': e.linkedBillRecordId,
          'odometerReading': e.odometerReading,
        }).toList();

    final billsJson = billRows.map((b) => {
          'recordId': b.recordId,
          'utilityType': b.utilityType,
          'providerName': b.providerName,
          'accountNumber': b.accountNumber,
          'billingPeriodStart': b.billingPeriodStart?.toIso8601String(),
          'billingPeriodEnd': b.billingPeriodEnd?.toIso8601String(),
          'dueDate': b.dueDate?.toIso8601String(),
          'amountDueMinor': b.amountDueMinor,
          'currencyCode': b.currencyCode,
          'paymentStatus': b.paymentStatus,
          'paidAt': b.paidAt?.toIso8601String(),
          'linkedAssetRecordId': b.linkedAssetRecordId,
          'linkedExpenseRecordId': b.linkedExpenseRecordId,
        }).toList();

    final fieldDefinitionsJson = fieldDefRows.map((f) => {
          'id': f.id,
          'workspaceId': f.workspaceId,
          'categoryId': f.categoryId,
          'fieldKey': f.fieldKey,
          'label': f.label,
          'dataType': f.dataType,
          'displayOrder': f.displayOrder,
          'createdAt': f.createdAt.toIso8601String(),
        }).toList();

    final fieldValuesJson = fieldValueRows.map((v) => {
          'id': v.id,
          'recordId': v.recordId,
          'fieldDefinitionId': v.fieldDefinitionId,
          'valueText': v.valueText,
          'createdAt': v.createdAt.toIso8601String(),
          'updatedAt': v.updatedAt.toIso8601String(),
        }).toList();

    final dataMap = <String, dynamic>{
      'workspaces': workspacesJson,
      'categories': categoriesJson,
      'records': recordsJson,
      'assets': assetsJson,
      'tasks': tasksJson,
      'documents': documentsJson,
      'expenses': expensesJson,
      'bills': billsJson,
      'fieldDefinitions': fieldDefinitionsJson,
      'fieldValues': fieldValuesJson,
    };

    final checksum = BackupPayload.computeChecksum(dataMap);

    final counts = BackupCounts(
      workspaces: workspacesJson.length,
      categories: categoriesJson.length,
      records: recordsJson.length,
      assets: assetsJson.length,
      tasks: tasksJson.length,
      documents: documentsJson.length,
      expenses: expensesJson.length,
      bills: billsJson.length,
      fieldDefinitions: fieldDefinitionsJson.length,
      fieldValues: fieldValuesJson.length,
    );

    final manifest = BackupManifest(
      version: BackupManifest.currentFormatVersion,
      appVersion: AppConstants.appVersion,
      exportedAt: DateTime.now().toUtc(),
      workspaceId: workspaceId,
      workspaceName: workspaceName,
      counts: counts,
      payloadChecksum: checksum,
    );

    return BackupPayload(
      manifest: manifest,
      workspaces: workspacesJson,
      categories: categoriesJson,
      records: recordsJson,
      assets: assetsJson,
      tasks: tasksJson,
      documents: documentsJson,
      expenses: expensesJson,
      bills: billsJson,
      fieldDefinitions: fieldDefinitionsJson,
      fieldValues: fieldValuesJson,
    );
  }

  @override
  Future<String> exportBackupToJson(String workspaceId) async {
    final payload = await createBackup(workspaceId);
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(payload.toJson());
  }

  @override
  Future<BackupValidationResult> validateBackup(String jsonContent) async {
    try {
      final decoded = jsonDecode(jsonContent);
      if (decoded is! Map<String, dynamic>) {
        return const BackupValidationResult.invalid(
          status: BackupValidationStatus.corrupted,
          errorMessage: 'Backup archive root must be a JSON object.',
        );
      }

      final manifestRaw = decoded['manifest'];
      final dataRaw = decoded['data'];

      if (manifestRaw is! Map<String, dynamic> || dataRaw is! Map<String, dynamic>) {
        return const BackupValidationResult.invalid(
          status: BackupValidationStatus.missingData,
          errorMessage: 'Archive is missing required "manifest" or "data" sections.',
        );
      }

      final manifest = BackupManifest.fromJson(manifestRaw);

      if (manifest.version > BackupManifest.currentFormatVersion) {
        return BackupValidationResult.invalid(
          status: BackupValidationStatus.unsupportedVersion,
          manifest: manifest,
          errorMessage:
              'Archive format version ${manifest.version} is not supported by this version of Domora.',
        );
      }

      // Verify SHA-256 Checksum
      final computedChecksum = BackupPayload.computeChecksum(dataRaw);
      if (computedChecksum != manifest.payloadChecksum) {
        return BackupValidationResult.invalid(
          status: BackupValidationStatus.corrupted,
          manifest: manifest,
          errorMessage:
              'Cryptographic checksum mismatch. Archive data is corrupted or has been tampered with.',
        );
      }

      final workspaces = (dataRaw['workspaces'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final categories = (dataRaw['categories'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final records = (dataRaw['records'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final assets = (dataRaw['assets'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final tasks = (dataRaw['tasks'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final documents = (dataRaw['documents'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final expenses = (dataRaw['expenses'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final bills = (dataRaw['bills'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final fieldDefinitions = (dataRaw['fieldDefinitions'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final fieldValues = (dataRaw['fieldValues'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      final payload = BackupPayload(
        manifest: manifest,
        workspaces: workspaces,
        categories: categories,
        records: records,
        assets: assets,
        tasks: tasks,
        documents: documents,
        expenses: expenses,
        bills: bills,
        fieldDefinitions: fieldDefinitions,
        fieldValues: fieldValues,
      );

      return BackupValidationResult.valid(
        manifest: manifest,
        payload: payload,
      );
    } catch (e) {
      return BackupValidationResult.invalid(
        status: BackupValidationStatus.corrupted,
        errorMessage: 'Failed to parse backup archive: $e',
      );
    }
  }

  @override
  Future<void> restoreBackup(
    BackupPayload payload, {
    required bool clearExisting,
  }) async {
    return _db.transaction(() async {
      final workspaceId = payload.manifest.workspaceId;

      if (clearExisting) {
        // Find existing records belonging strictly to this workspace
        final existingRecords = await (_db.select(_db.records)
              ..where((r) => r.workspaceId.equals(workspaceId)))
            .get();
        final existingRecordIds = existingRecords.map((r) => r.id).toSet();

        if (existingRecordIds.isNotEmpty) {
          await (_db.delete(_db.fieldValues)
                ..where((v) => v.recordId.isIn(existingRecordIds)))
              .go();
          await (_db.delete(_db.bills)
                ..where((b) => b.recordId.isIn(existingRecordIds)))
              .go();
          await (_db.delete(_db.expenses)
                ..where((e) => e.recordId.isIn(existingRecordIds)))
              .go();
          await (_db.delete(_db.documents)
                ..where((d) => d.recordId.isIn(existingRecordIds)))
              .go();
          await (_db.delete(_db.tasks)
                ..where((t) => t.recordId.isIn(existingRecordIds)))
              .go();
          await (_db.delete(_db.assets)
                ..where((a) => a.recordId.isIn(existingRecordIds)))
              .go();
        }

        await (_db.delete(_db.fieldDefinitions)
              ..where((f) => f.workspaceId.equals(workspaceId)))
            .go();
        await (_db.delete(_db.records)
              ..where((r) => r.workspaceId.equals(workspaceId)))
            .go();
        await (_db.delete(_db.categories)
              ..where((c) => c.workspaceId.equals(workspaceId)))
            .go();
      }

      // 1. Insert Workspace
      for (final w in payload.workspaces) {
        await _db.into(_db.workspaces).insertOnConflictUpdate(
              WorkspacesCompanion(
                id: Value(w['id'] as String),
                name: Value(w['name'] as String),
                workspaceType: Value(w['workspaceType'] as String? ?? 'personal'),
                createdAt: Value(DateTime.parse(w['createdAt'] as String).toUtc()),
                updatedAt: Value(DateTime.parse(w['updatedAt'] as String).toUtc()),
                archivedAt: Value(w['archivedAt'] != null
                    ? DateTime.parse(w['archivedAt'] as String).toUtc()
                    : null),
                deletedAt: Value(w['deletedAt'] != null
                    ? DateTime.parse(w['deletedAt'] as String).toUtc()
                    : null),
              ),
            );
      }

      // 2. Insert Categories
      for (final c in payload.categories) {
        await _db.into(_db.categories).insertOnConflictUpdate(
              CategoriesCompanion(
                id: Value(c['id'] as String),
                workspaceId: Value(c['workspaceId'] as String),
                name: Value(c['name'] as String),
                iconKey: Value(c['iconKey'] as String?),
                colorHex: Value(c['colorHex'] as String?),
                isSystem: Value(c['isSystem'] as bool? ?? false),
                createdAt: Value(DateTime.parse(c['createdAt'] as String).toUtc()),
                archivedAt: Value(c['archivedAt'] != null
                    ? DateTime.parse(c['archivedAt'] as String).toUtc()
                    : null),
              ),
            );
      }

      // 3. Insert Records
      for (final r in payload.records) {
        await _db.into(_db.records).insertOnConflictUpdate(
              RecordsCompanion(
                id: Value(r['id'] as String),
                workspaceId: Value(r['workspaceId'] as String),
                categoryId: Value(r['categoryId'] as String?),
                recordType: Value(r['recordType'] as String),
                title: Value(r['title'] as String),
                description: Value(r['description'] as String?),
                status: Value(r['status'] as String? ?? 'active'),
                createdAt: Value(DateTime.parse(r['createdAt'] as String).toUtc()),
                updatedAt: Value(DateTime.parse(r['updatedAt'] as String).toUtc()),
                archivedAt: Value(r['archivedAt'] != null
                    ? DateTime.parse(r['archivedAt'] as String).toUtc()
                    : null),
                deletedAt: Value(r['deletedAt'] != null
                    ? DateTime.parse(r['deletedAt'] as String).toUtc()
                    : null),
              ),
            );
      }

      // 4. Insert Assets
      for (final a in payload.assets) {
        await _db.into(_db.assets).insertOnConflictUpdate(
              AssetsCompanion(
                recordId: Value(a['recordId'] as String),
                brand: Value(a['brand'] as String?),
                model: Value(a['model'] as String?),
                serialNumber: Value(a['serialNumber'] as String?),
                condition: Value(a['condition'] as String?),
                purchaseDate: Value(a['purchaseDate'] != null
                    ? DateTime.parse(a['purchaseDate'] as String).toUtc()
                    : null),
                purchaseAmountMinor: Value(a['purchaseAmountMinor'] as int?),
                purchaseCurrency: Value(a['purchaseCurrency'] as String? ?? 'PHP'),
                locationDescription: Value(a['locationDescription'] as String?),
                acquiredFrom: Value(a['acquiredFrom'] as String?),
                disposedAt: Value(a['disposedAt'] != null
                    ? DateTime.parse(a['disposedAt'] as String).toUtc()
                    : null),
                odometerReading: Value(a['odometerReading'] as int?),
                pmsDistanceIntervalKm: Value(a['pmsDistanceIntervalKm'] as int?),
                pmsTimeIntervalMonths: Value(a['pmsTimeIntervalMonths'] as int?),
                nextPmsDueDate: Value(a['nextPmsDueDate'] != null
                    ? DateTime.parse(a['nextPmsDueDate'] as String).toUtc()
                    : null),
                nextPmsOdometerTarget: Value(a['nextPmsOdometerTarget'] as int?),
                warrantyExpiryDate: Value(a['warrantyExpiryDate'] != null
                    ? DateTime.parse(a['warrantyExpiryDate'] as String).toUtc()
                    : null),
              ),
            );
      }

      // 5. Insert Tasks
      for (final t in payload.tasks) {
        await _db.into(_db.tasks).insertOnConflictUpdate(
              TasksCompanion(
                recordId: Value(t['recordId'] as String),
                priority: Value(t['priority'] as String? ?? 'medium'),
                status: Value(t['status'] as String? ?? 'pending'),
                dueDate: Value(t['dueDate'] != null
                    ? DateTime.parse(t['dueDate'] as String).toUtc()
                    : null),
                completedAt: Value(t['completedAt'] != null
                    ? DateTime.parse(t['completedAt'] as String).toUtc()
                    : null),
                recurrenceRule: Value(t['recurrenceRule'] as String?),
                assetRecordId: Value(t['assetRecordId'] as String?),
              ),
            );
      }

      // 6. Insert Documents
      for (final d in payload.documents) {
        await _db.into(_db.documents).insertOnConflictUpdate(
              DocumentsCompanion(
                recordId: Value(d['recordId'] as String),
                fileName: Value(d['fileName'] as String? ?? 'document'),
                filePath: Value(d['filePath'] as String?),
                documentType: Value(d['documentType'] as String? ?? 'general'),
                fileSizeBytes: Value(d['fileSizeBytes'] as int?),
                mimeType: Value(d['mimeType'] as String?),
                linkedAssetRecordId: Value(d['linkedAssetRecordId'] as String?),
              ),
            );
      }

      // 7. Insert Expenses
      for (final e in payload.expenses) {
        await _db.into(_db.expenses).insertOnConflictUpdate(
              ExpensesCompanion(
                recordId: Value(e['recordId'] as String),
                amountMinor: Value(e['amountMinor'] as int),
                currencyCode: Value(e['currencyCode'] as String? ?? 'PHP'),
                transactionDate: Value(DateTime.parse(e['transactionDate'] as String).toUtc()),
                paymentMethod: Value(e['paymentMethod'] as String?),
                expenseCategory: Value(e['expenseCategory'] as String? ?? 'maintenance'),
                linkedAssetRecordId: Value(e['linkedAssetRecordId'] as String?),
                linkedTaskRecordId: Value(e['linkedTaskRecordId'] as String?),
                linkedBillRecordId: Value(e['linkedBillRecordId'] as String?),
                odometerReading: Value(e['odometerReading'] as int?),
              ),
            );
      }

      // 8. Insert Bills
      for (final b in payload.bills) {
        await _db.into(_db.bills).insertOnConflictUpdate(
              BillsCompanion(
                recordId: Value(b['recordId'] as String),
                utilityType: Value(b['utilityType'] as String? ?? 'utility'),
                providerName: Value(b['providerName'] as String?),
                accountNumber: Value(b['accountNumber'] as String?),
                billingPeriodStart: Value(b['billingPeriodStart'] != null
                    ? DateTime.parse(b['billingPeriodStart'] as String).toUtc()
                    : null),
                billingPeriodEnd: Value(b['billingPeriodEnd'] != null
                    ? DateTime.parse(b['billingPeriodEnd'] as String).toUtc()
                    : null),
                dueDate: Value(b['dueDate'] != null
                    ? DateTime.parse(b['dueDate'] as String).toUtc()
                    : null),
                amountDueMinor: Value(b['amountDueMinor'] as int),
                currencyCode: Value(b['currencyCode'] as String? ?? 'PHP'),
                paymentStatus: Value(b['paymentStatus'] as String? ?? 'unpaid'),
                paidAt: Value(b['paidAt'] != null
                    ? DateTime.parse(b['paidAt'] as String).toUtc()
                    : null),
                linkedAssetRecordId: Value(b['linkedAssetRecordId'] as String?),
                linkedExpenseRecordId: Value(b['linkedExpenseRecordId'] as String?),
              ),
            );
      }

      // 9. Insert FieldDefinitions
      for (final fd in payload.fieldDefinitions) {
        await _db.into(_db.fieldDefinitions).insertOnConflictUpdate(
              FieldDefinitionsCompanion(
                id: Value(fd['id'] as String),
                workspaceId: Value(fd['workspaceId'] as String),
                categoryId: Value(fd['categoryId'] as String?),
                fieldKey: Value(fd['fieldKey'] as String),
                label: Value(fd['label'] as String),
                dataType: Value(fd['dataType'] as String? ?? 'text'),
                displayOrder: Value(fd['displayOrder'] as int? ?? 0),
                createdAt: Value(DateTime.parse(fd['createdAt'] as String).toUtc()),
              ),
            );
      }

      // 10. Insert FieldValues
      for (final fv in payload.fieldValues) {
        await _db.into(_db.fieldValues).insertOnConflictUpdate(
              FieldValuesCompanion(
                id: Value(fv['id'] as String),
                recordId: Value(fv['recordId'] as String),
                fieldDefinitionId: Value(fv['fieldDefinitionId'] as String),
                valueText: Value(fv['valueText'] as String),
                createdAt: Value(DateTime.parse(fv['createdAt'] as String).toUtc()),
                updatedAt: Value(DateTime.parse(fv['updatedAt'] as String).toUtc()),
              ),
            );
      }
    });
  }
}
