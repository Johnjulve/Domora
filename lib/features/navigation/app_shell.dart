import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/under_construction_dialog.dart';
import '../records/presentation/records_screen.dart';

class SelectedTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 1; // Default to Life Records tab

  void setIndex(int index) => state = index;
}

final selectedTabIndexProvider = NotifierProvider<SelectedTabIndexNotifier, int>(
  SelectedTabIndexNotifier.new,
);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Proactively initialize and seed default workspace on app start
    final workspaceAsync = ref.watch(defaultWorkspaceProvider);
    final selectedIndex = ref.watch(selectedTabIndexProvider);

    final screens = [
      const _TodayDashboardPlaceholder(),
      const RecordsScreen(),
      const _DocumentVaultPlaceholder(),
      const _TasksRoutinesPlaceholder(),
    ];

    return workspaceAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.brandPrimary),
        ),
      ),
      error: (err, _) => Scaffold(
        body: Center(
          child: Text('Failed to initialize workspace: $err'),
        ),
      ),
      data: (_) => Scaffold(
        body: IndexedStack(
          index: selectedIndex,
          children: screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => ref.read(selectedTabIndexProvider.notifier).setIndex(index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.wb_sunny_outlined),
              activeIcon: Icon(Icons.wb_sunny),
              label: 'Today',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Records',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.lock_outline),
              activeIcon: Icon(Icons.lock),
              label: 'Vault',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist_outlined),
              activeIcon: Icon(Icons.checklist),
              label: 'Tasks',
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayDashboardPlaceholder extends StatelessWidget {
  const _TodayDashboardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.brandAccentSage,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wb_sunny_outlined, color: AppColors.brandPrimary, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Daily Rhythm & Insights', style: AppTypography.cardTitle),
              const SizedBox(height: 8),
              const Text(
                'Personalized cadence, urgent deadlines, and daily domestic routines will be aggregated here.',
                style: AppTypography.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => showUnderConstructionNotice(
                  context,
                  featureName: 'Today Dashboard Insights',
                  scheduledPhase: 'Stage 6',
                ),
                child: const Text('Preview Milestone Status'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentVaultPlaceholder extends StatelessWidget {
  const _DocumentVaultPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Vault'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.brandAccentSage,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: AppColors.brandPrimary, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Encrypted Document Storage', style: AppTypography.cardTitle),
              const SizedBox(height: 8),
              const Text(
                'On-device document archiving, warranty PDF attachments, and receipt scanning.',
                style: AppTypography.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => showUnderConstructionNotice(
                  context,
                  featureName: 'Document Vault & OCR Scanner',
                  scheduledPhase: 'Stage 3 & Stage 5',
                ),
                child: const Text('View Vault Schedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TasksRoutinesPlaceholder extends StatelessWidget {
  const _TasksRoutinesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks & Routines'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.brandAccentSage,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.checklist_outlined, color: AppColors.brandPrimary, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Maintenance & Domestic Cadence', style: AppTypography.cardTitle),
              const SizedBox(height: 8),
              const Text(
                'Recurring household tasks, smoke alarm checks, vehicle servicing, and local notifications.',
                style: AppTypography.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => showUnderConstructionNotice(
                  context,
                  featureName: 'Tasks & Recurrence Engine',
                  scheduledPhase: 'Stage 4',
                ),
                child: const Text('View Responsibilities Schedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
