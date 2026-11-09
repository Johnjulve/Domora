import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/record.dart';

/// Drift-backed implementation of [RecordRepository].
class RecordRepositoryImpl implements RecordRepository {
  final AppDatabase _db;

  const RecordRepositoryImpl(this._db);

  @override
  Future<Record> createRecord(Record record) async {
    final now = DateTime.now().toUtc();
    final stampedRecord = record.copyWith(
      createdAt: record.createdAt.toUtc(),
      updatedAt: now,
    );

    await _db.into(_db.records).insert(_toRecordCompanion(stampedRecord));
    return stampedRecord;
  }

  @override
  Future<RecordWithAsset> createAssetRecord({
    required Record record,
    required Asset asset,
    Map<String, String>? customFields,
  }) async {
    return _db.transaction(() async {
      final now = DateTime.now().toUtc();
      final stampedRecord = record.copyWith(
        recordType: 'asset',
        updatedAt: now,
      );
      final syncedAsset = asset.copyWith(recordId: record.id);

      await _db.into(_db.records).insert(_toRecordCompanion(stampedRecord));
      await _db.into(_db.assets).insert(_toAssetCompanion(syncedAsset));

      final customFieldEntries = <CustomFieldEntry>[];

      if (customFields != null && customFields.isNotEmpty) {
        for (final entry in customFields.entries) {
          final trimmedValue = entry.value.trim();
          if (trimmedValue.isEmpty) continue;

          final definition = await _getOrCreateFieldDefinitionInternal(
            workspaceId: record.workspaceId,
            categoryId: record.categoryId,
            fieldKey: entry.key,
            label: entry.key,
          );

          final valueId = const Uuid().v4();
          final valEntity = FieldValuesCompanion(
            id: Value(valueId),
            recordId: Value(record.id),
            fieldDefinitionId: Value(definition.id),
            valueText: Value(trimmedValue),
            createdAt: Value(now),
            updatedAt: Value(now),
          );

          await _db.into(_db.fieldValues).insert(valEntity);
          customFieldEntries.add(
            CustomFieldEntry(
              definition: definition,
              value: FieldValue(
                id: valueId,
                recordId: record.id,
                fieldDefinitionId: definition.id,
                valueText: trimmedValue,
                createdAt: now,
                updatedAt: now,
              ),
            ),
          );
        }
      }

      return RecordWithAsset(
        record: stampedRecord,
        asset: syncedAsset,
        customFields: customFieldEntries,
      );
    });
  }

  @override
  Future<RecordWithAsset?> getRecordWithAsset(String recordId) async {
    final query = _db.select(_db.records).join([
      leftOuterJoin(_db.assets, _db.assets.recordId.equalsExp(_db.records.id)),
    ])..where(_db.records.id.equals(recordId) & _db.records.deletedAt.isNull());

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final recordEntity = row.readTable(_db.records);
    final assetEntity = row.readTableOrNull(_db.assets);
    final customFields = await getCustomFieldsForRecord(recordId);

    return RecordWithAsset(
      record: _toDomainRecord(recordEntity),
      asset: assetEntity != null ? _toDomainAsset(assetEntity) : null,
      customFields: customFields,
    );
  }

  @override
  Future<List<RecordWithAsset>> getActiveRecordsByWorkspace(
    String workspaceId, {
    String? recordType,
    String? categoryId,
    String? searchQuery,
  }) async {
    final query = _buildActiveWorkspaceQuery(
      workspaceId,
      recordType: recordType,
      categoryId: categoryId,
      searchQuery: searchQuery,
    );
    final rows = await query.get();

    return rows.map((row) {
      final recordEntity = row.readTable(_db.records);
      final assetEntity = row.readTableOrNull(_db.assets);
      return RecordWithAsset(
        record: _toDomainRecord(recordEntity),
        asset: assetEntity != null ? _toDomainAsset(assetEntity) : null,
      );
    }).toList();
  }

  @override
  Stream<List<RecordWithAsset>> watchActiveRecordsByWorkspace(
    String workspaceId, {
    String? recordType,
    String? categoryId,
    String? searchQuery,
  }) {
    final query = _buildActiveWorkspaceQuery(
      workspaceId,
      recordType: recordType,
      categoryId: categoryId,
      searchQuery: searchQuery,
    );

    return query.watch().map((rows) {
      return rows.map((row) {
        final recordEntity = row.readTable(_db.records);
        final assetEntity = row.readTableOrNull(_db.assets);
        return RecordWithAsset(
          record: _toDomainRecord(recordEntity),
          asset: assetEntity != null ? _toDomainAsset(assetEntity) : null,
        );
      }).toList();
    });
  }

  @override
  Future<void> updateRecord(Record record) async {
    final now = DateTime.now().toUtc();
    final stampedRecord = record.copyWith(updatedAt: now);
    await (_db.update(_db.records)..where((r) => r.id.equals(record.id) & r.deletedAt.isNull()))
        .write(_toRecordCompanion(stampedRecord));
  }

  @override
  Future<void> updateAsset(Asset asset) async {
    await _db.transaction(() async {
      final now = DateTime.now().toUtc();
      await (_db.update(_db.assets)..where((a) => a.recordId.equals(asset.recordId)))
          .write(_toAssetCompanion(asset));
      // Bump parent record's updatedAt so sync and audit engines reliably track the asset mutation
      await (_db.update(_db.records)..where((r) => r.id.equals(asset.recordId) & r.deletedAt.isNull()))
          .write(RecordsCompanion(updatedAt: Value(now)));
    });
  }

  @override
  Future<void> softDeleteRecord(String recordId) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.records)..where((r) => r.id.equals(recordId))).write(
      RecordsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<FieldDefinition> getOrCreateFieldDefinition({
    required String workspaceId,
    String? categoryId,
    required String fieldKey,
    required String label,
    String dataType = 'text',
    int displayOrder = 0,
  }) async {
    return _getOrCreateFieldDefinitionInternal(
      workspaceId: workspaceId,
      categoryId: categoryId,
      fieldKey: fieldKey,
      label: label,
      dataType: dataType,
      displayOrder: displayOrder,
    );
  }

  Future<FieldDefinition> _getOrCreateFieldDefinitionInternal({
    required String workspaceId,
    String? categoryId,
    required String fieldKey,
    required String label,
    String dataType = 'text',
    int displayOrder = 0,
  }) async {
    final query = _db.select(_db.fieldDefinitions)
      ..where((f) {
        var expr = f.workspaceId.equals(workspaceId) & f.fieldKey.equals(fieldKey);
        if (categoryId != null) {
          expr = expr & f.categoryId.equals(categoryId);
        } else {
          expr = expr & f.categoryId.isNull();
        }
        return expr;
      });

    final existing = await query.getSingleOrNull();
    if (existing != null) {
      return _toDomainFieldDefinition(existing);
    }

    final now = DateTime.now().toUtc();
    final id = const Uuid().v4();
    final companion = FieldDefinitionsCompanion.insert(
      id: id,
      workspaceId: workspaceId,
      categoryId: Value(categoryId),
      fieldKey: fieldKey,
      label: label,
      dataType: Value(dataType),
      displayOrder: Value(displayOrder),
      createdAt: now,
    );

    await _db.into(_db.fieldDefinitions).insert(companion);

    return FieldDefinition(
      id: id,
      workspaceId: workspaceId,
      categoryId: categoryId,
      fieldKey: fieldKey,
      label: label,
      dataType: dataType,
      displayOrder: displayOrder,
      createdAt: now,
    );
  }

  @override
  Future<List<FieldDefinition>> getFieldDefinitions(
    String workspaceId, {
    String? categoryId,
  }) async {
    final query = _db.select(_db.fieldDefinitions)
      ..where((f) {
        var expr = f.workspaceId.equals(workspaceId);
        if (categoryId != null) {
          expr = expr & (f.categoryId.equals(categoryId) | f.categoryId.isNull());
        }
        return expr;
      })
      ..orderBy([(f) => OrderingTerm.asc(f.displayOrder), (f) => OrderingTerm.asc(f.label)]);

    final rows = await query.get();
    return rows.map(_toDomainFieldDefinition).toList();
  }

  @override
  Future<List<CustomFieldEntry>> getCustomFieldsForRecord(String recordId) async {
    final query = _db.select(_db.fieldValues).join([
      innerJoin(
        _db.fieldDefinitions,
        _db.fieldDefinitions.id.equalsExp(_db.fieldValues.fieldDefinitionId),
      ),
    ])..where(_db.fieldValues.recordId.equals(recordId));

    final rows = await query.get();
    return rows.map((row) {
      final def = row.readTable(_db.fieldDefinitions);
      final val = row.readTable(_db.fieldValues);
      return CustomFieldEntry(
        definition: _toDomainFieldDefinition(def),
        value: _toDomainFieldValue(val),
      );
    }).toList();
  }

  @override
  Future<void> saveCustomFieldValues({
    required String recordId,
    required String workspaceId,
    required Map<String, String> fieldValues,
    String? categoryId,
  }) async {
    await _db.transaction(() async {
      final now = DateTime.now().toUtc();
      for (final entry in fieldValues.entries) {
        final trimmed = entry.value.trim();
        if (trimmed.isEmpty) continue;

        final definition = await _getOrCreateFieldDefinitionInternal(
          workspaceId: workspaceId,
          categoryId: categoryId,
          fieldKey: entry.key,
          label: entry.key,
        );

        // Check if value already exists for this record and definition
        final existingValue = await (_db.select(_db.fieldValues)
              ..where((v) =>
                  v.recordId.equals(recordId) &
                  v.fieldDefinitionId.equals(definition.id)))
            .getSingleOrNull();

        if (existingValue != null) {
          await (_db.update(_db.fieldValues)
                ..where((v) => v.id.equals(existingValue.id)))
              .write(
            FieldValuesCompanion(
              valueText: Value(trimmed),
              updatedAt: Value(now),
            ),
          );
        } else {
          await _db.into(_db.fieldValues).insert(
                FieldValuesCompanion.insert(
                  id: const Uuid().v4(),
                  recordId: recordId,
                  fieldDefinitionId: definition.id,
                  valueText: trimmed,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        }
      }
    });
  }

  JoinedSelectStatement _buildActiveWorkspaceQuery(
    String workspaceId, {
    String? recordType,
    String? categoryId,
    String? searchQuery,
  }) {
    final query = _db.select(_db.records).join([
      leftOuterJoin(_db.assets, _db.assets.recordId.equalsExp(_db.records.id)),
    ]);

    var filter = _db.records.workspaceId.equals(workspaceId) & _db.records.deletedAt.isNull();
    if (recordType != null) {
      filter = filter & _db.records.recordType.equals(recordType);
    }
    if (categoryId != null) {
      filter = filter & _db.records.categoryId.equals(categoryId);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim().toLowerCase()}%';
      final searchExp = _db.records.title.lower().like(term) |
          _db.records.description.lower().like(term) |
          _db.assets.brand.lower().like(term) |
          _db.assets.model.lower().like(term) |
          _db.assets.serialNumber.lower().like(term) |
          _db.assets.locationDescription.lower().like(term);
      filter = filter & searchExp;
    }

    query
      ..where(filter)
      ..orderBy([OrderingTerm.desc(_db.records.createdAt)]);

    return query;
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
      createdAt: entity.createdAt.toUtc(),
      updatedAt: entity.updatedAt.toUtc(),
      archivedAt: entity.archivedAt?.toUtc(),
      deletedAt: entity.deletedAt?.toUtc(),
    );
  }

  Asset _toDomainAsset(AssetEntity entity) {
    return Asset(
      recordId: entity.recordId,
      purchaseDate: entity.purchaseDate?.toUtc(),
      purchaseAmountMinor: entity.purchaseAmountMinor,
      purchaseCurrency: entity.purchaseCurrency ?? 'PHP',
      brand: entity.brand,
      model: entity.model,
      serialNumber: entity.serialNumber,
      condition: entity.condition,
      locationDescription: entity.locationDescription,
      acquiredFrom: entity.acquiredFrom,
      disposedAt: entity.disposedAt?.toUtc(),
      odometerReading: entity.odometerReading,
      pmsDistanceIntervalKm: entity.pmsDistanceIntervalKm,
      pmsTimeIntervalMonths: entity.pmsTimeIntervalMonths,
      nextPmsDueDate: entity.nextPmsDueDate?.toUtc(),
      nextPmsOdometerTarget: entity.nextPmsOdometerTarget,
      warrantyExpiryDate: entity.warrantyExpiryDate?.toUtc(),
    );
  }

  FieldDefinition _toDomainFieldDefinition(FieldDefinitionEntity entity) {
    return FieldDefinition(
      id: entity.id,
      workspaceId: entity.workspaceId,
      categoryId: entity.categoryId,
      fieldKey: entity.fieldKey,
      label: entity.label,
      dataType: entity.dataType,
      displayOrder: entity.displayOrder,
      createdAt: entity.createdAt.toUtc(),
    );
  }

  FieldValue _toDomainFieldValue(FieldValueEntity entity) {
    return FieldValue(
      id: entity.id,
      recordId: entity.recordId,
      fieldDefinitionId: entity.fieldDefinitionId,
      valueText: entity.valueText,
      createdAt: entity.createdAt.toUtc(),
      updatedAt: entity.updatedAt.toUtc(),
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
      createdAt: Value(record.createdAt.toUtc()),
      updatedAt: Value(record.updatedAt.toUtc()),
      archivedAt: Value(record.archivedAt?.toUtc()),
      deletedAt: Value(record.deletedAt?.toUtc()),
    );
  }

  AssetsCompanion _toAssetCompanion(Asset asset) {
    return AssetsCompanion(
      recordId: Value(asset.recordId),
      purchaseDate: Value(asset.purchaseDate?.toUtc()),
      purchaseAmountMinor: Value(asset.purchaseAmountMinor),
      purchaseCurrency: Value(asset.purchaseCurrency),
      brand: Value(asset.brand),
      model: Value(asset.model),
      serialNumber: Value(asset.serialNumber),
      condition: Value(asset.condition),
      locationDescription: Value(asset.locationDescription),
      acquiredFrom: Value(asset.acquiredFrom),
      disposedAt: Value(asset.disposedAt?.toUtc()),
      odometerReading: Value(asset.odometerReading),
      pmsDistanceIntervalKm: Value(asset.pmsDistanceIntervalKm),
      pmsTimeIntervalMonths: Value(asset.pmsTimeIntervalMonths),
      nextPmsDueDate: Value(asset.nextPmsDueDate?.toUtc()),
      nextPmsOdometerTarget: Value(asset.nextPmsOdometerTarget),
      warrantyExpiryDate: Value(asset.warrantyExpiryDate?.toUtc()),
    );
  }
}
