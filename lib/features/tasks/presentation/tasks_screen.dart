import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../records/domain/record.dart';
import '../../records/presentation/widgets/asset_picker_sheet.dart';
import '../domain/task_item.dart';

const List<String> _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> _monthsFull = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _formatShortDate(DateTime dt) => '${_monthsShort[dt.month - 1]} ${dt.day}, ${dt.year}';
String _formatFullDate(DateTime dt) => '${_monthsFull[dt.month - 1]} ${dt.day}, ${dt.year}';

String _formatRecurrenceLabel(String rule) {
  switch (rule.toLowerCase()) {
    case 'daily':
      return 'Daily';
    case 'weekly':
      return 'Weekly';
    case 'monthly':
      return 'Monthly';
    case 'quarterly':
      return 'Every 3 mos';
    case 'semi_annual':
      return 'Every 6 mos';
    case 'yearly':
      return 'Annual';
    default:
      return rule;
  }
}

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(activeTasksStreamProvider);
    final selectedFilter = ref.watch(selectedTaskFilterProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tasks & Cadence'),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: context.brandAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Domestic cadence active • Local vault',
                  style: AppTypography.caption.copyWith(
                    color: context.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_task, color: context.brandAccent),
            tooltip: 'Add Task',
            onPressed: () => _openAddTaskModal(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips (Pending, Completed, All)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _buildSegmentChip(
                  label: 'Pending',
                  isSelected: selectedFilter == 'pending',
                  onTap: () => ref.read(selectedTaskFilterProvider.notifier).setFilter('pending'),
                ),
                const SizedBox(width: 8),
                _buildSegmentChip(
                  label: 'Completed',
                  isSelected: selectedFilter == 'completed',
                  onTap: () => ref.read(selectedTaskFilterProvider.notifier).setFilter('completed'),
                ),
                const SizedBox(width: 8),
                _buildSegmentChip(
                  label: 'All',
                  isSelected: selectedFilter == 'all',
                  onTap: () => ref.read(selectedTaskFilterProvider.notifier).setFilter('all'),
                ),
              ],
            ),
          ),

          // Tasks Content
          Expanded(
            child: tasksAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: context.brandAccent),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.statusDangerStroke, size: 48),
                      const SizedBox(height: 12),
                      const Text('Failed to load tasks', style: AppTypography.cardTitle),
                      const SizedBox(height: 8),
                      Text(err.toString(), style: AppTypography.bodySecondary, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Card(
                        color: context.surfaceCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          side: BorderSide(color: context.borderSubtle),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: context.isDarkMode
                                      ? AppTheme.darkBrandSecondary.withValues(alpha: 0.2)
                                      : AppColors.brandAccentSage,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.check_circle_outline, color: context.brandAccent, size: 36),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                selectedFilter == 'completed'
                                    ? 'No Completed Tasks'
                                    : 'All Caught Up',
                                style: AppTypography.cardTitle.copyWith(color: context.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selectedFilter == 'completed'
                                    ? 'Completed tasks will show up here once checked off.'
                                    : 'Keep your domestic maintenance, filter replacements, and household bills on schedule.',
                                style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              if (selectedFilter != 'completed')
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.isDarkMode ? AppTheme.darkBrandPrimary : AppColors.brandPrimary,
                                    foregroundColor: AppColors.brandOnPrimary,
                                  ),
                                  onPressed: () => _openAddTaskModal(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add First Task'),
                                )
                               else
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: context.textPrimary,
                                    side: BorderSide(color: context.borderSubtle),
                                  ),
                                  onPressed: () => ref.read(selectedTaskFilterProvider.notifier).setFilter('pending'),
                                  child: const Text('View Pending Tasks'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                if (selectedFilter == 'pending') {
                  return _buildAgendaView(context, tasks, now);
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final item = tasks[index];
                    return _TaskCard(
                      item: item,
                      onToggleCompletion: () => _toggleTask(context, item),
                      onTap: () => _openTaskDetailModal(context, item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaView(BuildContext context, List<RecordWithTask> tasks, DateTime now) {
    final overdueTasks = tasks.where((t) => t.task.isPending && t.task.isOverdue(now)).toList();
    final todayTasks = tasks.where((t) => t.task.isPending && t.task.isDueToday(now)).toList();
    final upcomingRoutines = tasks.where((t) => t.task.isPending && !t.task.isOverdue(now) && !t.task.isDueToday(now)).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
                if (overdueTasks.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.priority_high,
            iconColor: AppColors.statusDangerText,
            iconBgColor: AppColors.statusDangerFill,
            title: 'Overdue (${overdueTasks.length})',
            badgeText: 'ATTENTION',
            badgeColor: AppColors.statusDangerText,
          ),
          const SizedBox(height: 8),
          ...overdueTasks.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OverdueTaskCard(
              item: item,
              now: now,
              onToggleCompletion: () => _toggleTask(context, item),
              onTap: () => _openTaskDetailModal(context, item),
              onSnooze: () => _showSnoozeModal(context, item),
            ),
          )),
          const SizedBox(height: 16),
        ],

                if (todayTasks.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.today,
            iconColor: context.brandAccent,
            iconBgColor: context.isDarkMode
                ? AppTheme.darkBrandSecondary.withValues(alpha: 0.2)
                : AppColors.brandAccentSage,
            title: 'Today (${todayTasks.length} remaining)',
          ),
          const SizedBox(height: 8),
          ...todayTasks.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TaskCard(
              item: item,
              onToggleCompletion: () => _toggleTask(context, item),
              onTap: () => _openTaskDetailModal(context, item),
            ),
          )),
          const SizedBox(height: 16),
        ],

                if (upcomingRoutines.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.autorenew,
            iconColor: context.brandAccent,
            iconBgColor: context.isDarkMode
                ? AppTheme.darkBrandSecondary.withValues(alpha: 0.2)
                : AppColors.brandAccentSage,
            title: 'Upcoming & Routines',
          ),
          const SizedBox(height: 8),
          ...upcomingRoutines.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TaskCard(
              item: item,
              onToggleCompletion: () => _toggleTask(context, item),
              onTap: () => _openTaskDetailModal(context, item),
            ),
          )),
          const SizedBox(height: 16),
        ],

                const _MindfulHomePaceBanner(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSegmentChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label tasks filter',
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? (context.isDarkMode ? AppTheme.darkBrandPrimary : AppColors.brandPrimary)
                  : context.surfaceCard,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected
                    ? (context.isDarkMode ? AppTheme.darkBrandPrimary : AppColors.brandPrimary)
                    : context.borderSubtle,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.brandOnPrimary : context.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleTask(BuildContext context, RecordWithTask item) async {
    final messenger = ScaffoldMessenger.of(context);
    final newStatus = item.task.isCompleted ? 'pending' : 'completed';
    final repo = ref.read(taskRepositoryProvider);

    try {
      await repo.updateTaskStatus(
        recordId: item.record.id,
        status: newStatus,
        completedAt: newStatus == 'completed' ? DateTime.now().toUtc() : null,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update task: $e'),
          backgroundColor: AppColors.statusDangerStroke,
        ),
      );
    }
  }

  void _showSnoozeModal(BuildContext context, RecordWithTask item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(ctx).bottomSheetTheme.backgroundColor ?? ctx.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
          border: Border(
            top: BorderSide(color: ctx.borderSubtle),
            left: BorderSide(color: ctx.borderSubtle),
            right: BorderSide(color: ctx.borderSubtle),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.snooze, color: ctx.brandAccent),
                    const SizedBox(width: 8),
                    Text('Snooze Overdue Task', style: AppTypography.cardTitle.copyWith(color: ctx.textPrimary)),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, color: ctx.textPrimary),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.record.title,
              style: AppTypography.bodySecondary.copyWith(fontWeight: FontWeight.w600, color: ctx.textSecondary),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.today, color: ctx.brandAccent),
              title: Text('Tomorrow (+1 Day)', style: TextStyle(color: ctx.textPrimary)),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(ctx).pop();
                try {
                  final now = DateTime.now();
                  final tomorrow = DateTime(now.year, now.month, now.day + 1);
                  await ref.read(taskRepositoryProvider).rescheduleTask(
                    recordId: item.record.id,
                    newDueDate: tomorrow,
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to reschedule task: $e'),
                      backgroundColor: AppColors.statusDangerStroke,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.date_range, color: ctx.brandAccent),
              title: Text('In 3 Days (+3 Days)', style: TextStyle(color: ctx.textPrimary)),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(ctx).pop();
                try {
                  final now = DateTime.now();
                  final in3Days = DateTime(now.year, now.month, now.day + 3);
                  await ref.read(taskRepositoryProvider).rescheduleTask(
                    recordId: item.record.id,
                    newDueDate: in3Days,
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to reschedule task: $e'),
                      backgroundColor: AppColors.statusDangerStroke,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.next_week, color: ctx.brandAccent),
              title: Text('Next Week (+7 Days)', style: TextStyle(color: ctx.textPrimary)),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(ctx).pop();
                try {
                  final now = DateTime.now();
                  final nextWeek = DateTime(now.year, now.month, now.day + 7);
                  await ref.read(taskRepositoryProvider).rescheduleTask(
                    recordId: item.record.id,
                    newDueDate: nextWeek,
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to reschedule task: $e'),
                      backgroundColor: AppColors.statusDangerStroke,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openAddTaskModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const AddTaskSheet(),
    );
  }

  void _openTaskDetailModal(BuildContext context, RecordWithTask item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskDetailSheet(item: item),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final String title;
  final String? badgeText;
  final Color? badgeColor;

  const _SectionHeader({
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    required this.title,
    this.badgeText,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? context.brandAccent;
    final effectiveIconBgColor = iconBgColor ??
        (context.isDarkMode
            ? AppTheme.darkBrandSecondary.withValues(alpha: 0.2)
            : AppColors.brandAccentSage);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: effectiveIconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: effectiveIconColor),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.cardTitle.copyWith(fontSize: 16, color: context.textPrimary),
            ),
          ],
        ),
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.statusDangerFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.statusDangerStroke),
            ),
            child: Text(
              badgeText!,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: badgeColor ?? AppColors.statusDangerText,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}

class _OverdueTaskCard extends StatelessWidget {
  final RecordWithTask item;
  final DateTime now;
  final VoidCallback onToggleCompletion;
  final VoidCallback onTap;
  final VoidCallback onSnooze;

  const _OverdueTaskCard({
    required this.item,
    required this.now,
    required this.onToggleCompletion,
    required this.onTap,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    final record = item.record;
    final task = item.task;
    final isCompleted = task.isCompleted;

    int daysOverdue = 1;
    if (task.dueDate != null) {
      final nowDate = DateTime(now.year, now.month, now.day);
      final dueDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      final diff = nowDate.difference(dueDate).inDays;
      daysOverdue = diff > 0 ? diff : 1;
    }

    return Card(
      color: context.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.borderSubtle),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    tooltip: isCompleted ? 'Mark as pending' : 'Mark as completed',
                    icon: Icon(
                      isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isCompleted ? context.brandAccent : AppColors.statusDangerStroke,
                      size: 26,
                    ),
                    onPressed: onToggleCompletion,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.title,
                          style: AppTypography.cardTitle.copyWith(
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? context.textTertiary : context.textPrimary,
                          ),
                        ),
                        if (record.description != null && record.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            record.description!,
                            style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.statusDangerFill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$daysOverdue ${daysOverdue == 1 ? 'day' : 'days'} overdue',
                      style: AppTypography.badge.copyWith(
                        color: AppColors.statusDangerText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.linkedAssetTitle != null)
                    Row(
                      children: [
                        Icon(Icons.link, size: 13, color: context.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          item.linkedAssetTitle!,
                          style: AppTypography.caption.copyWith(color: context.textSecondary),
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: onSnooze,
                        icon: Icon(Icons.snooze, size: 15, color: context.textSecondary),
                        label: Text('Snooze', style: AppTypography.caption.copyWith(color: context.textSecondary)),
                      ),
                      const SizedBox(width: 4),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: onToggleCompletion,
                        child: Text('Complete', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ],
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

class _TaskCard extends StatelessWidget {
  final RecordWithTask item;
  final VoidCallback onToggleCompletion;
  final VoidCallback onTap;

  const _TaskCard({
    required this.item,
    required this.onToggleCompletion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final record = item.record;
    final task = item.task;
    final isCompleted = task.isCompleted;
    final isOverdue = task.isOverdue();
    final isDueToday = task.isDueToday();

    return Card(
      color: context.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.borderSubtle),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                tooltip: isCompleted ? 'Mark as pending' : 'Mark as completed',
                icon: Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isCompleted ? context.brandAccent : context.textSecondary,
                  size: 26,
                ),
                onPressed: onToggleCompletion,
              ),
              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: AppTypography.cardTitle.copyWith(
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? context.textTertiary : context.textPrimary,
                      ),
                    ),
                    if (record.description != null && record.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        record.description!,
                        style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildPriorityBadge(context, task.priority),

                        if (task.recurrenceRule != null && task.recurrenceRule != 'none')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: context.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: context.borderSubtle),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.autorenew, size: 12, color: context.brandAccent),
                                const SizedBox(width: 4),
                                Text(
                                  _formatRecurrenceLabel(task.recurrenceRule!),
                                  style: AppTypography.badge.copyWith(color: context.brandAccent),
                                ),
                              ],
                            ),
                          ),

                        if (item.linkedAssetTitle != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: context.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: context.borderSubtle),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.link, size: 12, color: context.textSecondary),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 160),
                                  child: Text(
                                    item.linkedAssetTitle!,
                                    style: AppTypography.badge.copyWith(color: context.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (task.dueDate != null)
                          Text(
                            _formatDueDate(task.dueDate!, isOverdue, isDueToday),
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isCompleted
                                  ? context.textTertiary
                                  : isDueToday
                                      ? AppColors.statusWarningText
                                      : isOverdue
                                          ? AppColors.statusDangerText
                                          : context.textSecondary,
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

  Widget _buildPriorityBadge(BuildContext context, String priority) {
    Color bg;
    Color fg;

    switch (priority.toLowerCase()) {
      case 'urgent':
        bg = AppColors.statusDangerFill;
        fg = AppColors.statusDangerText;
        break;
      case 'high':
        bg = AppColors.statusWarningFill;
        fg = AppColors.statusWarningText;
        break;
      case 'low':
        bg = context.surfaceContainerLow;
        fg = context.textSecondary;
        break;
      case 'medium':
      default:
        bg = context.isDarkMode
            ? AppTheme.darkBrandSecondary.withValues(alpha: 0.15)
            : AppColors.brandAccentSage;
        fg = context.brandAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority.toUpperCase(),
        style: AppTypography.badge.copyWith(color: fg),
      ),
    );
  }

  String _formatDueDate(DateTime dueDate, bool isOverdue, bool isDueToday) {
    if (isDueToday) return 'Due Today';
    final formatted = _formatShortDate(dueDate);
    if (isOverdue) return 'Overdue: $formatted';
    return 'Due: $formatted';
  }
}

class _MindfulHomePaceBanner extends StatelessWidget {
  const _MindfulHomePaceBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? AppTheme.darkBrandSecondary.withValues(alpha: 0.2)
                  : AppColors.brandAccentSage,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.spa_outlined, size: 18, color: context.brandAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mindful Home Pace',
                  style: AppTypography.cardTitle.copyWith(fontSize: 14, color: context.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Focus on today’s domestic rhythms. Recurring seasonal routines stay queued until their active cycle.',
                  style: AppTypography.caption.copyWith(color: context.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddTaskSheet extends ConsumerStatefulWidget {
  const AddTaskSheet({super.key});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'medium';
  String _recurrenceRule = 'none';
  DateTime? _selectedDueDate;
  String? _selectedAssetRecordId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (mounted && picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(taskRepositoryProvider);
      final recordId = const Uuid().v4();
      final now = DateTime.now().toUtc();

      await repo.createTaskRecord(
        record: Record(
          id: recordId,
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'task',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          createdAt: now,
          updatedAt: now,
        ),
        task: TaskItem(
          recordId: recordId,
          dueDate: _selectedDueDate,
          priority: _priority,
          status: 'pending',
          recurrenceRule: _recurrenceRule == 'none' ? null : _recurrenceRule,
          assetRecordId: _selectedAssetRecordId,
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save task: $e'),
            backgroundColor: AppColors.statusDangerStroke,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomSheetTheme.backgroundColor ?? context.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
        border: Border(
          top: BorderSide(color: context.borderSubtle),
          left: BorderSide(color: context.borderSubtle),
          right: BorderSide(color: context.borderSubtle),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New Task / Responsibility', style: AppTypography.sectionTitle.copyWith(color: context.textPrimary)),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'e.g. Replace AC Air Filter',
                  filled: true,
                  fillColor: context.surfaceContainerLow,
                ),
                autofocus: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Task title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Notes / Specifications',
                  hintText: 'e.g. Use 20x25x1 MERV 11 filter',
                  filled: true,
                  fillColor: context.surfaceContainerLow,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      dropdownColor: context.surfaceCard,
                      style: TextStyle(color: context.textPrimary),
                      initialValue: _priority,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        filled: true,
                        fillColor: context.surfaceContainerLow,
                      ),
                      items: [
                        DropdownMenuItem(value: 'low', child: Text('Low', style: TextStyle(color: context.textPrimary))),
                        DropdownMenuItem(value: 'medium', child: Text('Medium', style: TextStyle(color: context.textPrimary))),
                        DropdownMenuItem(value: 'high', child: Text('High', style: TextStyle(color: context.textPrimary))),
                        DropdownMenuItem(value: 'urgent', child: Text('Urgent', style: TextStyle(color: context.textPrimary))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _priority = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDueDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Due Date',
                          suffixIcon: Icon(Icons.calendar_today, size: 18, color: context.textSecondary),
                          filled: true,
                          fillColor: context.surfaceContainerLow,
                        ),
                        child: Text(
                          _selectedDueDate != null
                              ? _formatShortDate(_selectedDueDate!)
                              : 'Select date',
                          style: _selectedDueDate != null
                              ? AppTypography.bodyPrimary.copyWith(color: context.textPrimary)
                              : AppTypography.bodySecondary.copyWith(color: context.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cadence / Recurrence selector
              DropdownButtonFormField<String>(
                dropdownColor: context.surfaceCard,
                style: TextStyle(color: context.textPrimary),
                initialValue: _recurrenceRule,
                decoration: InputDecoration(
                  labelText: 'Cadence / Routine',
                  prefixIcon: Icon(Icons.autorenew, size: 20, color: context.brandAccent),
                  filled: true,
                  fillColor: context.surfaceContainerLow,
                ),
                items: [
                  DropdownMenuItem(value: 'none', child: Text('None (One-time Task)', style: TextStyle(color: context.textPrimary))),
                  DropdownMenuItem(value: 'daily', child: Text('Daily Cadence', style: TextStyle(color: context.textPrimary))),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly Cadence', style: TextStyle(color: context.textPrimary))),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly Cadence', style: TextStyle(color: context.textPrimary))),
                  DropdownMenuItem(value: 'quarterly', child: Text('Every 3 Months (Quarterly)', style: TextStyle(color: context.textPrimary))),
                  DropdownMenuItem(value: 'semi_annual', child: Text('Every 6 Months (Biannual)', style: TextStyle(color: context.textPrimary))),
                  DropdownMenuItem(value: 'yearly', child: Text('Every 1 Year (Annual)', style: TextStyle(color: context.textPrimary))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _recurrenceRule = val);
                },
              ),
              const SizedBox(height: 14),

              // Reusable AssetPickerTile eliminating popup dropdown misalignment
              AssetPickerTile(
                selectedAssetRecordId: _selectedAssetRecordId,
                onAssetChanged: (assetId) => setState(() => _selectedAssetRecordId = assetId),
                noneLabel: 'None (General Domestic Task)',
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.isDarkMode ? AppTheme.darkBrandPrimary : AppColors.brandPrimary,
                  foregroundColor: AppColors.brandOnPrimary,
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandOnPrimary),
                      )
                    : const Text('Save Task'),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class TaskDetailSheet extends ConsumerWidget {
  final RecordWithTask item;

  const TaskDetailSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = item.record;
    final task = item.task;
    final isCompleted = task.isCompleted;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomSheetTheme.backgroundColor ?? context.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
        border: Border(
          top: BorderSide(color: context.borderSubtle),
          left: BorderSide(color: context.borderSubtle),
          right: BorderSide(color: context.borderSubtle),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    record.title,
                    style: AppTypography.pageHeader.copyWith(fontSize: 22, color: context.textPrimary),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: context.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              color: context.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                side: BorderSide(color: context.borderSubtle),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(context, 'Status', task.status.toUpperCase()),
                    Divider(color: context.borderSubtle),
                    _buildDetailRow(context, 'Priority', task.priority.toUpperCase()),
                    if (task.dueDate != null) ...[
                      Divider(color: context.borderSubtle),
                      _buildDetailRow(context, 'Due Date', _formatFullDate(task.dueDate!)),
                    ],
                    if (task.recurrenceRule != null && task.recurrenceRule != 'none') ...[
                      Divider(color: context.borderSubtle),
                      _buildDetailRow(context, 'Cadence', _formatRecurrenceLabel(task.recurrenceRule!)),
                    ],
                    if (task.completedAt != null) ...[
                      Divider(color: context.borderSubtle),
                      _buildDetailRow(context, 'Completed At', _formatFullDate(task.completedAt!)),
                    ],
                    if (item.linkedAssetTitle != null) ...[
                      Divider(color: context.borderSubtle),
                      _buildDetailRow(context, 'Linked Asset', item.linkedAssetTitle!),
                    ],
                    if (record.description != null && record.description!.isNotEmpty) ...[
                      Divider(color: context.borderSubtle),
                      _buildDetailRow(context, 'Notes', record.description!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final newStatus = isCompleted ? 'pending' : 'completed';
                try {
                  await ref.read(taskRepositoryProvider).updateTaskStatus(
                    recordId: record.id,
                    status: newStatus,
                    completedAt: newStatus == 'completed' ? DateTime.now().toUtc() : null,
                  );
                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to update task: $e'),
                      backgroundColor: AppColors.statusDangerStroke,
                    ),
                  );
                }
              },
              icon: Icon(isCompleted ? Icons.undo : Icons.check_circle_outline),
              label: Text(isCompleted ? 'Mark as Pending' : 'Mark as Completed'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.statusDangerText,
                side: const BorderSide(color: AppColors.statusDangerStroke),
              ),
              onPressed: () => _confirmDeleteTask(context, ref, record.id, record.title),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Move to Trash'),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySecondary.copyWith(color: context.textSecondary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: AppTypography.cardTitle.copyWith(color: context.textPrimary),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTask(BuildContext context, WidgetRef ref, String recordId, String taskTitle) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.sheetRadius),
          side: BorderSide(color: ctx.borderSubtle),
        ),
        title: Text('Move to Trash?', style: AppTypography.cardTitle.copyWith(color: ctx.textPrimary)),
        content: Text(
          'Are you sure you want to move "$taskTitle" to trash?',
          style: AppTypography.bodyPrimary.copyWith(color: ctx.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: ctx.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDangerText,
              foregroundColor: AppColors.brandOnPrimary,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(taskRepositoryProvider).softDeleteTask(recordId);
                if (context.mounted) Navigator.of(context).pop(); // Close detail sheet
                messenger.showSnackBar(
                  SnackBar(content: Text('Moved "$taskTitle" to trash')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete task: $e'),
                    backgroundColor: AppColors.statusDangerStroke,
                  ),
                );
              }
            },
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );
  }
}
