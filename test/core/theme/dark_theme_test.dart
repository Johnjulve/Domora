import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/core/services/app_preferences.dart';
import 'package:domora/core/services/notification_service.dart';
import 'package:domora/core/theme/app_colors.dart';
import 'package:domora/core/theme/app_theme.dart';
import 'package:domora/core/theme/app_typography.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/onboarding/presentation/onboarding_screen.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/presentation/records_screen.dart';
import 'package:domora/features/settings/presentation/settings_profile_screen.dart';
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
  });
}
