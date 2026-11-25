import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
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

/// Supported recurrence cycles for subscriptions and recurring bills.
enum BillRecurrenceCycle {
  none('none', 'One-time', null),
  weekly('weekly', 'Weekly', null),
  monthly('monthly', 'Monthly', 1),
  quarterly('quarterly', 'Quarterly (3 months)', 3),
  semiAnnual('semi_annual', 'Semi-Annual (6 months)', 6),
  annual('annual', 'Annual (12 months)', 12);

  final String value;
  final String label;
  final int? months;

  const BillRecurrenceCycle(this.value, this.label, this.months);

  bool get isRecurring => this != BillRecurrenceCycle.none;

  static BillRecurrenceCycle fromString(String? val) {
    if (val == null) return BillRecurrenceCycle.none;
    final normalized = val.trim().toLowerCase();
    return BillRecurrenceCycle.values.firstWhere(
      (e) => e.value == normalized,
      orElse: () => BillRecurrenceCycle.none,
    );
  }

  /// Advances [from] by one cycle, clamping end-of-month days and preserving UTC/local kind.
  DateTime advanceDate(DateTime from) {
    if (this == BillRecurrenceCycle.none) return from;
    if (this == BillRecurrenceCycle.weekly) {
      return _buildDate(
        from.isUtc,
        from.year,
        from.month,
        from.day + 7,
        from,
      );
    }
    final zeroBasedMonth = (from.month - 1) + months!;
    final targetYear = from.year + (zeroBasedMonth ~/ 12);
    final targetMonth = (zeroBasedMonth % 12) + 1;
    final maxDays = DateTime.utc(targetYear, targetMonth + 1, 0).day;
    final targetDay = from.day > maxDays ? maxDays : from.day;
    return _buildDate(from.isUtc, targetYear, targetMonth, targetDay, from);
  }

  static DateTime _buildDate(
    bool isUtc,
    int year,
    int month,
    int day,
    DateTime template,
  ) {
    return isUtc
        ? DateTime.utc(
            year,
            month,
            day,
            template.hour,
            template.minute,
            template.second,
            template.millisecond,
            template.microsecond,
          )
        : DateTime(
            year,
            month,
            day,
            template.hour,
            template.minute,
            template.second,
            template.millisecond,
            template.microsecond,
          );
  }
}

/// Lifecycle payment status for bills.
enum BillPaymentStatus {
  unpaid('unpaid', 'Unpaid', Icons.schedule),
  paid('paid', 'Paid', Icons.check_circle_outline),
  overdue('overdue', 'Overdue', Icons.error_outline),
  paused('paused', 'Paused', Icons.pause_circle_outline),
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
  final String? recurrenceCycle;
  final bool autoLogPayment;
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
    this.recurrenceCycle,
    this.autoLogPayment = false,
    this.linkedAssetRecordId,
    this.linkedExpenseRecordId,
  });

  /// Human-readable currency amount formatted from integer minor units.
  String get formattedAmountDue => CurrencyFormatter.formatMinor(
        amountDueMinor,
        currencyCode: currencyCode,
      );

  /// Calendar-day difference between [dueDate] and [referenceDate] (negative when overdue).
  int? daysUntilDue([DateTime? referenceDate]) {
    if (dueDate == null) return null;
    final now = referenceDate ?? DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final dueUtc = DateTime.utc(dueDate!.year, dueDate!.month, dueDate!.day);
    return dueUtc.difference(todayUtc).inDays;
  }

  /// Whether this bill is due today.
  bool isDueToday([DateTime? referenceDate]) {
    return daysUntilDue(referenceDate) == 0;
  }

  /// Whether this bill is unpaid and past its due date.
  bool isPastDueAt([DateTime? referenceDate]) {
    if (paymentStatus == BillPaymentStatus.paid.value ||
        paymentStatus == BillPaymentStatus.paused.value ||
        paymentStatus == BillPaymentStatus.cancelled.value ||
        dueDate == null) {
      return false;
    }
    final delta = daysUntilDue(referenceDate);
    return delta != null && delta < 0;
  }

  /// Convenience getter for [isPastDueAt].
  bool get isPastDue => isPastDueAt();

  UtilityType get utilityTypeEnum => UtilityType.fromString(utilityType);
  BillPaymentStatus get paymentStatusEnum => BillPaymentStatus.fromString(paymentStatus);
  BillRecurrenceCycle get recurrenceCycleEnum => BillRecurrenceCycle.fromString(recurrenceCycle);
  bool get isRecurring => recurrenceCycleEnum.isRecurring;
  bool get isPaused => paymentStatus == BillPaymentStatus.paused.value;
  bool get isCancelled => paymentStatus == BillPaymentStatus.cancelled.value;

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
    String? recurrenceCycle,
    bool? autoLogPayment,
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
      recurrenceCycle: recurrenceCycle ?? this.recurrenceCycle,
      autoLogPayment: autoLogPayment ?? this.autoLogPayment,
      linkedAssetRecordId: linkedAssetRecordId ?? this.linkedAssetRecordId,
      linkedExpenseRecordId: linkedExpenseRecordId ?? this.linkedExpenseRecordId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillItem &&
          runtimeType == other.runtimeType &&
          recordId == other.recordId &&
          utilityType == other.utilityType &&
          providerName == other.providerName &&
          accountNumber == other.accountNumber &&
          billingPeriodStart == other.billingPeriodStart &&
          billingPeriodEnd == other.billingPeriodEnd &&
          dueDate == other.dueDate &&
          amountDueMinor == other.amountDueMinor &&
          currencyCode == other.currencyCode &&
          paymentStatus == other.paymentStatus &&
          paidAt == other.paidAt &&
          recurrenceCycle == other.recurrenceCycle &&
          autoLogPayment == other.autoLogPayment &&
          linkedAssetRecordId == other.linkedAssetRecordId &&
          linkedExpenseRecordId == other.linkedExpenseRecordId;

  @override
  int get hashCode => Object.hash(
        recordId,
        utilityType,
        providerName,
        accountNumber,
        billingPeriodStart,
        billingPeriodEnd,
        dueDate,
        amountDueMinor,
        currencyCode,
        paymentStatus,
        paidAt,
        recurrenceCycle,
        autoLogPayment,
        linkedAssetRecordId,
        linkedExpenseRecordId,
      );
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
