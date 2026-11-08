import 'dart:io';

import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/core/services/app_preferences.dart';
import 'package:domora/core/theme/app_theme.dart';
import 'package:domora/features/backup/data/backup_repository_impl.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/onboarding/presentation/onboarding_screen.dart';
import 'package:domora/features/settings/presentation/settings_profile_screen.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  final String testPath;
  FakePathProviderPlatform(this.testPath);

  @override
  Future<String?> getTemporaryPath() async => testPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => testPath;

  @override
  Future<String?> getApplicationSupportPath() async => testPath;

  @override
  Future<String?> getApplicationCachePath() async => testPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AppPreferences prefs;
  late Directory tempTestDir;

  setUp(() async {
    tempTestDir = Directory.systemTemp.createTempSync('domora_settings_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempTestDir.path);

    db = AppDatabase.forTesting(NativeDatabase.memory());
    prefs = AppPreferences.forTesting();
  });

  tearDown(() async {
    await db.close();
    try {
      if (tempTestDir.existsSync()) {
        tempTestDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  Widget buildTestableScreen({AppPreferences? testPrefs}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appPreferencesProvider.overrideWithValue(testPrefs ?? prefs),
        workspaceRepositoryProvider.overrideWithValue(WorkspaceRepositoryImpl(db)),
        categoryRepositoryProvider.overrideWithValue(CategoryRepositoryImpl(db)),
        backupRepositoryProvider.overrideWithValue(BackupRepositoryImpl(db)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const SettingsProfileScreen(),
      ),
    );
  }

  Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('SettingsProfileScreen Widget Tests', () {
    testWidgets('Renders all primary sections and headers', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Settings & Profile'), findsOneWidget);

      // Section 1: Profile Card
      expect(find.text('Elena Miller'), findsOneWidget);
      expect(find.text('428 Elmwood'), findsOneWidget);
      expect(find.byKey(const Key('edit_profile_button')), findsOneWidget);
      expect(find.byKey(const Key('manage_household_members_button')), findsOneWidget);

      // Section 2: Privacy & Security
      expect(find.text('PRIVACY & SECURITY'), findsOneWidget);
      expect(find.text('App Lock'), findsOneWidget);
      expect(find.byKey(const Key('app_lock_switch')), findsOneWidget);
      expect(find.text('Auto-lock'), findsOneWidget);
      expect(find.byKey(const Key('how_data_protected_link')), findsOneWidget);

      // Section 3: Backup
      expect(find.text('BACKUP'), findsOneWidget);
      expect(find.text('Export My Data'), findsOneWidget);
      expect(find.byKey(const Key('export_data_button')), findsOneWidget);
      expect(find.byKey(const Key('print_emergency_sheet_row')), findsOneWidget);
      expect(find.byKey(const Key('cloud_backup_restore_row')), findsOneWidget);

      // Section 4: Preferences
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('Daily Reminder'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);

      // Scroll down to expose bottom sections
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Section 5: Storage
      expect(find.text('STORAGE'), findsOneWidget);
      expect(find.byKey(const Key('clear_cache_button')), findsOneWidget);

      // Section 6: Updates
      expect(find.text('UPDATES'), findsOneWidget);
      expect(find.byKey(const Key('check_updates_button')), findsOneWidget);

      // Section 7: Danger Zone
      expect(find.text('DANGER ZONE'), findsOneWidget);
      expect(find.byKey(const Key('open_erase_dialog_button')), findsOneWidget);
    });

    testWidgets('Edit household name and address in dialog updates state and preferences',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Tap Edit Profile
      await tester.tap(find.byKey(const Key('edit_profile_button')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);

      // Enter new name and address
      await tester.enterText(find.byKey(const Key('edit_household_name_field')), 'Sophia Miller');
      await tester.enterText(find.byKey(const Key('edit_household_address_field')), '742 Evergreen Terrace');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify UI updated
      expect(find.text('Sophia Miller'), findsOneWidget);
      expect(find.text('742 Evergreen Terrace'), findsOneWidget);
      expect(prefs.householdName, 'Sophia Miller');
      expect(prefs.householdAddress, '742 Evergreen Terrace');
    });

    testWidgets('Toggling app lock switch updates preference', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const Key('app_lock_switch'));
      expect(switchFinder, findsOneWidget);
      expect(prefs.isBiometricsEnabled, false);

      // Toggle switch on
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(prefs.isBiometricsEnabled, true);

      // Toggle switch off
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(prefs.isBiometricsEnabled, false);
    });

    testWidgets('Picking auto-lock duration updates preference', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      final autoLockRow = find.byKey(const Key('auto_lock_row'));
      await tester.tap(autoLockRow);
      await tester.pumpAndSettle();

      expect(find.text('Select Auto-Lock Duration'), findsOneWidget);
      expect(find.text('After 5 minutes'), findsOneWidget);

      await tester.tap(find.text('After 5 minutes'));
      await tester.pumpAndSettle();

      expect(prefs.autoLockDuration, 'After 5 minutes');
      expect(find.text('After 5 minutes'), findsOneWidget);
    });

    testWidgets('Manage household members triggers Under Construction notice',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manage_household_members_button')));
      await tester.pumpAndSettle();

      expect(find.text('Feature Under Construction'), findsOneWidget);
      expect(find.textContaining('Household Members'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();

      expect(find.text('Feature Under Construction'), findsNothing);
    });

    testWidgets('Print Emergency Info Sheet triggers Under Construction notice',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      await scrollAndTap(tester, find.byKey(const Key('print_emergency_sheet_row')));

      expect(find.text('Feature Under Construction'), findsOneWidget);
      expect(
        find.text('Print Emergency Info Sheet is currently scheduled for implementation in Phase 2.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();

      expect(find.text('Feature Under Construction'), findsNothing);
    });

    testWidgets('Data protection reassurance link opens explainer modal', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('how_data_protected_link')));
      await tester.pumpAndSettle();

      expect(find.text('How Your Data Is Protected'), findsOneWidget);
      expect(find.text('Zero Remote Dependencies'), findsOneWidget);
      expect(find.text('Local Database Integrity'), findsOneWidget);
      expect(find.text('On-Device Biometric Lock'), findsOneWidget);

      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();

      expect(find.text('How Your Data Is Protected'), findsNothing);
    });

    testWidgets('Appearance segmented buttons switch theme mode', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      await scrollAndTap(tester, find.text('Dark'));
      expect(prefs.themeMode, 'dark');

      await scrollAndTap(tester, find.text('Light'));
      expect(prefs.themeMode, 'light');

      await scrollAndTap(tester, find.text('System'));
      expect(prefs.themeMode, 'system');
    });

    testWidgets('Export button opens BackupSheet and closes cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      await scrollAndTap(tester, find.byKey(const Key('export_data_button')));

      expect(find.text('Sanctuary Archival'), findsOneWidget);
      expect(find.text('Export Vault'), findsOneWidget);

      // Close bottom sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('Clear cache button triggers cache cleanup with SnackBar feedback',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('clear_cache_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('clear_cache_button')));
      await tester.pump();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Cache cleared successfully'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets(
        'Erase All Data dialog requires exact "ERASE" text and resets database and preferences',
        (WidgetTester tester) async {
      // Seed a workspace and record first
      final wsRepo = WorkspaceRepositoryImpl(db);
      final ws = await wsRepo.getOrCreateDefaultWorkspace();
      final catRepo = CategoryRepositoryImpl(db);
      await catRepo.seedDefaultCategories(ws.id);

      expect((await db.select(db.categories).get()).isNotEmpty, true);

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Open erase dialog
      await scrollAndTap(tester, find.byKey(const Key('open_erase_dialog_button')));

      expect(find.text('Erase All Data?'), findsOneWidget);
      expect(find.text('Type ERASE to confirm:'), findsOneWidget);

      final confirmBtn = find.byKey(const Key('confirm_erase_all_button'));
      expect(confirmBtn, findsOneWidget);

      // Verify button is disabled initially
      final initialButton = tester.widget<ElevatedButton>(confirmBtn);
      expect(initialButton.onPressed, isNull);

      // Type wrong input
      final inputFinder = find.byKey(const Key('erase_confirmation_textfield'));
      await tester.enterText(inputFinder, 'delete');
      await tester.pumpAndSettle();

      final stillDisabledButton = tester.widget<ElevatedButton>(confirmBtn);
      expect(stillDisabledButton.onPressed, isNull);

      // Type ERASE
      await tester.enterText(inputFinder, 'ERASE');
      await tester.pumpAndSettle();

      final enabledButton = tester.widget<ElevatedButton>(confirmBtn);
      expect(enabledButton.onPressed, isNotNull);

      // Tap Erase All
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify records erased from DB
      expect((await db.select(db.categories).get()).isEmpty, true);

      // Verify OnboardingScreen is now displayed
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });
  });
}
