import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../backup/presentation/backup_sheet.dart';
import '../../bills/domain/bill_item.dart';
import '../../bills/presentation/add_bill_sheet.dart';
import '../../bills/presentation/bill_detail_sheet.dart';
import '../../expenses/presentation/add_expense_sheet.dart';
import '../../expenses/presentation/expense_detail_sheet.dart';
import '../../navigation/app_shell.dart';
import '../../records/presentation/records_screen.dart';
import '../../settings/presentation/settings_profile_screen.dart';
import '../../tasks/domain/task_item.dart';
import '../../tasks/presentation/tasks_screen.dart';
import '../../vault/presentation/vault_screen.dart';

const List<String> _daysOfWeek = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

const List<String> _monthsFull = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _formatTodayHeader(DateTime now) {
  final dayName = _daysOfWeek[now.weekday - 1];
  final monthName = _monthsFull[now.month - 1];
  return '$dayName, $monthName ${now.day}';
}

String _getGreeting(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: context.brandAccent,
          onRefresh: () async {
            ref.invalidate(dashboardRecordsStreamProvider);
            ref.invalidate(dashboardTasksStreamProvider);
            ref.invalidate(dashboardExpensesStreamProvider);
            ref.invalidate(workspaceTotalExpensesProvider);
            ref.invalidate(activeBillsStreamProvider);
            ref.invalidate(dashboardBillsStreamProvider);
            ref.invalidate(upcomingBillsStreamProvider);
            ref.invalidate(workspaceTotalUnpaidBillsProvider);
            ref.invalidate(dashboardDocumentsStreamProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TodayTopHeader(now: now),
                const SizedBox(height: 20),
                _HeroStatusAndMetricsCard(now: now),
                const SizedBox(height: 12),
                _SummaryCardsSection(now: now),
                const SizedBox(height: 28),
                const _QuickAddSection(),
                const SizedBox(height: 28),
                const _SanctuarySetupCard(),
                const SizedBox(height: 28),
                _Next30DaysSection(now: now),
                const SizedBox(height: 28),
                const _RecentActivitySection(),
                const SizedBox(height: 36),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${AppConstants.appName} v${AppConstants.appVersion}',
                        style: AppTypography.caption.copyWith(
                          color: context.textTertiary,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Offline-First Household Sanctuary',
                        style: AppTypography.caption.copyWith(
                          color: context.textTertiary.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayTopHeader extends StatelessWidget {
  final DateTime now;

  const _TodayTopHeader({required this.now});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatTodayHeader(now),
                style: TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w500,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getGreeting(now.hour),
                style: TextStyle(
                  fontSize: 28,
                  height: 34 / 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const _SanctuaryBadge(),
        const SizedBox(width: 8),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderSubtle),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsProfileScreen()),
                );
              },
              child: Tooltip(
                message: 'Settings & Updates',
                child: Icon(
                  Icons.settings_outlined,
                  size: 20,
                  color: context.brandAccent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SanctuaryBadge extends StatelessWidget {
  const _SanctuaryBadge();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Sanctuary Archival & Backup',
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: context.surfaceCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: context.borderSubtle),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const BackupSheet(),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: context.brandAccent),
                  const SizedBox(width: 6),
                  Text(
                    'On-device',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.brandAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroStatusAndMetricsCard extends ConsumerWidget {
  final DateTime now;

  const _HeroStatusAndMetricsCard({required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(dashboardTasksStreamProvider);
    final billsAsync = ref.watch(upcomingBillsStreamProvider);

    final tasks = tasksAsync.value ?? const [];
    final bills = billsAsync.value ?? const [];

    final focusTasks = tasks.where((t) {
      final task = t.task;
      return task.isPending && (task.isOverdue(now) || task.isDueToday(now));
    }).toList();

    final pendingTasks = tasks.where((t) => t.task.isPending).length;
    final overdueTasks = tasks.where((t) => t.task.isOverdue(now)).length;
    final unpaidBillsCount = bills.length;

    final bool allCaughtUp = focusTasks.isEmpty && unpaidBillsCount == 0;
    final String heroTitle;
    final String heroSubtitle;
    final IconData heroIcon;
    final Color heroIconColor;

    if (allCaughtUp) {
      heroTitle = "You're all caught up";
      heroSubtitle = 'Nothing needs your attention today.';
      heroIcon = Icons.check_circle_outline;
      heroIconColor = context.brandAccent;
    } else if (overdueTasks > 0) {
      heroTitle = '$overdueTasks overdue item${overdueTasks == 1 ? '' : 's'}';
      heroSubtitle = 'Items require your immediate attention.';
      heroIcon = Icons.alarm_outlined;
      heroIconColor = AppColors.statusDangerText;
    } else if (focusTasks.isNotEmpty) {
      heroTitle = '${focusTasks.length} need your attention';
      heroSubtitle = 'Focus on maintenance deadlines scheduled for today.';
      heroIcon = Icons.check_circle_outline;
      heroIconColor = context.brandAccent;
    } else {
      heroTitle = '$unpaidBillsCount bill${unpaidBillsCount == 1 ? '' : 's'} due';
      heroSubtitle = 'Review upcoming utility bills due soon.';
      heroIcon = Icons.check_circle_outline;
      heroIconColor = context.brandAccent;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(heroIcon, size: 24, color: heroIconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      heroTitle,
                      style: TextStyle(
                        fontSize: 18,
                        height: 24 / 18,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      heroSubtitle,
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.borderSubtle),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pendingTasks.toString(),
                        style: TextStyle(
                          fontSize: 26,
                          height: 32 / 26,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        'Tasks today',
                        style: TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w500,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: context.borderSubtle),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overdueTasks.toString(),
                          style: TextStyle(
                            fontSize: 26,
                            height: 32 / 26,
                            fontWeight: FontWeight.w700,
                            color: overdueTasks > 0
                                ? AppColors.statusDangerText
                                : context.textPrimary,
                          ),
                        ),
                        Text(
                          'Overdue',
                          style: TextStyle(
                            fontSize: 12,
                            height: 16 / 12,
                            fontWeight: FontWeight.w500,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: context.borderSubtle),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unpaidBillsCount.toString(),
                          style: TextStyle(
                            fontSize: 26,
                            height: 32 / 26,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          'Bills due',
                          style: TextStyle(
                            fontSize: 12,
                            height: 16 / 12,
                            fontWeight: FontWeight.w500,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCardsSection extends ConsumerWidget {
  final DateTime now;

  const _SummaryCardsSection({required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(dashboardRecordsStreamProvider);
    final expensesTotalAsync = ref.watch(workspaceTotalExpensesProvider);

    final records = recordsAsync.value ?? const [];
    final activeAssets = records.where((r) => r.record.recordType == 'asset').length;

    final String formattedExpenses;
    final Color? expenseColor;
    if (expensesTotalAsync.hasError) {
      formattedExpenses = 'ERR';
      expenseColor = AppColors.statusDangerText;
    } else if (expensesTotalAsync.isLoading) {
      formattedExpenses = '...';
      expenseColor = null;
    } else {
      final totalExpensesMinor = expensesTotalAsync.value ?? 0;
      formattedExpenses = '${AppConstants.defaultCurrency} ${(totalExpensesMinor / 100).toStringAsFixed(2)}';
      expenseColor = null;
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.borderSubtle),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  ref.read(selectedTabIndexProvider.notifier).setIndex(1);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: context.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 18,
                            color: context.brandAccent,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: context.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      activeAssets.toString(),
                      style: TextStyle(
                        fontSize: 26,
                        height: 32 / 26,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      'Assets tracked',
                      style: TextStyle(
                        fontSize: 13,
                        height: 18 / 13,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.borderSubtle),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _openAddExpense(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: context.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            size: 18,
                            color: context.brandAccent,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: context.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formattedExpenses,
                        style: TextStyle(
                          fontSize: 22,
                          height: 32 / 22,
                          fontWeight: FontWeight.w700,
                          color: expenseColor ?? context.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      'Spent in ${_monthsFull[now.month - 1]}',
                      style: TextStyle(
                        fontSize: 13,
                        height: 18 / 13,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openAddExpense(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddExpenseSheet(),
    );
  }
}

class _QuickAddSection extends StatelessWidget {
  const _QuickAddSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick add',
          style: TextStyle(
            fontSize: 16,
            height: 22 / 16,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAddTile(
                icon: Icons.checklist_outlined,
                label: 'Task',
                onTap: () => _openAddTask(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAddTile(
                icon: Icons.inventory_2_outlined,
                label: 'Asset',
                onTap: () => _openAddAsset(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAddTile(
                icon: Icons.receipt_long_outlined,
                label: 'Expense',
                onTap: () => _openAddExpense(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAddTile(
                icon: Icons.bolt_outlined,
                label: 'Bill',
                onTap: () => _openAddBill(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openAddTask(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTaskSheet(),
    );
  }

  void _openAddAsset(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddAssetSheet(),
    );
  }

  void _openAddExpense(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddExpenseSheet(),
    );
  }

  void _openAddBill(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddBillSheet(),
    );
  }
}

class _QuickAddTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAddTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: context.brandAccent),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SanctuarySetupCard extends ConsumerWidget {
  const _SanctuarySetupCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(dashboardRecordsStreamProvider);
    final documentsAsync = ref.watch(dashboardDocumentsStreamProvider);
    final tasksAsync = ref.watch(dashboardTasksStreamProvider);

    final records = recordsAsync.value ?? const [];
    final documents = documentsAsync.value ?? const [];
    final tasks = tasksAsync.value ?? const [];

    final bool hasAssets = records.any((r) => r.record.recordType == 'asset');
    final bool hasDocuments = documents.isNotEmpty;
    final bool hasTasks = tasks.isNotEmpty;

    final int completedCount = (hasAssets ? 1 : 0) + (hasDocuments ? 1 : 0) + (hasTasks ? 1 : 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.isDarkMode ? const Color(0xFF35634D) : AppColors.brandAccentBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Set up your sanctuary',
                style: TextStyle(
                  fontSize: 17,
                  height: 24 / 17,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              Text(
                '$completedCount of 3',
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w600,
                  color: context.brandAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: completedCount > 0 ? context.brandAccent : context.borderSubtle,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: completedCount > 1 ? context.brandAccent : context.borderSubtle,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: completedCount > 2 ? context.brandAccent : context.borderSubtle,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: context.brandAccent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: hasAssets
                      ? const Icon(Icons.check, size: 16, color: Color(0xFF0F1A14))
                      : const Text(
                          '1',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F1A14),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add your first asset',
                      style: TextStyle(
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'A vehicle, appliance or home. It takes under a minute.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 18 / 13,
                        color: context.textSecondary,
                      ),
                    ),
                    if (!hasAssets) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.brandAccent,
                            foregroundColor: const Color(0xFF0F1A14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => _openAddAsset(context),
                          child: const Text(
                            'Add asset',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openAddDocument(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: hasDocuments
                          ? BoxDecoration(
                              color: context.brandAccent,
                              shape: BoxShape.circle,
                            )
                          : BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.isDarkMode
                                    ? const Color(0xFF3A453F)
                                    : context.borderSubtle,
                                width: 1.5,
                              ),
                            ),
                      child: Center(
                        child: hasDocuments
                            ? const Icon(Icons.check, size: 16, color: Color(0xFF0F1A14))
                            : Text(
                                '2',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Attach a receipt or warranty',
                        style: TextStyle(
                          fontSize: 15,
                          height: 20 / 15,
                          fontWeight: FontWeight.w600,
                          color: hasDocuments ? context.textPrimary : context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openAddTask(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: hasTasks
                          ? BoxDecoration(
                              color: context.brandAccent,
                              shape: BoxShape.circle,
                            )
                          : BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.isDarkMode
                                    ? const Color(0xFF3A453F)
                                    : context.borderSubtle,
                                width: 1.5,
                              ),
                            ),
                      child: Center(
                        child: hasTasks
                            ? const Icon(Icons.check, size: 16, color: Color(0xFF0F1A14))
                            : Text(
                                '3',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Set a maintenance reminder',
                        style: TextStyle(
                          fontSize: 15,
                          height: 20 / 15,
                          fontWeight: FontWeight.w600,
                          color: hasTasks ? context.textPrimary : context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddAsset(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddAssetSheet(),
    );
  }

  void _openAddDocument(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddDocumentSheet(),
    );
  }

  void _openAddTask(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTaskSheet(),
    );
  }
}

class _Next30DaysSection extends ConsumerWidget {
  final DateTime now;

  const _Next30DaysSection({required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(dashboardTasksStreamProvider);
    final billsAsync = ref.watch(upcomingBillsStreamProvider);

    final tasks = tasksAsync.value ?? const [];
    final bills = billsAsync.value ?? const [];

    final focusTasks = tasks.where((t) {
      final task = t.task;
      return task.isPending && (task.isOverdue(now) || task.isDueToday(now));
    }).toList();

    focusTasks.sort((a, b) {
      final aOverdue = a.task.isOverdue(now);
      final bOverdue = b.task.isOverdue(now);
      if (aOverdue && !bOverdue) return -1;
      if (!aOverdue && bOverdue) return 1;
      return 0;
    });

    final bool billsClear = bills.isEmpty;
    final bool tasksClear = focusTasks.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Next 30 days',
              style: TextStyle(
                fontSize: 16,
                height: 22 / 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.only(left: 16),
              ),
              onPressed: () {
                ref.read(selectedTabIndexProvider.notifier).setIndex(3);
              },
              child: Text(
                'See all',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.brandAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: context.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.borderSubtle),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.bolt_outlined,
                        size: 18,
                        color: context.brandAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bills & renewals',
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                          Text(
                            billsClear ? 'All up to date' : '${bills.length} upcoming',
                            style: TextStyle(
                              fontSize: 13,
                              height: 18 / 13,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: billsClear
                            ? context.brandAccent.withValues(alpha: 0.12)
                            : AppColors.statusWarningFill,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: billsClear
                              ? context.brandAccent.withValues(alpha: 0.25)
                              : AppColors.statusWarningStroke,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          billsClear ? 'Clear' : '${bills.length} due',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: billsClear ? context.brandAccent : AppColors.statusWarningText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: context.borderSubtle),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.notifications_none_outlined,
                        size: 18,
                        color: context.brandAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Maintenance',
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                          Text(
                            tasksClear ? 'Nothing scheduled' : '${focusTasks.length} scheduled',
                            style: TextStyle(
                              fontSize: 13,
                              height: 18 / 13,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: tasksClear
                            ? context.brandAccent.withValues(alpha: 0.12)
                            : (focusTasks.any((t) => t.task.isOverdue(now))
                                ? AppColors.statusDangerFill
                                : AppColors.statusWarningFill),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: tasksClear
                              ? context.brandAccent.withValues(alpha: 0.25)
                              : (focusTasks.any((t) => t.task.isOverdue(now))
                                  ? AppColors.statusDangerStroke
                                  : AppColors.statusWarningStroke),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          tasksClear ? 'Clear' : '${focusTasks.length} due',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: tasksClear
                                ? context.brandAccent
                                : (focusTasks.any((t) => t.task.isOverdue(now))
                                    ? AppColors.statusDangerText
                                    : AppColors.statusWarningText),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (focusTasks.isNotEmpty) ...[
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: focusTasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, index) {
              return _FocusTaskTile(item: focusTasks[index], now: now);
            },
          ),
        ],
        if (bills.isNotEmpty) ...[
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bills.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, index) {
              return _BillFocusTile(item: bills[index], now: now);
            },
          ),
        ],
      ],
    );
  }
}

class _FocusTaskTile extends ConsumerWidget {
  final RecordWithTask item;
  final DateTime now;

  const _FocusTaskTile({
    required this.item,
    required this.now,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverdue = item.task.isOverdue(now);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => TaskDetailSheet(item: item),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                tooltip: 'Mark as completed',
                icon: const Icon(
                  Icons.radio_button_unchecked,
                  color: AppColors.textSecondary,
                  size: 26,
                ),
                onPressed: () => _toggleTask(context, ref, item),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.record.title,
                      style: AppTypography.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOverdue
                                ? AppColors.statusDangerFill
                                : AppColors.statusWarningFill,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOverdue ? 'OVERDUE' : 'DUE TODAY',
                            style: AppTypography.badge.copyWith(
                              color: isOverdue
                                  ? AppColors.statusDangerText
                                  : AppColors.statusWarningText,
                            ),
                          ),
                        ),
                        if (item.linkedAssetTitle != null)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              '• ${item.linkedAssetTitle!}',
                              style: AppTypography.caption,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleTask(BuildContext context, WidgetRef ref, RecordWithTask item) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(taskRepositoryProvider);
    try {
      await repo.updateTaskStatus(
        recordId: item.record.id,
        status: 'completed',
        completedAt: DateTime.now().toUtc(),
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Completed "${item.record.title}"'),
          backgroundColor: AppColors.brandPrimary,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to complete task: $e'),
          backgroundColor: AppColors.statusDangerStroke,
        ),
      );
    }
  }
}

class _BillFocusTile extends ConsumerWidget {
  final RecordWithBill item;
  final DateTime now;

  const _BillFocusTile({
    required this.item,
    required this.now,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bill = item.bill;
    final isOverdue = bill.isPastDue;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => BillDetailSheet(item: item),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? AppColors.statusDangerFill
                      : (context.isDarkMode ? context.surfaceContainerLow : AppColors.brandAccentSage),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOverdue
                        ? AppColors.statusDangerStroke
                        : (context.isDarkMode ? context.borderSubtle : AppColors.brandAccentBorder),
                  ),
                ),
                child: Icon(
                  bill.utilityTypeEnum.icon,
                  color: isOverdue ? AppColors.statusDangerText : context.brandAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.record.title,
                      style: AppTypography.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOverdue
                                ? AppColors.statusDangerFill
                                : AppColors.statusWarningFill,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOverdue ? 'OVERDUE' : 'DUE SOON',
                            style: AppTypography.badge.copyWith(
                              color: isOverdue
                                  ? AppColors.statusDangerText
                                  : AppColors.statusWarningText,
                            ),
                          ),
                        ),
                        if (bill.dueDate != null)
                          Text(
                            'Due: ${bill.dueDate!.month}/${bill.dueDate!.day}',
                            style: AppTypography.caption,
                          ),
                        if (bill.providerName != null)
                          Text(
                            '• ${bill.providerName}',
                            style: AppTypography.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    bill.formattedAmountDue,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.brandAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => BillDetailSheet(item: item),
                      );
                    },
                    child: const Text('Pay', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(dashboardRecordsStreamProvider);
    final tasksAsync = ref.watch(dashboardTasksStreamProvider);
    final expensesAsync = ref.watch(dashboardExpensesStreamProvider);
    final billsAsync = ref.watch(dashboardBillsStreamProvider);

    if (recordsAsync.isLoading && tasksAsync.isLoading && expensesAsync.isLoading && billsAsync.isLoading) {
      return const SizedBox.shrink();
    }

    if (recordsAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Error loading activity records: ${recordsAsync.error}',
          style: AppTypography.caption.copyWith(color: AppColors.statusDangerStroke),
        ),
      );
    }
    if (tasksAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Error loading activity tasks: ${tasksAsync.error}',
          style: AppTypography.caption.copyWith(color: AppColors.statusDangerStroke),
        ),
      );
    }
    if (expensesAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Error loading activity expenses: ${expensesAsync.error}',
          style: AppTypography.caption.copyWith(color: AppColors.statusDangerStroke),
        ),
      );
    }

    final records = recordsAsync.value ?? const [];
    final tasks = tasksAsync.value ?? const [];
    final expenses = expensesAsync.value ?? const [];
    final bills = billsAsync.value ?? const [];

    final allItems = <_RecentActivityItem>[];

    for (final r in records) {
      if (r.record.recordType == 'asset') {
        allItems.add(
          _RecentActivityItem(
            title: r.record.title,
            type: 'ASSET',
            updatedAt: r.record.updatedAt,
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AssetDetailSheet(item: r),
              );
            },
          ),
        );
      }
    }

    for (final t in tasks) {
      allItems.add(
        _RecentActivityItem(
          title: t.record.title,
          type: 'TASK',
          updatedAt: t.record.updatedAt,
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => TaskDetailSheet(item: t),
            );
          },
        ),
      );
    }

    for (final e in expenses) {
      allItems.add(
        _RecentActivityItem(
          title: e.record.title,
          type: 'EXPENSE',
          updatedAt: e.record.updatedAt,
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ExpenseDetailSheet(item: e),
            );
          },
        ),
      );
    }

    for (final b in bills) {
      allItems.add(
        _RecentActivityItem(
          title: b.record.title,
          type: 'BILL',
          updatedAt: b.record.updatedAt,
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => BillDetailSheet(item: b),
            );
          },
        ),
      );
    }

    allItems.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recentDisplay = allItems.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Records Activity',
          style: TextStyle(
            fontSize: 16,
            height: 22 / 16,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (recentDisplay.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No recent activity recorded yet.',
              style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentDisplay.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, index) {
              final item = recentDisplay[index];
              final isAsset = item.type == 'ASSET';
              final isExpense = item.type == 'EXPENSE';
              final isBill = item.type == 'BILL';

              final Color badgeBg;
              final Color iconColor;
              final IconData iconData;

              if (isBill) {
                badgeBg = ctx.isDarkMode ? ctx.surfaceContainerLow : AppColors.brandAccentSage;
                iconColor = ctx.brandAccent;
                iconData = Icons.receipt_long;
              } else if (isAsset) {
                badgeBg = ctx.isDarkMode ? ctx.surfaceContainerLow : AppColors.brandAccentSage;
                iconColor = ctx.brandAccent;
                iconData = Icons.inventory_2_outlined;
              } else if (isExpense) {
                badgeBg = AppColors.statusWarningFill;
                iconColor = AppColors.statusWarningText;
                iconData = Icons.receipt_long_outlined;
              } else {
                badgeBg = ctx.surfaceContainerLow;
                iconColor = ctx.textSecondary;
                iconData = Icons.checklist_outlined;
              }

              return Card(
                child: ListTile(
                  onTap: item.onTap,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: AppTypography.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ctx.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: ctx.borderSubtle),
                    ),
                    child: Text(
                      item.type,
                      style: AppTypography.badge.copyWith(color: ctx.textSecondary),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _RecentActivityItem {
  final String title;
  final String type;
  final DateTime updatedAt;
  final VoidCallback onTap;

  const _RecentActivityItem({
    required this.title,
    required this.type,
    required this.updatedAt,
    required this.onTap,
  });
}
