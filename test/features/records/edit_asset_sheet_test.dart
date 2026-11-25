import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/core/theme/app_theme.dart';
import 'package:domora/features/bills/data/bill_repository_impl.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/expenses/data/expense_repository_impl.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/records/presentation/records_screen.dart';
import 'package:domora/features/records/presentation/widgets/edit_asset_sheet.dart';
import 'package:domora/features/tasks/data/task_repository_impl.dart';
import 'package:domora/features/vault/data/document_repository_impl.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase db;
  late CategoryRepositoryImpl categoryRepo;
  late RecordRepositoryImpl recordRepo;
  late BillRepositoryImpl billRepo;
  late ExpenseRepositoryImpl expenseRepo;
  late TaskRepositoryImpl taskRepo;
  late DocumentRepositoryImpl documentRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final wsRepo = WorkspaceRepositoryImpl(db);
    categoryRepo = CategoryRepositoryImpl(db);
    recordRepo = RecordRepositoryImpl(db);
    billRepo = BillRepositoryImpl(db);
    expenseRepo = ExpenseRepositoryImpl(db);
    taskRepo = TaskRepositoryImpl(db);
    documentRepo = DocumentRepositoryImpl(db);

    await wsRepo.getOrCreateDefaultWorkspace();
    await categoryRepo.seedDefaultCategories(AppConstants.defaultWorkspaceId);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildApp(Widget home, {ThemeMode themeMode = ThemeMode.light}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        workspaceRepositoryProvider.overrideWithValue(WorkspaceRepositoryImpl(db)),
        categoryRepositoryProvider.overrideWithValue(categoryRepo),
        recordRepositoryProvider.overrideWithValue(recordRepo),
        billRepositoryProvider.overrideWithValue(billRepo),
        expenseRepositoryProvider.overrideWithValue(expenseRepo),
        taskRepositoryProvider.overrideWithValue(taskRepo),
        documentRepositoryProvider.overrideWithValue(documentRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: home,
      ),
    );
  }

  Future<void> flush(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('RecordRepositoryImpl.updateAssetRecord', () {
    test(
      'atomically updates mutable fields & syncs custom fields while preserving locked hardware identity and category',
      () async {
        final now = DateTime.utc(2026, 5, 1);
        await recordRepo.createAssetRecord(
          record: Record(
            id: 'asset-lock-1',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-vehicles',
            recordType: 'asset',
            title: 'Honda V4',
            description: 'Initial notes',
            createdAt: now,
            updatedAt: now,
          ),
          asset: Asset(
            recordId: 'asset-lock-1',
            brand: 'Honda',
            model: 'V4',
            serialNumber: 'VIN-LOCKED-001',
            condition: 'Good',
            locationDescription: 'Garage A',
            purchaseAmountMinor: 1200000,
            purchaseCurrency: 'PHP',
            odometerReading: 729,
            pmsDistanceIntervalKm: 1000,
            pmsTimeIntervalMonths: 6,
            nextPmsOdometerTarget: 1729,
            nextPmsDueDate: DateTime.utc(2026, 11, 1),
          ),
          customFields: const {
            'License Plate': 'ABC-123',
            'Stale Field': 'Remove Me',
          },
        );

        // Attempt to mutate locked fields alongside valid edits
        await recordRepo.updateAssetRecord(
          record: Record(
            id: 'asset-lock-1',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-electronics', // must remain locked to cat-vehicles
            recordType: 'bill', // must remain locked to asset
            title: 'Honda V4 Touring',
            description: 'Updated notes',
            createdAt: now,
            updatedAt: now,
          ),
          asset: Asset(
            recordId: 'asset-lock-1',
            brand: 'TAMPERED', // must remain Honda
            model: 'TAMPERED', // must remain V4
            serialNumber: 'TAMPERED', // must remain VIN-LOCKED-001
            condition: 'Needs Repair',
            locationDescription: 'Covered Slot B2',
            purchaseAmountMinor: 1550000,
            purchaseCurrency: 'PHP',
            odometerReading: 1200,
            pmsDistanceIntervalKm: 1500,
            pmsTimeIntervalMonths: 3,
            nextPmsOdometerTarget: 2700,
            nextPmsDueDate: DateTime.utc(2026, 8, 1),
          ),
          customFields: const {
            'License Plate': 'XYZ-789',
            'Insurance Policy': 'POL-555',
            'Empty Value': '   ', // must be ignored
          },
        );

        final refreshed = await recordRepo.getRecordWithAsset('asset-lock-1');
        expect(refreshed, isNotNull);

        // Locked identity preserved
        expect(refreshed!.record.categoryId, 'cat-vehicles');
        expect(refreshed.record.recordType, 'asset');
        expect(refreshed.asset!.brand, 'Honda');
        expect(refreshed.asset!.model, 'V4');
        expect(refreshed.asset!.serialNumber, 'VIN-LOCKED-001');

        // Editable attributes updated
        expect(refreshed.record.title, 'Honda V4 Touring');
        expect(refreshed.record.description, 'Updated notes');
        expect(refreshed.asset!.condition, 'Needs Repair');
        expect(refreshed.asset!.locationDescription, 'Covered Slot B2');
        expect(refreshed.asset!.purchaseAmountMinor, 1550000);
        expect(refreshed.asset!.odometerReading, 1200);
        expect(refreshed.asset!.pmsDistanceIntervalKm, 1500);
        expect(refreshed.asset!.pmsTimeIntervalMonths, 3);
        expect(refreshed.asset!.nextPmsOdometerTarget, 2700);

        // Custom fields synchronized (updated + added + removed stale)
        final cfMap = {
          for (final cf in refreshed.customFields) cf.definition.label: cf.value.valueText,
        };
        expect(cfMap, equals({'License Plate': 'XYZ-789', 'Insurance Policy': 'POL-555'}));
      },
    );

    test('throws StateError when updating missing or soft-deleted record', () async {
      final now = DateTime.utc(2026, 5, 1);
      expect(
        () => recordRepo.updateAssetRecord(
          record: Record(
            id: 'missing-id',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'asset',
            title: 'Ghost',
            createdAt: now,
            updatedAt: now,
          ),
          asset: const Asset(recordId: 'missing-id'),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws StateError on non-asset record without inserting an Assets row', () async {
      final now = DateTime.utc(2026, 5, 1);
      await recordRepo.createRecord(
        Record(
          id: 'task-standalone-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'task',
          title: 'Renew Driver License',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await expectLater(
        recordRepo.updateAssetRecord(
          record: Record(
            id: 'task-standalone-1',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'task',
            title: 'Updated Task',
            createdAt: now,
            updatedAt: now,
          ),
          asset: const Asset(recordId: 'task-standalone-1'),
        ),
        throwsA(isA<StateError>()),
      );

      final assetRows = await (db.select(db.assets)
            ..where((a) => a.recordId.equals('task-standalone-1')))
          .get();
      expect(assetRows, isEmpty);
    });
  });

  group('EditAssetSheet & Reactive AssetDetailSheet Widget Tests', () {
    testWidgets(
      'edits Vehicle from AssetDetailSheet with locked Brand/Model/Serial and updates detail view reactively',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.utc(2026, 5, 1);
        final created = await recordRepo.createAssetRecord(
          record: Record(
            id: 'veh-honda-v4',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-vehicles',
            recordType: 'asset',
            title: 'Honda V4',
            createdAt: now,
            updatedAt: now,
          ),
          asset: Asset(
            recordId: 'veh-honda-v4',
            brand: 'Honda',
            model: 'V4',
            serialNumber: 'VIN-HONDA-9988',
            condition: 'Good',
            locationDescription: 'Garage A',
            purchaseAmountMinor: 1200000,
            purchaseCurrency: 'PHP',
            odometerReading: 729,
            pmsDistanceIntervalKm: 1000,
            pmsTimeIntervalMonths: 6,
            nextPmsOdometerTarget: 1729,
            nextPmsDueDate: DateTime.utc(2026, 11, 1),
          ),
          customFields: const {'License Plate': 'OLD-123'},
        );

        await tester.pumpWidget(
          buildApp(Scaffold(body: AssetDetailSheet(item: created))),
        );
        await tester.pumpAndSettle();

        // Initial formatted PMS interval uses comma & full word 'months'
        expect(find.text('1,000 km or 6 months'), findsOneWidget);
        expect(find.byKey(const Key('edit_asset_button')), findsOneWidget);

        // Open EditAssetSheet
        await tester.tap(find.byKey(const Key('edit_asset_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('edit_asset_sheet')), findsOneWidget);
        expect(find.byKey(const Key('locked_identity_card')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('locked_identity_card')),
            matching: find.text('Honda'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('locked_identity_card')),
            matching: find.text('V4'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('locked_identity_card')),
            matching: find.text('VIN-HONDA-9988'),
          ),
          findsOneWidget,
        );

        // Edit Condition -> Needs Repair
        await tester.tap(find.byKey(const Key('edit_asset_condition_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Needs Repair').last);
        await tester.pumpAndSettle();

        // Edit Location, License Plate, Odometer, PMS Distance, PMS Time, Estimated Value
        await tester.enterText(
          find.byKey(const Key('edit_asset_location_field')),
          'Covered Slot B2',
        );
        await tester.enterText(
          find.byKey(const Key('edit_asset_license_plate_field')),
          'NEW-456',
        );
        await tester.enterText(
          find.byKey(const Key('edit_asset_odometer_field')),
          '1200',
        );
        await tester.enterText(
          find.byKey(const Key('edit_asset_pms_distance_field')),
          '1500',
        );

        await tester.ensureVisible(find.byKey(const Key('edit_asset_pms_time_dropdown')));
        await tester.tap(find.byKey(const Key('edit_asset_pms_time_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('3 months').last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(const Key('edit_asset_amount_field')));
        await tester.enterText(
          find.byKey(const Key('edit_asset_amount_field')),
          '15500.00',
        );

        // Save changes
        await tester.ensureVisible(find.byKey(const Key('edit_asset_save_button')));
        await tester.tap(find.byKey(const Key('edit_asset_save_button')));
        await tester.pumpAndSettle();

        // Edit sheet closes and AssetDetailSheet updates reactively
        expect(find.byKey(const Key('edit_asset_sheet')), findsNothing);
        expect(find.text('Needs Repair'), findsOneWidget);
        expect(find.text('Covered Slot B2'), findsOneWidget);
        expect(find.text('1,200 km'), findsOneWidget);
        expect(find.text('1,500 km or 3 months'), findsOneWidget);
        expect(find.textContaining('2,700 km'), findsOneWidget);
        expect(find.text('PHP 15,500.00'), findsOneWidget);
        expect(find.text('NEW-456'), findsOneWidget);

        // Locked hardware identity remains intact
        expect(find.text('Honda'), findsOneWidget);
        expect(find.text('V4'), findsOneWidget);
        expect(find.text('VIN-HONDA-9988'), findsOneWidget);

        await flush(tester);
      },
    );

    testWidgets(
      'preserves Next Target PMS when editing a brand-new 0 km vehicle',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.utc(2026, 5, 1);
        final created = await recordRepo.createAssetRecord(
          record: Record(
            id: 'veh-zero-km',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-vehicles',
            recordType: 'asset',
            title: 'New Scooter',
            createdAt: now,
            updatedAt: now,
          ),
          asset: Asset(
            recordId: 'veh-zero-km',
            brand: 'Yamaha',
            model: 'NMAX',
            condition: 'Mint',
            odometerReading: 0,
            pmsDistanceIntervalKm: 1000,
            pmsTimeIntervalMonths: 6,
            nextPmsOdometerTarget: 1000,
            nextPmsDueDate: DateTime.utc(2026, 11, 1),
          ),
        );

        await tester.pumpWidget(
          buildApp(Scaffold(body: AssetDetailSheet(item: created))),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('edit_asset_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('edit_asset_location_field')),
          'Main Garage',
        );
        await tester.ensureVisible(find.byKey(const Key('edit_asset_save_button')));
        await tester.tap(find.byKey(const Key('edit_asset_save_button')));
        await tester.pumpAndSettle();

        final refreshed = await recordRepo.getRecordWithAsset('veh-zero-km');
        expect(refreshed?.asset?.odometerReading, 0);
        expect(refreshed?.asset?.nextPmsOdometerTarget, 1000);
        expect(find.textContaining('1,000 km'), findsWidgets);

        await flush(tester);
      },
    );

    testWidgets(
      'hides Edit button on non-asset records and disables Edit + surfaces error when custom fields fail to load',
      (tester) async {
        final now = DateTime.utc(2026, 5, 1);
        final taskRecord = RecordWithAsset(
          record: Record(
            id: 'task-view-1',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'task',
            title: 'Standalone Task',
            createdAt: now,
            updatedAt: now,
          ),
        );

        await tester.pumpWidget(
          buildApp(Scaffold(body: AssetDetailSheet(item: taskRecord))),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('edit_asset_button')), findsNothing);

        await flush(tester);

        final assetItem = RecordWithAsset(
          record: Record(
            id: 'asset-err-1',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-electronics',
            recordType: 'asset',
            title: 'Laptop',
            createdAt: now,
            updatedAt: now,
          ),
          asset: const Asset(recordId: 'asset-err-1', condition: 'Good'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              workspaceRepositoryProvider.overrideWithValue(WorkspaceRepositoryImpl(db)),
              categoryRepositoryProvider.overrideWithValue(categoryRepo),
              recordRepositoryProvider.overrideWithValue(recordRepo),
              billRepositoryProvider.overrideWithValue(billRepo),
              expenseRepositoryProvider.overrideWithValue(expenseRepo),
              taskRepositoryProvider.overrideWithValue(taskRepo),
              documentRepositoryProvider.overrideWithValue(documentRepo),
              recordCustomFieldsProvider('asset-err-1').overrideWith(
                (ref) => Future<List<CustomFieldEntry>>.error(Exception('disk read failed')),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(body: AssetDetailSheet(item: assetItem)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Custom Fields'), findsOneWidget);
        expect(find.text('Failed to load'), findsOneWidget);
        final editBtn = tester.widget<IconButton>(find.byKey(const Key('edit_asset_button')));
        expect(editBtn.onPressed, isNull);

        await flush(tester);
      },
    );

    testWidgets(
      'edits Family Member record with Family template fields and updates AssetDetailSheet without duplicate notes',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.utc(2026, 5, 1);
        final created = await recordRepo.createAssetRecord(
          record: Record(
            id: 'fam-elena-1',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-family',
            recordType: 'asset',
            title: 'Elena Cruz',
            description: 'Peanut allergy',
            createdAt: now,
            updatedAt: now,
          ),
          asset: const Asset(recordId: 'fam-elena-1'),
          customFields: const {
            'Relationship': 'Spouse',
            'Blood Type': 'O+',
            'Contact / Emergency Phone': '+63 917 000 1111',
            'Medical Notes & Allergies': 'Peanut allergy',
          },
        );

        await tester.pumpWidget(
          buildApp(Scaffold(body: AssetDetailSheet(item: created))),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('edit_asset_button')));
        await tester.pumpAndSettle();

        // Family template fields shown; non-Family fields hidden
        expect(find.byKey(const Key('edit_family_relationship_dropdown')), findsOneWidget);
        expect(find.byKey(const Key('edit_family_phone_field')), findsOneWidget);
        expect(find.byKey(const Key('edit_family_medical_notes_field')), findsOneWidget);
        expect(find.byKey(const Key('edit_asset_condition_dropdown')), findsNothing);
        expect(find.byKey(const Key('edit_asset_amount_field')), findsNothing);

        // Update phone & medical notes
        await tester.enterText(
          find.byKey(const Key('edit_family_phone_field')),
          '+63 917 999 8888',
        );
        await tester.enterText(
          find.byKey(const Key('edit_family_medical_notes_field')),
          'No known allergies; asthma inhaler',
        );

        await tester.ensureVisible(find.byKey(const Key('edit_asset_save_button')));
        await tester.tap(find.byKey(const Key('edit_asset_save_button')));
        await tester.pumpAndSettle();

        // AssetDetailSheet updates live without duplicating Notes / Description
        expect(find.text('+63 917 999 8888'), findsOneWidget);
        expect(find.text('No known allergies; asthma inhaler'), findsOneWidget);
        expect(find.text('Notes / Description'), findsNothing);

        await flush(tester);
      },
    );

    testWidgets(
      'renders EditAssetSheet with zero RenderFlex overflow at 360x800 in both Light and Dark mode',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.utc(2026, 5, 1);
        final vehicle = RecordWithAsset(
          record: Record(
            id: 'veh-narrow-1',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-vehicles',
            recordType: 'asset',
            title: 'Toyota Fortuner LTD 4x4',
            createdAt: now,
            updatedAt: now,
          ),
          asset: const Asset(
            recordId: 'veh-narrow-1',
            brand: 'Toyota',
            model: 'Fortuner LTD',
            serialNumber: 'VIN-LONG-998877665544',
            condition: 'Good',
            purchaseAmountMinor: 245000000,
            purchaseCurrency: 'PHP',
            odometerReading: 18500,
            pmsDistanceIntervalKm: 5000,
            pmsTimeIntervalMonths: 6,
          ),
        );

        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          await tester.pumpWidget(
            buildApp(
              Scaffold(
                body: EditAssetSheet(
                  item: vehicle,
                  initialCustomFields: const [],
                  categoryName: 'Vehicles',
                ),
              ),
              themeMode: mode,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final expectedScheme =
              mode == ThemeMode.dark ? AppTheme.darkTheme.colorScheme : AppTheme.lightTheme.colorScheme;
          final saveBtn = tester.widget<ElevatedButton>(
            find.byKey(const Key('edit_asset_save_button')),
          );
          expect(saveBtn.style?.backgroundColor?.resolve({}), equals(expectedScheme.primary));
          expect(saveBtn.style?.foregroundColor?.resolve({}), equals(expectedScheme.onPrimary));
        }

        await flush(tester);
      },
    );
  });
}
