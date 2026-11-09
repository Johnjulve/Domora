import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/core/theme/app_theme.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/categories/domain/category.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/records/presentation/records_screen.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase inMemoryDb;

  final now = DateTime.utc(2026, 11, 9, 12, 0, 0);
  final testCategories = [
    Category(
      id: 'cat-appliances',
      workspaceId: AppConstants.defaultWorkspaceId,
      name: 'Appliances',
      iconKey: 'kitchen',
      colorHex: '#C97A63',
      isSystem: true,
      createdAt: now,
    ),
    Category(
      id: 'cat-electronics',
      workspaceId: AppConstants.defaultWorkspaceId,
      name: 'Electronics',
      iconKey: 'devices',
      colorHex: '#4A7C59',
      isSystem: true,
      createdAt: now,
    ),
    Category(
      id: 'cat-furniture',
      workspaceId: AppConstants.defaultWorkspaceId,
      name: 'Furniture',
      iconKey: 'chair',
      colorHex: '#78593A',
      isSystem: true,
      createdAt: now,
    ),
    Category(
      id: 'cat-properties',
      workspaceId: AppConstants.defaultWorkspaceId,
      name: 'Properties',
      iconKey: 'home',
      colorHex: '#2C5E43',
      isSystem: true,
      createdAt: now,
    ),
    Category(
      id: 'cat-tools',
      workspaceId: AppConstants.defaultWorkspaceId,
      name: 'Tools',
      iconKey: 'home_repair_service',
      colorHex: '#4A5568',
      isSystem: true,
      createdAt: now,
    ),
    Category(
      id: 'cat-vehicles',
      workspaceId: AppConstants.defaultWorkspaceId,
      name: 'Vehicles',
      iconKey: 'directions_car',
      colorHex: '#8C6D3F',
      isSystem: true,
      createdAt: now,
    ),
  ];

  setUp(() async {
    inMemoryDb = AppDatabase.forTesting(NativeDatabase.memory());
    await WorkspaceRepositoryImpl(inMemoryDb).getOrCreateDefaultWorkspace();
    await CategoryRepositoryImpl(inMemoryDb).seedDefaultCategories(AppConstants.defaultWorkspaceId);
  });

  tearDown(() async {
    await inMemoryDb.close();
  });

  Widget buildTestHarness({Widget? child}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(inMemoryDb),
        workspaceRepositoryProvider.overrideWithValue(WorkspaceRepositoryImpl(inMemoryDb)),
        categoryRepositoryProvider.overrideWithValue(CategoryRepositoryImpl(inMemoryDb)),
        recordRepositoryProvider.overrideWithValue(RecordRepositoryImpl(inMemoryDb)),
        defaultCategoriesStreamProvider.overrideWith((ref) => Stream.value(testCategories)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: child ?? const AddAssetSheet(),
        ),
      ),
    );
  }

  Future<void> flush(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('Flexible Asset Sheet & Category Templates', () {
    testWidgets('AddAssetSheet renders core common fields and currency selector', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      expect(find.text('New Asset Record'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Asset Title *'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Purchase Amount (PHP)'), findsOneWidget);
      expect(find.text('Warranty, Dates & Notes'), findsOneWidget);
      expect(find.text('Custom Fields (0)'), findsOneWidget);
      expect(find.text('Save Asset Record'), findsOneWidget);

      await flush(tester);
    });

    testWidgets('Category switching is non-destructive and preserves entered values', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      // Enter common title, brand, and model under General category
      await tester.enterText(find.widgetWithText(TextFormField, 'Asset Title *'), 'Universal Equipment');
      await tester.enterText(find.widgetWithText(TextFormField, 'Brand'), 'Bose');
      await tester.enterText(find.widgetWithText(TextFormField, 'Model'), 'QuietComfort 45');
      await tester.enterText(find.widgetWithText(TextFormField, 'Location'), 'Office Studio');
      await tester.pumpAndSettle();

      // Switch category to Vehicles (cat-vehicles)
      await tester.tap(find.text('General / Uncategorized'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vehicles').last);
      await tester.pumpAndSettle();

      // Verify Vehicle-specific template is visible
      expect(find.text('Vehicle PMS Limits & Odometer'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'License Plate'), findsOneWidget);

      // Verify Brand and Model values entered prior to category switch were preserved non-destructively
      expect(find.widgetWithText(TextFormField, 'Brand / Make'), findsOneWidget);
      final brandField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Brand / Make'));
      expect(brandField.controller?.text, 'Bose');

      final modelField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Model'));
      expect(modelField.controller?.text, 'QuietComfort 45');

      // Switch category to Properties (cat-properties)
      await tester.tap(find.text('Vehicles'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Properties').last);
      await tester.pumpAndSettle();

      // Verify Property template is active and location is preserved
      expect(find.text('Property Details'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Title / Deed Number'), findsOneWidget);
      final locationField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Address / Location'));
      expect(locationField.controller?.text, 'Office Studio');

      await flush(tester);
    });

    testWidgets('Vehicle template exposes odometer, PMS distance, and PMS time intervals', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      // Switch to Vehicles
      await tester.tap(find.text('General / Uncategorized'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vehicles').last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Starting / Current Odometer (km)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'PMS Distance (km)'), findsOneWidget);
      expect(find.text('PMS Time Limit'), findsOneWidget);

      await flush(tester);
    });

    testWidgets('Custom fields can be added and removed dynamically in AddAssetSheet', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      expect(find.text('Custom Fields (0)'), findsOneWidget);

      // Tap + Add Custom Field
      await tester.tap(find.text('+ Add Custom Field'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Fields (1)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Field Label'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Field Value'), findsOneWidget);

      // Enter custom field data
      await tester.enterText(find.widgetWithText(TextFormField, 'Field Label'), 'Color');
      await tester.enterText(find.widgetWithText(TextFormField, 'Field Value'), 'Matte Black');
      await tester.pumpAndSettle();

      // Tap remove button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Custom Fields (0)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Field Label'), findsNothing);

      await flush(tester);
    });

    testWidgets('Collapsible warranty and dates expand and allow picking dates', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      // Initially collapsed
      expect(find.text('Purchase Date'), findsNothing);
      expect(find.text('Warranty Expiry'), findsNothing);

      // Tap header to expand
      await tester.tap(find.text('Warranty, Dates & Notes'));
      await tester.pumpAndSettle();

      expect(find.text('Purchase Date'), findsOneWidget);
      expect(find.text('Warranty Expiry'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Notes / Description'), findsOneWidget);

      await flush(tester);
    });

    testWidgets('Non-vehicle asset submission does not save vehicle PMS fields or leak ghost category fields', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      // Switch to Properties and enter Deed Number
      await tester.tap(find.text('General / Uncategorized'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Properties').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Title / Deed Number'), 'DEED-9988');
      await tester.pumpAndSettle();

      // Switch to Appliances (non-property, non-vehicle)
      await tester.tap(find.text('Properties'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appliances').last);
      await tester.pumpAndSettle();

      // Enter Title, Brand, Model for Appliance
      await tester.enterText(find.widgetWithText(TextFormField, 'Asset Title *'), 'Dyson Supersonic Hair Dryer');
      await tester.enterText(find.widgetWithText(TextFormField, 'Brand'), 'Dyson');
      await tester.enterText(find.widgetWithText(TextFormField, 'Model'), 'HD08');

      // Submit form
      await tester.ensureVisible(find.text('Save Asset Record'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Asset Record'));
      await tester.pumpAndSettle();

      // Query database directly
      final assets = await inMemoryDb.select(inMemoryDb.assets).get();
      expect(assets.length, 1);
      final asset = assets.first;

      // Assert non-vehicle asset has NO vehicle PMS data despite _pmsDistanceController defaulting to 5000
      expect(asset.odometerReading, isNull);
      expect(asset.pmsDistanceIntervalKm, isNull);
      expect(asset.pmsTimeIntervalMonths, isNull);
      expect(asset.nextPmsDueDate, isNull);
      expect(asset.nextPmsOdometerTarget, isNull);

      // Assert ghost deed number was NOT saved as custom field because category was switched to Appliances
      final customFieldVals = await inMemoryDb.select(inMemoryDb.fieldValues).get();
      expect(customFieldVals, isEmpty);

      await flush(tester);
    });
  });

  group('Record Repository Currency & Custom Fields Persistence', () {
    test('Can save asset with explicit currency and custom fields round-trip', () async {
      final recordRepo = RecordRepositoryImpl(inMemoryDb);
      final futureWarranty = DateTime.utc(2030, 11, 9, 10, 0, 0);

      const recordId = 'rec-custom-cur-1';
      await recordRepo.createAssetRecord(
        record: Record(
          id: recordId,
          workspaceId: AppConstants.defaultWorkspaceId,
          categoryId: 'cat-electronics',
          recordType: 'asset',
          title: 'Dell UltraSharp 32" Monitor',
          description: 'Purchased for workstation setup',
          createdAt: now,
          updatedAt: now,
        ),
        asset: Asset(
          recordId: recordId,
          brand: 'Dell',
          model: 'U3223QE',
          purchaseAmountMinor: 89900, // 899.00 USD
          purchaseCurrency: 'USD',
          purchaseDate: now,
          warrantyExpiryDate: futureWarranty,
          condition: 'Mint',
        ),
        customFields: {
          'Resolution': '4K UHD (3840 x 2160)',
          'Panel Type': 'IPS Black',
        },
      );

      final retrieved = await recordRepo.getRecordWithAsset(recordId);
      expect(retrieved, isNotNull);
      expect(retrieved!.record.title, 'Dell UltraSharp 32" Monitor');
      expect(retrieved.asset?.brand, 'Dell');
      expect(retrieved.asset?.purchaseCurrency, 'USD');
      expect(retrieved.asset?.purchaseAmountMinor, 89900);
      expect(retrieved.asset?.warrantyExpiryDate?.toUtc(), futureWarranty);

      // Verify custom field entries
      expect(retrieved.customFields.length, 2);
      final resolutionField = retrieved.customFields.firstWhere((cf) => cf.definition.label == 'Resolution');
      expect(resolutionField.value.valueText, '4K UHD (3840 x 2160)');

      final panelField = retrieved.customFields.firstWhere((cf) => cf.definition.label == 'Panel Type');
      expect(panelField.value.valueText, 'IPS Black');
    });
  });
}
