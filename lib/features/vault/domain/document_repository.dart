import '../../records/domain/record.dart';
import 'document_item.dart';

/// Repository interface governing Document Vault persistence.
abstract class DocumentRepository {
  /// Creates a unified Record and its associated Document metadata within a database transaction.
  Future<void> createDocumentRecord({
    required Record record,
    required DocumentItem document,
  });

  /// Soft deletes a document record.
  Future<void> softDeleteDocument(String recordId);

  /// Reactively observes active documents for a specific workspace.
  Stream<List<RecordWithDocument>> watchDocumentsByWorkspace(
    String workspaceId, {
    String? documentType,
    String? linkedAssetRecordId,
  });

  /// Queries active documents for a specific workspace.
  Future<List<RecordWithDocument>> getDocumentsByWorkspace(
    String workspaceId, {
    String? documentType,
    String? linkedAssetRecordId,
  });
}
