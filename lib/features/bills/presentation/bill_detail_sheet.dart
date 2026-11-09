import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/bill_item.dart';

class BillDetailSheet extends ConsumerStatefulWidget {
  final RecordWithBill item;

  const BillDetailSheet({super.key, required this.item});

  @override
  ConsumerState<BillDetailSheet> createState() => _BillDetailSheetState();
}

class _BillDetailSheetState extends ConsumerState<BillDetailSheet> {
  bool _isActionInProgress = false;

  Future<void> _handleMarkPaid() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.sheetRadius),
          side: BorderSide(color: ctx.borderSubtle),
        ),
        title: Text(
          'Confirm Payment',
          style: AppTypography.cardTitle.copyWith(color: ctx.textPrimary),
        ),
        content: Text(
          'Mark "${widget.item.record.title}" as paid?\n\n'
          'This will automatically record a ${widget.item.bill.formattedAmountDue} utility expense in your expense log.',
          style: AppTypography.bodyPrimary.copyWith(color: ctx.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ctx.brandAccent,
              foregroundColor: ctx.isDarkMode ? AppColors.surfaceCanvas : AppColors.brandOnPrimary,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Mark Paid & Log Expense'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isActionInProgress = true);

    try {
      final repo = ref.read(billRepositoryProvider);
      await repo.markBillAsPaid(
        billRecordId: widget.item.record.id,
        paidAt: DateTime.now().toUtc(),
      );

      // Invalidate relevant providers to refresh UI immediately
      ref.invalidate(activeBillsStreamProvider);
      ref.invalidate(dashboardBillsStreamProvider);
      ref.invalidate(upcomingBillsStreamProvider);
      ref.invalidate(workspaceTotalUnpaidBillsProvider);
      ref.invalidate(activeExpensesStreamProvider);
      ref.invalidate(dashboardExpensesStreamProvider);
      ref.invalidate(workspaceTotalExpensesProvider);

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Marked "${widget.item.record.title}" as paid and recorded expense.',
            ),
            backgroundColor: AppColors.brandPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update bill: $e'),
            backgroundColor: AppColors.statusDangerStroke,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.sheetRadius),
          side: BorderSide(color: ctx.borderSubtle),
        ),
        title: Text(
          'Delete Bill',
          style: AppTypography.cardTitle.copyWith(color: ctx.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.item.record.title}"? It can be recovered from trash.',
          style: AppTypography.bodyPrimary.copyWith(color: ctx.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDangerStroke,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isActionInProgress = true);

    try {
      final repo = ref.read(billRepositoryProvider);
      await repo.softDeleteBillRecord(widget.item.record.id);

      ref.invalidate(activeBillsStreamProvider);
      ref.invalidate(dashboardBillsStreamProvider);
      ref.invalidate(upcomingBillsStreamProvider);
      ref.invalidate(workspaceTotalUnpaidBillsProvider);

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Moved "${widget.item.record.title}" to trash.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete bill: $e'),
            backgroundColor: AppColors.statusDangerStroke,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.item.record;
    final bill = widget.item.bill;
    final isPaid = bill.paymentStatus == BillPaymentStatus.paid.value;
    final isOverdue = bill.isPastDue;
    final sheetBg = Theme.of(context).bottomSheetTheme.backgroundColor ?? context.surfaceCard;

    Color statusFill;
    Color statusStroke;
    Color statusTextColor;
    String statusLabel;

    if (isPaid) {
      statusFill = AppColors.statusSuccessFill;
      statusStroke = AppColors.statusSuccessStroke;
      statusTextColor = AppColors.statusSuccessText;
      statusLabel = 'PAID';
    } else if (isOverdue) {
      statusFill = AppColors.statusDangerFill;
      statusStroke = AppColors.statusDangerStroke;
      statusTextColor = AppColors.statusDangerText;
      statusLabel = 'OVERDUE';
    } else {
      statusFill = AppColors.statusWarningFill;
      statusStroke = AppColors.statusWarningStroke;
      statusTextColor = AppColors.statusWarningText;
      statusLabel = 'UNPAID';
    }

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
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.isDarkMode ? context.surfaceContainerLow : AppColors.brandAccentSage,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            bill.utilityTypeEnum.icon,
                            color: context.brandAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            record.title,
                            style: AppTypography.pageHeader.copyWith(
                              fontSize: 20,
                              color: context.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Card details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        context,
                        'Amount Due',
                        bill.formattedAmountDue,
                        valueStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.brandAccent,
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment Status',
                              style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusFill,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusStroke),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: statusTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      _buildDetailRow(context, 'Utility Type', bill.utilityTypeEnum.label),
                      if (bill.providerName != null) ...[
                        const Divider(),
                        _buildDetailRow(context, 'Provider / Issuer', bill.providerName!),
                      ],
                      if (bill.accountNumber != null) ...[
                        const Divider(),
                        _buildDetailRow(context, 'Account / Ref No.', bill.accountNumber!),
                      ],
                      if (bill.dueDate != null) ...[
                        const Divider(),
                        _buildDetailRow(
                          context,
                          'Due Date',
                          '${bill.dueDate!.year}-${bill.dueDate!.month.toString().padLeft(2, '0')}-${bill.dueDate!.day.toString().padLeft(2, '0')}',
                        ),
                      ],
                      if (bill.billingPeriodStart != null || bill.billingPeriodEnd != null) ...[
                        const Divider(),
                        _buildDetailRow(
                          context,
                          'Billing Period',
                          '${bill.billingPeriodStart != null ? "${bill.billingPeriodStart!.month}/${bill.billingPeriodStart!.day}" : "N/A"} — '
                          '${bill.billingPeriodEnd != null ? "${bill.billingPeriodEnd!.month}/${bill.billingPeriodEnd!.day}/${bill.billingPeriodEnd!.year}" : "N/A"}',
                        ),
                      ],
                      if (widget.item.linkedAssetRecord != null) ...[
                        const Divider(),
                        _buildDetailRow(context, 'Associated Property', widget.item.linkedAssetRecord!.title),
                      ],
                      if (bill.paidAt != null) ...[
                        const Divider(),
                        _buildDetailRow(
                          context,
                          'Paid On',
                          '${bill.paidAt!.year}-${bill.paidAt!.month.toString().padLeft(2, '0')}-${bill.paidAt!.day.toString().padLeft(2, '0')}',
                        ),
                      ],
                      if (widget.item.linkedExpenseRecord != null) ...[
                        const Divider(),
                        _buildDetailRow(
                          context,
                          'Linked Expense Log',
                          widget.item.linkedExpenseRecord!.title,
                          valueStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.brandAccent,
                          ),
                        ),
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

              // Pay Action Button (if unpaid)
              if (!isPaid) ...[
                ElevatedButton.icon(
                  onPressed: _isActionInProgress ? null : _handleMarkPaid,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.brandAccent,
                    foregroundColor: context.isDarkMode ? AppColors.surfaceCanvas : AppColors.brandOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isActionInProgress
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.isDarkMode ? AppColors.surfaceCanvas : AppColors.brandOnPrimary,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text(
                    'Mark as Paid',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Soft-Delete Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusDangerText,
                  side: const BorderSide(color: AppColors.statusDangerStroke),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isActionInProgress ? null : _confirmDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Move to Trash'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySecondary.copyWith(color: context.textSecondary)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: valueStyle ?? AppTypography.cardTitle.copyWith(fontSize: 14, color: context.textPrimary),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
