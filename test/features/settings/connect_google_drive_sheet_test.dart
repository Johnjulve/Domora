import 'dart:async';
import 'dart:io';

import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/core/services/app_preferences.dart';
import 'package:domora/core/services/google_auth_service.dart';
import 'package:domora/core/theme/app_theme.dart';
import 'package:domora/features/backup/data/backup_repository_impl.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/onboarding/presentation/widgets/storage_choice_step.dart';
import 'package:domora/features/settings/presentation/settings_profile_screen.dart';
import 'package:domora/features/settings/presentation/widgets/connect_google_drive_sheet.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

class FakeGoogleSignInAccount implements GoogleSignInAccount {
  FakeGoogleSignInAccount({
    required this.email,
    this.displayName = 'Test User',
    this.id = '123456789',
    this.photoUrl,
  });

  @override
  final String email;

  @override
  final String? displayName;

  @override
  final String id;

  @override
  final String? photoUrl;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGoogleAuthService extends GoogleAuthService {
  FakeGoogleAuthService({
    this.fakeAccount,
    this.shouldThrow = false,
  });

  final GoogleSignInAccount? fakeAccount;
  final bool shouldThrow;
  bool signOutCalled = false;
  int signInCallCount = 0;

  @override
  GoogleSignInAccount? get currentUser => fakeAccount;

  @override
  Future<GoogleSignInAccount?> signIn() async {
    signInCallCount++;
    if (shouldThrow) {
      return null;
    }
    return fakeAccount;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

class DelayGoogleAuthService extends GoogleAuthService {
  final Future<GoogleSignInAccount?> future;
  DelayGoogleAuthService(this.future);

  @override
  Future<GoogleSignInAccount?> signIn() => future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AppPreferences prefs;
  late Directory tempTestDir;
  late FakeGoogleAuthService fakeAuthService;
  late FakeGoogleSignInAccount defaultFakeAccount;

  setUp(() async {
    tempTestDir = Directory.systemTemp.createTempSync('domora_gdrive_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempTestDir.path);

    db = AppDatabase.forTesting(NativeDatabase.memory());
    prefs = AppPreferences.forTesting();
    defaultFakeAccount = FakeGoogleSignInAccount(email: 'test.user@example.com');
    fakeAuthService = FakeGoogleAuthService(fakeAccount: defaultFakeAccount);
  });

  tearDown(() async {
    await db.close();
    try {
      if (tempTestDir.existsSync()) {
        tempTestDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  Widget buildTestableSheet({
    AppPreferences? testPrefs,
    GoogleAuthService? testAuthService,
  }) {
    return ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWithValue(testPrefs ?? prefs),
        googleAuthServiceProvider.overrideWithValue(testAuthService ?? fakeAuthService),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const ConnectGoogleDriveConfirmationSheet(),
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTestableSettingsScreen({
    AppPreferences? testPrefs,
    GoogleAuthService? testAuthService,
  }) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appPreferencesProvider.overrideWithValue(testPrefs ?? prefs),
        googleAuthServiceProvider.overrideWithValue(testAuthService ?? fakeAuthService),
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

  group('ConnectGoogleDriveConfirmationSheet (Screen 12)', () {
    testWidgets('Renders Zero-Knowledge badge, 3 privacy promises and action buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableSheet());
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Check sheet container and grab handle
      expect(find.byKey(const Key('connect_google_drive_sheet')), findsOneWidget);

      // Check Header & Zero-Knowledge badge
      expect(find.byKey(const Key('zero_knowledge_badge')), findsOneWidget);
      expect(find.text('Zero-Knowledge'), findsOneWidget);

      // Check Headline & Subtext
      expect(find.text('Back up to Google Drive?'), findsOneWidget);
      expect(
        find.text('Keep household records safely synced across devices while preserving full end-to-end privacy.'),
        findsOneWidget,
      );

      // Check 3 Privacy Promises
      expect(find.text('Encrypted before upload'), findsOneWidget);
      expect(find.text('Vault sealed with local private key before leaving this phone.'), findsOneWidget);

      expect(find.text('Only you can read it'), findsOneWidget);
      expect(find.text('Neither Google nor Domora holds the keys.'), findsOneWidget);

      expect(find.text('Stored in a private app folder'), findsOneWidget);
      expect(find.text('Isolated sandbox container on your Drive.'), findsOneWidget);

      // Check buttons
      expect(find.byKey(const Key('connect_google_account_button')), findsOneWidget);
      expect(find.byKey(const Key('not_now_button')), findsOneWidget);
    });

    testWidgets('Tapping "Connect Google Account" updates preferences and dismisses sheet with true',
        (WidgetTester tester) async {
      bool? modalResult;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            googleAuthServiceProvider.overrideWithValue(fakeAuthService),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    modalResult = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const ConnectGoogleDriveConfirmationSheet(),
                    );
                  },
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially false
      expect(prefs.isGoogleDriveBackupEnabled, false);
      expect(prefs.googleAccountEmail, isNull);

      // Open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Tap Connect
      await tester.tap(find.byKey(const Key('connect_google_account_button')));
      await tester.pumpAndSettle();

      // Verified modal result & preferences updated with real account email
      expect(modalResult, isTrue);
      expect(prefs.isGoogleDriveBackupEnabled, isTrue);
      expect(prefs.googleAccountEmail, 'test.user@example.com');
      // Authentic metric: backup timestamp remains null until actual sync occurs
      expect(prefs.lastBackupTimestamp, isNull);
      expect(fakeAuthService.signInCallCount, 1);
      expect(find.byKey(const Key('connect_google_drive_sheet')), findsNothing);
    });

    testWidgets('PopScope prevents dismissing sheet while sign-in is in flight',
        (WidgetTester tester) async {
      final completer = Completer<GoogleSignInAccount?>();
      final slowAuthService = DelayGoogleAuthService(completer.future);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            googleAuthServiceProvider.overrideWithValue(slowAuthService),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const ConnectGoogleDriveConfirmationSheet(),
                  ),
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Tap connect to enter loading state
      await tester.tap(find.byKey(const Key('connect_google_account_button')));
      await tester.pump();

      // Loading indicator is visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Verify PopScope canPop is false
      final popScopeFinder = find.byType(PopScope);
      expect(popScopeFinder, findsWidgets);
      final popScope = tester.widget<PopScope>(popScopeFinder.first);
      expect(popScope.canPop, isFalse);

      // Complete sign-in
      completer.complete(defaultFakeAccount);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('connect_google_drive_sheet')), findsNothing);
      expect(prefs.isGoogleDriveBackupEnabled, isTrue);
      expect(prefs.googleAccountEmail, 'test.user@example.com');
      expect(prefs.lastBackupTimestamp, isNull);
    });

    testWidgets('Cancellation (returning null) does not enable backup and displays notice',
        (WidgetTester tester) async {
      final cancelledAuthService = FakeGoogleAuthService(fakeAccount: null);
      bool? modalResult;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            googleAuthServiceProvider.overrideWithValue(cancelledAuthService),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    modalResult = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const ConnectGoogleDriveConfirmationSheet(),
                    );
                  },
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(prefs.isGoogleDriveBackupEnabled, false);
      expect(prefs.googleAccountEmail, isNull);

      // Open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Tap Connect with cancelled auth
      await tester.tap(find.byKey(const Key('connect_google_account_button')));
      await tester.pumpAndSettle();

      // Sheet remains open, backup not enabled, notice displayed
      expect(modalResult, isNull);
      expect(prefs.isGoogleDriveBackupEnabled, false);
      expect(prefs.googleAccountEmail, isNull);
      expect(cancelledAuthService.signInCallCount, 1);
      expect(find.byKey(const Key('connect_google_drive_sheet')), findsOneWidget);
      expect(find.text('Google sign-in cancelled or unavailable'), findsOneWidget);

      // Tap Not now to dismiss
      await tester.tap(find.byKey(const Key('not_now_button')));
      await tester.pumpAndSettle();

      expect(modalResult, isFalse);
      expect(find.byKey(const Key('connect_google_drive_sheet')), findsNothing);
    });

    testWidgets('Tapping "Not now" dismisses sheet without modifying preferences and returns false',
        (WidgetTester tester) async {
      bool? modalResult;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            googleAuthServiceProvider.overrideWithValue(fakeAuthService),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    modalResult = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const ConnectGoogleDriveConfirmationSheet(),
                    );
                  },
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('not_now_button')));
      await tester.pumpAndSettle();

      expect(modalResult, isFalse);
      expect(prefs.isGoogleDriveBackupEnabled, false);
      expect(prefs.googleAccountEmail, isNull);
      expect(find.byKey(const Key('connect_google_drive_sheet')), findsNothing);
    });
  });

  group('SettingsProfileScreen Google Drive Backup (Screen 11)', () {
    testWidgets('Inactive state: shows Google Drive row with Inactive badge and opens sheet on tap',
        (WidgetTester tester) async {
      expect(prefs.isGoogleDriveBackupEnabled, false);

      await tester.pumpWidget(buildTestableSettingsScreen());
      await tester.pumpAndSettle();

      final rowFinder = find.byKey(const Key('connect_google_drive_row'));
      await tester.ensureVisible(rowFinder);
      await tester.pumpAndSettle();

      expect(find.text('Google Drive Cloud Backup'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(rowFinder, findsOneWidget);

      // Tap to open sheet
      await tester.tap(rowFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('connect_google_drive_sheet')), findsOneWidget);
      expect(find.text('Back up to Google Drive?'), findsOneWidget);

      // Dismiss
      await tester.tap(find.byKey(const Key('not_now_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('connect_google_drive_sheet')), findsNothing);
    });

    testWidgets('Active state: displays email, Wi-Fi toggle, Back up now, Recovery Key, and Sign out',
        (WidgetTester tester) async {
      final activePrefs = AppPreferences.forTesting({
        'google_drive_backup_enabled': true,
        'google_account_email': 'test.user@example.com',
        'backup_wifi_only': true,
        'last_backup_timestamp': 'Today, 2:14 PM',
      });

      await tester.pumpWidget(buildTestableSettingsScreen(testPrefs: activePrefs));
      await tester.pumpAndSettle();

      final masterSwitch = find.byKey(const Key('google_drive_master_switch'));
      await tester.ensureVisible(masterSwitch);
      await tester.pumpAndSettle();

      // Section 3: Backup Active Card
      expect(find.text('Google Drive'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('test.user@example.com'), findsOneWidget);
      expect(masterSwitch, findsOneWidget);

      // Toggling master switch pauses backup without destroying the card
      await tester.tap(masterSwitch);
      await tester.pumpAndSettle();
      expect(activePrefs.isGoogleDriveBackupEnabled, false);
      expect(activePrefs.googleAccountEmail, 'test.user@example.com');
      expect(find.text('Paused'), findsOneWidget);
      expect(find.byKey(const Key('google_drive_master_switch')), findsOneWidget);

      // Toggling back on returns to Active
      await tester.tap(masterSwitch);
      await tester.pumpAndSettle();
      expect(activePrefs.isGoogleDriveBackupEnabled, true);
      expect(find.text('Active'), findsOneWidget);

      // Sanctuary Backup & Restore is present in connected card
      expect(find.byKey(const Key('cloud_backup_restore_row')), findsOneWidget);
      expect(find.text('Sanctuary Backup & Restore'), findsOneWidget);

      // Wi-Fi only toggle
      expect(find.text('Back up on Wi-Fi only'), findsOneWidget);
      final wifiSwitchFinder = find.byKey(const Key('wifi_only_backup_switch'));
      expect(wifiSwitchFinder, findsOneWidget);
      expect(activePrefs.isBackupWifiOnly, true);

      await tester.tap(wifiSwitchFinder);
      await tester.pumpAndSettle();
      expect(activePrefs.isBackupWifiOnly, false);

      // Back up now trigger
      final backupNowButton = find.byKey(const Key('back_up_now_button'));
      await tester.ensureVisible(backupNowButton);
      await tester.pumpAndSettle();

      expect(find.text('Back up now'), findsOneWidget);
      expect(find.text('Last backup: Today, 2:14 PM'), findsOneWidget);
      expect(backupNowButton, findsOneWidget);

      await tester.tap(backupNowButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Encrypted snapshot synchronized to Google Drive'), findsOneWidget);
      expect(activePrefs.lastBackupTimestamp, 'Just now');
      expect(find.text('Last backup: Just now'), findsOneWidget);

      // Recovery Key row
      final recoveryKeyRow = find.byKey(const Key('recovery_key_row'));
      await tester.ensureVisible(recoveryKeyRow);
      await tester.pumpAndSettle();

      expect(recoveryKeyRow, findsOneWidget);
      await tester.tap(recoveryKeyRow);
      await tester.pumpAndSettle();

      expect(find.text('Sanctuary Recovery Key'), findsOneWidget);
      expect(find.textContaining('anchor'), findsOneWidget);
      expect(find.textContaining('willow'), findsOneWidget);

      // Close Recovery Key dialog
      await tester.tap(find.byKey(const Key('close_recovery_key_dialog_button')));
      await tester.pumpAndSettle();
      expect(find.text('Sanctuary Recovery Key'), findsNothing);

      // Sign out of Google action
      final signOutFinder = find.byKey(const Key('sign_out_google_button'));
      await tester.ensureVisible(signOutFinder);
      await tester.pumpAndSettle();

      expect(signOutFinder, findsOneWidget);
      await tester.tap(signOutFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Disconnected from Google Drive'), findsOneWidget);
      expect(activePrefs.isGoogleDriveBackupEnabled, false);
      expect(activePrefs.googleAccountEmail, isNull);
      expect(fakeAuthService.signOutCalled, isTrue);

      // UI should transition back to inactive card
      expect(find.text('Google Drive Cloud Backup'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
    });

    testWidgets('Shows "Last backup: Never" when no previous backup timestamp exists',
        (WidgetTester tester) async {
      final unbackedPrefs = AppPreferences.forTesting({
        'google_drive_backup_enabled': true,
        'google_account_email': 'test.user@example.com',
        'last_backup_timestamp': null,
      });

      await tester.pumpWidget(buildTestableSettingsScreen(testPrefs: unbackedPrefs));
      await tester.pumpAndSettle();

      final backupNowButton = find.byKey(const Key('back_up_now_button'));
      await tester.ensureVisible(backupNowButton);
      await tester.pumpAndSettle();

      expect(find.text('Last backup: Never'), findsOneWidget);
    });
  });

  group('Onboarding StorageChoiceStep Google Drive Connection', () {
    testWidgets('Tapping Option 2 opens ConnectGoogleDriveConfirmationSheet, connecting advances via onContinue',
        (WidgetTester tester) async {
      bool onContinueCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            googleAuthServiceProvider.overrideWithValue(fakeAuthService),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: StorageChoiceStep(
                onContinue: () => onContinueCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Option 2 "Continue with Google" card
      await tester.tap(find.text('Continue with Google').first);
      await tester.pumpAndSettle();

      // Expect sheet to open
      expect(find.byKey(const Key('connect_google_drive_sheet')), findsOneWidget);

      // Connect Google Account
      await tester.tap(find.byKey(const Key('connect_google_account_button')));
      await tester.pumpAndSettle();

      // Sheet dismissed, onContinue called, prefs updated
      expect(find.byKey(const Key('connect_google_drive_sheet')), findsNothing);
      expect(onContinueCalled, isTrue);
      expect(prefs.isGoogleDriveBackupEnabled, isTrue);
      expect(prefs.googleAccountEmail, 'test.user@example.com');
      expect(prefs.lastBackupTimestamp, isNull);
    });

    testWidgets('Tapping primary button when Google is selected opens sheet and dismissal preserves step',
        (WidgetTester tester) async {
      bool onContinueCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            googleAuthServiceProvider.overrideWithValue(fakeAuthService),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: StorageChoiceStep(
                onContinue: () => onContinueCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open sheet by tapping Option 2 card and dismiss with "Not now"
      await tester.tap(find.text('Continue with Google').first);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('not_now_button')));
      await tester.pumpAndSettle();

      expect(onContinueCalled, isFalse);
      expect(find.byKey(const Key('connect_google_drive_sheet')), findsNothing);

      // Now Google is selected in state, tap the bottom primary ElevatedButton
      final continueButton = find.byType(ElevatedButton);
      await tester.ensureVisible(continueButton);
      await tester.pumpAndSettle();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Sheet opens again
      expect(find.byKey(const Key('connect_google_drive_sheet')), findsOneWidget);

      // Connect Google Account
      await tester.tap(find.byKey(const Key('connect_google_account_button')));
      await tester.pumpAndSettle();

      expect(onContinueCalled, isTrue);
      expect(prefs.isGoogleDriveBackupEnabled, isTrue);
      expect(prefs.googleAccountEmail, 'test.user@example.com');
      expect(prefs.lastBackupTimestamp, isNull);
    });
  });
}
