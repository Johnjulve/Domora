import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../backup/presentation/backup_sheet.dart';
import '../../settings/presentation/settings_profile_screen.dart';
import '../../records/presentation/records_screen.dart';
import '../../tasks/domain/task_item.dart';
import '../../tasks/presentation/tasks_screen.dart';
import '../../expenses/presentation/add_expense_sheet.dart';
import '../../expenses/presentation/expense_detail_sheet.dart';
import '../../bills/domain/bill_item.dart';
import '../../bills/presentation/add_bill_sheet.dart';
import '../../bills/presentation/bill_detail_sheet.dart';

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
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          const _SanctuaryBadge(),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.brandAccent),
            tooltip: 'Settings & Updates',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardRecordsStreamProvider);
          ref.invalidate(dashboardTasksStreamProvider);
          ref.invalidate(dashboardExpensesStreamProvider);
          ref.invalidate(workspaceTotalExpensesProvider);
          ref.invalidate(activeBillsStreamProvider);
          ref.invalidate(dashboardBillsStreamProvider);
          ref.invalidate(upcomingBillsStreamProvider);
          ref.invalidate(workspaceTotalUnpaidBillsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TodayHeaderSection(now: now),
              const SizedBox(height: 20),
              _TodayMetricsSection(now: now),
              const SizedBox(height: 24),
              const _QuickActionBar(),
              const SizedBox(height: 28),
              _TodayFocusSection(now: now),
              const SizedBox(height: 28),
              _TodayBillsSection(now: now),
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
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Offline-First Household Sanctuary',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary.withValues(alpha: 0.7),
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
    );
  }
}

class _SanctuaryBadge extends StatelessWidget {
  const _SanctuaryBadge();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Sanctuary Archival & Backup',
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const BackupSheet(),
          );
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: context.isDarkMode ? context.surfaceContainerLow : AppColors.brandAccentSage,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: context.isDarkMode ? context.borderSubtle : AppColors.brandAccentBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 14, color: context.brandAccent),
              const SizedBox(width: 4),
              Text(
                'Sanctuary',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.brandAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayHeaderSection extends StatelessWidget {
  final DateTime now;

  const _TodayHeaderSection({required this.now});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(now.hour),
          style: AppTypography.pageHeader.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 4),
        Text(
          _formatTodayHeader(now),
          style: AppTypography.bodySecondary,
        ),
      ],
    );
  }
}

class _TodayMetricsSection extends ConsumerWidget {
  final DateTime now;

  const _TodayMetricsSection({required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(dashboardTasksStreamProvider);
    final recordsAsync = ref.watch(dashboardRecordsStreamProvider);
    final expensesTotalAsync = ref.watch(workspaceTotalExpensesProvider);

    // Guard: Loading state
    if (tasksAsync.isLoading || recordsAsync.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: context.brandAccent),
        ),
      );
    }

    // Guard: Error states surfaced loudly
    if (tasksAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Failed to load task metrics: ${tasksAsync.error}',
          style: AppTypography.caption.copyWith(color: AppColors.statusDangerStroke),
        ),
      );
    }
    if (recordsAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Failed to load record metrics: ${recordsAsync.error}',
          style: AppTypography.caption.copyWith(color: AppColors.statusDangerStroke),
        ),
      );
    }

    final tasks = tasksAsync.requireValue;
    final records = recordsAsync.requireValue;

    final activeAssets = records.where((r) => r.record.recordType == 'asset').length;
    final pendingTasks = tasks.where((t) => t.task.isPending).length;
    final overdueTasks = tasks.where((t) => t.task.isOverdue(now)).length;

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

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Pending Tasks',
                value: pendingTasks.toString(),
                icon: Icons.checklist_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Overdue',
                value: overdueTasks.toString(),
                icon: Icons.alarm_outlined,
                valueColor: overdueTasks > 0
                    ? AppColors.statusDangerText
                    : context.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Total Assets',
                value: activeAssets.toString(),
                icon: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Recorded Expenses',
                value: formattedExpenses,
                icon: Icons.receipt_long_outlined,
                valueColor: expenseColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: context.textSecondary),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTypography.pageHeader.copyWith(
                  fontSize: 22,
                  color: valueColor ?? context.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption.copyWith(color: context.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionBar extends StatelessWidget {
  const _QuickActionBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: AppTypography.sectionTitle),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  side: BorderSide(color: context.brandAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openAddTask(context),
                icon: Icon(Icons.add_task, color: context.brandAccent, size: 18),
                label: Text(
                  'Add Task',
                  style: TextStyle(color: context.brandAccent, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openAddAsset(context),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text(
                  'Add Asset',
                  style: TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openAddExpense(context),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text(
                  'Log Cost',
                  style: TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
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
}

class _TodayFocusSection extends ConsumerWidget {
  final DateTime now;

  const _TodayFocusSection({required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(dashboardTasksStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Today's Focus & Deadlines", style: AppTypography.sectionTitle),
        const SizedBox(height: 12),
        tasksAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Error loading focus: $err',
              style: AppTypography.caption.copyWith(color: AppColors.statusDangerStroke),
            ),
          ),
          data: (tasks) {
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

            if (focusTasks.isEmpty) {
              return const _AllCaughtUpCard();
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: focusTasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final item = focusTasks[index];
                return _FocusTaskTile(item: item, now: now);
              },
            );
          },
        ),
      ],
    );
  }
}

class _AllCaughtUpCard extends StatelessWidget {
  const _AllCaughtUpCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.isDarkMode ? context.surfaceContainerLow : AppColors.brandAccentSage,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.done_all, color: context.brandAccent, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("You're all caught up", style: AppTypography.cardTitle),
                  SizedBox(height: 4),
                  Text(
                    'No pending tasks or maintenance deadlines require your attention today.',
                    style: AppTypography.bodySecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

class _TodayBillsSection extends ConsumerWidget {
  final DateTime now;

  const _TodayBillsSection({required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingBillsAsync = ref.watch(upcomingBillsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Upcoming & Overdue Bills', style: AppTypography.sectionTitle),
            TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onPressed: () => _openAddBill(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Bill'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        upcomingBillsAsync.when(
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: context.brandAccent),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Error loading bills: $err',
              style: AppTypography.caption.copyWith(color: AppColors.statusDangerStroke),
            ),
          ),
          data: (bills) {
            if (bills.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? context.surfaceContainerLow : AppColors.brandAccentSage,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_circle_outline, color: context.brandAccent, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('All Bills Up to Date', style: AppTypography.cardTitle),
                            SizedBox(height: 4),
                            Text(
                              'No pending utility bills or obligations due in the next 30 days.',
                              style: AppTypography.bodySecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bills.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                return _BillFocusTile(item: bills[index], now: now);
              },
            );
          },
        ),
      ],
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

    // Guard: Loading state
    if (recordsAsync.isLoading && tasksAsync.isLoading && expensesAsync.isLoading && billsAsync.isLoading) {
      return const SizedBox.shrink();
    }

    // Guard: Error states surfaced loudly
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
        const Text('Recent Records Activity', style: AppTypography.sectionTitle),
        const SizedBox(height: 12),
        if (recentDisplay.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No recent activity recorded yet.',
              style: AppTypography.bodySecondary,
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
