import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../records/presentation/records_screen.dart';
import '../tasks/presentation/tasks_screen.dart';
import '../today/presentation/today_screen.dart';
import '../vault/presentation/vault_screen.dart';

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
      const TodayScreen(),
      const RecordsScreen(),
      const VaultScreen(),
      const TasksScreen(),
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
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: context.surfaceCard,
            border: Border(
              top: BorderSide(color: context.borderSubtle),
            ),
          ),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            currentIndex: selectedIndex,
            onTap: (index) => ref.read(selectedTabIndexProvider.notifier).setIndex(index),
            selectedItemColor: context.textPrimary,
            unselectedItemColor: context.textSecondary,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.wb_sunny_outlined),
                activeIcon: Container(
                  width: 56,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.brandAccent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.wb_sunny, color: context.brandAccent),
                ),
                label: 'Today',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.inventory_2_outlined),
                activeIcon: Container(
                  width: 56,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.brandAccent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.inventory_2, color: context.brandAccent),
                ),
                label: 'Records',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.lock_outline),
                activeIcon: Container(
                  width: 56,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.brandAccent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.lock, color: context.brandAccent),
                ),
                label: 'Vault',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.checklist_outlined),
                activeIcon: Container(
                  width: 56,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.brandAccent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.checklist, color: context.brandAccent),
                ),
                label: 'Tasks',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
