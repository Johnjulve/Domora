import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/vault/data/document_repository_impl.dart';
import 'package:domora/features/vault/domain/document_item.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';

void main() {
  late AppDatabase db;
  late DocumentRepositoryImpl docRepo;
  late RecordRepositoryImpl recordRepo;
  late WorkspaceRepositoryImpl workspaceRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    docRepo = DocumentRepositoryImpl(db);
    recordRepo = RecordRepositoryImpl(db);
    workspaceRepo = WorkspaceRepositoryImpl(db);

    await workspaceRepo.getOrCreateDefaultWorkspace();
  });

  tearDown(() async {
    await db.close();
  });

  group('DocumentRepositoryImpl Tests', () {
    test('Can create a document record linked to an asset and retrieve it', () async {
      final now = DateTime.now().toUtc();

      // Create asset first
      await recordRepo.createAssetRecord(
        record: Record(
          id: 'asset-mac',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'MacBook Pro',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'asset-mac', brand: 'Apple', model: 'M3 Pro'),
      );

      // Create linked document (warranty receipt)
      await docRepo.createDocumentRecord(
        record: Record(
          id: 'doc-warranty',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'document',
          title: 'AppleCare+ Proof of Coverage',
          description: '3-year extended warranty document',
          createdAt: now,
          updatedAt: now,
        ),
        document: const DocumentItem(
          recordId: 'doc-warranty',
          fileName: 'applecare_macbook.pdf',
          documentType: 'warranty',
          fileSizeBytes: 2450000,
          mimeType: 'application/pdf',
          linkedAssetRecordId: 'asset-mac',
        ),
      );

      final docs = await docRepo.getDocumentsByWorkspace(AppConstants.defaultWorkspaceId);
      expect(docs.length, 1);
      final item = docs.first;
      expect(item.record.title, 'AppleCare+ Proof of Coverage');
      expect(item.document.fileName, 'applecare_macbook.pdf');
      expect(item.document.documentType, 'warranty');
      expect(item.document.formattedFileSize, '2.3 MB');
      expect(item.linkedAssetTitle, 'MacBook Pro');
    });

    test('Filter by documentType returns only matching documents', () async {
      final now = DateTime.now().toUtc();

      await docRepo.createDocumentRecord(
        record: Record(
          id: 'doc-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'document',
          title: 'Electric Stove Receipt',
          createdAt: now,
          updatedAt: now,
        ),
        document: const DocumentItem(
          recordId: 'doc-1',
          fileName: 'receipt.pdf',
          documentType: 'receipt',
        ),
      );

      await docRepo.createDocumentRecord(
        record: Record(
          id: 'doc-2',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'document',
          title: 'Microwave User Manual',
          createdAt: now,
          updatedAt: now,
        ),
        document: const DocumentItem(
          recordId: 'doc-2',
          fileName: 'manual.pdf',
          documentType: 'manual',
        ),
      );

      final receipts = await docRepo.getDocumentsByWorkspace(
        AppConstants.defaultWorkspaceId,
        documentType: 'receipt',
      );
      expect(receipts.length, 1);
      expect(receipts.first.record.title, 'Electric Stove Receipt');

      final manuals = await docRepo.getDocumentsByWorkspace(
        AppConstants.defaultWorkspaceId,
        documentType: 'manual',
      );
      expect(manuals.length, 1);
      expect(manuals.first.record.title, 'Microwave User Manual');
    });

    test('softDeleteDocument sets deletedAt and excludes document from active list', () async {
      final now = DateTime.now().toUtc();

      await docRepo.createDocumentRecord(
        record: Record(
          id: 'doc-temp',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'document',
          title: 'Temporary Doc',
          createdAt: now,
          updatedAt: now,
        ),
        document: const DocumentItem(recordId: 'doc-temp', fileName: 'temp.pdf'),
      );

      expect((await docRepo.getDocumentsByWorkspace(AppConstants.defaultWorkspaceId)).length, 1);

      await docRepo.softDeleteDocument('doc-temp');

      // Excluded from query
      expect((await docRepo.getDocumentsByWorkspace(AppConstants.defaultWorkspaceId)).length, 0);

      // Still in database with deletedAt timestamp set
      final rawRecord = await (db.select(db.records)..where((r) => r.id.equals('doc-temp'))).getSingle();
      expect(rawRecord.deletedAt, isNotNull);
    });

    test('Deleting an asset cascades setNull on linked document linkedAssetRecordId', () async {
      final now = DateTime.now().toUtc();

      await recordRepo.createAssetRecord(
        record: Record(
          id: 'parent-car',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Mazda CX-5',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'parent-car', brand: 'Mazda'),
      );

      await docRepo.createDocumentRecord(
        record: Record(
          id: 'doc-registration',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'document',
          title: 'Vehicle Registration',
          createdAt: now,
          updatedAt: now,
        ),
        document: const DocumentItem(
          recordId: 'doc-registration',
          fileName: 'registration.pdf',
          linkedAssetRecordId: 'parent-car',
        ),
      );

      var docs = await docRepo.getDocumentsByWorkspace(AppConstants.defaultWorkspaceId);
      expect(docs.first.linkedAssetTitle, 'Mazda CX-5');

      // Hard delete parent asset record
      await (db.delete(db.records)..where((r) => r.id.equals('parent-car'))).go();

      // Document still exists, but linkedAssetRecordId is cleared
      docs = await docRepo.getDocumentsByWorkspace(AppConstants.defaultWorkspaceId);
      expect(docs.length, 1);
      expect(docs.first.document.linkedAssetRecordId, isNull);
      expect(docs.first.linkedAssetTitle, isNull);
    });

    test('Soft-deleting an asset immediately decouples linkedAssetTitle from active document query', () async {
      final now = DateTime.now().toUtc();

      await recordRepo.createAssetRecord(
        record: Record(
          id: 'soft-del-asset',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Dell Laptop',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'soft-del-asset', brand: 'Dell'),
      );

      await docRepo.createDocumentRecord(
        record: Record(
          id: 'doc-invoice',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'document',
          title: 'Purchase Invoice',
          createdAt: now,
          updatedAt: now,
        ),
        document: const DocumentItem(
          recordId: 'doc-invoice',
          fileName: 'invoice.pdf',
          linkedAssetRecordId: 'soft-del-asset',
        ),
      );

      var docs = await docRepo.getDocumentsByWorkspace(AppConstants.defaultWorkspaceId);
      expect(docs.first.linkedAssetTitle, 'Dell Laptop');

      // Soft delete the asset
      await recordRepo.softDeleteRecord('soft-del-asset');

      // Linked asset title is null because the asset is now in trash
      docs = await docRepo.getDocumentsByWorkspace(AppConstants.defaultWorkspaceId);
      expect(docs.length, 1);
      expect(docs.first.linkedAssetTitle, isNull);
    });

    test('watchDocumentsByWorkspace emits updates reactively', () async {
      final stream = docRepo.watchDocumentsByWorkspace(AppConstants.defaultWorkspaceId);
      expect(
        stream,
        emitsInOrder([
          isEmpty,
          hasLength(1),
        ]),
      );

      final now = DateTime.now().toUtc();
      await docRepo.createDocumentRecord(
        record: Record(
          id: 'stream-doc',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'document',
          title: 'Stream Doc',
          createdAt: now,
          updatedAt: now,
        ),
        document: const DocumentItem(recordId: 'stream-doc', fileName: 'test.pdf'),
      );
    });
  });
}
