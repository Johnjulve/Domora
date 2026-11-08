import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/core/theme/app_theme.dart';
import 'package:domora/features/backup/data/backup_repository_impl.dart';
import 'package:domora/features/onboarding/presentation/onboarding_screen.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestableOnboarding({VoidCallback? onCompleted}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        workspaceRepositoryProvider.overrideWithValue(WorkspaceRepositoryImpl(db)),
        backupRepositoryProvider.overrideWithValue(BackupRepositoryImpl(db)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: OnboardingScreen(onCompleted: onCompleted),
      ),
    );
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('First-Run Sanctuary Onboarding Tests', () {
    testWidgets('Complete 5-step walkthrough flow from Welcome to Finish', (WidgetTester tester) async {
      bool completedCalled = false;

      await tester.pumpWidget(
        buildTestableOnboarding(
          onCompleted: () => completedCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      // Step 0: Welcome Screen
      expect(find.text('Domora'), findsOneWidget);
      expect(find.text('Your home & life, in one safe place'), findsOneWidget);
      expect(find.text('100% on-device encryption'), findsOneWidget);
      expect(find.text('Zero cloud tracking'), findsOneWidget);

      // Tap Get Started -> Step 1
      await tapVisible(tester, find.text('Get Started'));

      // Step 1: How Domora Works
      expect(find.text('How Domora works'), findsOneWidget);
      expect(find.text('STEP 1 OF 4'), findsOneWidget);
      expect(find.text('Keep everything together'), findsOneWidget);
      expect(find.text('Never miss a date'), findsOneWidget);
      expect(find.text('Private by design'), findsOneWidget);

      // Tap Continue -> Step 2
      await tapVisible(tester, find.text('Continue'));

      // Step 2: Storage Choice
      expect(find.text('How would you like to start?'), findsOneWidget);
      expect(find.text('STEP 2 OF 4'), findsOneWidget);
      expect(find.text('Continue with Google'), findsWidgets);
      expect(find.text('Continue without an account'), findsOneWidget);

      // Switch to Offline storage
      await tapVisible(tester, find.text('Continue without an account'));

      // Tap Continue Offline -> Step 3
      await tapVisible(tester, find.text('Continue Offline'));

      // Step 3: Protect Your Records (Biometrics)
      expect(find.text('Protect your records'), findsOneWidget);
      expect(find.text('STEP 3 OF 4'), findsOneWidget);
      expect(find.text('Instant app lock'), findsOneWidget);
      expect(find.text('Hardware protected'), findsOneWidget);
      expect(find.text('Turn on Biometrics'), findsOneWidget);

      // Tap Turn on Biometrics -> Step 4
      await tapVisible(tester, find.text('Turn on Biometrics'));

      // Step 4: Save Recovery Key
      expect(find.text('Save your recovery key'), findsOneWidget);
      expect(find.text('STEP 4 OF 4'), findsOneWidget);
      expect(find.text('Important Security Notice'), findsOneWidget);
      expect(find.text('12-Word Passphrase'), findsOneWidget);
      expect(find.text('anchor'), findsOneWidget);
      expect(find.text('willow'), findsOneWidget);

      // Copy 12 words
      await tapVisible(tester, find.text('Copy 12 Words'));
      expect(find.text('Copied to Clipboard'), findsOneWidget);

      // Check the confirmation checkbox
      await tapVisible(tester, find.text("I've saved my recovery key"));

      // Tap Finish & Enter Domora
      expect(find.text('Finish & Enter Domora'), findsOneWidget);
      await tapVisible(tester, find.text('Finish & Enter Domora'));

      expect(completedCalled, isTrue);

      // Clean flush
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Tapping "I already have a backup" on Welcome opens BackupSheet', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableOnboarding());
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('I already have a backup'));

      // BackupSheet opened
      expect(find.text('Sanctuary Archival'), findsOneWidget);
      expect(find.text('Restore Vault'), findsOneWidget);

      // Dismiss sheet
      Navigator.of(tester.element(find.text('Sanctuary Archival'))).pop();
      await tester.pumpAndSettle();

      // Clean flush
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Back button navigates to previous step correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableOnboarding());
      await tester.pumpAndSettle();

      // Step 0 -> Step 1
      await tapVisible(tester, find.text('Get Started'));
      expect(find.text('STEP 1 OF 4'), findsOneWidget);

      // Back to Step 0
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Your home & life, in one safe place'), findsOneWidget);

      // Clean flush
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
