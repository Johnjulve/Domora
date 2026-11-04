import 'package:drift/drift.dart';

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
      createdAt: record.createdAt,
      updatedAt: now,
    );

    await _db.into(_db.records).insert(_toRecordCompanion(stampedRecord));
    return stampedRecord;
  }

  @override
  Future<RecordWithAsset> createAssetRecord({
    required Record record,
    required Asset asset,
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

      return RecordWithAsset(record: stampedRecord, asset: syncedAsset);
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

    return RecordWithAsset(
      record: _toDomainRecord(recordEntity),
      asset: assetEntity != null ? _toDomainAsset(assetEntity) : null,
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
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      archivedAt: entity.archivedAt,
      deletedAt: entity.deletedAt,
    );
  }

  Asset _toDomainAsset(AssetEntity entity) {
    return Asset(
      recordId: entity.recordId,
      purchaseDate: entity.purchaseDate,
      purchaseAmountMinor: entity.purchaseAmountMinor,
      purchaseCurrency: entity.purchaseCurrency ?? 'PHP',
      brand: entity.brand,
      model: entity.model,
      serialNumber: entity.serialNumber,
      condition: entity.condition,
      locationDescription: entity.locationDescription,
      acquiredFrom: entity.acquiredFrom,
      disposedAt: entity.disposedAt,
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

  AssetsCompanion _toAssetCompanion(Asset asset) {
    return AssetsCompanion(
      recordId: Value(asset.recordId),
      purchaseDate: Value(asset.purchaseDate),
      purchaseAmountMinor: Value(asset.purchaseAmountMinor),
      purchaseCurrency: Value(asset.purchaseCurrency),
      brand: Value(asset.brand),
      model: Value(asset.model),
      serialNumber: Value(asset.serialNumber),
      condition: Value(asset.condition),
      locationDescription: Value(asset.locationDescription),
      acquiredFrom: Value(asset.acquiredFrom),
      disposedAt: Value(asset.disposedAt),
    );
  }
}
