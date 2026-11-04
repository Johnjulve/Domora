import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:domora/features/workspaces/domain/workspace.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late RecordRepository recordRepository;
  late WorkspaceRepository workspaceRepository;
  late CategoryRepositoryImpl categoryRepository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    recordRepository = RecordRepositoryImpl(db);
    workspaceRepository = WorkspaceRepositoryImpl(db);
    categoryRepository = CategoryRepositoryImpl(db);

    // Bootstrap default personal workspace and system categories
    await workspaceRepository.getOrCreateDefaultWorkspace();
    await categoryRepository.seedDefaultCategories(AppConstants.defaultWorkspaceId);
  });

  tearDown(() async {
    await db.close();
  });

  group('RecordRepositoryImpl Tests', () {
    test('Can create standalone universal record and retrieve it', () async {
      final now = DateTime.utc(2026, 11, 4, 12, 0, 0);
      final record = Record(
        id: 'rec-generic-1',
        workspaceId: AppConstants.defaultWorkspaceId,
        recordType: 'note',
        title: 'Meeting Notes',
        description: 'Discussion on household maintenance schedule',
        createdAt: now,
        updatedAt: now,
      );

      final created = await recordRepository.createRecord(record);
      expect(created.id, record.id);
      expect(created.title, 'Meeting Notes');

      final retrieved = await recordRepository.getRecordWithAsset('rec-generic-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.record.title, 'Meeting Notes');
      expect(retrieved.asset, isNull);
    });

    test('Can atomically create Record with Asset details', () async {
      final now = DateTime.utc(2026, 11, 4, 12, 0, 0);
      const recordId = 'rec-asset-100';

      final record = Record(
        id: recordId,
        workspaceId: AppConstants.defaultWorkspaceId,
        recordType: 'asset',
        title: 'Sony Bravia 65" 4K OLED',
        createdAt: now,
        updatedAt: now,
      );

      final asset = Asset(
        recordId: recordId,
        brand: 'Sony',
        model: 'A80L',
        serialNumber: 'SN-998877',
        purchaseAmountMinor: 11000000, // 110,000.00 PHP
        purchaseCurrency: 'PHP',
        condition: 'Mint',
        locationDescription: 'Living Room',
      );

      final result = await recordRepository.createAssetRecord(
        record: record,
        asset: asset,
      );

      expect(result.record.id, recordId);
      expect(result.asset, isNotNull);
      expect(result.asset!.brand, 'Sony');
      expect(result.asset!.purchaseAmountMinor, 11000000);

      // Verify retrieval through getRecordWithAsset
      final retrieved = await recordRepository.getRecordWithAsset(recordId);
      expect(retrieved, isNotNull);
      expect(retrieved!.record.title, 'Sony Bravia 65" 4K OLED');
      expect(retrieved.asset!.model, 'A80L');
      expect(retrieved.asset!.locationDescription, 'Living Room');
    });

    test('Querying active records filters by workspace and recordType', () async {
      final now = DateTime.utc(2026, 11, 4, 12, 0, 0);

      // Create an asset record
      await recordRepository.createAssetRecord(
        record: Record(
          id: 'rec-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Dyson V15 Vacuum',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'rec-1', brand: 'Dyson'),
      );

      // Create a document record
      await recordRepository.createRecord(
        Record(
          id: 'rec-2',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'document',
          title: 'Insurance Policy PDF',
          createdAt: now.add(const Duration(minutes: 5)),
          updatedAt: now.add(const Duration(minutes: 5)),
        ),
      );

      // Query all records in workspace
      final all = await recordRepository.getActiveRecordsByWorkspace(AppConstants.defaultWorkspaceId);
      expect(all.length, 2);

      // Filter by recordType 'asset'
      final assetsOnly = await recordRepository.getActiveRecordsByWorkspace(
        AppConstants.defaultWorkspaceId,
        recordType: 'asset',
      );
      expect(assetsOnly.length, 1);
      expect(assetsOnly.first.record.title, 'Dyson V15 Vacuum');
      expect(assetsOnly.first.asset, isNotNull);

      // Filter by recordType 'document'
      final docsOnly = await recordRepository.getActiveRecordsByWorkspace(
        AppConstants.defaultWorkspaceId,
        recordType: 'document',
      );
      expect(docsOnly.length, 1);
      expect(docsOnly.first.record.title, 'Insurance Policy PDF');
      expect(docsOnly.first.asset, isNull);
    });

    test('Soft deleting a record excludes it from active queries and details', () async {
      final now = DateTime.utc(2026, 11, 4, 12, 0, 0);
      const recordId = 'rec-to-soft-delete';

      await recordRepository.createAssetRecord(
        record: Record(
          id: recordId,
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Old Microwave',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: recordId, brand: 'Samsung'),
      );

      expect((await recordRepository.getActiveRecordsByWorkspace(AppConstants.defaultWorkspaceId)).length, 1);

      // Soft delete
      await recordRepository.softDeleteRecord(recordId);

      // Active records should now be empty
      final active = await recordRepository.getActiveRecordsByWorkspace(AppConstants.defaultWorkspaceId);
      expect(active.isEmpty, isTrue);

      // getRecordWithAsset should return null for soft-deleted record
      final detail = await recordRepository.getRecordWithAsset(recordId);
      expect(detail, isNull);
    });

    test('Can update Asset metadata and Record details independently', () async {
      final now = DateTime.utc(2026, 11, 4, 12, 0, 0);
      const recordId = 'rec-update-test';

      await recordRepository.createAssetRecord(
        record: Record(
          id: recordId,
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Refrigerator',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(
          recordId: recordId,
          brand: 'LG',
          condition: 'Good',
          locationDescription: 'Kitchen',
        ),
      );

      // Update asset location and condition
      await recordRepository.updateAsset(
        const Asset(
          recordId: recordId,
          brand: 'LG',
          condition: 'Repaired',
          locationDescription: 'Basement Storage',
        ),
      );

      final updated = await recordRepository.getRecordWithAsset(recordId);
      expect(updated!.asset!.condition, 'Repaired');
      expect(updated.asset!.locationDescription, 'Basement Storage');
    });

    test('watchActiveRecordsByWorkspace emits changes reactively', () async {
      final stream = recordRepository.watchActiveRecordsByWorkspace(AppConstants.defaultWorkspaceId);

      expectLater(
        stream,
        emitsThrough(hasLength(1)),
      );

      final now = DateTime.utc(2026, 11, 4, 12, 0, 0);
      await recordRepository.createRecord(
        Record(
          id: 'rec-stream-test',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Reactive TV',
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    test('Querying active records filters by categoryId', () async {
      final now = DateTime.utc(2026, 11, 4, 12, 0, 0);

      await recordRepository.createAssetRecord(
        record: Record(
          id: 'rec-cat-appliances',
          workspaceId: AppConstants.defaultWorkspaceId,
          categoryId: 'cat-appliances',
          recordType: 'asset',
          title: 'Bosch Series 8 Dishwasher',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'rec-cat-appliances', brand: 'Bosch'),
      );

      await recordRepository.createAssetRecord(
        record: Record(
          id: 'rec-cat-vehicles',
          workspaceId: AppConstants.defaultWorkspaceId,
          categoryId: 'cat-vehicles',
          recordType: 'asset',
          title: 'Mazda CX-5',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'rec-cat-vehicles', brand: 'Mazda'),
      );

      final appliances = await recordRepository.getActiveRecordsByWorkspace(
        AppConstants.defaultWorkspaceId,
        categoryId: 'cat-appliances',
      );
      expect(appliances.length, 1);
      expect(appliances.first.record.title, 'Bosch Series 8 Dishwasher');

      final vehicles = await recordRepository.getActiveRecordsByWorkspace(
        AppConstants.defaultWorkspaceId,
        categoryId: 'cat-vehicles',
      );
      expect(vehicles.length, 1);
      expect(vehicles.first.record.title, 'Mazda CX-5');
    });

    test('Querying active records searches across title, brand, model, and location', () async {
      final now = DateTime.utc(2026, 11, 4, 12, 0, 0);

      await recordRepository.createAssetRecord(
        record: Record(
          id: 'rec-search-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Workstation Laptop',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(
          recordId: 'rec-search-1',
          brand: 'Apple',
          model: 'MacBook Pro 16',
          serialNumber: 'C02XYZ999',
          locationDescription: 'Attic Office',
        ),
      );

      // Match by title
      final matchTitle = await recordRepository.getActiveRecordsByWorkspace(
        AppConstants.defaultWorkspaceId,
        searchQuery: 'laptop',
      );
      expect(matchTitle.length, 1);

      // Match by brand
      final matchBrand = await recordRepository.getActiveRecordsByWorkspace(
        AppConstants.defaultWorkspaceId,
        searchQuery: 'apple',
      );
      expect(matchBrand.length, 1);

      // Match by model
      final matchModel = await recordRepository.getActiveRecordsByWorkspace(
        AppConstants.defaultWorkspaceId,
        searchQuery: 'macbook',
      );
      expect(matchModel.length, 1);

      // Match by serial number
      final matchSerial = await recordRepository.getActiveRecordsByWorkspace(
        AppConstants.defaultWorkspaceId,
        searchQuery: 'XYZ999',
      );
      expect(matchSerial.length, 1);

      // Match by location
      final matchLoc = await recordRepository.getActiveRecordsByWorkspace(
        AppConstants.defaultWorkspaceId,
        searchQuery: 'attic',
      );
      expect(matchLoc.length, 1);

      // Non-matching query returns empty
      final noMatch = await recordRepository.getActiveRecordsByWorkspace(
        AppConstants.defaultWorkspaceId,
        searchQuery: 'NonExistentThing',
      );
      expect(noMatch.isEmpty, isTrue);
    });
  });
}
