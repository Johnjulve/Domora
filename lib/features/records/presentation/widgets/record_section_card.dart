import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../bills/domain/bill_item.dart';
import '../../../categories/domain/category.dart';
import '../../../expenses/domain/expense_item.dart';
import '../../domain/record.dart';

/// Adaptive Sanctuary sage highlight fill compliant with both Light and Dark themes.
Color adaptiveSageFill(BuildContext context) {
  return context.isDarkMode
      ? AppTheme.darkBrandSecondary.withValues(alpha: 0.15)
      : AppColors.brandAccentSage;
}

/// Maps a category `iconKey` string to its Sanctuary Material [IconData].
IconData categoryIconFromKey(String? iconKey) {
  switch (iconKey) {
    case 'home':
      return Icons.home_outlined;
    case 'directions_car':
      return Icons.directions_car_outlined;
    case 'kitchen':
      return Icons.kitchen_outlined;
    case 'devices':
      return Icons.devices_outlined;
    case 'chair':
      return Icons.chair_outlined;
    case 'home_repair_service':
      return Icons.home_repair_service_outlined;
    case 'people':
      return Icons.people_outlined;
    case 'receipt_long':
      return Icons.receipt_long_outlined;
    case 'autorenew':
      return Icons.autorenew;
    case 'swap_horiz':
      return Icons.swap_horiz;
    case 'build':
      return Icons.build_outlined;
    case 'payments':
      return Icons.payments_outlined;
    default:
      return Icons.folder_outlined;
  }
}

typedef _CanonicalSubCategory = ({String id, String defaultName});

const Map<String, _CanonicalSubCategory> _canonicalSubCategoryAliases = {
  'electricity': (id: 'cat-sub-bill', defaultName: 'Bill'),
  'water': (id: 'cat-sub-bill', defaultName: 'Bill'),
  'internet': (id: 'cat-sub-bill', defaultName: 'Bill'),
  'rent': (id: 'cat-sub-bill', defaultName: 'Bill'),
  'insurance': (id: 'cat-sub-bill', defaultName: 'Bill'),
  'trash': (id: 'cat-sub-bill', defaultName: 'Bill'),
  'utility': (id: 'cat-sub-bill', defaultName: 'Bill'),
  'bill': (id: 'cat-sub-bill', defaultName: 'Bill'),
  'subscription': (id: 'cat-sub-subscription', defaultName: 'Subscription'),
  'withdraw': (id: 'cat-sub-withdraw-deposit', defaultName: 'Withdraw / Deposit'),
  'deposit': (id: 'cat-sub-withdraw-deposit', defaultName: 'Withdraw / Deposit'),
  'withdraw_deposit': (id: 'cat-sub-withdraw-deposit', defaultName: 'Withdraw / Deposit'),
  'maintenance': (id: 'cat-sub-maintenance', defaultName: 'Maintenance'),
  'purchase': (id: 'cat-sub-general-expense', defaultName: 'General Expense'),
  'service': (id: 'cat-sub-general-expense', defaultName: 'General Expense'),
  'other': (id: 'cat-sub-general-expense', defaultName: 'General Expense'),
  'general_expense': (id: 'cat-sub-general-expense', defaultName: 'General Expense'),
};

/// Resolves a bill's `utilityType` or an expense's `expenseCategory` to the matching
/// active sub-category label under `Bills & Expenses`.
String resolveBillsExpensesSubCategoryLabel({
  required String rawType,
  required List<Category> billsExpensesSubCategories,
  String? categoryId,
}) {
  if (categoryId != null) {
    for (final sub in billsExpensesSubCategories) {
      if (sub.id == categoryId) return sub.name;
    }
  }

  final normalized = rawType.trim().toLowerCase();
  if (normalized.isEmpty) return 'Other';

  for (final sub in billsExpensesSubCategories) {
    if (sub.name.trim().toLowerCase() == normalized) {
      return sub.name;
    }
  }

  final canonical = _canonicalSubCategoryAliases[normalized];
  if (canonical == null) return 'Other';

  for (final sub in billsExpensesSubCategories) {
    if (sub.id == canonical.id) return sub.name;
  }
  for (final sub in billsExpensesSubCategories) {
    if (sub.name.trim().toLowerCase() == canonical.defaultName.toLowerCase()) {
      return sub.name;
    }
  }

  return billsExpensesSubCategories.isEmpty ? canonical.defaultName : 'Other';
}

/// Sanctuary-styled collapsible boxed section container for grouped Life Records.
class RecordSectionCard extends StatelessWidget {
  final String sectionId;
  final String title;
  final IconData icon;
  final int itemCount;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> children;
  final String? emptyMessage;

  const RecordSectionCard({
    super.key,
    required this.sectionId,
    required this.title,
    required this.icon,
    required this.itemCount,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: context.borderSubtle, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            if (isExpanded) _buildBody(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Semantics(
      button: true,
      expanded: isExpanded,
      label: '$title section, $itemCount items',
      child: InkWell(
        key: Key('section_header_$sectionId'),
        onTap: onToggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: context.brandAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.cardTitle.copyWith(color: context.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  key: Key('section_count_$sectionId'),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: adaptiveSageFill(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$itemCount',
                    style: AppTypography.badge.copyWith(color: context.brandAccent),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: context.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (children.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, color: context.borderSubtle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              emptyMessage ?? 'No records in this section yet.',
              style: AppTypography.bodySecondary.copyWith(color: context.textTertiary),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: context.borderSubtle),
        ..._withDividers(context, children),
      ],
    );
  }

  List<Widget> _withDividers(BuildContext context, List<Widget> widgets) {
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      if (i > 0) {
        result.add(
          Divider(
            height: 1,
            indent: 14,
            endIndent: 14,
            color: context.borderSubtle,
          ),
        );
      }
      result.add(widgets[i]);
    }
    return result;
  }
}

/// Compact sub-category header strip rendered inside the `Bills & Expenses` section.
class BillsSubCategoryHeader extends StatelessWidget {
  final String label;
  final int count;

  const BillsSubCategoryHeader({
    super.key,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('bills_subgroup_$label'),
      color: context.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: context.textSecondary,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$count',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: context.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact summary row for an Asset (or standalone non-bill/non-expense record).
class AssetSummaryTile extends StatelessWidget {
  final RecordWithAsset item;
  final int linkedExpenseCount;
  final int linkedDocumentCount;
  final VoidCallback onTap;

  const AssetSummaryTile({
    super.key,
    required this.item,
    required this.linkedExpenseCount,
    required this.linkedDocumentCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final asset = item.asset;
    final subtitleParts = <String>[
      if (asset?.brand != null && asset!.brand!.isNotEmpty) asset.brand!,
      if (asset?.model != null && asset!.model!.isNotEmpty) asset.model!,
      if (asset?.locationDescription != null && asset!.locationDescription!.isNotEmpty)
        asset.locationDescription!,
    ];

    final metaPills = <Widget>[
      if (linkedExpenseCount > 0)
        _MetaPill(
          icon: Icons.build_outlined,
          label: '$linkedExpenseCount ${linkedExpenseCount == 1 ? 'log' : 'logs'}',
        ),
      if (asset?.nextPmsOdometerTarget != null)
        _MetaPill(
          icon: Icons.speed_outlined,
          label: 'Next PMS: ${asset!.nextPmsOdometerTarget} km',
        ),
      if (linkedDocumentCount > 0)
        _MetaPill(
          icon: Icons.description_outlined,
          label: '$linkedDocumentCount ${linkedDocumentCount == 1 ? 'paper' : 'papers'}',
        ),
    ];

    return InkWell(
      key: Key('record_item_${item.record.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.record.title,
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 15,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: adaptiveSageFill(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.record.recordType.toUpperCase(),
                    style: AppTypography.badge.copyWith(color: context.brandAccent),
                  ),
                ),
              ],
            ),
            if (subtitleParts.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitleParts.join(' • '),
                style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (asset?.purchaseAmountMinor != null) ...[
              const SizedBox(height: 6),
              Text(
                'Value: ${CurrencyFormatter.formatMinor(asset!.purchaseAmountMinor!, currencyCode: asset.purchaseCurrency)}',
                style: AppTypography.bodyPrimary.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.brandAccent,
                ),
              ),
            ],
            if (metaPills.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: metaPills,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact row for a Bill inside `Bills & Expenses` or search results.
class BillRecordTile extends StatelessWidget {
  final RecordWithBill item;
  final int linkedPaymentCount;
  final VoidCallback onTap;

  const BillRecordTile({
    super.key,
    required this.item,
    required this.linkedPaymentCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bill = item.bill;
    final statusBadge = _resolveStatusBadge(context, bill);
    final effectivePaymentCount = linkedPaymentCount > 0
        ? linkedPaymentCount
        : (bill.linkedExpenseRecordId != null ? 1 : 0);
    final recurringSubtitle = _buildRecurringSubtitle(bill);

    return InkWell(
      key: Key('bill_item_${item.record.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.record.title,
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 15,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  key: Key('bill_status_pill_${item.record.id}'),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBadge.fill,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusBadge.label,
                    style: AppTypography.badge.copyWith(color: statusBadge.text),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bill.formattedAmountDue,
                  style: AppTypography.bodyPrimary.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.brandAccent,
                  ),
                ),
                if (bill.providerName != null && bill.providerName!.isNotEmpty)
                  Flexible(
                    child: Text(
                      bill.providerName!,
                      style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            if (recurringSubtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                recurringSubtitle,
                style: AppTypography.caption.copyWith(color: context.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (effectivePaymentCount > 0) ...[
              const SizedBox(height: 6),
              _MetaPill(
                icon: Icons.check_circle_outline,
                label:
                    '$effectivePaymentCount ${effectivePaymentCount == 1 ? 'payment logged' : 'payments logged'}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _buildRecurringSubtitle(BillItem bill) {
    if (!bill.isRecurring) return null;
    final cycleLabel = bill.recurrenceCycleEnum.label;
    if (bill.isPaused) return '$cycleLabel • Paused';
    if (bill.isCancelled) return '$cycleLabel • Cancelled';
    final mode = bill.autoLogPayment ? 'Auto-log' : 'Manual';
    final due = bill.dueDate;
    if (due == null) return '$cycleLabel • $mode';
    final dateStr =
        '${due.year.toString().padLeft(4, '0')}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}';
    return '$cycleLabel • $mode • Next: $dateStr';
  }

  ({String label, Color fill, Color text}) _resolveStatusBadge(
    BuildContext context,
    BillItem bill,
  ) {
    final isDark = context.isDarkMode;
    if (bill.paymentStatus == BillPaymentStatus.paid.value) {
      return (
        label: 'Paid',
        fill: isDark
            ? AppColors.statusSuccessStroke.withValues(alpha: 0.22)
            : AppColors.statusSuccessFill,
        text: isDark ? AppTheme.darkBrandSecondary : AppColors.statusSuccessText,
      );
    }
    if (bill.isPaused) {
      return (
        label: 'Paused',
        fill: context.surfaceContainerLow,
        text: context.textSecondary,
      );
    }
    if (bill.isCancelled) {
      return (
        label: 'Cancelled',
        fill: context.surfaceContainerLow,
        text: context.textSecondary,
      );
    }
    final delta = bill.daysUntilDue();
    if (bill.paymentStatus == BillPaymentStatus.overdue.value || bill.isPastDue) {
      final overdueLabel = delta != null && delta < 0 ? 'Overdue by ${-delta}d' : 'Overdue';
      return (
        label: overdueLabel,
        fill: isDark
            ? AppColors.statusDangerStroke.withValues(alpha: 0.22)
            : AppColors.statusDangerFill,
        text: isDark ? AppColors.statusDangerStroke : AppColors.statusDangerText,
      );
    }
    if (delta == 0) {
      return (
        label: 'Due today',
        fill: isDark
            ? AppColors.statusWarningStroke.withValues(alpha: 0.22)
            : AppColors.statusWarningFill,
        text: isDark ? AppColors.statusWarningStroke : AppColors.statusWarningText,
      );
    }
    if (delta != null && delta > 0 && delta <= 7) {
      return (
        label: 'Due in ${delta}d',
        fill: isDark
            ? AppColors.statusWarningStroke.withValues(alpha: 0.22)
            : AppColors.statusWarningFill,
        text: isDark ? AppColors.statusWarningStroke : AppColors.statusWarningText,
      );
    }
    return (
      label: 'Unpaid',
      fill: isDark
          ? AppColors.statusWarningStroke.withValues(alpha: 0.22)
          : AppColors.statusWarningFill,
      text: isDark ? AppColors.statusWarningStroke : AppColors.statusWarningText,
    );
  }
}

/// Compact row for a standalone Expense inside `Bills & Expenses` or search results.
class ExpenseRecordTile extends StatelessWidget {
  final RecordWithExpense item;
  final String subCategoryLabel;
  final VoidCallback onTap;

  const ExpenseRecordTile({
    super.key,
    required this.item,
    required this.subCategoryLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final expense = item.expense;
    final date = expense.transactionDate;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return InkWell(
      key: Key('expense_item_${item.record.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.record.title,
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 15,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  expense.formattedAmount,
                  style: AppTypography.bodyPrimary.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.brandAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  dateStr,
                  style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
                ),
                if (expense.paymentMethod != null && expense.paymentMethod!.isNotEmpty)
                  _MetaPill(
                    icon: Icons.payments_outlined,
                    label: expense.paymentMethod!.replaceAll('_', ' '),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: adaptiveSageFill(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    subCategoryLabel,
                    style: AppTypography.badge.copyWith(color: context.brandAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}
