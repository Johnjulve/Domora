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
import 'package:domora/features/tasks/data/task_repository_impl.dart';
import 'package:domora/features/vault/data/document_repository_impl.dart';
import 'package:domora/features/vault/domain/document_item.dart';
import 'package:domora/features/vault/domain/vault_asset_matcher.dart';
import 'package:domora/features/vault/presentation/vault_screen.dart';
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

  group('VaultAssetMatcher Unit Tests', () {
    final now = DateTime.utc(2026, 11, 25);

    VaultAssetCandidate makeCandidate({
      required String id,
      required String title,
      String? brand,
      String? model,
      String? serialNumber,
      String? licensePlate,
    }) {
      return VaultAssetCandidate(
        asset: RecordWithAsset(
          record: Record(
            id: id,
            workspaceId: 'ws-1',
            categoryId: 'cat-vehicles',
            recordType: 'asset',
            title: title,
            createdAt: now,
            updatedAt: now,
          ),
          asset: Asset(
            recordId: id,
            brand: brand,
            model: model,
            serialNumber: serialNumber,
          ),
        ),
        licensePlate: licensePlate,
      );
    }

    test('matches exact License Plate across hyphens, spaces, compact codes, and filenames while rejecting embedded codes and short plates', () {
      final vehicle = makeCandidate(
        id: 'veh-1',
        title: 'Honda Civic',
        brand: 'Honda',
        model: 'Civic',
        licensePlate: 'ABC-1234',
      );
      final shortPlateVehicle = makeCandidate(
        id: 'veh-short',
        title: 'Mini Bike',
        licensePlate: 'A12',
      );

      for (final fileName in ['ORCR_ABC-1234.pdf', 'ABC 1234 insurance.jpg', 'ABC1234.pdf']) {
        final matches = VaultAssetMatcher.findMatchingAssetsForDocument(
          title: 'Vehicle Document',
          fileName: fileName,
          candidates: [vehicle, shortPlateVehicle],
        );
        expect(matches, hasLength(1), reason: 'Expected match for $fileName');
        expect(matches.first.asset.record.id, 'veh-1');
        expect(matches.first.confidence, VaultMatchConfidence.exactIdentifier);
        expect(matches.first.score, 100);
        expect(matches.first.shouldAutoPreselect, isTrue);
        expect(matches.first.reason, 'Matched Plate: ABC-1234');
      }

      // Boundary-safe rejection of longer unrelated alphanumeric strings
      for (final badName in ['XABC1234.pdf', 'ABC-12345.pdf', '1ABC12349.pdf', 'A12_doc.pdf']) {
        final matches = VaultAssetMatcher.findMatchingAssetsForDocument(
          title: 'Unrelated',
          fileName: badName,
          candidates: [vehicle, shortPlateVehicle],
        );
        expect(matches, isEmpty, reason: 'Expected no match for $badName');
      }

      // Must NOT bridge across newline boundary between title and fileName
      final carPlate = makeCandidate(
        id: 'veh-car',
        title: 'Sedan',
        licensePlate: 'CAR-1234',
      );
      final crossField = VaultAssetMatcher.findMatchingAssetsForDocument(
        title: 'My Car',
        fileName: '1234.pdf',
        candidates: [carPlate],
      );
      expect(crossField, isEmpty);
    });

    test('matches Serial / VIN (len >= 5), Brand + Model without short-token false positives, and Title', () {
      final tv = makeCandidate(
        id: 'tv-1',
        title: 'Living Room OLED',
        brand: 'LG',
        model: 'C3',
        serialNumber: 'SN-49281-XY',
      );
      final moto = makeCandidate(
        id: 'moto-1',
        title: 'Yamaha NMAX',
        brand: 'Yamaha',
        model: 'NMAX 155',
        serialNumber: '1234', // too short (< 5)
      );

      // Exact serial match
      final serialMatches = VaultAssetMatcher.findMatchingAssetsForDocument(
        title: 'Warranty Card',
        fileName: 'warranty_SN49281XY.pdf',
        candidates: [tv, moto],
      );
      expect(serialMatches, hasLength(1));
      expect(serialMatches.first.score, 95);
      expect(serialMatches.first.shouldAutoPreselect, isTrue);
      expect(serialMatches.first.reason, 'Matched Serial: SN-49281-XY');

      // Brand + Model match (2-char whole tokens accepted, substrings rejected)
      final bmMatches = VaultAssetMatcher.findMatchingAssetsForDocument(
        title: 'LG C3 Manual',
        fileName: 'manual.pdf',
        candidates: [tv, moto],
      );
      expect(bmMatches, hasLength(1));
      expect(bmMatches.first.score, 80);
      expect(bmMatches.first.shouldAutoPreselect, isFalse);
      expect(bmMatches.first.reason, 'Matched Brand & Model: LG C3');

      final falsePositiveCheck = VaultAssetMatcher.findMatchingAssetsForDocument(
        title: 'ALGAE EC300 Report',
        fileName: 'lab_1234.pdf',
        candidates: [tv, moto],
      );
      expect(falsePositiveCheck, isEmpty);

      // Title match
      final titleMatches = VaultAssetMatcher.findMatchingAssetsForDocument(
        title: 'Yamaha NMAX Insurance Policy',
        fileName: 'policy.pdf',
        candidates: [tv, moto],
      );
      expect(titleMatches, hasLength(1));
      expect(titleMatches.first.score, 60);
      expect(titleMatches.first.confidence, VaultMatchConfidence.titleMatch);
      expect(titleMatches.first.reason, 'Matched Name: Yamaha NMAX');
    });

    test('ranks by priority score descending (max 3) and filters unlinked documents for asset', () {
      final candidates = [
        makeCandidate(id: 'a-title', title: 'Civic Sedan'),
        makeCandidate(id: 'a-bm', title: 'Car B', brand: 'Honda', model: 'Civic'),
        makeCandidate(id: 'a-serial', title: 'Car C', serialNumber: 'VIN998877'),
        makeCandidate(id: 'a-plate', title: 'Car D', licensePlate: 'XYZ-9012'),
      ];

      final ranked = VaultAssetMatcher.findMatchingAssetsForDocument(
        title: 'Honda Civic Sedan',
        fileName: 'ORCR_XYZ-9012_VIN998877.pdf',
        candidates: candidates,
      );
      expect(ranked, hasLength(3));
      expect(ranked.map((m) => m.asset.record.id).toList(), [
        'a-plate',
        'a-serial',
        'a-bm',
      ]);

      final unlinkedDocs = [
        RecordWithDocument(
          record: Record(
            id: 'doc-linked',
            workspaceId: 'ws-1',
            recordType: 'document',
            title: 'Already Linked XYZ-9012',
            createdAt: now,
            updatedAt: now,
          ),
          document: const DocumentItem(
            recordId: 'doc-linked',
            fileName: 'XYZ-9012.pdf',
            linkedAssetRecordId: 'a-plate',
          ),
        ),
        RecordWithDocument(
          record: Record(
            id: 'doc-unlinked-plate',
            workspaceId: 'ws-1',
            recordType: 'document',
            title: 'LTO Renewal',
            createdAt: now,
            updatedAt: now,
          ),
          document: const DocumentItem(
            recordId: 'doc-unlinked-plate',
            fileName: 'LTO_XYZ-9012.pdf',
          ),
        ),
      ];

      final docMatches = VaultAssetMatcher.findMatchingUnlinkedDocumentsForAsset(
        candidate: candidates.last,
        documents: unlinkedDocs,
      );
      expect(docMatches, hasLength(1));
      expect(docMatches.first.document.record.id, 'doc-unlinked-plate');
      expect(docMatches.first.reason, 'Matched Plate: XYZ-9012');
    });
  });

  group('Repository & Widget Integration Tests (Pass 4)', () {
    late AppDatabase db;
    late WorkspaceRepositoryImpl wsRepo;
    late CategoryRepositoryImpl categoryRepo;
    late RecordRepositoryImpl recordRepo;
    late BillRepositoryImpl billRepo;
    late ExpenseRepositoryImpl expenseRepo;
    late TaskRepositoryImpl taskRepo;
    late DocumentRepositoryImpl documentRepo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      wsRepo = WorkspaceRepositoryImpl(db);
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
          workspaceRepositoryProvider.overrideWithValue(wsRepo),
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

    test('updateDocumentAssetLink connects, unlinks, and guards invalid/non-asset/cross-workspace targets', () async {
      final now = DateTime.utc(2026, 11, 25);
      await recordRepo.createAssetRecord(
        record: Record(
          id: 'asset-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          categoryId: 'cat-vehicles',
          recordType: 'asset',
          title: 'Honda V4',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'asset-1', brand: 'Honda', model: 'V4'),
        customFields: const {'License Plate': 'ABC-1234'},
      );
      await documentRepo.createDocumentRecord(
        record: Record(
          id: 'doc-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'document',
          title: 'ORCR ABC-1234',
          createdAt: now,
          updatedAt: now,
        ),
        document: const DocumentItem(recordId: 'doc-1', fileName: 'orcr_abc1234.pdf'),
      );
      await recordRepo.createRecord(
        Record(
          id: 'task-not-asset',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'task',
          title: 'Some Task',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Batched license plates stream emits active vehicle plate
      final plates =
          await recordRepo.watchLicensePlatesByWorkspace(AppConstants.defaultWorkspaceId).first;
      expect(plates, equals({'asset-1': 'ABC-1234'}));

      // Connect
      await documentRepo.updateDocumentAssetLink(
        documentRecordId: 'doc-1',
        linkedAssetRecordId: 'asset-1',
      );
      var docs = await documentRepo.getDocumentsByWorkspace(AppConstants.defaultWorkspaceId);
      expect(docs.first.document.linkedAssetRecordId, 'asset-1');
      expect(docs.first.linkedAssetTitle, 'Honda V4');

      // Unlink
      await documentRepo.updateDocumentAssetLink(
        documentRecordId: 'doc-1',
        linkedAssetRecordId: null,
      );
      docs = await documentRepo.getDocumentsByWorkspace(AppConstants.defaultWorkspaceId);
      expect(docs.first.document.linkedAssetRecordId, isNull);

      // Guards: non-asset target, missing document, cross-workspace asset
      await expectLater(
        documentRepo.updateDocumentAssetLink(
          documentRecordId: 'doc-1',
          linkedAssetRecordId: 'task-not-asset',
        ),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        documentRepo.updateDocumentAssetLink(
          documentRecordId: 'missing-doc',
          linkedAssetRecordId: 'asset-1',
        ),
        throwsA(isA<StateError>()),
      );

      // Cross-workspace guard
      await db.into(db.workspaces).insert(
            WorkspacesCompanion.insert(
              id: 'ws-other',
              name: 'Other Home',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await recordRepo.createAssetRecord(
        record: Record(
          id: 'asset-other-ws',
          workspaceId: 'ws-other',
          recordType: 'asset',
          title: 'Other Car',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'asset-other-ws'),
      );
      await expectLater(
        documentRepo.updateDocumentAssetLink(
          documentRecordId: 'doc-1',
          linkedAssetRecordId: 'asset-other-ws',
        ),
        throwsA(isA<StateError>()),
      );
    });

    testWidgets(
      'AddDocumentSheet auto-preselects vehicle on exact plate match with 1-tap Unlink, and shows Brand+Model suggestion with 1-tap Link',
      (tester) async {
        tester.view.physicalSize = const Size(520, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.utc(2026, 11, 25);
        await recordRepo.createAssetRecord(
          record: Record(
            id: 'veh-civic',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-vehicles',
            recordType: 'asset',
            title: 'Honda Civic RS',
            createdAt: now,
            updatedAt: now,
          ),
          asset: const Asset(
            recordId: 'veh-civic',
            brand: 'Honda',
            model: 'Civic',
          ),
          customFields: const {'License Plate': 'ABC-1234'},
        );

        await tester.pumpWidget(
          buildApp(const Scaffold(body: AddDocumentSheet())),
        );
        await tester.pumpAndSettle();

        // Typing exact plate auto-preselects and displays vault_auto_match_banner
        await tester.enterText(
          find.widgetWithText(TextFormField, 'File Name *'),
          'ORCR_ABC-1234.pdf',
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('vault_auto_match_banner')), findsOneWidget);
        expect(find.textContaining('Matched Plate: ABC-1234'), findsOneWidget);

        // 1-tap Unlink dismisses auto-match and clears selection
        await tester.tap(find.byKey(const Key('vault_auto_match_unlink_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('vault_auto_match_banner')), findsNothing);

        // Fresh sheet: Brand + Model shows suggestion banner (no auto-preselect) + 1-tap Link
        await flush(tester);
        await tester.pumpWidget(
          buildApp(const Scaffold(body: AddDocumentSheet())),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Document Title *'),
          'Honda Civic Service Booklet',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'File Name *'),
          'booklet.pdf',
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('vault_auto_match_banner')), findsNothing);
        expect(find.byKey(const Key('vault_suggested_match_banner')), findsOneWidget);
        expect(find.textContaining('Matched Brand & Model: Honda Civic'), findsOneWidget);

        await tester.tap(find.byKey(const Key('vault_suggested_match_link_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('vault_suggested_match_banner')), findsNothing);

        // Save and verify link persisted in SQLite
        await tester.ensureVisible(find.text('Save Document'));
        await tester.tap(find.text('Save Document'));
        await tester.pumpAndSettle();

        final savedDocs = await db.select(db.documents).get();
        expect(savedDocs, hasLength(1));
        expect(savedDocs.first.linkedAssetRecordId, 'veh-civic');

        await flush(tester);
      },
    );

    testWidgets(
      'DocumentDetailSheet supports 1-tap Connect and 1-tap Unlink reactively in Dark Mode',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.utc(2026, 11, 25);
        await recordRepo.createAssetRecord(
          record: Record(
            id: 'veh-dark',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-vehicles',
            recordType: 'asset',
            title: 'Toyota Fortuner',
            createdAt: now,
            updatedAt: now,
          ),
          asset: const Asset(recordId: 'veh-dark', brand: 'Toyota', model: 'Fortuner'),
          customFields: const {'License Plate': 'NAA-7788'},
        );
        await documentRepo.createDocumentRecord(
          record: Record(
            id: 'doc-dark-1',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'document',
            title: 'LTO OR/CR NAA-7788',
            createdAt: now,
            updatedAt: now,
          ),
          document: const DocumentItem(recordId: 'doc-dark-1', fileName: 'lto_naa7788.pdf'),
        );

        final docs = await documentRepo.getDocumentsByWorkspace(AppConstants.defaultWorkspaceId);
        await tester.pumpWidget(
          buildApp(
            Scaffold(body: DocumentDetailSheet(item: docs.first)),
            themeMode: ThemeMode.dark,
          ),
        );
        await tester.pumpAndSettle();

        // Suggested Asset Match card appears -> tap Connect
        expect(find.byKey(const Key('vault_detail_suggested_match_card')), findsOneWidget);
        expect(find.text('Matched Plate: NAA-7788'), findsOneWidget);

        await tester.tap(find.byKey(const Key('vault_detail_connect_button')));
        await tester.pumpAndSettle();

        // Reactively flips to Linked Asset + Unlink button
        expect(find.byKey(const Key('vault_detail_suggested_match_card')), findsNothing);
        expect(find.byKey(const Key('vault_unlink_asset_button')), findsOneWidget);
        expect(find.text('Toyota Fortuner'), findsOneWidget);

        // Tap Unlink -> reactively flips back to Suggested Asset Match
        await tester.tap(find.byKey(const Key('vault_unlink_asset_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('vault_unlink_asset_button')), findsNothing);
        expect(find.byKey(const Key('vault_detail_suggested_match_card')), findsOneWidget);

        await flush(tester);
      },
    );

    testWidgets(
      'AssetDetailSheet displays matching unlinked Vault paper and 1-tap Connect moves it into linked documents',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.utc(2026, 11, 25);
        final vehicle = await recordRepo.createAssetRecord(
          record: Record(
            id: 'veh-suggest',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-vehicles',
            recordType: 'asset',
            title: 'Honda V4',
            createdAt: now,
            updatedAt: now,
          ),
          asset: const Asset(recordId: 'veh-suggest', brand: 'Honda', model: 'V4'),
          customFields: const {'License Plate': 'ABC-1234'},
        );
        await documentRepo.createDocumentRecord(
          record: Record(
            id: 'doc-unlinked-orcr',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'document',
            title: 'Motorcycle OR/CR',
            createdAt: now,
            updatedAt: now,
          ),
          document: const DocumentItem(
            recordId: 'doc-unlinked-orcr',
            fileName: 'ORCR_ABC-1234.pdf',
          ),
        );

        await tester.pumpWidget(
          buildApp(Scaffold(body: AssetDetailSheet(item: vehicle))),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('asset_suggested_documents_section')), findsOneWidget);
        expect(find.text('Motorcycle OR/CR'), findsOneWidget);
        expect(find.text('Matched Plate: ABC-1234'), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const Key('connect_suggested_doc_doc-unlinked-orcr')),
        );
        await tester.tap(
          find.byKey(const Key('connect_suggested_doc_doc-unlinked-orcr')),
        );
        await tester.pumpAndSettle();

        // Moves out of Suggested Vault Papers and into Vault Documents & Attachments
        expect(find.byKey(const Key('asset_suggested_documents_section')), findsNothing);
        expect(find.text('Vault Documents & Attachments'), findsOneWidget);
        expect(find.text('Motorcycle OR/CR'), findsOneWidget);

        await flush(tester);
      },
    );

    testWidgets(
      'AddDocumentSheet updates or clears auto-linked asset when filename changes to a different plate or unrelated file',
      (tester) async {
        tester.view.physicalSize = const Size(520, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.utc(2026, 11, 25);
        await recordRepo.createAssetRecord(
          record: Record(
            id: 'veh-a',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-vehicles',
            recordType: 'asset',
            title: 'Honda Civic',
            createdAt: now,
            updatedAt: now,
          ),
          asset: const Asset(recordId: 'veh-a', brand: 'Honda', model: 'Civic'),
          customFields: const {'License Plate': 'ABC-1234'},
        );
        await recordRepo.createAssetRecord(
          record: Record(
            id: 'veh-b',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-vehicles',
            recordType: 'asset',
            title: 'Toyota Fortuner',
            createdAt: now,
            updatedAt: now,
          ),
          asset: const Asset(recordId: 'veh-b', brand: 'Toyota', model: 'Fortuner'),
          customFields: const {'License Plate': 'XYZ-9999'},
        );

        await tester.pumpWidget(buildApp(const Scaffold(body: AddDocumentSheet())));
        await tester.pumpAndSettle();

        // First matches Honda Civic
        await tester.enterText(
          find.widgetWithText(TextFormField, 'File Name *'),
          'ORCR_ABC-1234.pdf',
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Auto-linked to Honda Civic'), findsOneWidget);

        // Changing filename to second car's plate switches auto-link cleanly
        await tester.enterText(
          find.widgetWithText(TextFormField, 'File Name *'),
          'ORCR_XYZ-9999.pdf',
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Auto-linked to Toyota Fortuner'), findsOneWidget);

        // Changing to unrelated file clears auto-link & banner
        await tester.enterText(
          find.widgetWithText(TextFormField, 'File Name *'),
          'groceries.pdf',
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('vault_auto_match_banner')), findsNothing);

        await flush(tester);
      },
    );

    testWidgets(
      'DocumentDetailSheet and AssetDetailSheet suggestion cards render with zero overflow at 360x800 in Light and Dark mode',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.utc(2026, 11, 25);
        final vehicle = await recordRepo.createAssetRecord(
          record: Record(
            id: 'veh-narrow',
            workspaceId: AppConstants.defaultWorkspaceId,
            categoryId: 'cat-vehicles',
            recordType: 'asset',
            title: 'Honda V4 Touring Special Edition',
            createdAt: now,
            updatedAt: now,
          ),
          asset: const Asset(recordId: 'veh-narrow', brand: 'Honda', model: 'V4'),
          customFields: const {'License Plate': 'ABC-1234'},
        );
        await documentRepo.createDocumentRecord(
          record: Record(
            id: 'doc-narrow',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'document',
            title: 'Long Vehicle Registration Certificate OR/CR Copy',
            createdAt: now,
            updatedAt: now,
          ),
          document: const DocumentItem(
            recordId: 'doc-narrow',
            fileName: 'ORCR_ABC-1234_2026.pdf',
          ),
        );
        final docs = await documentRepo.getDocumentsByWorkspace(AppConstants.defaultWorkspaceId);

        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          await tester.pumpWidget(
            buildApp(Scaffold(body: DocumentDetailSheet(item: docs.first)), themeMode: mode),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('vault_detail_suggested_match_card')), findsOneWidget);
          await flush(tester);

          await tester.pumpWidget(
            buildApp(Scaffold(body: AssetDetailSheet(item: vehicle)), themeMode: mode),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('asset_suggested_documents_section')), findsOneWidget);
          await flush(tester);
        }
      },
    );
  });
}
