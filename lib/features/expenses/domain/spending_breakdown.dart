import '../../../core/constants/app_constants.dart';
import '../../bills/domain/bill_item.dart';
import '../../categories/data/category_repository_impl.dart';
import '../../categories/domain/category.dart';
import '../../records/domain/record.dart';
import '../../records/presentation/widgets/record_section_card.dart';
import 'expense_item.dart';

/// Supported time windows for aggregating household spending.
enum SpendingTimeRange {
  thisMonth('This Month'),
  last3Months('3 Months'),
  thisYear('This Year'),
  allTime('All Time');

  final String label;

  const SpendingTimeRange(this.label);
}

/// Immutable spending rollup for a single sub-category inside a main category.
class SpendingSubCategorySummary {
  final String id;
  final String name;
  final int totalMinor;
  final int expenseCount;
  final double sharePercent;

  const SpendingSubCategorySummary({
    required this.id,
    required this.name,
    required this.totalMinor,
    required this.expenseCount,
    required this.sharePercent,
  });
}

/// Immutable spending rollup for a top-level section/category and its sub-categories.
class SpendingCategorySummary {
  final String id;
  final String name;
  final String? iconKey;
  final int totalMinor;
  final int expenseCount;
  final double sharePercent;
  final List<SpendingSubCategorySummary> subCategories;

  const SpendingCategorySummary({
    required this.id,
    required this.name,
    this.iconKey,
    required this.totalMinor,
    required this.expenseCount,
    required this.sharePercent,
    required this.subCategories,
  });
}

/// Complete aggregated spending breakdown for a chosen [SpendingTimeRange].
class SpendingBreakdown {
  final int totalMinor;
  final int expenseCount;
  final String currencyCode;
  final List<String> currencies;
  final List<SpendingCategorySummary> categories;

  const SpendingBreakdown({
    required this.totalMinor,
    required this.expenseCount,
    this.currencyCode = AppConstants.defaultCurrency,
    this.currencies = const [],
    required this.categories,
  });

  /// Whether expenses in this breakdown span more than one currency code.
  bool get hasMixedCurrencies => currencies.length > 1;

  /// Aggregates [expenses] by top-level category and sub-category using exact
  /// integer minor-unit sums and calendar-date range filtering.
  static SpendingBreakdown compute({
    required List<RecordWithExpense> expenses,
    required List<RecordWithAsset> activeAssets,
    required List<Category> topLevelCategories,
    required List<Category> billsExpensesSubCategories,
    required List<RecordWithBill> bills,
    required SpendingTimeRange range,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final refDate = DateTime.utc(reference.year, reference.month, reference.day);

    final assetById = {for (final a in activeAssets) a.record.id: a};
    final categoryById = {for (final c in topLevelCategories) c.id: c};
    final billById = {for (final b in bills) b.record.id: b};
    final billsCategory = categoryById[CategoryRepositoryImpl.billsExpensesCategoryId];

    final categoryBuckets = <String, _MutableCategoryBucket>{};
    final currencySet = <String>{};
    var grandTotalMinor = 0;
    var totalCount = 0;

    for (final item in expenses) {
      if (!_matchesRange(item.expense.transactionDate, refDate, range)) {
        continue;
      }

      final amount = item.expense.amountMinor;
      grandTotalMinor += amount;
      totalCount += 1;
      currencySet.add(item.expense.currencyCode.trim());

      final resolved = _resolveClassification(
        item: item,
        assetById: assetById,
        categoryById: categoryById,
        billById: billById,
        billsCategory: billsCategory,
        billsExpensesSubCategories: billsExpensesSubCategories,
      );

      final catBucket = categoryBuckets.putIfAbsent(
        resolved.categoryId,
        () => _MutableCategoryBucket(
          id: resolved.categoryId,
          name: resolved.categoryName,
          iconKey: resolved.iconKey,
        ),
      );
      catBucket.totalMinor += amount;
      catBucket.expenseCount += 1;

      final subBucket = catBucket.subBuckets.putIfAbsent(
        resolved.subCategoryId,
        () => _MutableSubCategoryBucket(
          id: resolved.subCategoryId,
          name: resolved.subCategoryName,
        ),
      );
      subBucket.totalMinor += amount;
      subBucket.expenseCount += 1;
    }

    final sortedCurrencies = currencySet.where((c) => c.isNotEmpty).toList()..sort();
    final resolvedCurrency =
        sortedCurrencies.length == 1 ? sortedCurrencies.first : AppConstants.defaultCurrency;

    return SpendingBreakdown(
      totalMinor: grandTotalMinor,
      expenseCount: totalCount,
      currencyCode: resolvedCurrency,
      currencies: sortedCurrencies,
      categories: _buildCategorySummaries(categoryBuckets, grandTotalMinor),
    );
  }

  static List<SpendingCategorySummary> _buildCategorySummaries(
    Map<String, _MutableCategoryBucket> buckets,
    int grandTotalMinor,
  ) {
    final categories = buckets.values.map((bucket) {
      final subSummaries = bucket.subBuckets.values.map((sub) {
        final subShare =
            bucket.totalMinor <= 0 ? 0.0 : (sub.totalMinor * 100.0) / bucket.totalMinor;
        return SpendingSubCategorySummary(
          id: sub.id,
          name: sub.name,
          totalMinor: sub.totalMinor,
          expenseCount: sub.expenseCount,
          sharePercent: subShare,
        );
      }).toList()
        ..sort(_compareSubCategories);

      final catShare =
          grandTotalMinor <= 0 ? 0.0 : (bucket.totalMinor * 100.0) / grandTotalMinor;
      return SpendingCategorySummary(
        id: bucket.id,
        name: bucket.name,
        iconKey: bucket.iconKey,
        totalMinor: bucket.totalMinor,
        expenseCount: bucket.expenseCount,
        sharePercent: catShare,
        subCategories: subSummaries,
      );
    }).toList()
      ..sort(_compareCategories);
    return categories;
  }

  static bool _matchesRange(
    DateTime transactionDate,
    DateTime refDateUtc,
    SpendingTimeRange range,
  ) {
    if (range == SpendingTimeRange.allTime) return true;

    final txDate = DateTime.utc(
      transactionDate.year,
      transactionDate.month,
      transactionDate.day,
    );

    switch (range) {
      case SpendingTimeRange.thisMonth:
        return txDate.year == refDateUtc.year && txDate.month == refDateUtc.month;
      case SpendingTimeRange.last3Months:
        final start = DateTime.utc(refDateUtc.year, refDateUtc.month - 2, 1);
        final endOfMonth = DateTime.utc(refDateUtc.year, refDateUtc.month + 1, 0);
        return !txDate.isBefore(start) && !txDate.isAfter(endOfMonth);
      case SpendingTimeRange.thisYear:
        return txDate.year == refDateUtc.year;
      case SpendingTimeRange.allTime:
        return true;
    }
  }

  static _ExpenseClassification _resolveClassification({
    required RecordWithExpense item,
    required Map<String, RecordWithAsset> assetById,
    required Map<String, Category> categoryById,
    required Map<String, RecordWithBill> billById,
    required Category? billsCategory,
    required List<Category> billsExpensesSubCategories,
  }) {
    final linkedAssetId = item.expense.linkedAssetRecordId;
    final linkedAsset = linkedAssetId != null ? assetById[linkedAssetId] : null;
    if (linkedAsset != null) {
      final parentCategory =
          linkedAsset.record.categoryId != null ? categoryById[linkedAsset.record.categoryId!] : null;
      final expenseLabel = _resolveAssetExpenseLabel(
        item: item,
        billsExpensesSubCategories: billsExpensesSubCategories,
      );
      final assetTitle = linkedAsset.record.title.trim();
      final subName = assetTitle.toLowerCase() == expenseLabel.toLowerCase()
          ? assetTitle
          : '$assetTitle • $expenseLabel';

      return _ExpenseClassification(
        categoryId: parentCategory?.id ?? 'other-assets',
        categoryName: parentCategory?.name ?? 'Other Assets',
        iconKey: parentCategory?.iconKey ?? 'folder',
        subCategoryId: '${linkedAsset.record.id}::${expenseLabel.toLowerCase()}',
        subCategoryName: subName,
      );
    }

    final linkedBillId = item.expense.linkedBillRecordId;
    final linkedBill = linkedBillId != null ? billById[linkedBillId] : null;
    final subLabel = linkedBill != null
        ? resolveBillsExpensesSubCategoryLabel(
            rawType: linkedBill.bill.utilityType,
            billsExpensesSubCategories: billsExpensesSubCategories,
            categoryId: linkedBill.record.categoryId,
          )
        : resolveBillsExpensesSubCategoryLabel(
            rawType: item.expense.expenseCategory,
            billsExpensesSubCategories: billsExpensesSubCategories,
            categoryId: item.record.categoryId,
          );

    return _ExpenseClassification(
      categoryId: CategoryRepositoryImpl.billsExpensesCategoryId,
      categoryName: billsCategory?.name ?? 'Bills & Expenses',
      iconKey: billsCategory?.iconKey ?? 'receipt_long',
      subCategoryId: 'bills-sub::${subLabel.toLowerCase()}',
      subCategoryName: subLabel,
    );
  }

  static String _resolveAssetExpenseLabel({
    required RecordWithExpense item,
    required List<Category> billsExpensesSubCategories,
  }) {
    if (item.record.categoryId != null) {
      for (final sub in billsExpensesSubCategories) {
        if (sub.id == item.record.categoryId) return sub.name;
      }
    }
    return ExpenseCategory.fromString(item.expense.expenseCategory).label;
  }

  static int _compareCategories(SpendingCategorySummary a, SpendingCategorySummary b) {
    final byAmount = b.totalMinor.compareTo(a.totalMinor);
    return byAmount != 0 ? byAmount : a.name.compareTo(b.name);
  }

  static int _compareSubCategories(
    SpendingSubCategorySummary a,
    SpendingSubCategorySummary b,
  ) {
    final byAmount = b.totalMinor.compareTo(a.totalMinor);
    return byAmount != 0 ? byAmount : a.name.compareTo(b.name);
  }
}

class _ExpenseClassification {
  final String categoryId;
  final String categoryName;
  final String? iconKey;
  final String subCategoryId;
  final String subCategoryName;

  const _ExpenseClassification({
    required this.categoryId,
    required this.categoryName,
    required this.iconKey,
    required this.subCategoryId,
    required this.subCategoryName,
  });
}

class _MutableCategoryBucket {
  final String id;
  final String name;
  final String? iconKey;
  int totalMinor = 0;
  int expenseCount = 0;
  final Map<String, _MutableSubCategoryBucket> subBuckets = {};

  _MutableCategoryBucket({
    required this.id,
    required this.name,
    required this.iconKey,
  });
}

class _MutableSubCategoryBucket {
  final String id;
  final String name;
  int totalMinor = 0;
  int expenseCount = 0;

  _MutableSubCategoryBucket({
    required this.id,
    required this.name,
  });
}
