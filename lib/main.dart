import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/app_preferences.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/app_shell.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/security/presentation/app_lock_screen.dart';

/// Notifier tracking whether the sanctuary vault is locked with biometrics.
/// Defaults to true if biometrics are enabled in user preferences, false otherwise.
final appLockedProvider = NotifierProvider<AppLockedNotifier, bool>(
  AppLockedNotifier.new,
);

class AppLockedNotifier extends Notifier<bool> {
  @override
  bool build() {
    try {
      final prefs = ref.watch(appPreferencesProvider);
      return prefs.isBiometricsEnabled;
    } catch (_) {
      return false;
    }
  }

  void lock() => state = true;
  void unlock() => state = false;
  void setLocked(bool locked) => state = locked;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await AppPreferences.load();
  final notificationService = LocalNotificationService();
  try {
    await notificationService.initialize();
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const DomoraApp(),
    ),
  );
}

class DomoraApp extends ConsumerStatefulWidget {
  final bool? showOnboarding;
  final bool? appLockedOverride;

  const DomoraApp({
    super.key,
    this.showOnboarding,
    this.appLockedOverride,
  });

  @override
  ConsumerState<DomoraApp> createState() => DomoraAppState();
}

class DomoraAppState extends ConsumerState<DomoraApp> with WidgetsBindingObserver {
  DateTime? pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      checkAutoLock();
    }
  }

  void checkAutoLock() {
    final prefs = ref.read(appPreferencesProvider);
    if (!prefs.isBiometricsEnabled) return;

    final recordTime = pausedAt;
    if (recordTime == null) return;
    final elapsedSeconds = DateTime.now().difference(recordTime).inSeconds;
    final threshold = getAutoLockThresholdSeconds(prefs.autoLockDuration);

    if (elapsedSeconds >= threshold) {
      ref.read(appLockedProvider.notifier).lock();
    }
    pausedAt = null;
  }

  static int getAutoLockThresholdSeconds(String durationSetting) {
    switch (durationSetting) {
      case 'Immediately':
        return 0;
      case 'After 1 minute':
        return 60;
      case 'After 5 minutes':
        return 300;
      case 'After 15 minutes':
        return 900;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = ref.watch(onboardingCompletedProvider);
    final isFirstRun = widget.showOnboarding ?? !completed;
    final prefs = ref.watch(appPreferencesProvider);
    final bool isLocked = widget.appLockedOverride ?? ref.watch(appLockedProvider);

    final Widget home = isFirstRun
        ? OnboardingScreen(
            onCompleted: () {
              ref.read(onboardingCompletedProvider.notifier).complete();
            },
          )
        : const AppShell();

    return MaterialApp(
      title: 'Domora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: home,
      builder: (context, child) {
        if (!isFirstRun && prefs.isBiometricsEnabled && isLocked) {
          return Stack(
            children: [
              if (child != null)
                Offstage(
                  offstage: true,
                  child: child,
                ),
              AppLockScreen(
                onUnlocked: () {
                  ref.read(appLockedProvider.notifier).unlock();
                },
              ),
            ],
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
