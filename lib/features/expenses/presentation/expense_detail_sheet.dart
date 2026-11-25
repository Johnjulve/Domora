import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../tasks/domain/task_item.dart';
import '../domain/expense_item.dart';

class ExpenseDetailSheet extends ConsumerStatefulWidget {
  final RecordWithExpense item;

  const ExpenseDetailSheet({super.key, required this.item});

  @override
  ConsumerState<ExpenseDetailSheet> createState() => _ExpenseDetailSheetState();
}

class _ExpenseDetailSheetState extends ConsumerState<ExpenseDetailSheet> {
  bool _isDeleting = false;
  bool _isDialogOpen = false;

  Future<List<RecordWithTask>> _findCandidatePmsTasks() async {
    final record = widget.item.record;
    final expense = widget.item.expense;
    final taskRepo = ref.read(taskRepositoryProvider);
    final byId = <String, RecordWithTask>{};

    if (expense.linkedTaskRecordId != null) {
      final pendingTasks = await taskRepo.getTasksByWorkspace(
        record.workspaceId,
        statusFilter: 'pending',
      );
      for (final t in pendingTasks) {
        if (t.record.id == expense.linkedTaskRecordId &&
            t.record.title.startsWith('Next PMS')) {
          byId[t.record.id] = t;
        }
      }
      return byId.values.toList();
    }

    if (expense.linkedAssetRecordId != null &&
        expense.expenseCategory == ExpenseCategory.maintenance.value) {
      final assetPendingTasks = await taskRepo.getTasksByWorkspace(
        record.workspaceId,
        statusFilter: 'pending',
        assetRecordId: expense.linkedAssetRecordId,
      );
      final assetExpenses = await ref.read(expenseRepositoryProvider).getExpensesByWorkspace(
            record.workspaceId,
            linkedAssetRecordId: expense.linkedAssetRecordId,
          );
      final claimedTaskIds = {
        for (final e in assetExpenses)
          if (e.record.id != record.id && e.expense.linkedTaskRecordId != null)
            e.expense.linkedTaskRecordId!,
      };
      for (final t in assetPendingTasks) {
        if (t.record.title.startsWith('Next PMS') && !claimedTaskIds.contains(t.record.id)) {
          byId[t.record.id] = t;
        }
      }
    }

    return byId.values.toList();
  }

  void _invalidateAfterDelete(String? linkedAssetRecordId) {
    ref.invalidate(activeTasksStreamProvider);
    ref.invalidate(dashboardTasksStreamProvider);
    ref.invalidate(activeRecordsStreamProvider);
    ref.invalidate(dashboardRecordsStreamProvider);
    ref.invalidate(activeAssetsStreamProvider);
    ref.invalidate(activeExpensesStreamProvider);
    ref.invalidate(dashboardExpensesStreamProvider);
    ref.invalidate(workspaceTotalExpensesProvider);
    if (linkedAssetRecordId != null) {
      ref.invalidate(assetExpensesStreamProvider(linkedAssetRecordId));
      ref.invalidate(assetTotalExpensesProvider(linkedAssetRecordId));
    }
  }

  Future<void> _handleDeleteTap() async {
    if (_isDeleting || _isDialogOpen) return;
    setState(() => _isDialogOpen = true);

    List<RecordWithTask> candidatePmsTasks;
    try {
      candidatePmsTasks = await _findCandidatePmsTasks();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDialogOpen = false);
      _showDangerSnackBar('Failed to check linked PMS tasks: $e');
      return;
    }

    if (!mounted) return;
    final decision = await showDialog<({bool removePms})>(
      context: context,
      builder: (_) => _ConfirmDeleteExpenseDialog(
        expenseTitle: widget.item.record.title,
        candidatePmsTasks: candidatePmsTasks,
      ),
    );

    if (decision == null || !mounted) {
      if (mounted) setState(() => _isDialogOpen = false);
      return;
    }

    final candidateIds = candidatePmsTasks.map((t) => t.record.id).toList();
    await _executeDelete(
      candidateTaskIds: candidateIds,
      removePms: decision.removePms && candidateIds.isNotEmpty,
    );
  }

  Future<void> _executeDelete({
    required List<String> candidateTaskIds,
    required bool removePms,
  }) async {
    setState(() => _isDeleting = true);
    final colorScheme = Theme.of(context).colorScheme;

    try {
      await ref.read(expenseRepositoryProvider).softDeleteExpense(
            widget.item.record.id,
            linkedTaskRecordIdsToDelete: removePms ? candidateTaskIds : const [],
            clearAssetNextPmsTarget: removePms,
          );
      _invalidateAfterDelete(widget.item.expense.linkedAssetRecordId);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            removePms
                ? 'Moved "${widget.item.record.title}" and scheduled Next PMS to trash'
                : 'Moved "${widget.item.record.title}" to trash',
            style: TextStyle(color: colorScheme.onPrimary),
          ),
          backgroundColor: colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _isDialogOpen = false;
      });
      _showDangerSnackBar('Failed to delete expense: $e');
    }
  }

  void _showDangerSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.statusDangerStroke,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.item.record;
    final expense = widget.item.expense;
    final category = ExpenseCategory.fromString(expense.expenseCategory);
    final sheetBg = Theme.of(context).bottomSheetTheme.backgroundColor ?? context.surfaceCard;
    final dangerForeground =
        context.isDarkMode ? AppColors.statusDangerStroke : AppColors.statusDangerText;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
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
                      style: AppTypography.pageHeader.copyWith(
                        fontSize: 22,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textSecondary),
                    onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDetailRow(context, 'Amount', expense.formattedAmount),
                      const Divider(),
                      _buildDetailRow(context, 'Category', category.label),
                      const Divider(),
                      _buildDetailRow(
                        context,
                        'Transaction Date',
                        '${expense.transactionDate.year}-${expense.transactionDate.month.toString().padLeft(2, '0')}-${expense.transactionDate.day.toString().padLeft(2, '0')}',
                      ),
                      if (expense.paymentMethod != null) ...[
                        const Divider(),
                        _buildDetailRow(
                          context,
                          'Payment Method',
                          expense.paymentMethod!.toUpperCase(),
                        ),
                      ],
                      if (widget.item.linkedAssetTitle != null) ...[
                        const Divider(),
                        _buildDetailRow(context, 'Linked Asset', widget.item.linkedAssetTitle!),
                      ],
                      if (widget.item.linkedTaskTitle != null) ...[
                        const Divider(),
                        _buildDetailRow(context, 'Linked Task', widget.item.linkedTaskTitle!),
                      ],
                      if (record.description != null && record.description!.isNotEmpty) ...[
                        const Divider(),
                        _buildDetailRow(context, 'Notes', record.description!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                key: const Key('expense_delete_button'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: dangerForeground,
                  side: const BorderSide(color: AppColors.statusDangerStroke),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (_isDeleting || _isDialogOpen) ? null : _handleDeleteTap,
                icon: _isDeleting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: dangerForeground,
                        ),
                      )
                    : const Icon(Icons.delete_outline),
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
          Text(
            label,
            style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.bodyPrimary.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmDeleteExpenseDialog extends StatefulWidget {
  final String expenseTitle;
  final List<RecordWithTask> candidatePmsTasks;

  const _ConfirmDeleteExpenseDialog({
    required this.expenseTitle,
    required this.candidatePmsTasks,
  });

  @override
  State<_ConfirmDeleteExpenseDialog> createState() => _ConfirmDeleteExpenseDialogState();
}

class _ConfirmDeleteExpenseDialogState extends State<_ConfirmDeleteExpenseDialog> {
  bool _removeLinkedPms = true;

  @override
  Widget build(BuildContext context) {
    final hasPms = widget.candidatePmsTasks.isNotEmpty;
    final pmsTitles = widget.candidatePmsTasks.map((t) => t.record.title).join(', ');

    return AlertDialog(
      backgroundColor: context.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.sheetRadius),
        side: BorderSide(color: context.borderSubtle),
      ),
      title: Text(
        'Move to Trash?',
        style: AppTypography.cardTitle.copyWith(color: context.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Are you sure you want to remove "${widget.expenseTitle}"?',
              style: AppTypography.bodyPrimary.copyWith(color: context.textPrimary),
            ),
            if (hasPms) ...[
              const SizedBox(height: 14),
              Material(
                color: context.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: context.borderSubtle),
                ),
                clipBehavior: Clip.antiAlias,
                child: CheckboxListTile(
                  key: const Key('delete_linked_pms_checkbox'),
                  value: _removeLinkedPms,
                  onChanged: (val) => setState(() => _removeLinkedPms = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  activeColor: Theme.of(context).colorScheme.primary,
                  checkColor: Theme.of(context).colorScheme.onPrimary,
                  title: Text(
                    'Also remove scheduled Next PMS task',
                    style: AppTypography.bodySecondary.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$pmsTitles\nClears the pending PMS reminder and vehicle Next Target PMS',
                      style: AppTypography.caption.copyWith(color: context.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.statusDangerStroke,
            foregroundColor: Colors.white,
            minimumSize: const Size(120, 44),
          ),
          onPressed: () => Navigator.of(context).pop((removePms: hasPms && _removeLinkedPms)),
          child: const Text('Move to Trash'),
        ),
      ],
    );
  }
}
