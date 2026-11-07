import 'package:flutter/material.dart';

import '../../categories/domain/category.dart';
import '../../records/domain/record.dart';

/// Supported categories for utility and recurring household obligations.
enum UtilityType {
  electricity('electricity', 'Electricity', Icons.bolt),
  water('water', 'Water', Icons.water_drop_outlined),
  internet('internet', 'Internet & Telecom', Icons.wifi),
  rent('rent', 'Rent & Housing', Icons.home_outlined),
  insurance('insurance', 'Insurance', Icons.shield_outlined),
  subscription('subscription', 'Subscription', Icons.subscriptions_outlined),
  trash('trash', 'Waste & Sanitation', Icons.delete_outline),
  other('other', 'Other Utility', Icons.receipt_long_outlined);

  final String value;
  final String label;
  final IconData icon;

  const UtilityType(this.value, this.label, this.icon);

  static UtilityType fromString(String? val) {
    return UtilityType.values.firstWhere(
      (e) => e.value.toLowerCase() == (val ?? '').toLowerCase(),
      orElse: () => UtilityType.other,
    );
  }
}

/// Lifecycle payment status for bills.
enum BillPaymentStatus {
  unpaid('unpaid', 'Unpaid', Icons.schedule),
  paid('paid', 'Paid', Icons.check_circle_outline),
  overdue('overdue', 'Overdue', Icons.error_outline),
  cancelled('cancelled', 'Cancelled', Icons.cancel_outlined);

  final String value;
  final String label;
  final IconData icon;

  const BillPaymentStatus(this.value, this.label, this.icon);

  static BillPaymentStatus fromString(String? val) {
    return BillPaymentStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == (val ?? '').toLowerCase(),
      orElse: () => BillPaymentStatus.unpaid,
    );
  }
}

/// Pure domain entity representing specialized Bill & Utility attributes.
class BillItem {
  final String recordId;
  final String utilityType;
  final String? providerName;
  final String? accountNumber;
  final DateTime? billingPeriodStart;
  final DateTime? billingPeriodEnd;
  final DateTime? dueDate;
  final int amountDueMinor;
  final String currencyCode;
  final String paymentStatus;
  final DateTime? paidAt;
  final String? linkedAssetRecordId;
  final String? linkedExpenseRecordId;

  const BillItem({
    required this.recordId,
    this.utilityType = 'utility',
    this.providerName,
    this.accountNumber,
    this.billingPeriodStart,
    this.billingPeriodEnd,
    this.dueDate,
    required this.amountDueMinor,
    this.currencyCode = 'PHP',
    this.paymentStatus = 'unpaid',
    this.paidAt,
    this.linkedAssetRecordId,
    this.linkedExpenseRecordId,
  });

  /// Human-readable currency amount formatted from integer minor units.
  String get formattedAmountDue {
    final major = amountDueMinor / 100.0;
    return '$currencyCode ${major.toStringAsFixed(2)}';
  }

  /// Whether this bill is due today.
  bool isDueToday([DateTime? referenceDate]) {
    if (dueDate == null) return false;
    final now = referenceDate ?? DateTime.now();
    return dueDate!.year == now.year && dueDate!.month == now.month && dueDate!.day == now.day;
  }

  /// Whether this bill is unpaid and past its due date.
  bool isPastDueAt([DateTime? referenceDate]) {
    if (paymentStatus == BillPaymentStatus.paid.value ||
        paymentStatus == BillPaymentStatus.cancelled.value ||
        dueDate == null) {
      return false;
    }
    final now = referenceDate ?? DateTime.now();
    if (isDueToday(now)) return false;
    final todayMidnight = DateTime(now.year, now.month, now.day);
    return dueDate!.isBefore(todayMidnight);
  }

  /// Convenience getter for [isPastDueAt].
  bool get isPastDue => isPastDueAt();

  UtilityType get utilityTypeEnum => UtilityType.fromString(utilityType);
  BillPaymentStatus get paymentStatusEnum => BillPaymentStatus.fromString(paymentStatus);

  BillItem copyWith({
    String? recordId,
    String? utilityType,
    String? providerName,
    String? accountNumber,
    DateTime? billingPeriodStart,
    DateTime? billingPeriodEnd,
    DateTime? dueDate,
    int? amountDueMinor,
    String? currencyCode,
    String? paymentStatus,
    DateTime? paidAt,
    String? linkedAssetRecordId,
    String? linkedExpenseRecordId,
  }) {
    return BillItem(
      recordId: recordId ?? this.recordId,
      utilityType: utilityType ?? this.utilityType,
      providerName: providerName ?? this.providerName,
      accountNumber: accountNumber ?? this.accountNumber,
      billingPeriodStart: billingPeriodStart ?? this.billingPeriodStart,
      billingPeriodEnd: billingPeriodEnd ?? this.billingPeriodEnd,
      dueDate: dueDate ?? this.dueDate,
      amountDueMinor: amountDueMinor ?? this.amountDueMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAt: paidAt ?? this.paidAt,
      linkedAssetRecordId: linkedAssetRecordId ?? this.linkedAssetRecordId,
      linkedExpenseRecordId: linkedExpenseRecordId ?? this.linkedExpenseRecordId,
    );
  }
}

/// Composite projection bundling universal [Record] with specialized [BillItem],
/// and optional linked [Asset], [Record] expense, and [Category].
class RecordWithBill {
  final Record record;
  final BillItem bill;
  final Record? linkedAssetRecord;
  final Record? linkedExpenseRecord;
  final Category? category;

  const RecordWithBill({
    required this.record,
    required this.bill,
    this.linkedAssetRecord,
    this.linkedExpenseRecord,
    this.category,
  });
}
