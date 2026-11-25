import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../expenses/domain/expense_item.dart';
import '../../records/presentation/widgets/record_section_card.dart';
import '../domain/bill_item.dart';

String _formatIsoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime _calendarDate(DateTime dt) => DateTime.utc(dt.year, dt.month, dt.day);

class BillDetailSheet extends ConsumerStatefulWidget {
  final RecordWithBill item;

  const BillDetailSheet({super.key, required this.item});

  @override
  ConsumerState<BillDetailSheet> createState() => _BillDetailSheetState();
}

class _BillDetailSheetState extends ConsumerState<BillDetailSheet> {
  bool _isActionInProgress = false;

  void _invalidateBillAndExpenseProviders(String billRecordId) {
    ref.invalidate(activeRecordsStreamProvider);
    ref.invalidate(dashboardRecordsStreamProvider);
    ref.invalidate(activeBillsStreamProvider);
    ref.invalidate(dashboardBillsStreamProvider);
    ref.invalidate(upcomingBillsStreamProvider);
    ref.invalidate(workspaceTotalUnpaidBillsProvider);
    ref.invalidate(activeExpensesStreamProvider);
    ref.invalidate(dashboardExpensesStreamProvider);
    ref.invalidate(workspaceTotalExpensesProvider);
    ref.invalidate(billPaymentHistoryStreamProvider(billRecordId));
  }

  Future<void> _runBillMutation({
    required String billRecordId,
    required Future<void> Function() action,
    required String successMessage,
    required String errorPrefix,
    bool popSheetOnSuccess = false,
    bool usePrimarySnackBar = true,
  }) async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    setState(() => _isActionInProgress = true);
    try {
      await action();
      _invalidateBillAndExpenseProviders(billRecordId);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (popSheetOnSuccess) {
        Navigator.of(context).pop();
      } else {
        setState(() => _isActionInProgress = false);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: usePrimarySnackBar ? primaryColor : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isActionInProgress = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$errorPrefix: $e'),
          backgroundColor: AppColors.statusDangerStroke,
        ),
      );
    }
  }

  Future<void> _handleMarkPaid(RecordWithBill currentItem) async {
    final selectedPaidDate = await showDialog<DateTime>(
      context: context,
      builder: (_) => _ConfirmBillPaymentDialog(item: currentItem),
    );
    if (selectedPaidDate == null || !mounted) return;

    await _runBillMutation(
      billRecordId: currentItem.record.id,
      action: () => ref.read(billRepositoryProvider).markBillAsPaid(
            billRecordId: currentItem.record.id,
            paidAt: selectedPaidDate,
          ),
      successMessage: currentItem.bill.isRecurring
          ? 'Logged payment for "${currentItem.record.title}" and advanced to next cycle.'
          : 'Marked "${currentItem.record.title}" as paid and recorded expense.',
      errorPrefix: 'Failed to update bill',
      popSheetOnSuccess: !currentItem.bill.isRecurring,
    );
  }

  Future<void> _handlePause(RecordWithBill currentItem) async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final confirmed = await _showConfirmDialog(
      title: 'Pause Subscription?',
      message:
          'Pause "${currentItem.record.title}"? Domora will stop counting it as due and skip auto-logging until you resume.',
      confirmLabel: 'Pause',
      confirmColor: primaryColor,
    );
    if (confirmed != true || !mounted) return;

    await _runBillMutation(
      billRecordId: currentItem.record.id,
      action: () => ref.read(billRepositoryProvider).pauseSubscription(currentItem.record.id),
      successMessage: 'Paused "${currentItem.record.title}".',
      errorPrefix: 'Failed to pause subscription',
    );
  }

  Future<void> _handleCancel(RecordWithBill currentItem) async {
    final confirmed = await _showConfirmDialog(
      title: 'Cancel Subscription?',
      message:
          'Mark "${currentItem.record.title}" as cancelled? Auto-logging will be turned off and past payment history will remain preserved.',
      confirmLabel: 'Cancel Subscription',
      confirmColor: AppColors.statusDangerStroke,
    );
    if (confirmed != true || !mounted) return;

    await _runBillMutation(
      billRecordId: currentItem.record.id,
      action: () => ref.read(billRepositoryProvider).cancelSubscription(currentItem.record.id),
      successMessage: 'Cancelled "${currentItem.record.title}".',
      errorPrefix: 'Failed to cancel subscription',
    );
  }

  Future<void> _handleResume(RecordWithBill currentItem) async {
    final resumeSelection = await showDialog<_ResumeSubscriptionResult>(
      context: context,
      builder: (_) => _ResumeSubscriptionDialog(item: currentItem),
    );
    if (resumeSelection == null || !mounted) return;

    await _runBillMutation(
      billRecordId: currentItem.record.id,
      action: () async {
        final billRepo = ref.read(billRepositoryProvider);
        await billRepo.resumeSubscription(
          billRecordId: currentItem.record.id,
          nextDueDate: resumeSelection.nextDueDate,
          autoLogPayment: resumeSelection.autoLogPayment,
        );
        if (resumeSelection.autoLogPayment) {
          await billRepo.processDueSubscriptions(currentItem.record.workspaceId);
        }
      },
      successMessage: 'Resumed "${currentItem.record.title}".',
      errorPrefix: 'Failed to resume subscription',
    );
  }

  Future<void> _confirmDelete(RecordWithBill currentItem) async {
    final confirmed = await _showConfirmDialog(
      title: 'Delete Bill',
      message:
          'Are you sure you want to delete "${currentItem.record.title}"? It can be recovered from trash.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.statusDangerStroke,
    );
    if (confirmed != true || !mounted) return;

    await _runBillMutation(
      billRecordId: currentItem.record.id,
      action: () => ref.read(billRepositoryProvider).softDeleteBillRecord(currentItem.record.id),
      successMessage: 'Moved "${currentItem.record.title}" to trash.',
      errorPrefix: 'Failed to delete bill',
      popSheetOnSuccess: true,
      usePrimarySnackBar: false,
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.sheetRadius),
          side: BorderSide(color: ctx.borderSubtle),
        ),
        title: Text(
          title,
          style: AppTypography.cardTitle.copyWith(color: ctx.textPrimary),
        ),
        content: Text(
          message,
          style: AppTypography.bodyPrimary.copyWith(color: ctx.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveBills = ref.watch(dashboardBillsStreamProvider).asData?.value;
    final currentItem = liveBills
            ?.where((b) => b.record.id == widget.item.record.id)
            .firstOrNull ??
        widget.item;
    final record = currentItem.record;
    final bill = currentItem.bill;
    final isPaid = bill.paymentStatus == BillPaymentStatus.paid.value;
    final sheetBg = Theme.of(context).bottomSheetTheme.backgroundColor ?? context.surfaceCard;
    final statusStyle = _resolveStatusStyle(context, bill);
    final relativeDueLabel = _resolveRelativeDueLabel(bill);

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
              _buildHeader(context, currentItem),
              const SizedBox(height: 16),
              _buildDetailsCard(context, currentItem, statusStyle, relativeDueLabel),
              const SizedBox(height: 16),
              _BillPaymentHistorySection(billRecordId: record.id),
              const SizedBox(height: 20),
              if (!isPaid && !bill.isPaused && !bill.isCancelled) ...[
                ElevatedButton.icon(
                  key: const Key('bill_log_payment_button'),
                  onPressed: _isActionInProgress ? null : () => _handleMarkPaid(currentItem),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isActionInProgress
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    bill.isRecurring ? 'Log Payment & Advance Cycle' : 'Mark as Paid',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (bill.isRecurring) ...[
                _buildSubscriptionLifecycleActions(context, currentItem),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      context.isDarkMode ? AppColors.statusDangerStroke : AppColors.statusDangerText,
                  side: const BorderSide(color: AppColors.statusDangerStroke),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isActionInProgress ? null : () => _confirmDelete(currentItem),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Move to Trash'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, RecordWithBill currentItem) {
    final bill = currentItem.bill;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? context.surfaceContainerLow
                      : AppColors.brandAccentSage,
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
                  currentItem.record.title,
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
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    RecordWithBill currentItem,
    _StatusBadgeStyle statusStyle,
    String? relativeDueLabel,
  ) {
    final record = currentItem.record;
    final bill = currentItem.bill;

    return Card(
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
                    key: const Key('bill_detail_status_pill'),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusStyle.fill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusStyle.stroke),
                    ),
                    child: Text(
                      statusStyle.label,
                      style: AppTypography.badge.copyWith(
                        fontSize: 12,
                        color: statusStyle.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Utility Type',
              currentItem.category?.name ??
                  (bill.utilityTypeEnum == UtilityType.other && bill.utilityType != 'other'
                      ? bill.utilityType
                      : bill.utilityTypeEnum.label),
            ),
            if (bill.isRecurring) ...[
              const Divider(),
              _buildDetailRow(context, 'Billing Coverage', bill.recurrenceCycleEnum.label),
              const Divider(),
              _buildDetailRow(
                context,
                'Payment Mode',
                bill.autoLogPayment ? 'Auto-log ON' : 'Manual',
              ),
            ],
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
                bill.isRecurring ? 'Next Renewal' : 'Due Date',
                relativeDueLabel == null
                    ? _formatIsoDate(bill.dueDate!)
                    : '${_formatIsoDate(bill.dueDate!)} ($relativeDueLabel)',
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
            if (currentItem.linkedAssetRecord != null) ...[
              const Divider(),
              _buildDetailRow(context, 'Associated Property', currentItem.linkedAssetRecord!.title),
            ],
            if (bill.paidAt != null) ...[
              const Divider(),
              _buildDetailRow(context, 'Last Paid On', _formatIsoDate(bill.paidAt!)),
            ],
            if (currentItem.linkedExpenseRecord != null) ...[
              const Divider(),
              _buildDetailRow(
                context,
                'Linked Expense Log',
                currentItem.linkedExpenseRecord!.title,
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
    );
  }

  Widget _buildSubscriptionLifecycleActions(BuildContext context, RecordWithBill currentItem) {
    final bill = currentItem.bill;
    if (bill.isPaused || bill.isCancelled) {
      return ElevatedButton.icon(
        key: const Key('resume_subscription_button'),
        onPressed: _isActionInProgress ? null : () => _handleResume(currentItem),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 20),
        label: const Text(
          'Resume Subscription',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('pause_subscription_button'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.textPrimary,
              side: BorderSide(color: context.borderSubtle),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isActionInProgress ? null : () => _handlePause(currentItem),
            icon: const Icon(Icons.pause_circle_outline, size: 18),
            label: const Text('Pause'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('cancel_subscription_button'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  context.isDarkMode ? AppColors.statusDangerStroke : AppColors.statusDangerText,
              side: const BorderSide(color: AppColors.statusDangerStroke),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isActionInProgress ? null : () => _handleCancel(currentItem),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  _StatusBadgeStyle _resolveStatusStyle(BuildContext context, BillItem bill) {
    final isDark = context.isDarkMode;
    if (bill.paymentStatus == BillPaymentStatus.paid.value) {
      return _StatusBadgeStyle(
        label: 'PAID',
        fill: isDark
            ? AppColors.statusSuccessStroke.withValues(alpha: 0.22)
            : AppColors.statusSuccessFill,
        stroke: AppColors.statusSuccessStroke,
        text: isDark ? AppTheme.darkBrandSecondary : AppColors.statusSuccessText,
      );
    }
    if (bill.isPaused) {
      return _StatusBadgeStyle(
        label: 'PAUSED',
        fill: context.surfaceContainerLow,
        stroke: context.borderSubtle,
        text: context.textSecondary,
      );
    }
    if (bill.isCancelled) {
      return _StatusBadgeStyle(
        label: 'CANCELLED',
        fill: context.surfaceContainerLow,
        stroke: context.borderSubtle,
        text: context.textSecondary,
      );
    }
    if (bill.isPastDue) {
      return _StatusBadgeStyle(
        label: 'OVERDUE',
        fill: isDark
            ? AppColors.statusDangerStroke.withValues(alpha: 0.22)
            : AppColors.statusDangerFill,
        stroke: AppColors.statusDangerStroke,
        text: isDark ? AppColors.statusDangerStroke : AppColors.statusDangerText,
      );
    }
    return _StatusBadgeStyle(
      label: 'UNPAID',
      fill: isDark
          ? AppColors.statusWarningStroke.withValues(alpha: 0.22)
          : AppColors.statusWarningFill,
      stroke: AppColors.statusWarningStroke,
      text: isDark ? AppColors.statusWarningStroke : AppColors.statusWarningText,
    );
  }

  String? _resolveRelativeDueLabel(BillItem bill) {
    if (bill.isPaused) return 'Paused';
    if (bill.isCancelled) return 'Cancelled';
    if (bill.paymentStatus == BillPaymentStatus.paid.value) return null;
    final delta = bill.daysUntilDue();
    if (delta == null) return null;
    if (delta < 0) return 'Overdue by ${-delta} ${-delta == 1 ? 'day' : 'days'}';
    if (delta == 0) return 'Due today';
    return 'Due in $delta ${delta == 1 ? 'day' : 'days'}';
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
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
              style: valueStyle ??
                  AppTypography.cardTitle.copyWith(fontSize: 14, color: context.textPrimary),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadgeStyle {
  final String label;
  final Color fill;
  final Color stroke;
  final Color text;

  const _StatusBadgeStyle({
    required this.label,
    required this.fill,
    required this.stroke,
    required this.text,
  });
}

class _BillPaymentHistorySection extends ConsumerWidget {
  final String billRecordId;

  const _BillPaymentHistorySection({required this.billRecordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(billPaymentHistoryStreamProvider(billRecordId));

    return Container(
      key: const Key('bill_payment_history_section'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 17, color: context.brandAccent),
              const SizedBox(width: 8),
              Text(
                'Payment History',
                style: AppTypography.cardTitle.copyWith(fontSize: 14, color: context.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          historyAsync.when(
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: context.brandAccent),
                ),
              ),
            ),
            error: (err, _) => Text(
              'Failed to load payment history: $err',
              style: AppTypography.caption.copyWith(color: AppColors.statusDangerStroke),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return Text(
                  'No payments logged yet.',
                  style: AppTypography.bodySecondary.copyWith(color: context.textTertiary),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) Divider(height: 14, color: context.borderSubtle),
                    _PaymentHistoryRow(entry: entries[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PaymentHistoryRow extends StatelessWidget {
  final RecordWithExpense entry;

  const _PaymentHistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final expense = entry.expense;
    final description = entry.record.description ?? '';
    final isAutoLogged =
        expense.paymentMethod == 'auto_debit' || description.contains('Auto-logged');
    final isLate = description.contains('Paid late');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatIsoDate(expense.transactionDate),
                style: AppTypography.bodySecondary.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: adaptiveSageFill(context),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAutoLogged ? 'Auto-logged' : 'Manual',
                      style: AppTypography.badge.copyWith(color: context.brandAccent),
                    ),
                  ),
                  if (isLate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? AppColors.statusDangerStroke.withValues(alpha: 0.22)
                            : AppColors.statusDangerFill,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Paid late',
                        style: AppTypography.badge.copyWith(
                          color: context.isDarkMode
                              ? AppColors.statusDangerStroke
                              : AppColors.statusDangerText,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          expense.formattedAmount,
          style: AppTypography.cardTitle.copyWith(fontSize: 14, color: context.brandAccent),
        ),
      ],
    );
  }
}

class _ConfirmBillPaymentDialog extends StatefulWidget {
  final RecordWithBill item;

  const _ConfirmBillPaymentDialog({required this.item});

  @override
  State<_ConfirmBillPaymentDialog> createState() => _ConfirmBillPaymentDialogState();
}

class _ConfirmBillPaymentDialogState extends State<_ConfirmBillPaymentDialog> {
  late DateTime _selectedPaidDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedPaidDate = DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickPaidDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = _selectedPaidDate.isAfter(today) ? today : _selectedPaidDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked != null && mounted) {
      setState(() => _selectedPaidDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueDate = widget.item.bill.dueDate;
    final isLate = dueDate != null &&
        _calendarDate(_selectedPaidDate).isAfter(_calendarDate(dueDate));

    return AlertDialog(
      backgroundColor: context.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.sheetRadius),
        side: BorderSide(color: context.borderSubtle),
      ),
      title: Text(
        'Confirm Payment',
        style: AppTypography.cardTitle.copyWith(color: context.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.item.bill.isRecurring
                  ? 'Log ${widget.item.bill.formattedAmountDue} payment for "${widget.item.record.title}" and advance to the next cycle?'
                  : 'Mark "${widget.item.record.title}" as paid?\n\n'
                      'This will automatically record a ${widget.item.bill.formattedAmountDue} utility expense in your expense log.',
              style: AppTypography.bodyPrimary.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: 14),
            InkWell(
              key: const Key('bill_paid_date_picker'),
              onTap: _pickPaidDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(minHeight: 46),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: context.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_available_outlined, size: 18, color: context.brandAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Actual Paid Date: ${_formatIsoDate(_selectedPaidDate)}',
                        style: AppTypography.bodySecondary.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isLate) ...[
              const SizedBox(height: 10),
              Container(
                key: const Key('bill_late_payment_warning'),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? AppColors.statusWarningStroke.withValues(alpha: 0.18)
                      : AppColors.statusWarningFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Paid past due date (${_formatIsoDate(dueDate)}) — will be logged as paid late.',
                  style: AppTypography.caption.copyWith(
                    color: context.isDarkMode
                        ? AppColors.statusWarningStroke
                        : AppColors.statusWarningText,
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
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () => Navigator.of(context).pop(
            DateTime.utc(
              _selectedPaidDate.year,
              _selectedPaidDate.month,
              _selectedPaidDate.day,
            ),
          ),
          child: const Text('Mark Paid & Log Expense'),
        ),
      ],
    );
  }
}

class _ResumeSubscriptionResult {
  final DateTime nextDueDate;
  final bool autoLogPayment;

  const _ResumeSubscriptionResult({
    required this.nextDueDate,
    required this.autoLogPayment,
  });
}

class _ResumeSubscriptionDialog extends StatefulWidget {
  final RecordWithBill item;

  const _ResumeSubscriptionDialog({required this.item});

  @override
  State<_ResumeSubscriptionDialog> createState() => _ResumeSubscriptionDialogState();
}

class _ResumeSubscriptionDialogState extends State<_ResumeSubscriptionDialog> {
  late DateTime _nextDueDate;
  late bool _autoLogPayment;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final existingDue = widget.item.bill.dueDate;
    final initialUtc = existingDue != null && !_calendarDate(existingDue).isBefore(todayUtc)
        ? _calendarDate(existingDue)
        : widget.item.bill.recurrenceCycleEnum.advanceDate(todayUtc);
    _nextDueDate = DateTime(initialUtc.year, initialUtc.month, initialUtc.day);
    _autoLogPayment = widget.item.bill.autoLogPayment;
  }

  Future<void> _pickNextDueDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final defaultLastDate = firstDate.add(const Duration(days: 730));
    final lastDate = _nextDueDate.isAfter(defaultLastDate) ? _nextDueDate : defaultLastDate;
    final initial = _nextDueDate.isBefore(firstDate) ? firstDate : _nextDueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null && mounted) {
      setState(() => _nextDueDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.sheetRadius),
        side: BorderSide(color: context.borderSubtle),
      ),
      title: Text(
        'Resume Subscription',
        style: AppTypography.cardTitle.copyWith(color: context.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose the next renewal date for "${widget.item.record.title}". Past paused months will not be back-charged.',
              style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
            ),
            const SizedBox(height: 12),
            InkWell(
              key: const Key('resume_next_due_picker'),
              onTap: _pickNextDueDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(minHeight: 46),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: context.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_outlined, size: 18, color: context.brandAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Next Renewal: ${_formatIsoDate(_nextDueDate)}',
                        style: AppTypography.bodySecondary.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Auto-log payments',
                    style: AppTypography.bodySecondary.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  key: const Key('resume_auto_log_switch'),
                  value: _autoLogPayment,
                  onChanged: (val) => setState(() => _autoLogPayment = val),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('resume_subscription_confirm'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () => Navigator.of(context).pop(
            _ResumeSubscriptionResult(
              nextDueDate: DateTime.utc(
                _nextDueDate.year,
                _nextDueDate.month,
                _nextDueDate.day,
              ),
              autoLogPayment: _autoLogPayment,
            ),
          ),
          child: const Text('Resume'),
        ),
      ],
    );
  }
}
