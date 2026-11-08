import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/app_preferences.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/app_shell.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

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

class DomoraApp extends ConsumerWidget {
  final bool? showOnboarding;

  const DomoraApp({super.key, this.showOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = ref.watch(onboardingCompletedProvider);
    final isFirstRun = showOnboarding ?? !completed;

    return MaterialApp(
      title: 'Domora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isFirstRun
          ? OnboardingScreen(
              onCompleted: () {
                ref.read(onboardingCompletedProvider.notifier).complete();
              },
            )
          : const AppShell(),
    );
  }
}
