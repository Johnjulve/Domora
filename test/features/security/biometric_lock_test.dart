import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/core/services/app_preferences.dart';
import 'package:domora/core/services/biometric_service.dart';
import 'package:domora/features/onboarding/presentation/widgets/security_step.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/security/presentation/app_lock_screen.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:domora/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';

class FakeLocalAuth extends LocalAuthentication {
  final bool supported;
  final bool canCheck;
  final bool authResult;
  final bool throwError;

  FakeLocalAuth({
    this.supported = true,
    this.canCheck = true,
    this.authResult = true,
    this.throwError = false,
  });

  @override
  Future<bool> isDeviceSupported() async {
    if (throwError) throw PlatformException(code: 'UNAVAILABLE', message: 'No hardware enclave');
    return supported;
  }

  @override
  Future<bool> get canCheckBiometrics async {
    if (throwError) throw PlatformException(code: 'NOT_ENROLLED', message: 'No biometrics enrolled');
    return canCheck;
  }

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<dynamic> authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    if (throwError) throw PlatformException(code: 'AUTH_FAILED', message: 'Hardware failure');
    return authResult;
  }
}

class FakeBiometricService extends BiometricService {
  bool authSuccess;
  int authCallCount = 0;

  FakeBiometricService({this.authSuccess = true});

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<bool> canCheckBiometrics() async => true;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
    bool persistAcrossBackgrounding = true,
  }) async {
    authCallCount++;
    return authSuccess;
  }
}

void main() {
  group('BiometricService Unit & Platform Defensive Tests', () {
    test('Returns false defensively when platform channel throws', () async {
      final throwingAuth = FakeLocalAuth(throwError: true);
      final service = BiometricService(throwingAuth);

      expect(await service.isDeviceSupported(), isFalse);
      expect(await service.canCheckBiometrics(), isFalse);
      expect(
        await service.authenticate(localizedReason: 'Test platform crash resilience'),
        isFalse,
      );
    });

    test('Delegates successfully to native hardware platform when available', () async {
      final successfulAuth = FakeLocalAuth(supported: true, canCheck: true, authResult: true);
      final service = BiometricService(successfulAuth);

      expect(await service.isDeviceSupported(), isTrue);
      expect(await service.canCheckBiometrics(), isTrue);
      expect(
        await service.authenticate(localizedReason: 'Test successful biometric auth'),
        isTrue,
      );
    });

    test('Default constructor operates safely without crashes', () async {
      final defaultService = BiometricService();
      // On desktop or test environment without mock channels, should return false gracefully
      final supported = await defaultService.isDeviceSupported();
      expect(supported, isA<bool>());
    });
  });

  group('AppLockScreen Component & Interaction Tests', () {
    testWidgets('Renders Sanctuary Archival tokens, headlines, and unlock actions', (tester) async {
      var unlocked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              biometricServiceProvider.overrideWithValue(FakeBiometricService(authSuccess: false)),
            ],
            child: AppLockScreen(
              autoPrompt: false,
              onUnlocked: () => unlocked = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Sanctuary headlines and description
      expect(find.text('Domora is Locked'), findsOneWidget);
      expect(
        find.text('Scan your fingerprint or face to access your private sanctuary vault'),
        findsOneWidget,
      );

      // Verify Fingerprint Icon & concentric circles
      expect(find.byIcon(Icons.fingerprint), findsAtLeastNWidgets(1));

      // Verify Primary & Fallback CTA buttons
      expect(find.byKey(const Key('unlock_biometrics_button')), findsOneWidget);
      expect(find.byKey(const Key('quick_unlock_button')), findsOneWidget);
      expect(find.text('Quick Unlock (Alpha Fallback)'), findsOneWidget);
      expect(unlocked, isFalse);
    });

    testWidgets('Tapping Quick Unlock fallback immediately triggers onUnlocked', (tester) async {
      var unlocked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              biometricServiceProvider.overrideWithValue(FakeBiometricService(authSuccess: false)),
            ],
            child: AppLockScreen(
              autoPrompt: false,
              onUnlocked: () => unlocked = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('quick_unlock_button')));
      await tester.pumpAndSettle();

      expect(unlocked, isTrue);
    });

    testWidgets('Tapping Unlock with Biometrics triggers authentication and unlocks on success', (tester) async {
      var unlocked = false;
      final fakeBiometrics = FakeBiometricService(authSuccess: true);

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              biometricServiceProvider.overrideWithValue(fakeBiometrics),
            ],
            child: AppLockScreen(
              autoPrompt: false,
              onUnlocked: () => unlocked = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('unlock_biometrics_button')));
      await tester.pumpAndSettle();

      expect(fakeBiometrics.authCallCount, 1);
      expect(unlocked, isTrue);
    });

    testWidgets('Failed biometric authentication shows error message without unlocking', (tester) async {
      var unlocked = false;
      final fakeBiometrics = FakeBiometricService(authSuccess: false);

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              biometricServiceProvider.overrideWithValue(fakeBiometrics),
            ],
            child: AppLockScreen(
              autoPrompt: false,
              onUnlocked: () => unlocked = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('unlock_biometrics_button')));
      await tester.pumpAndSettle();

      expect(fakeBiometrics.authCallCount, 1);
      expect(unlocked, isFalse);
      expect(find.byKey(const Key('lock_error_message')), findsOneWidget);
      expect(
        find.text('Authentication could not be completed. Use Quick Unlock to proceed.'),
        findsOneWidget,
      );
    });

    testWidgets('Auto-prompt on launch triggers authentication automatically', (tester) async {
      var unlocked = false;
      final fakeBiometrics = FakeBiometricService(authSuccess: true);

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              biometricServiceProvider.overrideWithValue(fakeBiometrics),
            ],
            child: AppLockScreen(
              autoPrompt: true,
              onUnlocked: () => unlocked = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(fakeBiometrics.authCallCount, 1);
      expect(unlocked, isTrue);
    });
  });

  group('SecurityStep Onboarding Integration Tests', () {
    testWidgets('Tapping biometric shield toggles enrollment state and displays SnackBar feedback', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SecurityStep(onContinue: () {}),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap fingerprint shield to enable
      await tester.tap(find.byIcon(Icons.fingerprint).first);
      await tester.pumpAndSettle();

      expect(find.text('Biometric vault protection enabled'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Tap again to toggle off
      await tester.tap(find.byIcon(Icons.check_circle).first);
      await tester.pumpAndSettle();

      expect(find.text('Biometric vault protection disabled'), findsOneWidget);
    });

    testWidgets('Tapping "Skip for now" resets previously toggled biometrics to false', (tester) async {
      var continued = false;
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SecurityStep(onContinue: () => continued = true),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap shield to toggle on
      await tester.tap(find.byIcon(Icons.fingerprint).first);
      await tester.pumpAndSettle();
      expect(container.read(onboardingBiometricsEnabledProvider), isTrue);

      // Dismiss SnackBar and tap "Skip for now"
      ScaffoldMessenger.of(tester.element(find.byType(SecurityStep))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Skip for now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      expect(container.read(onboardingBiometricsEnabledProvider), isFalse);
      expect(continued, isTrue);
    });
  });

  group('DomoraApp Lock State & Lifecycle Integration Tests', () {
    testWidgets('Boots into AppLockScreen when biometrics enabled, unlocks to AppShell', (tester) async {
      final inMemoryDb = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() => inMemoryDb.close());

      final testPrefs = AppPreferences.forTesting({
        'onboarding_completed': true,
        'biometrics_enabled': true,
        'auto_lock_duration': 'Immediately',
      });

      final fakeBiometrics = FakeBiometricService(authSuccess: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(inMemoryDb),
            workspaceRepositoryProvider.overrideWithValue(WorkspaceRepositoryImpl(inMemoryDb)),
            recordRepositoryProvider.overrideWithValue(RecordRepositoryImpl(inMemoryDb)),
            appPreferencesProvider.overrideWithValue(testPrefs),
            biometricServiceProvider.overrideWithValue(fakeBiometrics),
          ],
          child: const DomoraApp(showOnboarding: false),
        ),
      );

      await tester.pumpAndSettle();

      // Locked screen is displayed
      expect(find.text('Domora is Locked'), findsOneWidget);
      expect(find.text('Today'), findsNothing);

      // Quick Unlock unlocks to AppShell
      await tester.tap(find.byKey(const Key('quick_unlock_button')));
      await tester.pumpAndSettle();

      // AppShell with navigation tabs now visible
      expect(find.text('Domora is Locked'), findsNothing);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Records'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Vault'), findsOneWidget);

      // Unmount and flush Drift stream cancellation timer
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Lifecycle auto-lock re-locks app after threshold duration expires', (tester) async {
      final inMemoryDb = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() => inMemoryDb.close());

      final testPrefs = AppPreferences.forTesting({
        'onboarding_completed': true,
        'biometrics_enabled': true,
        'auto_lock_duration': 'After 1 minute',
      });

      final fakeBiometrics = FakeBiometricService(authSuccess: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(inMemoryDb),
            workspaceRepositoryProvider.overrideWithValue(WorkspaceRepositoryImpl(inMemoryDb)),
            recordRepositoryProvider.overrideWithValue(RecordRepositoryImpl(inMemoryDb)),
            appPreferencesProvider.overrideWithValue(testPrefs),
            biometricServiceProvider.overrideWithValue(fakeBiometrics),
          ],
          child: const DomoraApp(showOnboarding: false),
        ),
      );

      await tester.pumpAndSettle();

      // Unlock first
      await tester.tap(find.byKey(const Key('quick_unlock_button')));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);

      final appState = tester.state<DomoraAppState>(find.byType(DomoraApp));

      // Test short duration under 60 seconds (no lock)
      appState.pausedAt = DateTime.now().subtract(const Duration(seconds: 10));
      appState.checkAutoLock();
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Domora is Locked'), findsNothing);

      // Test elapsed duration exceeding 60 seconds (locks!)
      appState.pausedAt = DateTime.now().subtract(const Duration(seconds: 70));
      appState.checkAutoLock();
      await tester.pumpAndSettle();
      expect(find.text('Domora is Locked'), findsOneWidget);

      // Unmount and flush Drift stream cancellation timer
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Lock overlay obscures pushed Navigator sub-routes when app locks', (tester) async {
      final inMemoryDb = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() => inMemoryDb.close());

      final testPrefs = AppPreferences.forTesting({
        'onboarding_completed': true,
        'biometrics_enabled': true,
        'auto_lock_duration': 'Immediately',
      });

      final fakeBiometrics = FakeBiometricService(authSuccess: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(inMemoryDb),
            workspaceRepositoryProvider.overrideWithValue(WorkspaceRepositoryImpl(inMemoryDb)),
            recordRepositoryProvider.overrideWithValue(RecordRepositoryImpl(inMemoryDb)),
            appPreferencesProvider.overrideWithValue(testPrefs),
            biometricServiceProvider.overrideWithValue(fakeBiometrics),
          ],
          child: const DomoraApp(showOnboarding: false),
        ),
      );

      await tester.pumpAndSettle();

      // Unlock initial lock screen
      await tester.tap(find.byKey(const Key('quick_unlock_button')));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);

      // Push a simulated sub-route onto the navigator
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      navigator.push(
        MaterialPageRoute<void>(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Secret Sub-Route Screen')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Secret Sub-Route Screen'), findsOneWidget);

      // Trigger app lock via lifecycle
      final appState = tester.state<DomoraAppState>(find.byType(DomoraApp));
      appState.pausedAt = DateTime.now().subtract(const Duration(seconds: 1));
      appState.checkAutoLock();
      await tester.pumpAndSettle();

      // Verify AppLockScreen is displayed globally and sub-route is obscured offstage
      expect(find.text('Domora is Locked'), findsOneWidget);
      expect(find.text('Secret Sub-Route Screen'), findsNothing);

      // Unlock again
      await tester.tap(find.byKey(const Key('quick_unlock_button')));
      await tester.pumpAndSettle();

      // Sub-route is visible again intact
      expect(find.text('Secret Sub-Route Screen'), findsOneWidget);
      expect(find.text('Domora is Locked'), findsNothing);

      // Flush drift stream timers
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
