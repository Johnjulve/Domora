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
  final DateTime? warrantyExpiryDate;

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
    this.warrantyExpiryDate,
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
    DateTime? warrantyExpiryDate,
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
      warrantyExpiryDate: warrantyExpiryDate ?? this.warrantyExpiryDate,
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
          nextPmsOdometerTarget == other.nextPmsOdometerTarget &&
          warrantyExpiryDate == other.warrantyExpiryDate;

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
        warrantyExpiryDate,
      );
}

/// Pure domain entity representing a custom field definition.
class FieldDefinition {
  final String id;
  final String workspaceId;
  final String? categoryId;
  final String fieldKey;
  final String label;
  final String dataType;
  final int displayOrder;
  final DateTime createdAt;

  const FieldDefinition({
    required this.id,
    required this.workspaceId,
    this.categoryId,
    required this.fieldKey,
    required this.label,
    this.dataType = 'text',
    this.displayOrder = 0,
    required this.createdAt,
  });

  FieldDefinition copyWith({
    String? id,
    String? workspaceId,
    String? categoryId,
    String? fieldKey,
    String? label,
    String? dataType,
    int? displayOrder,
    DateTime? createdAt,
  }) {
    return FieldDefinition(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      categoryId: categoryId ?? this.categoryId,
      fieldKey: fieldKey ?? this.fieldKey,
      label: label ?? this.label,
      dataType: dataType ?? this.dataType,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldDefinition &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          categoryId == other.categoryId &&
          fieldKey == other.fieldKey &&
          label == other.label &&
          dataType == other.dataType &&
          displayOrder == other.displayOrder &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        workspaceId,
        categoryId,
        fieldKey,
        label,
        dataType,
        displayOrder,
        createdAt,
      );
}

/// Pure domain entity representing a stored custom field value.
class FieldValue {
  final String id;
  final String recordId;
  final String fieldDefinitionId;
  final String valueText;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FieldValue({
    required this.id,
    required this.recordId,
    required this.fieldDefinitionId,
    required this.valueText,
    required this.createdAt,
    required this.updatedAt,
  });

  FieldValue copyWith({
    String? id,
    String? recordId,
    String? fieldDefinitionId,
    String? valueText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FieldValue(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      fieldDefinitionId: fieldDefinitionId ?? this.fieldDefinitionId,
      valueText: valueText ?? this.valueText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldValue &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          recordId == other.recordId &&
          fieldDefinitionId == other.fieldDefinitionId &&
          valueText == other.valueText &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        recordId,
        fieldDefinitionId,
        valueText,
        createdAt,
        updatedAt,
      );
}

/// Composite domain entity pairing a custom field definition with its corresponding value.
class CustomFieldEntry {
  final FieldDefinition definition;
  final FieldValue value;

  const CustomFieldEntry({
    required this.definition,
    required this.value,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomFieldEntry &&
          runtimeType == other.runtimeType &&
          definition == other.definition &&
          value == other.value;

  @override
  int get hashCode => Object.hash(definition, value);
}

/// Composite domain entity holding a Record and its optional specialized Asset metadata and custom fields.
class RecordWithAsset {
  final Record record;
  final Asset? asset;
  final List<CustomFieldEntry> customFields;

  const RecordWithAsset({
    required this.record,
    this.asset,
    this.customFields = const [],
  });

  RecordWithAsset copyWith({
    Record? record,
    Asset? asset,
    List<CustomFieldEntry>? customFields,
  }) {
    return RecordWithAsset(
      record: record ?? this.record,
      asset: asset ?? this.asset,
      customFields: customFields ?? this.customFields,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordWithAsset &&
          runtimeType == other.runtimeType &&
          record == other.record &&
          asset == other.asset &&
          _listEquals(customFields, other.customFields);

  @override
  int get hashCode => Object.hash(record, asset, Object.hashAll(customFields));

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Abstract contract for Record and Asset persistence operations.
abstract class RecordRepository {
  /// Creates a standalone universal record.
  Future<Record> createRecord(Record record);

  /// Atomically creates a universal record and its linked specialized asset with optional custom field values.
  Future<RecordWithAsset> createAssetRecord({
    required Record record,
    required Asset asset,
    Map<String, String>? customFields,
  });

  /// Retrieves a record along with its asset details and custom fields if present.
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

  /// Retrieves or creates a custom field definition for a given workspace and optional category.
  Future<FieldDefinition> getOrCreateFieldDefinition({
    required String workspaceId,
    String? categoryId,
    required String fieldKey,
    required String label,
    String dataType = 'text',
    int displayOrder = 0,
  });

  /// Retrieves custom field definitions for a workspace and optional category.
  Future<List<FieldDefinition>> getFieldDefinitions(
    String workspaceId, {
    String? categoryId,
  });

  /// Retrieves all custom fields with their definitions and values for a given record.
  Future<List<CustomFieldEntry>> getCustomFieldsForRecord(String recordId);

  /// Persists custom field values for a record.
  Future<void> saveCustomFieldValues({
    required String recordId,
    required String workspaceId,
    required Map<String, String> fieldValues,
    String? categoryId,
  });
}
