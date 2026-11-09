import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/core/services/app_preferences.dart';
import 'package:domora/core/theme/app_theme.dart';
import 'package:domora/features/backup/data/backup_repository_impl.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/onboarding/presentation/widgets/terms_and_privacy_sheet.dart';
import 'package:domora/features/onboarding/presentation/widgets/welcome_step.dart';
import 'package:domora/features/settings/presentation/settings_profile_screen.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WelcomeStep Terms & Privacy Policy Mandatory Gate Tests', () {
    late AppPreferences prefs;

    setUp(() {
      prefs = AppPreferences.forTesting({'has_accepted_terms': false});
    });

    Widget buildTestableWelcomeStep({
      required VoidCallback onGetStarted,
      required VoidCallback onOpenBackupSheet,
      ThemeData? theme,
      AppPreferences? customPrefs,
    }) {
      return ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(customPrefs ?? prefs),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.lightTheme,
          home: Scaffold(
            body: WelcomeStep(
              onGetStarted: onGetStarted,
              onOpenBackupSheet: onOpenBackupSheet,
            ),
          ),
        ),
      );
    }

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('Action buttons are disabled by default when terms checkbox is unchecked', (WidgetTester tester) async {
      bool startedCalled = false;
      bool backupCalled = false;

      await tester.pumpWidget(
        buildTestableWelcomeStep(
          onGetStarted: () => startedCalled = true,
          onOpenBackupSheet: () => backupCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Welcome UI elements
      expect(find.text('Domora'), findsOneWidget);
      expect(find.text('Your home & life, in one safe place'), findsOneWidget);
      expect(find.byKey(const Key('terms_acceptance_checkbox')), findsOneWidget);

      final checkbox = tester.widget<Checkbox>(find.byKey(const Key('terms_acceptance_checkbox')));
      expect(checkbox.value, isFalse);

      final getStartedButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(getStartedButton.enabled, isFalse);

      final backupButton = tester.widget<TextButton>(find.byType(TextButton));
      expect(backupButton.enabled, isFalse);

      // Attempt tapping disabled buttons - neither callback must fire
      await tapVisible(tester, find.byType(ElevatedButton));
      expect(startedCalled, isFalse);

      await tapVisible(tester, find.byType(TextButton));
      expect(backupCalled, isFalse);
    });

    testWidgets('Tapping "Terms of Service" opens modal bottom sheet on Terms tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWelcomeStep(
          onGetStarted: () {},
          onOpenBackupSheet: () {},
        ),
      );
      await tester.pumpAndSettle();

      final termsLink = find.byKey(const Key('terms_of_service_link'));
      expect(termsLink, findsOneWidget);
      await tapVisible(tester, termsLink);

      // Verify sheet is open
      expect(find.byKey(const Key('terms_and_privacy_sheet')), findsOneWidget);
      expect(find.byType(TermsAndPrivacySheet), findsOneWidget);
      expect(find.text('OFFLINE SANCTUARY • ZERO TRACKING'), findsOneWidget);
      expect(find.text('Welcome to Domora'), findsOneWidget);
      expect(find.text('Self-Sovereign Data Custody'), findsOneWidget);
      expect(find.text('Master Recovery Key & Encryption'), findsOneWidget);

      // Close sheet with agreement button
      await tapVisible(tester, find.byKey(const Key('close_terms_sheet_button')));
      expect(find.byKey(const Key('terms_and_privacy_sheet')), findsNothing);

      // Verifies Finding 2: Agreeing inside the sheet automatically accepts on WelcomeStep
      expect(tester.widget<Checkbox>(find.byKey(const Key('terms_acceptance_checkbox'))).value, isTrue);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled, isTrue);
    });

    testWidgets('Tapping "Privacy Policy" opens modal bottom sheet on Privacy tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWelcomeStep(
          onGetStarted: () {},
          onOpenBackupSheet: () {},
        ),
      );
      await tester.pumpAndSettle();

      final privacyLink = find.byKey(const Key('privacy_policy_link'));
      expect(privacyLink, findsOneWidget);
      await tapVisible(tester, privacyLink);

      // Verify sheet is open with Privacy content
      expect(find.byKey(const Key('terms_and_privacy_sheet')), findsOneWidget);
      expect(find.text('Radical Privacy by Architecture'), findsOneWidget);
      expect(find.text('Zero Tracking & Zero Analytics'), findsOneWidget);
      expect(find.text('100% On-Device SQLite Storage'), findsOneWidget);
      expect(find.text('Hardware Keystore Biometrics'), findsOneWidget);

      // Can switch to Terms of Service tab inside the sheet
      await tapVisible(tester, find.byKey(const Key('terms_tab_button')));
      expect(find.text('Welcome to Domora'), findsOneWidget);

      // Dismiss via top close icon
      await tapVisible(tester, find.byKey(const Key('dismiss_terms_sheet_icon_button')));
      expect(find.byKey(const Key('terms_and_privacy_sheet')), findsNothing);
    });

    testWidgets('Tapping checkbox toggles button states between disabled and enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWelcomeStep(
          onGetStarted: () {},
          onOpenBackupSheet: () {},
        ),
      );
      await tester.pumpAndSettle();

      final checkboxFinder = find.byKey(const Key('terms_acceptance_checkbox'));

      // Initially disabled
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled, isFalse);
      expect(tester.widget<TextButton>(find.byType(TextButton)).enabled, isFalse);

      // Tap to check
      await tapVisible(tester, checkboxFinder);

      expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled, isTrue);
      expect(tester.widget<TextButton>(find.byType(TextButton)).enabled, isTrue);

      // Tap again to uncheck
      await tapVisible(tester, checkboxFinder);

      expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled, isFalse);
      expect(tester.widget<TextButton>(find.byType(TextButton)).enabled, isFalse);
    });

    testWidgets('Tapping label text toggles terms acceptance checkbox', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWelcomeStep(
          onGetStarted: () {},
          onOpenBackupSheet: () {},
        ),
      );
      await tester.pumpAndSettle();

      final checkboxFinder = find.byKey(const Key('terms_acceptance_checkbox'));
      expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);

      // Tap the label prefix
      await tapVisible(tester, find.text('I agree to the '));
      expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);

      // Tap the label separator
      await tapVisible(tester, find.text(' and '));
      expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);
    });

    testWidgets('Tapping "Get Started" when accepted persists acceptance and calls callback', (WidgetTester tester) async {
      bool startedCalled = false;

      await tester.pumpWidget(
        buildTestableWelcomeStep(
          onGetStarted: () => startedCalled = true,
          onOpenBackupSheet: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(prefs.hasAcceptedTerms, isFalse);

      // Check box
      await tapVisible(tester, find.byKey(const Key('terms_acceptance_checkbox')));

      // Tap Get Started
      await tapVisible(tester, find.byType(ElevatedButton));

      expect(startedCalled, isTrue);
      expect(prefs.hasAcceptedTerms, isTrue);
    });

    testWidgets('Tapping "I already have a backup" when accepted persists acceptance and calls callback', (WidgetTester tester) async {
      bool backupCalled = false;

      await tester.pumpWidget(
        buildTestableWelcomeStep(
          onGetStarted: () {},
          onOpenBackupSheet: () => backupCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(prefs.hasAcceptedTerms, isFalse);

      // Check box
      await tapVisible(tester, find.byKey(const Key('terms_acceptance_checkbox')));

      // Tap Backup button
      await tapVisible(tester, find.byType(TextButton));

      expect(backupCalled, isTrue);
      expect(prefs.hasAcceptedTerms, isTrue);
    });

    testWidgets('Initializes checkbox to true if AppPreferences already has accepted terms', (WidgetTester tester) async {
      final preAcceptedPrefs = AppPreferences.forTesting({'has_accepted_terms': true});

      await tester.pumpWidget(
        buildTestableWelcomeStep(
          onGetStarted: () {},
          onOpenBackupSheet: () {},
          customPrefs: preAcceptedPrefs,
        ),
      );
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(find.byKey(const Key('terms_acceptance_checkbox')));
      expect(checkbox.value, isTrue);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled, isTrue);
      expect(tester.widget<TextButton>(find.byType(TextButton)).enabled, isTrue);
    });

    testWidgets('Renders cleanly without overflow in Sanctuary Dark Theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWelcomeStep(
          onGetStarted: () {},
          onOpenBackupSheet: () {},
          theme: AppTheme.darkTheme,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Domora'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SettingsProfileScreen has Terms & Privacy Policy tile that opens sheet', (WidgetTester tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() => db.close());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            appPreferencesProvider.overrideWithValue(prefs),
            workspaceRepositoryProvider.overrideWithValue(WorkspaceRepositoryImpl(db)),
            categoryRepositoryProvider.overrideWithValue(CategoryRepositoryImpl(db)),
            backupRepositoryProvider.overrideWithValue(BackupRepositoryImpl(db)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SettingsProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tileFinder = find.byKey(const Key('terms_and_privacy_tile'));
      expect(tileFinder, findsOneWidget);

      await tapVisible(tester, tileFinder);

      expect(find.byKey(const Key('terms_and_privacy_sheet')), findsOneWidget);
      expect(find.text('Terms & Privacy Policy'), findsWidgets);
    });
  });
}
