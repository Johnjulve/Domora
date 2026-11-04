import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../records/domain/record.dart';
import '../domain/document_item.dart';
import '../domain/document_repository.dart';

/// Drift-backed implementation of [DocumentRepository].
class DocumentRepositoryImpl implements DocumentRepository {
  final AppDatabase _db;

  const DocumentRepositoryImpl(this._db);

  @override
  Future<void> createDocumentRecord({
    required Record record,
    required DocumentItem document,
  }) async {
    return _db.transaction(() async {
      final now = DateTime.now().toUtc();
      final stampedRecord = record.copyWith(
        recordType: 'document',
        updatedAt: now,
      );
      final syncedDoc = document.copyWith(recordId: record.id);

      await _db.into(_db.records).insert(_toRecordCompanion(stampedRecord));
      await _db.into(_db.documents).insert(_toDocumentCompanion(syncedDoc));
    });
  }

  @override
  Future<void> softDeleteDocument(String recordId) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.records)..where((r) => r.id.equals(recordId))).write(
      RecordsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Stream<List<RecordWithDocument>> watchDocumentsByWorkspace(
    String workspaceId, {
    String? documentType,
    String? linkedAssetRecordId,
  }) {
    final query = _buildDocumentsQuery(
      workspaceId,
      documentType: documentType,
      linkedAssetRecordId: linkedAssetRecordId,
    );
    return query.watch().map(_mapRowsToRecordsWithDocuments);
  }

  @override
  Future<List<RecordWithDocument>> getDocumentsByWorkspace(
    String workspaceId, {
    String? documentType,
    String? linkedAssetRecordId,
  }) async {
    final query = _buildDocumentsQuery(
      workspaceId,
      documentType: documentType,
      linkedAssetRecordId: linkedAssetRecordId,
    );
    final rows = await query.get();
    return _mapRowsToRecordsWithDocuments(rows);
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildDocumentsQuery(
    String workspaceId, {
    String? documentType,
    String? linkedAssetRecordId,
  }) {
    final docRecords = _db.records;
    final docsTable = _db.documents;
    final assetRecords = _db.alias(_db.records, 'asset_records');

    final query = _db.select(docRecords).join([
      innerJoin(docsTable, docsTable.recordId.equalsExp(docRecords.id)),
      leftOuterJoin(
        assetRecords,
        assetRecords.id.equalsExp(docsTable.linkedAssetRecordId) &
            assetRecords.deletedAt.isNull(),
      ),
    ]);

    Expression<bool> predicate = docRecords.workspaceId.equals(workspaceId) &
        docRecords.deletedAt.isNull() &
        docRecords.recordType.equals('document');

    if (documentType != null && documentType.isNotEmpty) {
      predicate = predicate & docsTable.documentType.equals(documentType);
    }

    if (linkedAssetRecordId != null && linkedAssetRecordId.isNotEmpty) {
      predicate = predicate & docsTable.linkedAssetRecordId.equals(linkedAssetRecordId);
    }

    query.where(predicate);

    query.orderBy([
      OrderingTerm(
        expression: docRecords.createdAt,
        mode: OrderingMode.desc,
      ),
    ]);

    return query;
  }

  List<RecordWithDocument> _mapRowsToRecordsWithDocuments(List<TypedResult> rows) {
    final assetRecords = _db.alias(_db.records, 'asset_records');
    return rows.map((row) {
      final recordEntity = row.readTable(_db.records);
      final docEntity = row.readTable(_db.documents);
      final linkedAssetEntity = row.readTableOrNull(assetRecords);

      return RecordWithDocument(
        record: _toDomainRecord(recordEntity),
        document: _toDomainDocument(docEntity),
        linkedAssetTitle: linkedAssetEntity?.title,
      );
    }).toList();
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

  DocumentItem _toDomainDocument(DocumentEntity entity) {
    return DocumentItem(
      recordId: entity.recordId,
      fileName: entity.fileName,
      filePath: entity.filePath,
      documentType: entity.documentType,
      fileSizeBytes: entity.fileSizeBytes,
      mimeType: entity.mimeType,
      linkedAssetRecordId: entity.linkedAssetRecordId,
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

  DocumentsCompanion _toDocumentCompanion(DocumentItem doc) {
    return DocumentsCompanion(
      recordId: Value(doc.recordId),
      fileName: Value(doc.fileName),
      filePath: Value(doc.filePath),
      documentType: Value(doc.documentType),
      fileSizeBytes: Value(doc.fileSizeBytes),
      mimeType: Value(doc.mimeType),
      linkedAssetRecordId: Value(doc.linkedAssetRecordId),
    );
  }
}
