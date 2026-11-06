import '../../records/domain/record.dart';

/// Categories of expenses and maintenance costs.
enum ExpenseCategory {
  maintenance,
  purchase,
  utility,
  service,
  subscription,
  other;

  static ExpenseCategory fromString(String? val) {
    switch (val?.toLowerCase()) {
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
      case 'other':
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

  const ExpenseItem({
    required this.recordId,
    required this.amountMinor,
    this.currencyCode = 'PHP',
    required this.transactionDate,
    this.paymentMethod,
    this.expenseCategory = 'maintenance',
    this.linkedAssetRecordId,
    this.linkedTaskRecordId,
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
          linkedTaskRecordId == other.linkedTaskRecordId;

  @override
  int get hashCode => Object.hash(
        recordId,
        amountMinor,
        currencyCode,
        transactionDate,
        paymentMethod,
        expenseCategory,
        linkedAssetRecordId,
        linkedTaskRecordId,
      );
}

/// Composite domain entity holding a universal Record and its linked specialized Expense metadata.
class RecordWithExpense {
  final Record record;
  final ExpenseItem expense;
  final String? linkedAssetTitle;
  final String? linkedTaskTitle;

  const RecordWithExpense({
    required this.record,
    required this.expense,
    this.linkedAssetTitle,
    this.linkedTaskTitle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordWithExpense &&
          runtimeType == other.runtimeType &&
          record == other.record &&
          expense == other.expense &&
          linkedAssetTitle == other.linkedAssetTitle &&
          linkedTaskTitle == other.linkedTaskTitle;

  @override
  int get hashCode => Object.hash(record, expense, linkedAssetTitle, linkedTaskTitle);
}
