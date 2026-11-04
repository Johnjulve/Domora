import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../records/domain/record.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks & Cadence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task, color: AppColors.brandPrimary),
            tooltip: 'Add Task',
            onPressed: () => _openAddTaskModal(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips (Pending, Completed, All) with horizontal scrolling to prevent RenderFlex overflow
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

          // Tasks List
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.brandPrimary),
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
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: AppColors.brandAccentSage,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle_outline, color: AppColors.brandPrimary, size: 36),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                selectedFilter == 'completed'
                                    ? 'No Completed Tasks'
                                    : 'All Caught Up',
                                style: AppTypography.cardTitle,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selectedFilter == 'completed'
                                    ? 'Completed tasks will show up here once checked off.'
                                    : 'Keep your domestic maintenance, filter replacements, and household bills on schedule.',
                                style: AppTypography.bodySecondary,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              if (selectedFilter != 'completed')
                                ElevatedButton.icon(
                                  onPressed: () => _openAddTaskModal(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add First Task'),
                                )
                              else
                                OutlinedButton(
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
              color: isSelected ? AppColors.brandPrimary : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? AppColors.brandPrimary : AppColors.borderSubtle,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.brandOnPrimary : AppColors.textPrimary,
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

  void _openAddTaskModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox Toggle with accessible touch target and tooltip
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                tooltip: isCompleted ? 'Mark as pending' : 'Mark as completed',
                icon: Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isCompleted ? AppColors.brandPrimary : AppColors.textSecondary,
                  size: 26,
                ),
                onPressed: onToggleCompletion,
              ),
              const SizedBox(width: 8),

              // Title and Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: AppTypography.cardTitle.copyWith(
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? AppColors.textTertiary : AppColors.textPrimary,
                      ),
                    ),
                    if (record.description != null && record.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        record.description!,
                        style: AppTypography.bodySecondary,
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
                        // Priority Badge
                        _buildPriorityBadge(task.priority),

                        // Linked Asset Badge with overflow protection
                        if (item.linkedAssetTitle != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.link, size: 12, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 160),
                                  child: Text(
                                    item.linkedAssetTitle!,
                                    style: AppTypography.badge.copyWith(color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Due Date with synchronized precedence (Today checked before Overdue)
                        if (task.dueDate != null)
                          Text(
                            _formatDueDate(task.dueDate!, isOverdue, isDueToday),
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isCompleted
                                  ? AppColors.textTertiary
                                  : isDueToday
                                      ? AppColors.statusWarningText
                                      : isOverdue
                                          ? AppColors.statusDangerText
                                          : AppColors.textSecondary,
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

  Widget _buildPriorityBadge(String priority) {
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
        bg = AppColors.surfaceContainerLow;
        fg = AppColors.textSecondary;
        break;
      case 'medium':
      default:
        bg = AppColors.brandAccentSage;
        fg = AppColors.brandPrimary;
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
    if (picked != null) {
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
    final recordsAsync = ref.watch(activeRecordsStreamProvider);

    return Padding(
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
                  const Text('New Task / Responsibility', style: AppTypography.sectionTitle),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'e.g. Replace AC Air Filter',
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
                decoration: const InputDecoration(
                  labelText: 'Notes / Specifications',
                  hintText: 'e.g. Use 20x25x1 MERV 11 filter',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
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
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          suffixIcon: Icon(Icons.calendar_today, size: 18),
                        ),
                        child: Text(
                          _selectedDueDate != null
                              ? _formatShortDate(_selectedDueDate!)
                              : 'Select date',
                          style: _selectedDueDate != null
                              ? AppTypography.bodyPrimary
                              : AppTypography.bodySecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Optional Asset Link with explicit error feedback & isExpanded overflow protection
              recordsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Failed to load assets: $err',
                    style: AppTypography.caption.copyWith(color: AppColors.statusDangerStroke),
                  ),
                ),
                data: (records) {
                  final assetRecords = records.where((r) => r.record.recordType == 'asset').toList();
                  if (assetRecords.isEmpty) return const SizedBox.shrink();

                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedAssetRecordId,
                    decoration: const InputDecoration(
                      labelText: 'Link to Asset (Optional)',
                      hintText: 'Select linked possession or property',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('None (General Domestic Task)', overflow: TextOverflow.ellipsis),
                      ),
                      ...assetRecords.map(
                        (item) => DropdownMenuItem<String>(
                          value: item.record.id,
                          child: Text(item.record.title, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedAssetRecordId = val),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Task'),
              ),
            ],
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

    return Padding(
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
                    style: AppTypography.pageHeader.copyWith(fontSize: 22),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow('Status', task.status.toUpperCase()),
                    const Divider(),
                    _buildDetailRow('Priority', task.priority.toUpperCase()),
                    if (task.dueDate != null) ...[
                      const Divider(),
                      _buildDetailRow('Due Date', _formatFullDate(task.dueDate!)),
                    ],
                    if (task.completedAt != null) ...[
                      const Divider(),
                      _buildDetailRow('Completed On', _formatFullDate(task.completedAt!)),
                    ],
                    if (item.linkedAssetTitle != null) ...[
                      const Divider(),
                      _buildDetailRow('Linked Asset', item.linkedAssetTitle!),
                    ],
                    if (record.description != null && record.description!.isNotEmpty) ...[
                      const Divider(),
                      _buildDetailRow('Notes', record.description!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                final repo = ref.read(taskRepositoryProvider);
                final newStatus = isCompleted ? 'pending' : 'completed';

                try {
                  await repo.updateTaskStatus(
                    recordId: record.id,
                    status: newStatus,
                    completedAt: newStatus == 'completed' ? DateTime.now().toUtc() : null,
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to update task status: $e'),
                      backgroundColor: AppColors.statusDangerStroke,
                    ),
                  );
                }
              },
              icon: Icon(isCompleted ? Icons.undo : Icons.check_circle_outline),
              label: Text(isCompleted ? 'Mark as Pending' : 'Mark as Completed'),
            ),
            const SizedBox(height: 10),
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.bodyPrimary.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTask(BuildContext context, WidgetRef ref, String recordId, String title) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        title: const Text('Move to Trash?', style: AppTypography.cardTitle),
        content: Text(
          'Are you sure you want to remove "$title"?',
          style: AppTypography.bodyPrimary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDangerStroke,
              minimumSize: const Size(120, 44),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();

              try {
                final repo = ref.read(taskRepositoryProvider);
                await repo.softDeleteTask(recordId);

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Moved "$title" to trash'),
                    backgroundColor: AppColors.brandPrimary,
                  ),
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
