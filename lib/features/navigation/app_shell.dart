import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_providers.dart';
import '../../core/theme/app_colors.dart';
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
