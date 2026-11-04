import '../../records/domain/record.dart';

/// Categories of documents stored in the Sanctuary Vault.
enum DocumentType {
  warranty,
  receipt,
  manual,
  deed,
  idCard,
  general;

  static DocumentType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'warranty':
        return DocumentType.warranty;
      case 'receipt':
        return DocumentType.receipt;
      case 'manual':
        return DocumentType.manual;
      case 'deed':
        return DocumentType.deed;
      case 'id':
      case 'id_card':
      case 'idcard':
        return DocumentType.idCard;
      case 'general':
      default:
        return DocumentType.general;
    }
  }

  String get label {
    switch (this) {
      case DocumentType.warranty:
        return 'Warranty';
      case DocumentType.receipt:
        return 'Receipt';
      case DocumentType.manual:
        return 'Manual';
      case DocumentType.deed:
        return 'Deed / Title';
      case DocumentType.idCard:
        return 'ID Card';
      case DocumentType.general:
        return 'General';
    }
  }

  String get value {
    switch (this) {
      case DocumentType.warranty:
        return 'warranty';
      case DocumentType.receipt:
        return 'receipt';
      case DocumentType.manual:
        return 'manual';
      case DocumentType.deed:
        return 'deed';
      case DocumentType.idCard:
        return 'id';
      case DocumentType.general:
        return 'general';
    }
  }
}

/// Pure domain entity representing Document & Attachment metadata.
class DocumentItem {
  final String recordId;
  final String fileName;
  final String? filePath;
  final String documentType; // 'warranty', 'receipt', 'manual', 'deed', 'id', 'general'
  final int? fileSizeBytes;
  final String? mimeType;
  final String? linkedAssetRecordId;

  const DocumentItem({
    required this.recordId,
    required this.fileName,
    this.filePath,
    this.documentType = 'general',
    this.fileSizeBytes,
    this.mimeType,
    this.linkedAssetRecordId,
  });

  String get formattedFileSize {
    if (fileSizeBytes == null || fileSizeBytes! <= 0) return 'Unknown size';
    final bytes = fileSizeBytes!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  DocumentItem copyWith({
    String? recordId,
    String? fileName,
    String? filePath,
    String? documentType,
    int? fileSizeBytes,
    String? mimeType,
    String? linkedAssetRecordId,
  }) {
    return DocumentItem(
      recordId: recordId ?? this.recordId,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      documentType: documentType ?? this.documentType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      linkedAssetRecordId: linkedAssetRecordId ?? this.linkedAssetRecordId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentItem &&
          runtimeType == other.runtimeType &&
          recordId == other.recordId &&
          fileName == other.fileName &&
          filePath == other.filePath &&
          documentType == other.documentType &&
          fileSizeBytes == other.fileSizeBytes &&
          mimeType == other.mimeType &&
          linkedAssetRecordId == other.linkedAssetRecordId;

  @override
  int get hashCode => Object.hash(
        recordId,
        fileName,
        filePath,
        documentType,
        fileSizeBytes,
        mimeType,
        linkedAssetRecordId,
      );
}

/// Composite domain entity holding a Record and its specialized Document metadata.
class RecordWithDocument {
  final Record record;
  final DocumentItem document;
  final String? linkedAssetTitle;

  const RecordWithDocument({
    required this.record,
    required this.document,
    this.linkedAssetTitle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordWithDocument &&
          runtimeType == other.runtimeType &&
          record == other.record &&
          document == other.document &&
          linkedAssetTitle == other.linkedAssetTitle;

  @override
  int get hashCode => Object.hash(record, document, linkedAssetTitle);
}
