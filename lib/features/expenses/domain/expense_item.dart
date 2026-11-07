import '../../records/domain/record.dart';

/// Semantic category definitions for financial expenses and maintenance costs.
enum ExpenseCategory {
  maintenance,
  purchase,
  utility,
  service,
  subscription,
  other;

  static ExpenseCategory fromString(String? value) {
    if (value == null) return ExpenseCategory.maintenance;
    switch (value.toLowerCase().trim()) {
      case 'maintenance':
        return ExpenseCategory.maintenance;
      case 'purchase':
        return ExpenseCategory.purchase;
      case 'utility':
        return ExpenseCategory.utility;
      case 'service':
        return ExpenseCategory.service;
      case 'subscription':
        return ExpenseCategory.subscription;
      default:
        return ExpenseCategory.other;
    }
  }

  String get label {
    switch (this) {
      case ExpenseCategory.maintenance:
        return 'Maintenance & Repairs';
      case ExpenseCategory.purchase:
        return 'Purchase / Acquisition';
      case ExpenseCategory.utility:
        return 'Utility & Energy';
      case ExpenseCategory.service:
        return 'Professional Service';
      case ExpenseCategory.subscription:
        return 'Subscription & Dues';
      case ExpenseCategory.other:
        return 'Miscellaneous';
    }
  }

  String get value {
    switch (this) {
      case ExpenseCategory.maintenance:
        return 'maintenance';
      case ExpenseCategory.purchase:
        return 'purchase';
      case ExpenseCategory.utility:
        return 'utility';
      case ExpenseCategory.service:
        return 'service';
      case ExpenseCategory.subscription:
        return 'subscription';
      case ExpenseCategory.other:
        return 'other';
    }
  }
}

/// Pure domain entity representing Expense & Maintenance Cost metadata.
class ExpenseItem {
  final String recordId;
  final int amountMinor;
  final String currencyCode;
  final DateTime transactionDate;
  final String? paymentMethod;
  final String expenseCategory;
  final String? linkedAssetRecordId;
  final String? linkedTaskRecordId;
  final String? linkedBillRecordId;
  final int? odometerReading;

  const ExpenseItem({
    required this.recordId,
    required this.amountMinor,
    this.currencyCode = 'PHP',
    required this.transactionDate,
    this.paymentMethod,
    this.expenseCategory = 'maintenance',
    this.linkedAssetRecordId,
    this.linkedTaskRecordId,
    this.linkedBillRecordId,
    this.odometerReading,
  });

  /// Formatted currency string with minor unit conversion (e.g. 150050 -> "PHP 1500.50").
  String get formattedAmount {
    final major = amountMinor / 100.0;
    return '$currencyCode ${major.toStringAsFixed(2)}';
  }

  ExpenseItem copyWith({
    String? recordId,
    int? amountMinor,
    String? currencyCode,
    DateTime? transactionDate,
    String? paymentMethod,
    String? expenseCategory,
    String? linkedAssetRecordId,
    String? linkedTaskRecordId,
    String? linkedBillRecordId,
    int? odometerReading,
  }) {
    return ExpenseItem(
      recordId: recordId ?? this.recordId,
      amountMinor: amountMinor ?? this.amountMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      transactionDate: transactionDate ?? this.transactionDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      expenseCategory: expenseCategory ?? this.expenseCategory,
      linkedAssetRecordId: linkedAssetRecordId ?? this.linkedAssetRecordId,
      linkedTaskRecordId: linkedTaskRecordId ?? this.linkedTaskRecordId,
      linkedBillRecordId: linkedBillRecordId ?? this.linkedBillRecordId,
      odometerReading: odometerReading ?? this.odometerReading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseItem &&
          runtimeType == other.runtimeType &&
          recordId == other.recordId &&
          amountMinor == other.amountMinor &&
          currencyCode == other.currencyCode &&
          transactionDate == other.transactionDate &&
          paymentMethod == other.paymentMethod &&
          expenseCategory == other.expenseCategory &&
          linkedAssetRecordId == other.linkedAssetRecordId &&
          linkedTaskRecordId == other.linkedTaskRecordId &&
          linkedBillRecordId == other.linkedBillRecordId &&
          odometerReading == other.odometerReading;

  @override
  int get hashCode =>
      recordId.hashCode ^
      amountMinor.hashCode ^
      currencyCode.hashCode ^
      transactionDate.hashCode ^
      paymentMethod.hashCode ^
      expenseCategory.hashCode ^
      linkedAssetRecordId.hashCode ^
      linkedTaskRecordId.hashCode ^
      linkedBillRecordId.hashCode ^
      odometerReading.hashCode;
}

/// Composite projection bundling universal Record with specialized ExpenseItem and optional link targets.
class RecordWithExpense {
  final Record record;
  final ExpenseItem expense;
  final String? linkedAssetTitle;
  final String? linkedTaskTitle;
  final String? linkedBillTitle;

  const RecordWithExpense({
    required this.record,
    required this.expense,
    this.linkedAssetTitle,
    this.linkedTaskTitle,
    this.linkedBillTitle,
  });
}
