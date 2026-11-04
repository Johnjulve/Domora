import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../records/presentation/records_screen.dart';
import '../../tasks/domain/task_item.dart';
import '../../tasks/presentation/tasks_screen.dart';

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
        actions: const [
          _SanctuaryBadge(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardRecordsStreamProvider);
          ref.invalidate(dashboardTasksStreamProvider);
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
              const _RecentActivitySection(),
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
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandAccentSage,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.brandAccentBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined, size: 14, color: AppColors.brandPrimary),
          const SizedBox(width: 4),
          Text(
            'Sanctuary',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.brandPrimary,
            ),
          ),
        ],
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

    return tasksAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: AppColors.brandPrimary),
        ),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Failed to load task metrics: $err',
          style: AppTypography.caption.copyWith(color: AppColors.statusDangerStroke),
        ),
      ),
      data: (tasks) {
        return recordsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Failed to load record metrics: $err',
              style: AppTypography.caption.copyWith(color: AppColors.statusDangerStroke),
            ),
          ),
          data: (records) {
            final activeAssets = records.where((r) => r.record.recordType == 'asset').length;
            final pendingTasks = tasks.where((t) => t.task.isPending).length;
            final overdueTasks = tasks.where((t) => t.task.isOverdue(now)).length;

            return Row(
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
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'Total Assets',
                    value: activeAssets.toString(),
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
              ],
            );
          },
        );
      },
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
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTypography.pageHeader.copyWith(
                  fontSize: 22,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption,
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
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  side: const BorderSide(color: AppColors.brandPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openAddTask(context),
                icon: const Icon(Icons.add_task, color: AppColors.brandPrimary, size: 20),
                label: const Text(
                  'Add Task',
                  style: TextStyle(color: AppColors.brandPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openAddAsset(context),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text(
                  'Add Asset',
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
      builder: (_) => const AddTaskSheet(),
    );
  }

  void _openAddAsset(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddAssetSheet(),
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
              decoration: const BoxDecoration(
                color: AppColors.brandAccentSage,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.done_all, color: AppColors.brandPrimary, size: 24),
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

class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(dashboardRecordsStreamProvider);
    final tasksAsync = ref.watch(dashboardTasksStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Records Activity', style: AppTypography.sectionTitle),
        const SizedBox(height: 12),
        recordsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Error loading activity records: $err',
              style: AppTypography.caption.copyWith(color: AppColors.statusDangerStroke),
            ),
          ),
          data: (records) {
            return tasksAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Error loading activity tasks: $err',
                  style: AppTypography.caption.copyWith(color: AppColors.statusDangerStroke),
                ),
              ),
              data: (tasks) {
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
                          builder: (_) => TaskDetailSheet(item: t),
                        );
                      },
                    ),
                  );
                }

                allItems.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                final recentDisplay = allItems.take(4).toList();

                if (recentDisplay.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No recent activity recorded yet.',
                      style: AppTypography.bodySecondary,
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentDisplay.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final item = recentDisplay[index];
                    final isAsset = item.type == 'ASSET';

                    return Card(
                      child: ListTile(
                        onTap: item.onTap,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isAsset
                                ? AppColors.brandAccentSage
                                : AppColors.surfaceContainerLow,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAsset ? Icons.inventory_2_outlined : Icons.checklist_outlined,
                            color: isAsset ? AppColors.brandPrimary : AppColors.textSecondary,
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
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Text(item.type, style: AppTypography.badge),
                        ),
                      ),
                    );
                  },
                );
              },
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
