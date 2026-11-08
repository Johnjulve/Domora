import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../backup/presentation/backup_sheet.dart';
import 'widgets/how_it_works_step.dart';
import 'widgets/recovery_key_step.dart';
import 'widgets/security_step.dart';
import 'widgets/storage_choice_step.dart';
import 'widgets/welcome_step.dart';

export 'widgets/security_step.dart' show onboardingBiometricsEnabledProvider;
export 'widgets/storage_choice_step.dart' show onboardingStorageChoiceProvider;

/// Persistent NotifierProvider tracking whether first-run sanctuary onboarding has been completed.
final onboardingCompletedProvider = NotifierProvider<OnboardingCompletedNotifier, bool>(
  OnboardingCompletedNotifier.new,
);

class OnboardingCompletedNotifier extends Notifier<bool> {
  @override
  bool build() {
    try {
      final prefs = ref.watch(appPreferencesProvider);
      return prefs.isOnboardingCompleted;
    } catch (_) {
      return false;
    }
  }

  Future<void> complete() async {
    state = true;
    try {
      final prefs = ref.read(appPreferencesProvider);
      await prefs.setOnboardingCompleted(true);
      await prefs.setStorageMode(ref.read(onboardingStorageChoiceProvider));
      await prefs.setBiometricsEnabled(ref.read(onboardingBiometricsEnabledProvider));
    } catch (_) {}
  }

  Future<void> reset() async {
    state = false;
    try {
      final prefs = ref.read(appPreferencesProvider);
      await prefs.setOnboardingCompleted(false);
    } catch (_) {}
  }
}

/// 5-Step First-Run Onboarding Sanctuary Flow orchestrator.
class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback? onCompleted;

  const OnboardingScreen({super.key, this.onCompleted});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    await ref.read(onboardingCompletedProvider.notifier).complete();
    widget.onCompleted?.call();
  }

  void _openBackupSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const BackupSheet(),
    );
  }

  String _stepTitle(int step) {
    switch (step) {
      case 1:
        return 'How Domora Works';
      case 2:
        return 'Sign In or Skip';
      case 3:
        return 'Protect Your App';
      case 4:
        return 'Save Recovery Key';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentStep > 0) {
          _prevPage();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceCanvas,
        appBar: _currentStep == 0
            ? null
            : AppBar(
                backgroundColor: AppColors.surfaceCanvas,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.brandPrimary),
                  onPressed: _prevPage,
                  tooltip: 'Back',
                ),
                title: Text(
                  _stepTitle(_currentStep),
                  style: AppTypography.cardTitle.copyWith(fontSize: 15),
                ),
                centerTitle: true,
              ),
        body: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (page) => setState(() => _currentStep = page),
            children: [
              WelcomeStep(
                onGetStarted: _nextPage,
                onOpenBackupSheet: _openBackupSheet,
              ),
              HowItWorksStep(onContinue: _nextPage),
              StorageChoiceStep(onContinue: _nextPage),
              SecurityStep(onContinue: _nextPage),
              RecoveryKeyStep(onFinish: _finishOnboarding),
            ],
          ),
        ),
      ),
    );
  }
}
