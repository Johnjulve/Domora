import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/core/services/app_preferences.dart';
import 'package:domora/core/services/notification_service.dart';
import 'package:domora/core/theme/app_colors.dart';
import 'package:domora/core/theme/app_theme.dart';
import 'package:domora/core/theme/app_typography.dart';
import 'package:domora/features/bills/data/bill_repository_impl.dart';
import 'package:domora/features/bills/domain/bill_item.dart';
import 'package:domora/features/bills/presentation/add_bill_sheet.dart';
import 'package:domora/features/bills/presentation/bill_detail_sheet.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/onboarding/presentation/onboarding_screen.dart';
import 'package:domora/features/onboarding/presentation/widgets/storage_choice_step.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/records/presentation/records_screen.dart';
import 'package:domora/features/settings/presentation/settings_profile_screen.dart';
import 'package:domora/features/records/presentation/widgets/asset_picker_sheet.dart';
import 'package:domora/features/settings/presentation/widgets/emergency_info_sheet.dart';
import 'package:domora/features/today/presentation/today_screen.dart';
import 'package:domora/features/vault/data/document_repository_impl.dart';
import 'package:domora/features/vault/presentation/vault_screen.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:domora/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pillar 1: Sanctuary Archival Dark Theme Specification Tests', () {
    test('AppTheme.darkTheme has dark brightness and matches centralized AppTheme dark tokens', () {
      final theme = AppTheme.darkTheme;

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppTheme.darkSurfaceCanvas);

      // ColorScheme tokens
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, AppTheme.darkBrandPrimary);
      expect(theme.colorScheme.onPrimary, Colors.white);
      expect(theme.colorScheme.secondary, AppTheme.darkBrandSecondary);
      expect(theme.colorScheme.onSecondary, AppTheme.darkSurfaceCanvas);
      expect(theme.colorScheme.surface, AppTheme.darkSurfaceCard);
      expect(theme.colorScheme.onSurface, AppTheme.darkTextPrimary);
      expect(theme.colorScheme.outline, AppTheme.darkBorderSubtle);
      expect(theme.colorScheme.surfaceContainerHighest, AppTheme.darkSurfaceContainerLow);

      // Card & Sheet Surfaces
      expect(theme.cardTheme.color, AppTheme.darkSurfaceCard);
      expect(theme.cardTheme.elevation, 0);
      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(cardShape.borderRadius, BorderRadius.circular(AppTheme.cardRadius));
      expect(cardShape.side.color, AppTheme.darkBorderSubtle);

      expect(theme.bottomSheetTheme.backgroundColor, AppTheme.darkSurfaceCard);
      expect(theme.bottomSheetTheme.modalBackgroundColor, AppTheme.darkSurfaceCard);
      final sheetShape = theme.bottomSheetTheme.shape as RoundedRectangleBorder;
      expect(sheetShape.borderRadius, const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)));

      // Dialog Theme
      expect(theme.dialogTheme.backgroundColor, AppTheme.darkSurfaceCard);
      final dialogShape = theme.dialogTheme.shape as RoundedRectangleBorder;
      expect(dialogShape.borderRadius, BorderRadius.circular(AppTheme.cardRadius));
      expect(dialogShape.side.color, AppTheme.darkBorderSubtle);

      // AppBar Theme
      expect(theme.appBarTheme.backgroundColor, AppTheme.darkSurfaceCanvas);
      expect(theme.appBarTheme.foregroundColor, AppTheme.darkTextPrimary);

      // Input Decoration Theme
      expect(theme.inputDecorationTheme.fillColor, AppTheme.darkSurfaceContainerLow);
      final inputBorder = theme.inputDecorationTheme.border as OutlineInputBorder;
      expect(inputBorder.borderRadius, BorderRadius.circular(AppTheme.inputRadius));
      expect(inputBorder.borderSide.color, AppTheme.darkBorderSubtle);

      // Button Theme
      final elevatedHeight = theme.elevatedButtonTheme.style?.minimumSize?.resolve({})?.height;
      expect(elevatedHeight, AppTheme.buttonHeight);

      // Typography Hierarchy
      expect(theme.textTheme.displayLarge?.color, AppTheme.darkTextPrimary);
      expect(theme.textTheme.bodyLarge?.color, AppTheme.darkTextPrimary);
      expect(theme.textTheme.bodyMedium?.color, AppTheme.darkTextSecondary);
      expect(theme.textTheme.bodySmall?.color, AppTheme.darkTextTertiary);
      expect(theme.textTheme.labelSmall?.color, AppTheme.darkBrandSecondary);

      // Divider Theme
      expect(theme.dividerTheme.color, AppTheme.darkBorderSubtle);
    });
  });

  group('Pillar 2: ThemeModeNotifier & Riverpod State Management Tests', () {
    test('Initializes with ThemeMode matching preferences', () {
      final prefsLight = AppPreferences.forTesting({'theme_mode': 'light'});
      final containerLight = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefsLight)],
      );
      addTearDown(containerLight.dispose);
      expect(containerLight.read(themeModeProvider), ThemeMode.light);

      final prefsDark = AppPreferences.forTesting({'theme_mode': 'dark'});
      final containerDark = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefsDark)],
      );
      addTearDown(containerDark.dispose);
      expect(containerDark.read(themeModeProvider), ThemeMode.dark);

      final prefsSystem = AppPreferences.forTesting({'theme_mode': 'system'});
      final containerSystem = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefsSystem)],
      );
      addTearDown(containerSystem.dispose);
      expect(containerSystem.read(themeModeProvider), ThemeMode.system);
    });

    test('Defaults unknown strings safely to ThemeMode.system', () {
      final prefsUnknown = AppPreferences.forTesting({'theme_mode': 'custom_unknown'});
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefsUnknown)],
      );
      addTearDown(container.dispose);
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('setThemeMode updates state reactively and persists to AppPreferences', () async {
      final prefs = AppPreferences.forTesting({'theme_mode': 'system'});
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);
      expect(prefs.themeMode, 'system');

      // Switch to dark
      await container.read(themeModeProvider.notifier).setThemeMode('dark');
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(prefs.themeMode, 'dark');

      // Switch to light
      await container.read(themeModeProvider.notifier).setThemeMode('light');
      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(prefs.themeMode, 'light');

      // Switch back to system
      await container.read(themeModeProvider.notifier).setThemeMode('system');
      expect(container.read(themeModeProvider), ThemeMode.system);
      expect(prefs.themeMode, 'system');
    });
  });

  group('Pillar 3: DomoraApp MaterialApp ThemeMode Integration Tests', () {
    late AppDatabase db;
    late AppPreferences prefs;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      prefs = AppPreferences.forTesting({
        'onboarding_completed': true,
        'theme_mode': 'dark',
      });
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('DomoraApp applies darkTheme when themeMode is set to ThemeMode.dark',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appPreferencesProvider.overrideWithValue(prefs),
          workspaceRepositoryProvider.overrideWithValue(WorkspaceRepositoryImpl(db)),
          categoryRepositoryProvider.overrideWithValue(CategoryRepositoryImpl(db)),
          notificationServiceProvider.overrideWithValue(LocalNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DomoraApp(showOnboarding: false),
        ),
      );
      await tester.pumpAndSettle();

      // Find the MaterialApp widget and verify theme configuration
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, AppTheme.lightTheme);
      expect(materialApp.darkTheme, AppTheme.darkTheme);
      expect(materialApp.themeMode, ThemeMode.dark);

      // Verify active theme in context is dark
      final BuildContext innerContext = tester.element(find.byType(Scaffold).first);
      final activeTheme = Theme.of(innerContext);
      expect(activeTheme.brightness, Brightness.dark);
      expect(activeTheme.scaffoldBackgroundColor, AppTheme.darkSurfaceCanvas);

      // Dynamically switch to light theme
      await container.read(themeModeProvider.notifier).setThemeMode('light');
      await tester.pumpAndSettle();

      final updatedMaterialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(updatedMaterialApp.themeMode, ThemeMode.light);

      final updatedContext = tester.element(find.byType(Scaffold).first);
      final updatedTheme = Theme.of(updatedContext);
      expect(updatedTheme.brightness, Brightness.light);
      expect(updatedTheme.scaffoldBackgroundColor, const Color(0xFFFAF9F6));
    });
  });

  group('Pillar 4: GitHub Releases Direct APK Extraction Contract Tests', () {
    test('extractApkDownloadUrl finds and returns .apk browser_download_url', () {
      final releasePayload = {
        'tag_name': 'v0.1.0-alpha.13',
        'html_url': 'https://github.com/Johnjulve/Domora/releases/tag/v0.1.0-alpha.13',
        'assets': [
          {
            'name': 'source-code.zip',
            'browser_download_url': 'https://github.com/Johnjulve/Domora/releases/download/v0.1.0-alpha.13/source.zip',
          },
          {
            'name': 'domora-v0.1.0-alpha13.apk',
            'browser_download_url':
                'https://github.com/Johnjulve/Domora/releases/download/v0.1.0-alpha.13/domora-v0.1.0-alpha13.apk',
          },
          {
            'name': 'checksums.txt',
            'browser_download_url': 'https://github.com/Johnjulve/Domora/releases/download/v0.1.0-alpha.13/checksums.txt',
          },
        ],
      };

      final apkUrl = SettingsProfileScreen.extractApkDownloadUrl(releasePayload);
      expect(
        apkUrl,
        'https://github.com/Johnjulve/Domora/releases/download/v0.1.0-alpha.13/domora-v0.1.0-alpha13.apk',
      );
    });

    test('extractApkDownloadUrl handles uppercase .APK extension gracefully', () {
      final releasePayload = {
        'tag_name': 'v0.1.0-alpha.13',
        'assets': [
          {
            'name': 'DOMORA_RELEASE.APK',
            'browser_download_url': 'https://github.com/download/release.apk',
          },
        ],
      };

      final apkUrl = SettingsProfileScreen.extractApkDownloadUrl(releasePayload);
      expect(apkUrl, 'https://github.com/download/release.apk');
    });

    test('extractApkDownloadUrl handles dynamic Map<dynamic, dynamic> safely without reified cast crash', () {
      final Map<dynamic, dynamic> dynamicPayload = {
        'tag_name': 'v0.1.0-alpha.13',
        'assets': <dynamic>[
          <dynamic, dynamic>{
            'name': 'domora-safe.apk',
            'browser_download_url': 'https://github.com/download/domora-safe.apk',
          },
        ],
      };

      final apkUrl = SettingsProfileScreen.extractApkDownloadUrl(
        Map<String, dynamic>.from(dynamicPayload),
      );
      expect(apkUrl, 'https://github.com/download/domora-safe.apk');
    });

    test('extractApkDownloadUrl returns null when no APK asset exists (triggers html_url fallback)', () {
      final releaseWithoutApk = {
        'tag_name': 'v0.1.0-alpha.13',
        'html_url': 'https://github.com/Johnjulve/Domora/releases/tag/v0.1.0-alpha.13',
        'assets': [
          {
            'name': 'domora-mac.dmg',
            'browser_download_url': 'https://github.com/download/domora.dmg',
          },
          {
            'name': 'domora-windows.exe',
            'browser_download_url': 'https://github.com/download/domora.exe',
          },
        ],
      };

      final apkUrl = SettingsProfileScreen.extractApkDownloadUrl(releaseWithoutApk);
      expect(apkUrl, isNull);
    });

    test('extractApkDownloadUrl returns null for empty or malformed assets list', () {
      expect(SettingsProfileScreen.extractApkDownloadUrl({}), isNull);
      expect(SettingsProfileScreen.extractApkDownloadUrl({'assets': []}), isNull);
      expect(SettingsProfileScreen.extractApkDownloadUrl({'assets': 'not_a_list'}), isNull);
      expect(
        SettingsProfileScreen.extractApkDownloadUrl({
          'assets': [
            {'name': 'domora.apk', 'browser_download_url': null},
            {'name': 'domora2.apk', 'browser_download_url': ''},
          ],
        }),
        isNull,
      );
    });
  });

  group('Pillar 5: SettingsProfileScreen Dark Theme & UI State Tests', () {
    late AppDatabase db;
    late AppPreferences prefs;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      prefs = AppPreferences.forTesting({
        'theme_mode': 'dark',
      });
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('SettingsProfileScreen renders with dark theme canvas and selects Dark mode segment',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appPreferencesProvider.overrideWithValue(prefs),
          workspaceRepositoryProvider.overrideWithValue(WorkspaceRepositoryImpl(db)),
          categoryRepositoryProvider.overrideWithValue(CategoryRepositoryImpl(db)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const SettingsProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Scaffold has no hardcoded light canvas, inheriting darkTheme
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull);

      // Verify AppBar background inherits dark theme
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, isNull);

      // Verify active theme in context is dark
      final BuildContext context = tester.element(find.byType(Scaffold));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(Theme.of(context).scaffoldBackgroundColor, AppTheme.darkSurfaceCanvas);

      // Verify Appearance segment shows 'Dark' as selected
      final darkText = tester.widget<Text>(find.descendant(
        of: find.byKey(const Key('theme_option_dark')),
        matching: find.byType(Text),
      ));
      expect(darkText.style?.color, AppTheme.darkTextPrimary);
    });
  });

  group('Pillar 6: Visual Contrast, Theming & Dark Mode Collision Verification Tests', () {
    test('AppTypography base styles omit explicit color and inherit ambient theme color in Light and Dark Mode', () {
      expect(AppTypography.displayHero.color, isNull);
      expect(AppTypography.pageHeader.color, isNull);
      expect(AppTypography.sectionTitle.color, isNull);
      expect(AppTypography.cardTitle.color, isNull);
      expect(AppTypography.bodyPrimary.color, isNull);
      expect(AppTypography.bodySecondary.color, isNull);
      expect(AppTypography.caption.color, isNull);
      expect(AppTypography.badge.color, AppColors.brandPrimary);
    });

    testWidgets('AppTypography inherits light text color under light theme and dark text color under dark theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: const [
                    Text('Hero Title', style: AppTypography.displayHero),
                    Text('Page Header', style: AppTypography.pageHeader),
                    Text('Body Content', style: AppTypography.bodyPrimary),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final lightContext = tester.element(find.text('Page Header'));
      expect(lightContext.isDarkMode, isFalse);
      expect(lightContext.surfaceCanvas, AppColors.surfaceCanvas);
      expect(lightContext.surfaceCard, AppColors.surfaceCard);
      expect(lightContext.textPrimary, AppColors.textPrimary);
      expect(lightContext.textSecondary, AppColors.textSecondary);
      expect(lightContext.textTertiary, AppColors.textTertiary);
      expect(lightContext.borderSubtle, AppColors.borderSubtle);
      expect(lightContext.surfaceContainerLow, AppColors.surfaceContainerLow);
      expect(lightContext.brandAccent, AppColors.brandPrimary);
      expect(DefaultTextStyle.of(lightContext).style.color, AppColors.textSecondary);

      // Verify effective style inherits from DefaultTextStyle without color override
      final lightEffective = DefaultTextStyle.of(lightContext).style.merge(AppTypography.pageHeader);
      expect(lightEffective.color, AppColors.textSecondary);

      // Now pump under dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: const [
                    Text('Hero Title', style: AppTypography.displayHero),
                    Text('Page Header', style: AppTypography.pageHeader),
                    Text('Body Content', style: AppTypography.bodyPrimary),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final darkContext = tester.element(find.text('Page Header'));
      expect(darkContext.isDarkMode, isTrue);
      expect(darkContext.surfaceCanvas, AppTheme.darkSurfaceCanvas);
      expect(darkContext.surfaceCard, AppTheme.darkSurfaceCard);
      expect(darkContext.textPrimary, AppTheme.darkTextPrimary);
      expect(darkContext.textSecondary, AppTheme.darkTextSecondary);
      expect(darkContext.textTertiary, AppTheme.darkTextTertiary);
      expect(darkContext.borderSubtle, AppTheme.darkBorderSubtle);
      expect(darkContext.surfaceContainerLow, AppTheme.darkSurfaceContainerLow);
      expect(darkContext.brandAccent, AppTheme.darkBrandSecondary);
      expect(DefaultTextStyle.of(darkContext).style.color, AppTheme.darkTextSecondary);

      // Verify dark effective style inherits dark text color without override
      final darkEffective = DefaultTextStyle.of(darkContext).style.merge(AppTypography.pageHeader);
      expect(darkEffective.color, AppTheme.darkTextSecondary);
    });

    testWidgets('OnboardingScreen Scaffold renders dark scaffold background when running under AppTheme.darkTheme',
        (WidgetTester tester) async {
      final prefs = AppPreferences.forTesting({
        'onboarding_completed': false,
        'theme_mode': 'dark',
      });
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull);

      final scaffoldContext = tester.element(find.byType(Scaffold));
      expect(Theme.of(scaffoldContext).scaffoldBackgroundColor, AppTheme.darkSurfaceCanvas);
      expect(scaffoldContext.surfaceCanvas, AppTheme.darkSurfaceCanvas);
    });

    testWidgets('AddAssetSheet bottom sheet container renders dark card color when running under AppTheme.darkTheme',
        (WidgetTester tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          categoryRepositoryProvider.overrideWithValue(CategoryRepositoryImpl(db)),
          recordRepositoryProvider.overrideWithValue(RecordRepositoryImpl(db)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const Scaffold(
              body: AddAssetSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final containerWidget = tester.widget<Container>(find.descendant(
        of: find.byType(AddAssetSheet),
        matching: find.byType(Container).first,
      ));

      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, AppTheme.darkSurfaceCard);
      expect(decoration.borderRadius, const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)));
    });

    testWidgets('RecordsScreen metrics render with darkBrandSecondary under AppTheme.darkTheme',
        (WidgetTester tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await WorkspaceRepositoryImpl(db).getOrCreateDefaultWorkspace();
      final recordRepo = RecordRepositoryImpl(db);
      final now = DateTime.now().toUtc();
      await recordRepo.createAssetRecord(
        record: Record(
          id: 'test-record-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'MacBook Pro M3',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(
          recordId: 'test-record-1',
          purchaseAmountMinor: 14500000,
          purchaseCurrency: 'PHP',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          recordRepositoryProvider.overrideWithValue(recordRepo),
          categoryRepositoryProvider.overrideWithValue(CategoryRepositoryImpl(db)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const RecordsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final valueText = tester.widget<Text>(find.textContaining('Value: PHP'));
      expect(valueText.style?.color, AppTheme.darkBrandSecondary);
    });

    testWidgets('StorageChoiceStep cards render with darkSurfaceCard and darkTextPrimary under AppTheme.darkTheme',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: Scaffold(
              body: StorageChoiceStep(onContinue: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardContainers = tester.widgetList<Container>(find.descendant(
        of: find.byType(InkWell),
        matching: find.byType(Container),
      ));

      final firstCard = cardContainers.first;
      final decoration = firstCard.decoration as BoxDecoration;
      expect(decoration.color, AppTheme.darkSurfaceCard);

      final context = tester.element(find.text('Continue without an account'));
      expect(DefaultTextStyle.of(context).style.color, AppTheme.darkTextSecondary);
      expect(context.textPrimary, AppTheme.darkTextPrimary);
      expect(context.surfaceCard, AppTheme.darkSurfaceCard);
    });

    testWidgets('VaultScreen filter chips and empty state render with dark theme tokens in Dark Mode',
        (WidgetTester tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          documentRepositoryProvider.overrideWithValue(DocumentRepositoryImpl(db)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const VaultScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the 'Warranty' chip container (unselected)
      final unselectedChipContainer = tester.widget<Container>(find.ancestor(
        of: find.text('Warranty'),
        matching: find.byType(Container),
      ).first);

      final unselectedDec = unselectedChipContainer.decoration as BoxDecoration;
      expect(unselectedDec.color, AppTheme.darkSurfaceCard);
      expect((unselectedDec.border as Border).top.color, AppTheme.darkBorderSubtle);
      expect(unselectedDec.borderRadius, BorderRadius.circular(999));

      final unselectedText = tester.widget<Text>(find.text('Warranty'));
      expect(unselectedText.style?.color, AppTheme.darkTextPrimary);
      expect(unselectedText.style?.fontWeight, FontWeight.w500);

      // Find the 'All' chip container (selected)
      final selectedChipContainer = tester.widget<Container>(find.ancestor(
        of: find.text('All'),
        matching: find.byType(Container),
      ).first);

      final selectedDec = selectedChipContainer.decoration as BoxDecoration;
      expect(selectedDec.color, AppColors.brandPrimary);
      expect((selectedDec.border as Border).top.color, AppColors.brandPrimary);
      expect(selectedDec.borderRadius, BorderRadius.circular(999));

      final selectedText = tester.widget<Text>(find.text('All'));
      expect(selectedText.style?.color, AppColors.brandOnPrimary);
      expect(selectedText.style?.fontWeight, FontWeight.w600);

      // Empty state lock icon circle in dark mode
      final lockIcon = find.byIcon(Icons.lock_outline);
      expect(lockIcon, findsOneWidget);
      final lockWidget = tester.widget<Icon>(lockIcon);
      expect(lockWidget.color, AppTheme.darkBrandSecondary);

      final lockCircle = tester.widget<Container>(find.ancestor(
        of: lockIcon,
        matching: find.byType(Container),
      ).first);
      final lockDec = lockCircle.decoration as BoxDecoration;
      expect(lockDec.color, AppTheme.darkSurfaceContainerLow);
    });

    testWidgets('AddDocumentSheet renders with dark surfaceCard and dark surfaceContainerLow in Dark Mode',
        (WidgetTester tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          documentRepositoryProvider.overrideWithValue(DocumentRepositoryImpl(db)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const Scaffold(
              body: AddDocumentSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Root sheet container
      final rootContainer = tester.widget<Container>(find.descendant(
        of: find.byType(AddDocumentSheet),
        matching: find.byType(Container),
      ).first);
      final rootDec = rootContainer.decoration as BoxDecoration;
      expect(rootDec.color, AppTheme.darkSurfaceCard);
      expect(rootDec.borderRadius, const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)));

      // File upload card container
      final uploadCard = tester.widget<Container>(find.descendant(
        of: find.byType(InkWell),
        matching: find.byType(Container),
      ).first);
      final uploadDec = uploadCard.decoration as BoxDecoration;
      expect(uploadDec.color, AppTheme.darkSurfaceContainerLow);
      expect((uploadDec.border as Border).top.color, AppTheme.darkBorderSubtle);

      // Upload icon
      final uploadIcon = tester.widget<Icon>(find.byIcon(Icons.upload_file_outlined));
      expect(uploadIcon.color, AppTheme.darkBrandSecondary);
    });

    testWidgets('AssetPickerTile and showAssetPickerModal render with dark theme tokens in Dark Mode',
        (WidgetTester tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final now = DateTime.now().toUtc();
      final record = Record(
        id: 'asset-test-1',
        workspaceId: AppConstants.defaultWorkspaceId,
        recordType: 'asset',
        title: 'Toyota Fortuner',
        categoryId: 'cat-vehicles',
        createdAt: now,
        updatedAt: now,
      );
      final testAsset = RecordWithAsset(
        record: record,
        asset: const Asset(recordId: 'asset-test-1', brand: 'Toyota', model: 'Fortuner', odometerReading: 45000),
      );

      final container = ProviderContainer(
        overrides: [
          activeAssetsStreamProvider.overrideWith((ref) => Stream.value([testAsset])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: Scaffold(
              body: AssetPickerTile(
                selectedAssetRecordId: null,
                onAssetChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AssetPickerTile surface tokens
      final tileContainer = tester.widget<Container>(find.descendant(
        of: find.byType(AssetPickerTile),
        matching: find.byType(Container),
      ).first);
      final tileDec = tileContainer.decoration as BoxDecoration;
      expect(tileDec.color, AppTheme.darkSurfaceContainerLow);
      expect((tileDec.border as Border).top.color, AppTheme.darkBorderSubtle);

      final linkIcon = tester.widget<Icon>(find.byIcon(Icons.link));
      expect(linkIcon.color, AppTheme.darkBrandSecondary);

      // Tap to open showAssetPickerModal
      await tester.tap(find.byType(AssetPickerTile));
      await tester.pumpAndSettle();

      // Modal Material surface should have darkSurfaceCard
      final modalMaterial = tester.widget<Material>(find.ancestor(
        of: find.text('Select Associated Asset'),
        matching: find.byType(Material),
      ).first);
      expect(modalMaterial.color, AppTheme.darkSurfaceCard);

      // Leading car icon has darkBrandSecondary
      final carIcon = tester.widget<Icon>(find.byIcon(Icons.directions_car_outlined));
      expect(carIcon.color, AppTheme.darkBrandSecondary);
    });

    testWidgets('EmergencyInfoSheet renders with high-contrast dark theme tokens and legible text in Dark Mode',
        (WidgetTester tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final prefs = AppPreferences.forTesting({
        'household_name': 'Sanctuary Manor',
        'household_address': '124 Lotus Avenue',
        'theme_mode': 'dark',
      });

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appPreferencesProvider.overrideWithValue(prefs),
          activeAssetsStreamProvider.overrideWith((ref) => Stream.value([])),
          dashboardBillsStreamProvider.overrideWith((ref) => Stream.value([])),
          dashboardDocumentsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const Scaffold(
              body: EmergencyInfoSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Root bottom sheet container
      final sheetContainer = tester.widget<Container>(find.byKey(const Key('emergency_info_sheet')));
      final sheetDec = sheetContainer.decoration as BoxDecoration;
      expect(sheetDec.color, AppTheme.darkSurfaceCard);
      expect((sheetDec.border as Border).top.color, AppTheme.darkBorderSubtle);

      // Header shield icon and container
      final shieldIcon = tester.widget<Icon>(find.byIcon(Icons.shield_outlined));
      expect(shieldIcon.color, AppTheme.darkBrandSecondary);

      final shieldContainer = tester.widget<Container>(find.ancestor(
        of: find.byIcon(Icons.shield_outlined),
        matching: find.byType(Container),
      ).first);
      final shieldDec = shieldContainer.decoration as BoxDecoration;
      expect(shieldDec.color, AppTheme.darkSurfaceContainerLow);
      expect((shieldDec.border as Border).top.color, AppTheme.darkBorderSubtle);

      // Title & Subtitle text colors
      final titleText = tester.widget<Text>(find.text('Emergency Household Dossier'));
      expect(titleText.style?.color, AppTheme.darkTextPrimary);

      final subtitleText = tester.widget<Text>(find.text('Sanctuary Manor • 124 Lotus Avenue'));
      expect(subtitleText.style?.color, AppTheme.darkTextSecondary);

      // Household & Primary Identity card container
      final identityCard = tester.widget<Container>(find.ancestor(
        of: find.text('Household & Primary Identity'),
        matching: find.byType(Container),
      ).first);
      final identityDec = identityCard.decoration as BoxDecoration;
      expect(identityDec.color, AppTheme.darkSurfaceContainerLow);
      expect((identityDec.border as Border).top.color, AppTheme.darkBorderSubtle);

      final homeIcon = tester.widget<Icon>(find.byIcon(Icons.home_outlined));
      expect(homeIcon.color, AppTheme.darkBrandSecondary);

      // Close OutlinedButton in Action Bar
      final closeButton = tester.widget<OutlinedButton>(find.byKey(const Key('close_dossier_button')));
      final closeStyle = closeButton.style;
      expect(closeStyle?.side?.resolve({})?.color, AppTheme.darkBorderSubtle);
      expect(closeStyle?.foregroundColor?.resolve({}), AppTheme.darkTextPrimary);
    });

    testWidgets('TodayScreen metrics and quick action buttons render with high-contrast dark theme tokens in Dark Mode',
        (WidgetTester tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          dashboardTasksStreamProvider.overrideWith((ref) => Stream.value([])),
          dashboardRecordsStreamProvider.overrideWith((ref) => Stream.value([])),
          workspaceTotalExpensesProvider.overrideWith((ref) => Stream.value(0)),
          upcomingBillsStreamProvider.overrideWith((ref) => Stream.value([])),
          dashboardBillsStreamProvider.overrideWith((ref) => Stream.value([])),
          dashboardExpensesStreamProvider.overrideWith((ref) => Stream.value([])),
          dashboardDocumentsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const TodayScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Metric Card text colors (should be darkTextPrimary, not black or invisible)
      final pendingValue = tester.widget<Text>(find.text('0').first);
      expect(pendingValue.style?.color, AppTheme.darkTextPrimary);

      // Task quick add tile in _QuickAddSection (should be darkBrandSecondary)
      final taskIcon = tester.widget<Icon>(find.byIcon(Icons.checklist_outlined).first);
      expect(taskIcon.color, AppTheme.darkBrandSecondary);

      final taskText = tester.widget<Text>(find.text('Task'));
      expect(taskText.style?.color, AppTheme.darkTextPrimary);

      // Settings icon (should be darkBrandSecondary)
      final settingsIcon = tester.widget<Icon>(find.byIcon(Icons.settings_outlined));
      expect(settingsIcon.color, AppTheme.darkBrandSecondary);

      // Sanctuary badge ('On-device')
      final sanctuaryIcon = tester.widget<Icon>(find.byIcon(Icons.shield_outlined));
      expect(sanctuaryIcon.color, AppTheme.darkBrandSecondary);

      final sanctuaryText = tester.widget<Text>(find.text('On-device'));
      expect(sanctuaryText.style?.color, AppTheme.darkBrandSecondary);

      final sanctuaryContainer = tester.widget<Container>(find.ancestor(
        of: find.text('On-device'),
        matching: find.byType(Container),
      ).first);
      final sanctuaryDec = sanctuaryContainer.decoration as BoxDecoration;
      expect(sanctuaryDec.color, AppTheme.darkSurfaceCard);
      expect((sanctuaryDec.border as Border).top.color, AppTheme.darkBorderSubtle);

      // Hero reassurance card
      final allCaughtUpIcon = tester.widget<Icon>(find.byIcon(Icons.check_circle_outline));
      expect(allCaughtUpIcon.color, AppTheme.darkBrandSecondary);

      final caughtUpCircle = tester.widget<Container>(find.ancestor(
        of: find.byIcon(Icons.check_circle_outline),
        matching: find.byType(Container),
      ).first);
      final caughtUpDec = caughtUpCircle.decoration as BoxDecoration;
      expect(caughtUpDec.color, AppTheme.darkSurfaceContainerLow);

      final caughtUpTitle = tester.widget<Text>(find.text("You're all caught up"));
      expect(caughtUpTitle.style?.color, AppTheme.darkTextPrimary);
    });

    testWidgets('AddBillSheet and BillDetailSheet render with dark theme tokens, responsive inputs, and high contrast in Dark Mode',
        (WidgetTester tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          billRepositoryProvider.overrideWithValue(BillRepositoryImpl(db)),
          activeAssetsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
      );
      addTearDown(container.dispose);

      // 1. Pump AddBillSheet in Dark Mode
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const Scaffold(
              body: AddBillSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AddBillSheet root container has darkSurfaceCard
      final addBillContainer = tester.widget<Container>(find.descendant(
        of: find.byType(AddBillSheet),
        matching: find.byType(Container),
      ).first);
      final addBillDec = addBillContainer.decoration as BoxDecoration;
      expect(addBillDec.color, AppTheme.darkSurfaceCard);

      // Verify responsive Currency selector and non-truncated Amount Due field
      expect(find.byKey(const Key('bill_currency_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('bill_amount_due_field')), findsOneWidget);
      expect(find.text('Amount Due *'), findsOneWidget);

      // Verify Due Date container has darkSurfaceContainerLow and darkBorderSubtle
      final dueDateFinder = find.ancestor(
        of: find.textContaining('Due Date:'),
        matching: find.byType(Container),
      );
      expect(dueDateFinder, findsWidgets);
      final dueDateContainer = tester.widget<Container>(dueDateFinder.first);
      final dueDateDec = dueDateContainer.decoration as BoxDecoration;
      expect(dueDateDec.color, AppTheme.darkSurfaceContainerLow);
      expect((dueDateDec.border as Border).top.color, AppTheme.darkBorderSubtle);

      // Verify Billing Period selector cards have darkSurfaceContainerLow and darkBorderSubtle
      final periodStartCard = tester.widget<Container>(find.descendant(
        of: find.byKey(const Key('billing_period_start_card')),
        matching: find.byType(Container),
      ).first);
      final periodStartDec = periodStartCard.decoration as BoxDecoration;
      expect(periodStartDec.color, AppTheme.darkSurfaceContainerLow);
      expect((periodStartDec.border as Border).top.color, AppTheme.darkBorderSubtle);

      final periodEndCard = tester.widget<Container>(find.descendant(
        of: find.byKey(const Key('billing_period_end_card')),
        matching: find.byType(Container),
      ).first);
      final periodEndDec = periodEndCard.decoration as BoxDecoration;
      expect(periodEndDec.color, AppTheme.darkSurfaceContainerLow);
      expect((periodEndDec.border as Border).top.color, AppTheme.darkBorderSubtle);

      // 2. Pump BillDetailSheet in Dark Mode
      final now = DateTime.now().toUtc();
      final billRecord = Record(
        id: 'bill-1',
        workspaceId: AppConstants.defaultWorkspaceId,
        recordType: 'bill',
        title: 'Electricity Oct 2026',
        createdAt: now,
        updatedAt: now,
      );
      final billItem = BillItem(
        recordId: 'bill-1',
        utilityType: 'electricity',
        providerName: 'Meralco',
        accountNumber: '1092837465',
        amountDueMinor: 245000,
        currencyCode: 'PHP',
        paymentStatus: 'unpaid',
      );
      final recordWithBill = RecordWithBill(
        record: billRecord,
        bill: billItem,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: Scaffold(
              body: BillDetailSheet(item: recordWithBill),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify BillDetailSheet root container has darkSurfaceCard
      final detailSheetContainer = tester.widget<Container>(find.descendant(
        of: find.byType(BillDetailSheet),
        matching: find.byType(Container),
      ).first);
      final detailSheetDec = detailSheetContainer.decoration as BoxDecoration;
      expect(detailSheetDec.color, AppTheme.darkSurfaceCard);

      // Verify header utility icon container has darkSurfaceContainerLow and darkBrandSecondary icon
      final boltIcon = tester.widget<Icon>(find.byIcon(Icons.bolt));
      expect(boltIcon.color, AppTheme.darkBrandSecondary);

      final boltContainer = tester.widget<Container>(find.ancestor(
        of: find.byIcon(Icons.bolt),
        matching: find.byType(Container),
      ).first);
      final boltDec = boltContainer.decoration as BoxDecoration;
      expect(boltDec.color, AppTheme.darkSurfaceContainerLow);

      // Verify Amount Due value text has darkBrandSecondary
      final amountDueText = tester.widget<Text>(find.text('PHP 2450.00'));
      expect(amountDueText.style?.color, AppTheme.darkBrandSecondary);
    });
  });
}
