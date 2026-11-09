import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/core/services/app_preferences.dart';
import 'package:domora/core/theme/app_theme.dart';
import 'package:domora/features/backup/data/backup_repository_impl.dart';
import 'package:domora/features/bills/domain/bill_item.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/settings/presentation/settings_profile_screen.dart';
import 'package:domora/features/settings/presentation/widgets/emergency_info_sheet.dart';
import 'package:domora/features/vault/domain/document_item.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AppPreferences prefs;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    prefs = AppPreferences.forTesting({
      'household_name': 'Elena Miller',
      'household_address': '428 Elmwood',
    });
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildSheetHarness({
    List<RecordWithAsset>? assets,
    List<RecordWithBill>? bills,
    List<RecordWithDocument>? documents,
    AppPreferences? customPrefs,
  }) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appPreferencesProvider.overrideWithValue(customPrefs ?? prefs),
        activeAssetsStreamProvider.overrideWith(
          (ref) => Stream.value(assets ?? const []),
        ),
        dashboardBillsStreamProvider.overrideWith(
          (ref) => Stream.value(bills ?? const []),
        ),
        dashboardDocumentsStreamProvider.overrideWith(
          (ref) => Stream.value(documents ?? const []),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: EmergencyInfoSheet(),
          ),
        ),
      ),
    );
  }

  Widget buildSettingsHarness() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appPreferencesProvider.overrideWithValue(prefs),
        workspaceRepositoryProvider.overrideWithValue(WorkspaceRepositoryImpl(db)),
        categoryRepositoryProvider.overrideWithValue(CategoryRepositoryImpl(db)),
        backupRepositoryProvider.overrideWithValue(BackupRepositoryImpl(db)),
        activeAssetsStreamProvider.overrideWith((ref) => Stream.value(const [])),
        dashboardBillsStreamProvider.overrideWith((ref) => Stream.value(const [])),
        dashboardDocumentsStreamProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const SettingsProfileScreen(),
      ),
    );
  }

  group('EmergencyInfoSheet Widget Tests', () {
    testWidgets('Renders sanctuary header, grab handle, and household identity card',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildSheetHarness());
      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('Emergency Household Dossier'), findsOneWidget);
      expect(find.textContaining('Elena Miller'), findsWidgets);
      expect(find.textContaining('428 Elmwood'), findsWidgets);

      // Section titles
      expect(find.text('Household & Primary Identity'), findsOneWidget);
      expect(find.text('Essential Property & Vehicles'), findsOneWidget);
      expect(find.text('Utility Obligations & Providers'), findsOneWidget);
      expect(find.text('Important Documents & Policies'), findsOneWidget);

      // Primary Workspace label
      expect(find.text('Sanctuary Workspace'), findsOneWidget);
      expect(find.text(AppConstants.defaultWorkspaceName), findsOneWidget);
    });

    testWidgets('Handles ultra-long addresses without RenderFlex overflow',
        (WidgetTester tester) async {
      final longPrefs = AppPreferences.forTesting({
        'household_name': 'Montgomery Alexander Bartholomew-Smythe III',
        'household_address':
            'Penthouse 42B, Tower 9, Sovereign Archival Heights, 9842 Grand Boulevard West, Metropolitan District 10001, Northern Territory',
      });

      await tester.pumpWidget(buildSheetHarness(customPrefs: longPrefs));
      await tester.pumpAndSettle();

      // Verify widget rendered cleanly without layout overflow exceptions
      expect(find.text('Household & Primary Identity'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders explicit empty states when no records exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildSheetHarness(
        assets: const [],
        bills: const [],
        documents: const [],
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('No property or vehicle records recorded yet.'),
        findsOneWidget,
      );
      expect(
        find.text('No utility accounts recorded yet.'),
        findsOneWidget,
      );
      expect(
        find.text('No vault documents recorded yet.'),
        findsOneWidget,
      );
    });

    testWidgets('Renders populated assets, utility accounts, and vault documents',
        (WidgetTester tester) async {
      final now = DateTime.now();

      final sampleAsset = RecordWithAsset(
        record: Record(
          id: 'asset-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: '2024 Honda Civic',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(
          recordId: 'asset-1',
          brand: 'Honda',
          model: 'Civic',
          serialNumber: 'VIN-987654321',
          locationDescription: 'North Garage',
        ),
      );

      final sampleBill = RecordWithBill(
        record: Record(
          id: 'bill-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: 'Meralco Power Bill',
          createdAt: now,
          updatedAt: now,
        ),
        bill: const BillItem(
          recordId: 'bill-1',
          utilityType: 'electricity',
          providerName: 'Manila Electric Co.',
          accountNumber: 'ACCT-888-999',
          amountDueMinor: 350000,
        ),
      );

      final sampleDoc = RecordWithDocument(
        record: Record(
          id: 'doc-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'document',
          title: 'Real Estate Title Deed',
          createdAt: now,
          updatedAt: now,
        ),
        document: const DocumentItem(
          recordId: 'doc-1',
          fileName: 'title_deed.pdf',
          filePath: '/vault/title_deed.pdf',
          documentType: 'deed',
          fileSizeBytes: 2048576,
          mimeType: 'application/pdf',
        ),
        linkedAssetTitle: 'Elmwood Property',
      );

      await tester.pumpWidget(buildSheetHarness(
        assets: [sampleAsset],
        bills: [sampleBill],
        documents: [sampleDoc],
      ));
      await tester.pumpAndSettle();

      // Asset record verification
      expect(find.text('2024 Honda Civic'), findsOneWidget);
      expect(find.text('Honda Civic'), findsOneWidget);
      expect(find.text('Serial/VIN: VIN-987654321'), findsOneWidget);
      expect(find.text('Loc: North Garage'), findsOneWidget);

      // Utility bill verification
      expect(find.text('Manila Electric Co.'), findsOneWidget);
      expect(find.text('Account: ACCT-888-999'), findsOneWidget);
      expect(find.text('ELECTRICITY'), findsOneWidget);

      // Document record verification
      expect(find.text('Real Estate Title Deed'), findsOneWidget);
      expect(find.text('DEED'), findsOneWidget);
      expect(find.text('Linked Asset: Elmwood Property'), findsOneWidget);
    });

    testWidgets('Tapping "Copy Dossier" writes markdown text to clipboard and shows SnackBar',
        (WidgetTester tester) async {
      String? copiedClipboardText;

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            final args = methodCall.arguments as Map<dynamic, dynamic>;
            copiedClipboardText = args['text'] as String?;
            return null;
          }
          return null;
        },
      );

      await tester.pumpWidget(buildSheetHarness());
      await tester.pumpAndSettle();

      final copyButton = find.byKey(const Key('copy_dossier_button'));
      expect(copyButton, findsOneWidget);
      expect(find.text('Copy Dossier'), findsOneWidget);

      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      // Verify button status changed
      expect(find.text('Dossier Copied'), findsOneWidget);

      // Verify SnackBar message
      expect(find.text('Emergency Household Dossier copied to clipboard'), findsOneWidget);

      // Verify clipboard payload formatting
      expect(copiedClipboardText, isNotNull);
      expect(copiedClipboardText!, contains('# EMERGENCY HOUSEHOLD DOSSIER'));
      expect(copiedClipboardText!, contains('Elena Miller'));
      expect(copiedClipboardText!, contains('428 Elmwood'));
      expect(copiedClipboardText!, contains('## 1. HOUSEHOLD & PRIMARY IDENTITY'));
      expect(copiedClipboardText!, contains('## 2. ESSENTIAL PROPERTY & VEHICLES'));
      expect(copiedClipboardText!, contains('## 3. UTILITY OBLIGATIONS & PROVIDERS'));
      expect(copiedClipboardText!, contains('## 4. IMPORTANT DOCUMENTS & POLICIES'));
    });

    testWidgets('Tapping "Close" button dismisses sheet in modal context',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            appPreferencesProvider.overrideWithValue(prefs),
            activeAssetsStreamProvider.overrideWith((ref) => Stream.value(const [])),
            dashboardBillsStreamProvider.overrideWith((ref) => Stream.value(const [])),
            dashboardDocumentsStreamProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => const EmergencyInfoSheet(),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emergency_info_sheet')), findsOneWidget);

      await tester.tap(find.byKey(const Key('close_dossier_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emergency_info_sheet')), findsNothing);
    });

    testWidgets('Tapping print_emergency_sheet_row in SettingsProfileScreen opens EmergencyInfoSheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildSettingsHarness());
      await tester.pumpAndSettle();

      final rowFinder = find.byKey(const Key('print_emergency_sheet_row'));
      await tester.ensureVisible(rowFinder);
      await tester.pumpAndSettle();

      await tester.tap(rowFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emergency_info_sheet')), findsOneWidget);
      expect(find.text('Emergency Household Dossier'), findsOneWidget);
    });
  });
}
