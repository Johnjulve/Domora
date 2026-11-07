/// Pure domain entity representing a Universal Record in Domora.
class Record {
  final String id;
  final String workspaceId;
  final String? categoryId; // References Category.id
  final String recordType; // e.g. 'asset', 'task', 'expense', 'bill', 'document'
  final String title;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final DateTime? deletedAt;

  const Record({
    required this.id,
    required this.workspaceId,
    this.categoryId,
    required this.recordType,
    required this.title,
    this.description,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get isArchived => archivedAt != null;

  Record copyWith({
    String? id,
    String? workspaceId,
    String? categoryId,
    String? recordType,
    String? title,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
    DateTime? deletedAt,
  }) {
    return Record(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      categoryId: categoryId ?? this.categoryId,
      recordType: recordType ?? this.recordType,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Record &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          categoryId == other.categoryId &&
          recordType == other.recordType &&
          title == other.title &&
          description == other.description &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          archivedAt == other.archivedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        workspaceId,
        categoryId,
        recordType,
        title,
        description,
        status,
        createdAt,
        updatedAt,
        archivedAt,
        deletedAt,
      );
}

/// Pure domain entity representing specialized Asset details linked 1-to-1 to a Record.
class Asset {
  final String recordId;
  final DateTime? purchaseDate;
  final int? purchaseAmountMinor; // Financial minor units (e.g. cents)
  final String purchaseCurrency;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final String? condition;
  final String? locationDescription;
  final String? acquiredFrom;
  final DateTime? disposedAt;
  final int? odometerReading;
  final int? pmsDistanceIntervalKm;
  final int? pmsTimeIntervalMonths;
  final DateTime? nextPmsDueDate;
  final int? nextPmsOdometerTarget;

  const Asset({
    required this.recordId,
    this.purchaseDate,
    this.purchaseAmountMinor,
    this.purchaseCurrency = 'PHP',
    this.brand,
    this.model,
    this.serialNumber,
    this.condition,
    this.locationDescription,
    this.acquiredFrom,
    this.disposedAt,
    this.odometerReading,
    this.pmsDistanceIntervalKm,
    this.pmsTimeIntervalMonths,
    this.nextPmsDueDate,
    this.nextPmsOdometerTarget,
  });

  Asset copyWith({
    String? recordId,
    DateTime? purchaseDate,
    int? purchaseAmountMinor,
    String? purchaseCurrency,
    String? brand,
    String? model,
    String? serialNumber,
    String? condition,
    String? locationDescription,
    String? acquiredFrom,
    DateTime? disposedAt,
    int? odometerReading,
    int? pmsDistanceIntervalKm,
    int? pmsTimeIntervalMonths,
    DateTime? nextPmsDueDate,
    int? nextPmsOdometerTarget,
  }) {
    return Asset(
      recordId: recordId ?? this.recordId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchaseAmountMinor: purchaseAmountMinor ?? this.purchaseAmountMinor,
      purchaseCurrency: purchaseCurrency ?? this.purchaseCurrency,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      condition: condition ?? this.condition,
      locationDescription: locationDescription ?? this.locationDescription,
      acquiredFrom: acquiredFrom ?? this.acquiredFrom,
      disposedAt: disposedAt ?? this.disposedAt,
      odometerReading: odometerReading ?? this.odometerReading,
      pmsDistanceIntervalKm: pmsDistanceIntervalKm ?? this.pmsDistanceIntervalKm,
      pmsTimeIntervalMonths: pmsTimeIntervalMonths ?? this.pmsTimeIntervalMonths,
      nextPmsDueDate: nextPmsDueDate ?? this.nextPmsDueDate,
      nextPmsOdometerTarget: nextPmsOdometerTarget ?? this.nextPmsOdometerTarget,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Asset &&
          runtimeType == other.runtimeType &&
          recordId == other.recordId &&
          purchaseDate == other.purchaseDate &&
          purchaseAmountMinor == other.purchaseAmountMinor &&
          purchaseCurrency == other.purchaseCurrency &&
          brand == other.brand &&
          model == other.model &&
          serialNumber == other.serialNumber &&
          condition == other.condition &&
          locationDescription == other.locationDescription &&
          acquiredFrom == other.acquiredFrom &&
          disposedAt == other.disposedAt &&
          odometerReading == other.odometerReading &&
          pmsDistanceIntervalKm == other.pmsDistanceIntervalKm &&
          pmsTimeIntervalMonths == other.pmsTimeIntervalMonths &&
          nextPmsDueDate == other.nextPmsDueDate &&
          nextPmsOdometerTarget == other.nextPmsOdometerTarget;

  @override
  int get hashCode => Object.hash(
        recordId,
        purchaseDate,
        purchaseAmountMinor,
        purchaseCurrency,
        brand,
        model,
        serialNumber,
        condition,
        locationDescription,
        acquiredFrom,
        disposedAt,
        odometerReading,
        pmsDistanceIntervalKm,
        pmsTimeIntervalMonths,
        nextPmsDueDate,
        nextPmsOdometerTarget,
      );
}

/// Composite domain entity holding a Record and its optional specialized Asset metadata.
class RecordWithAsset {
  final Record record;
  final Asset? asset;

  const RecordWithAsset({
    required this.record,
    this.asset,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordWithAsset &&
          runtimeType == other.runtimeType &&
          record == other.record &&
          asset == other.asset;

  @override
  int get hashCode => Object.hash(record, asset);
}

/// Abstract contract for Record and Asset persistence operations.
abstract class RecordRepository {
  /// Creates a standalone universal record.
  Future<Record> createRecord(Record record);

  /// Atomically creates a universal record and its linked specialized asset.
  Future<RecordWithAsset> createAssetRecord({
    required Record record,
    required Asset asset,
  });

  /// Retrieves a record along with its asset details if present.
  Future<RecordWithAsset?> getRecordWithAsset(String recordId);

  /// Retrieves active records for a workspace, with optional type, category, and search query filters.
  Future<List<RecordWithAsset>> getActiveRecordsByWorkspace(
    String workspaceId, {
    String? recordType,
    String? categoryId,
    String? searchQuery,
  });

  /// Watches active records for a workspace reactively, with optional type, category, and search query filters.
  Stream<List<RecordWithAsset>> watchActiveRecordsByWorkspace(
    String workspaceId, {
    String? recordType,
    String? categoryId,
    String? searchQuery,
  });

  /// Updates universal record attributes, auto-stamping `updatedAt`.
  Future<void> updateRecord(Record record);

  /// Updates specialized asset details.
  Future<void> updateAsset(Asset asset);

  /// Soft deletes a record by setting its `deletedAt` timestamp.
  Future<void> softDeleteRecord(String recordId);
}
