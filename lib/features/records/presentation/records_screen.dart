import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../bills/domain/bill_item.dart';
import '../../bills/presentation/add_bill_sheet.dart';
import '../../bills/presentation/bill_detail_sheet.dart';
import '../../categories/data/category_repository_impl.dart';
import '../../categories/domain/category.dart';
import '../../expenses/domain/expense_item.dart';
import '../../expenses/presentation/add_expense_sheet.dart';
import '../../expenses/presentation/expense_detail_sheet.dart';
import '../../tasks/domain/task_item.dart';
import '../../vault/domain/document_item.dart';
import '../../vault/presentation/vault_screen.dart';
import '../domain/record.dart';
import 'widgets/manage_categories_sheet.dart';
import 'widgets/quick_add_record_sheet.dart';
import 'widgets/record_section_card.dart';

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  late final TextEditingController _searchController;
  final Set<String> _collapsedSectionIds = <String>{};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSection(String sectionId) {
    setState(() {
      if (!_collapsedSectionIds.remove(sectionId)) {
        _collapsedSectionIds.add(sectionId);
      }
    });
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(recordSearchQueryProvider.notifier).clear();
    ref.read(selectedCategoryFilterProvider.notifier).selectCategory(null);
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(activeRecordsStreamProvider);
    final activeAssetsAsync = ref.watch(activeAssetsStreamProvider);
    final categoriesAsync = ref.watch(defaultCategoriesStreamProvider);
    final subCategoriesAsync = ref.watch(billsExpensesSubCategoriesStreamProvider);
    final billsAsync = ref.watch(dashboardBillsStreamProvider);
    final expensesAsync = ref.watch(dashboardExpensesStreamProvider);
    final tasksAsync = ref.watch(dashboardTasksStreamProvider);
    final docsAsync = ref.watch(dashboardDocumentsStreamProvider);
    final selectedCategoryId = ref.watch(selectedCategoryFilterProvider);
    final searchQuery = ref.watch(recordSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Records'),
        actions: [
          IconButton(
            key: const Key('records_quick_add_button'),
            icon: Icon(Icons.add_circle_outline, color: context.brandAccent),
            tooltip: 'Add Record',
            onPressed: () => _openQuickAddModal(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context, searchQuery),
          _buildCategoryChipBar(context, categoriesAsync, selectedCategoryId),
          const SizedBox(height: 8),
          Expanded(
            child: _buildBody(
              context: context,
              recordsAsync: recordsAsync,
              activeAssetsAsync: activeAssetsAsync,
              categoriesAsync: categoriesAsync,
              subCategoriesAsync: subCategoriesAsync,
              billsAsync: billsAsync,
              expensesAsync: expensesAsync,
              tasksAsync: tasksAsync,
              docsAsync: docsAsync,
              selectedCategoryId: selectedCategoryId,
              searchQuery: searchQuery,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, String searchQuery) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by title, brand, model, location...',
          prefixIcon: Icon(Icons.search, color: context.textSecondary),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: context.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(recordSearchQueryProvider.notifier).clear();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (val) => ref.read(recordSearchQueryProvider.notifier).setQuery(val),
      ),
    );
  }

  Widget _buildCategoryChipBar(
    BuildContext context,
    AsyncValue<List<Category>> categoriesAsync,
    String? selectedCategoryId,
  ) {
    return categoriesAsync.when(
      loading: () => const SizedBox(height: 44),
      error: (_, _) => const SizedBox.shrink(),
      data: (categories) {
        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildFilterChip(
                label: 'All',
                isSelected: selectedCategoryId == null,
                onTap: () => ref.read(selectedCategoryFilterProvider.notifier).selectCategory(null),
              ),
              const SizedBox(width: 8),
              ...categories.map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    label: cat.name,
                    isSelected: selectedCategoryId == cat.id,
                    onTap: () =>
                        ref.read(selectedCategoryFilterProvider.notifier).selectCategory(cat.id),
                  ),
                ),
              ),
              _buildManageChip(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildManageChip(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Manage categories',
      child: GestureDetector(
        key: const Key('manage_categories_chip'),
        onTap: () => _openManageCategoriesModal(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: context.borderSubtle, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, size: 15, color: context.brandAccent),
                const SizedBox(width: 6),
                Text(
                  'Manage',
                  style: AppTypography.bodySecondary.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.brandAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required AsyncValue<List<RecordWithAsset>> recordsAsync,
    required AsyncValue<List<RecordWithAsset>> activeAssetsAsync,
    required AsyncValue<List<Category>> categoriesAsync,
    required AsyncValue<List<Category>> subCategoriesAsync,
    required AsyncValue<List<RecordWithBill>> billsAsync,
    required AsyncValue<List<RecordWithExpense>> expensesAsync,
    required AsyncValue<List<RecordWithTask>> tasksAsync,
    required AsyncValue<List<RecordWithDocument>> docsAsync,
    required String? selectedCategoryId,
    required String searchQuery,
  }) {
    final firstError = recordsAsync.error ??
        activeAssetsAsync.error ??
        categoriesAsync.error ??
        billsAsync.error ??
        expensesAsync.error;
    if (firstError != null) {
      return _buildErrorState(firstError);
    }

    final isInitialLoading = (recordsAsync.isLoading && !recordsAsync.hasValue) ||
        (activeAssetsAsync.isLoading && !activeAssetsAsync.hasValue) ||
        (categoriesAsync.isLoading && !categoriesAsync.hasValue) ||
        (billsAsync.isLoading && !billsAsync.hasValue) ||
        (expensesAsync.isLoading && !expensesAsync.hasValue);
    if (isInitialLoading) {
      return Center(child: CircularProgressIndicator(color: context.brandAccent));
    }

    final viewData = _RecordsViewData.from(
      records: recordsAsync.asData?.value ?? const [],
      activeAssets: activeAssetsAsync.asData?.value ?? const [],
      categories: categoriesAsync.asData?.value ?? const [],
      billsSubCategories: subCategoriesAsync.asData?.value ?? const [],
      bills: billsAsync.asData?.value ?? const [],
      expenses: expensesAsync.asData?.value ?? const [],
      tasks: tasksAsync.asData?.value ?? const [],
      docs: docsAsync.asData?.value ?? const [],
    );

    final trimmedQuery = searchQuery.trim();
    if (trimmedQuery.isNotEmpty) {
      return _buildSearchResults(context, viewData, selectedCategoryId, trimmedQuery);
    }
    if (selectedCategoryId != null) {
      return _buildSingleCategoryView(context, viewData, selectedCategoryId);
    }
    return _buildAllSectionsView(context, viewData);
  }

  Widget _buildSearchResults(
    BuildContext context,
    _RecordsViewData data,
    String? selectedCategoryId,
    String searchQuery,
  ) {
    final tiles = <Widget>[];
    final seenIds = <String>{};
    final isBillsFilter = selectedCategoryId == CategoryRepositoryImpl.billsExpensesCategoryId;

    if (selectedCategoryId == null || isBillsFilter) {
      _appendFinancialSearchMatches(
        context: context,
        data: data,
        needle: searchQuery.toLowerCase(),
        standaloneOnly: isBillsFilter,
        seenIds: seenIds,
        tiles: tiles,
      );
    }

    for (final item in data.records) {
      if (seenIds.contains(item.record.id)) continue;
      final matchedExpense = data.lookup.expenseById[item.record.id];
      if (isBillsFilter && matchedExpense != null && !data.isStandaloneExpense(matchedExpense)) {
        continue;
      }
      seenIds.add(item.record.id);
      tiles.add(
        Card(
          clipBehavior: Clip.antiAlias,
          child: _buildSearchTileForRecord(context, data, item),
        ),
      );
    }

    if (tiles.isEmpty) {
      return _buildEmptyState(context, isFiltered: true);
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: tiles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) => tiles[index],
    );
  }

  void _appendFinancialSearchMatches({
    required BuildContext context,
    required _RecordsViewData data,
    required String needle,
    required bool standaloneOnly,
    required Set<String> seenIds,
    required List<Widget> tiles,
  }) {
    for (final bill in data.bills) {
      if (!_matchesBillQuery(bill, needle)) continue;
      seenIds.add(bill.record.id);
      tiles.add(
        Card(
          clipBehavior: Clip.antiAlias,
          child: BillRecordTile(
            item: bill,
            linkedPaymentCount: data.lookup.linkedPaymentsByBill[bill.record.id] ?? 0,
            onTap: () => _openBillDetailModal(context, bill),
          ),
        ),
      );
    }

    for (final exp in data.expenses) {
      if (standaloneOnly && !data.isStandaloneExpense(exp)) continue;
      if (!_matchesExpenseQuery(exp, needle)) continue;
      seenIds.add(exp.record.id);
      tiles.add(
        Card(
          clipBehavior: Clip.antiAlias,
          child: ExpenseRecordTile(
            item: exp,
            subCategoryLabel: resolveBillsExpensesSubCategoryLabel(
              rawType: exp.expense.expenseCategory,
              categoryId: exp.record.categoryId,
              billsExpensesSubCategories: data.billsSubCategories,
            ),
            onTap: () => _openExpenseDetailModal(context, exp),
          ),
        ),
      );
    }
  }

  Widget _buildSearchTileForRecord(
    BuildContext context,
    _RecordsViewData data,
    RecordWithAsset item,
  ) {
    final bill = data.lookup.billById[item.record.id];
    if (bill != null) {
      return BillRecordTile(
        item: bill,
        linkedPaymentCount: data.lookup.linkedPaymentsByBill[bill.record.id] ?? 0,
        onTap: () => _openBillDetailModal(context, bill),
      );
    }

    final expense = data.lookup.expenseById[item.record.id];
    if (expense != null) {
      return ExpenseRecordTile(
        item: expense,
        subCategoryLabel: resolveBillsExpensesSubCategoryLabel(
          rawType: expense.expense.expenseCategory,
          categoryId: expense.record.categoryId,
          billsExpensesSubCategories: data.billsSubCategories,
        ),
        onTap: () => _openExpenseDetailModal(context, expense),
      );
    }

    return AssetSummaryTile(
      item: item,
      linkedExpenseCount: data.lookup.expensesByAsset[item.record.id] ?? 0,
      linkedDocumentCount: data.lookup.docsByAsset[item.record.id] ?? 0,
      onTap: () => _openRecordDetailModal(context, item, data.lookup),
    );
  }

  Widget _buildSingleCategoryView(
    BuildContext context,
    _RecordsViewData data,
    String selectedCategoryId,
  ) {
    if (selectedCategoryId == CategoryRepositoryImpl.billsExpensesCategoryId) {
      final billsCategory = data.findCategory(selectedCategoryId);
      final taggedAssets = data.records.where((r) => r.record.recordType == 'asset').toList();
      final totalCount = data.bills.length + data.standaloneExpenses.length + taggedAssets.length;
      if (totalCount == 0) {
        return _buildEmptyState(context, isFiltered: true);
      }
      final card = _buildBillsExpensesSectionCard(
        context: context,
        data: data,
        title: billsCategory?.name ?? 'Bills & Expenses',
        iconKey: billsCategory?.iconKey ?? 'receipt_long',
        taggedAssets: taggedAssets,
      );
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [card],
      );
    }

    final assets = data.records.where((r) => r.record.recordType == 'asset').toList();
    if (assets.isEmpty) {
      return _buildEmptyState(context, isFiltered: true);
    }

    final category = data.findCategory(selectedCategoryId);
    final card = _buildAssetSectionCard(
      context: context,
      sectionId: selectedCategoryId,
      title: category?.name ?? 'Records',
      icon: categoryIconFromKey(category?.iconKey),
      items: assets,
      lookup: data.lookup,
    );
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [card],
    );
  }

  Widget _buildAllSectionsView(BuildContext context, _RecordsViewData data) {
    final partitioned = _partitionRecordsForAllSections(data);
    final sectionCards = _buildVisibleSectionCards(context, data, partitioned);

    if (sectionCards.isEmpty) {
      return _buildEmptyState(context, isFiltered: false);
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: sectionCards.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) => sectionCards[index],
    );
  }

  ({
    Map<String, List<RecordWithAsset>> assetsByCategory,
    List<RecordWithAsset> otherRecords,
  }) _partitionRecordsForAllSections(_RecordsViewData data) {
    final activeCategoryIds = data.categories.map((c) => c.id).toSet();
    final assetsByCategory = <String, List<RecordWithAsset>>{};
    final otherRecords = <RecordWithAsset>[];

    for (final item in data.records) {
      final type = item.record.recordType;
      if (type == 'asset') {
        final catId = item.record.categoryId;
        if (catId != null && activeCategoryIds.contains(catId)) {
          assetsByCategory.putIfAbsent(catId, () => []).add(item);
        } else {
          otherRecords.add(item);
        }
        continue;
      }
      if (type == 'task' && !data.lookup.linkedTaskIds.contains(item.record.id)) {
        otherRecords.add(item);
      }
    }

    return (assetsByCategory: assetsByCategory, otherRecords: otherRecords);
  }

  List<Widget> _buildVisibleSectionCards(
    BuildContext context,
    _RecordsViewData data,
    ({
      Map<String, List<RecordWithAsset>> assetsByCategory,
      List<RecordWithAsset> otherRecords,
    }) partitioned,
  ) {
    final sectionCards = <Widget>[];
    var renderedBillsSection = false;

    for (final cat in data.categories) {
      if (cat.id == CategoryRepositoryImpl.billsExpensesCategoryId) {
        final taggedAssets = partitioned.assetsByCategory[cat.id] ?? const [];
        final count = data.bills.length + data.standaloneExpenses.length + taggedAssets.length;
        if (count == 0 && cat.isSystem) continue;
        renderedBillsSection = true;
        sectionCards.add(
          _buildBillsExpensesSectionCard(
            context: context,
            data: data,
            title: cat.name,
            iconKey: cat.iconKey,
            taggedAssets: taggedAssets,
          ),
        );
        continue;
      }

      final items = partitioned.assetsByCategory[cat.id] ?? const [];
      if (items.isEmpty && cat.isSystem) continue;
      sectionCards.add(
        _buildAssetSectionCard(
          context: context,
          sectionId: cat.id,
          title: cat.name,
          icon: categoryIconFromKey(cat.iconKey),
          items: items,
          lookup: data.lookup,
        ),
      );
    }

    if (!renderedBillsSection && (data.bills.isNotEmpty || data.standaloneExpenses.isNotEmpty)) {
      sectionCards.add(
        _buildBillsExpensesSectionCard(
          context: context,
          data: data,
          title: 'Bills & Expenses',
          iconKey: 'receipt_long',
          taggedAssets: const [],
        ),
      );
    }

    if (partitioned.otherRecords.isNotEmpty) {
      sectionCards.add(
        _buildAssetSectionCard(
          context: context,
          sectionId: 'other-records',
          title: 'Other Records',
          icon: Icons.inventory_2_outlined,
          items: partitioned.otherRecords,
          lookup: data.lookup,
        ),
      );
    }

    return sectionCards;
  }

  RecordSectionCard _buildAssetSectionCard({
    required BuildContext context,
    required String sectionId,
    required String title,
    required IconData icon,
    required List<RecordWithAsset> items,
    required _RecordsLookup lookup,
  }) {
    return RecordSectionCard(
      sectionId: sectionId,
      title: title,
      icon: icon,
      itemCount: items.length,
      isExpanded: !_collapsedSectionIds.contains(sectionId),
      onToggle: () => _toggleSection(sectionId),
      children: items
          .map(
            (item) => AssetSummaryTile(
              item: item,
              linkedExpenseCount: lookup.expensesByAsset[item.record.id] ?? 0,
              linkedDocumentCount: lookup.docsByAsset[item.record.id] ?? 0,
              onTap: () => _openRecordDetailModal(context, item, lookup),
            ),
          )
          .toList(),
    );
  }

  RecordSectionCard _buildBillsExpensesSectionCard({
    required BuildContext context,
    required _RecordsViewData data,
    required String title,
    required String? iconKey,
    required List<RecordWithAsset> taggedAssets,
  }) {
    const sectionId = CategoryRepositoryImpl.billsExpensesCategoryId;
    final children = _groupBillsExpensesWidgets(context, data, taggedAssets);

    return RecordSectionCard(
      sectionId: sectionId,
      title: title,
      icon: categoryIconFromKey(iconKey),
      itemCount: data.bills.length + data.standaloneExpenses.length + taggedAssets.length,
      isExpanded: !_collapsedSectionIds.contains(sectionId),
      onToggle: () => _toggleSection(sectionId),
      children: children,
    );
  }

  List<Widget> _groupBillsExpensesWidgets(
    BuildContext context,
    _RecordsViewData data,
    List<RecordWithAsset> taggedAssets,
  ) {
    final grouped = <String, List<Widget>>{};

    for (final bill in data.bills) {
      final label = resolveBillsExpensesSubCategoryLabel(
        rawType: bill.bill.utilityType,
        categoryId: bill.record.categoryId,
        billsExpensesSubCategories: data.billsSubCategories,
      );
      grouped.putIfAbsent(label, () => []).add(
            BillRecordTile(
              item: bill,
              linkedPaymentCount: data.lookup.linkedPaymentsByBill[bill.record.id] ?? 0,
              onTap: () => _openBillDetailModal(context, bill),
            ),
          );
    }

    for (final exp in data.standaloneExpenses) {
      final label = resolveBillsExpensesSubCategoryLabel(
        rawType: exp.expense.expenseCategory,
        categoryId: exp.record.categoryId,
        billsExpensesSubCategories: data.billsSubCategories,
      );
      grouped.putIfAbsent(label, () => []).add(
            ExpenseRecordTile(
              item: exp,
              subCategoryLabel: label,
              onTap: () => _openExpenseDetailModal(context, exp),
            ),
          );
    }

    for (final asset in taggedAssets) {
      grouped.putIfAbsent('Other', () => []).add(
            AssetSummaryTile(
              item: asset,
              linkedExpenseCount: data.lookup.expensesByAsset[asset.record.id] ?? 0,
              linkedDocumentCount: data.lookup.docsByAsset[asset.record.id] ?? 0,
              onTap: () => _openRecordDetailModal(context, asset, data.lookup),
            ),
          );
    }

    final orderedLabels = <String>{
      for (final sub in data.billsSubCategories)
        if (grouped.containsKey(sub.name)) sub.name,
      ...grouped.keys,
    }.toList();

    final children = <Widget>[];
    for (final label in orderedLabels) {
      final groupItems = grouped[label]!;
      children.add(BillsSubCategoryHeader(label: label, count: groupItems.length));
      children.addAll(groupItems);
    }
    return children;
  }

  Widget _buildErrorState(Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.statusDangerStroke, size: 48),
            const SizedBox(height: 12),
            const Text('Failed to load records', style: AppTypography.cardTitle),
            const SizedBox(height: 8),
            Text(err.toString(), style: AppTypography.bodySecondary, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isFiltered}) {
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
                  decoration: BoxDecoration(
                    color: adaptiveSageFill(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.inventory_2_outlined, color: context.brandAccent, size: 36),
                ),
                const SizedBox(height: 20),
                Text(
                  isFiltered ? 'No Matching Records' : 'No Life Records Yet',
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  isFiltered
                      ? 'Try adjusting your search query or selecting a different category.'
                      : 'Keep your property, vehicle, appliance warranties, and receipts organized in one place.',
                  style: AppTypography.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (!isFiltered)
                  ElevatedButton.icon(
                    onPressed: () => _openAddAssetModal(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Asset'),
                  )
                else
                  OutlinedButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear Filters'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _matchesBillQuery(RecordWithBill bill, String needle) {
    final haystacks = [
      bill.record.title,
      bill.record.description,
      bill.bill.providerName,
      bill.bill.utilityType,
      bill.bill.accountNumber,
    ];
    return haystacks.any((s) => s != null && s.toLowerCase().contains(needle));
  }

  bool _matchesExpenseQuery(RecordWithExpense exp, String needle) {
    final haystacks = [
      exp.record.title,
      exp.record.description,
      exp.expense.expenseCategory,
      exp.expense.paymentMethod,
    ];
    return haystacks.any((s) => s != null && s.toLowerCase().contains(needle));
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label category filter',
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : context.surfaceCard,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? colorScheme.primary : context.borderSubtle,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: AppTypography.bodySecondary.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? colorScheme.onPrimary : context.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openManageCategoriesModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ManageCategoriesSheet(),
    );
  }

  Future<void> _openQuickAddModal(BuildContext context) async {
    final action = await showModalBottomSheet<QuickAddAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickAddRecordSheet(),
    );
    if (action == null || !context.mounted) return;

    switch (action.kind) {
      case QuickAddKind.bill:
        _openAddBillModal(context);
      case QuickAddKind.expense:
        _openAddExpenseModal(
          context,
          initialExpenseCategory: ExpenseCategory.other.value,
        );
      case QuickAddKind.maintenance:
        _openAddExpenseModal(
          context,
          initialExpenseCategory: ExpenseCategory.maintenance.value,
          prioritizeAssetLink: true,
        );
      case QuickAddKind.asset:
        _openAddAssetModal(context, initialCategoryId: action.categoryId);
    }
  }

  void _openAddBillModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddBillSheet(),
    );
  }

  void _openAddExpenseModal(
    BuildContext context, {
    String? initialExpenseCategory,
    bool prioritizeAssetLink = false,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseSheet(
        initialExpenseCategory: initialExpenseCategory,
        prioritizeAssetLink: prioritizeAssetLink,
      ),
    );
  }

  void _openAddAssetModal(BuildContext context, {String? initialCategoryId}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAssetSheet(initialCategoryId: initialCategoryId),
    );
  }

  void _openBillDetailModal(BuildContext context, RecordWithBill billItem) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BillDetailSheet(item: billItem),
    );
  }

  void _openExpenseDetailModal(BuildContext context, RecordWithExpense expenseItem) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseDetailSheet(item: expenseItem),
    );
  }

  Future<void> _openRecordDetailModal(
    BuildContext context,
    RecordWithAsset item,
    _RecordsLookup lookup,
  ) async {
    final bill = lookup.billById[item.record.id];
    if (bill != null) {
      _openBillDetailModal(context, bill);
      return;
    }

    if (item.record.recordType == 'bill') {
      final billRepo = ref.read(billRepositoryProvider);
      final billItem = await billRepo.getBillById(item.record.id);
      if (billItem != null && context.mounted) {
        _openBillDetailModal(context, billItem);
      }
      return;
    }

    final expense = lookup.expenseById[item.record.id];
    if (expense != null) {
      _openExpenseDetailModal(context, expense);
      return;
    }

    _openAssetDetailModal(context, item);
  }

  void _openAssetDetailModal(BuildContext context, RecordWithAsset item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssetDetailSheet(item: item),
    );
  }
}

class _RecordsViewData {
  final List<RecordWithAsset> records;
  final List<Category> categories;
  final List<Category> billsSubCategories;
  final List<RecordWithBill> bills;
  final List<RecordWithExpense> expenses;
  final Set<String> activeAssetIds;
  final Set<String> activeBillIds;
  final _RecordsLookup lookup;
  final List<RecordWithExpense> standaloneExpenses;

  const _RecordsViewData({
    required this.records,
    required this.categories,
    required this.billsSubCategories,
    required this.bills,
    required this.expenses,
    required this.activeAssetIds,
    required this.activeBillIds,
    required this.lookup,
    required this.standaloneExpenses,
  });

  factory _RecordsViewData.from({
    required List<RecordWithAsset> records,
    required List<RecordWithAsset> activeAssets,
    required List<Category> categories,
    required List<Category> billsSubCategories,
    required List<RecordWithBill> bills,
    required List<RecordWithExpense> expenses,
    required List<RecordWithTask> tasks,
    required List<RecordWithDocument> docs,
  }) {
    final activeAssetIds = {for (final a in activeAssets) a.record.id};
    final activeBillIds = {for (final b in bills) b.record.id};
    final lookup = _RecordsLookup.from(
      bills: bills,
      expenses: expenses,
      tasks: tasks,
      docs: docs,
      activeAssetIds: activeAssetIds,
    );
    final standaloneExpenses = expenses.where((e) {
      final hasActiveAsset =
          e.expense.linkedAssetRecordId != null && activeAssetIds.contains(e.expense.linkedAssetRecordId);
      final hasActiveBill =
          e.expense.linkedBillRecordId != null && activeBillIds.contains(e.expense.linkedBillRecordId);
      return !hasActiveAsset && !hasActiveBill;
    }).toList();

    return _RecordsViewData(
      records: records,
      categories: categories,
      billsSubCategories: billsSubCategories,
      bills: bills,
      expenses: expenses,
      activeAssetIds: activeAssetIds,
      activeBillIds: activeBillIds,
      lookup: lookup,
      standaloneExpenses: standaloneExpenses,
    );
  }

  bool isStandaloneExpense(RecordWithExpense e) {
    final hasActiveAsset =
        e.expense.linkedAssetRecordId != null && activeAssetIds.contains(e.expense.linkedAssetRecordId);
    final hasActiveBill =
        e.expense.linkedBillRecordId != null && activeBillIds.contains(e.expense.linkedBillRecordId);
    return !hasActiveAsset && !hasActiveBill;
  }

  Category? findCategory(String id) {
    for (final cat in categories) {
      if (cat.id == id) return cat;
    }
    return null;
  }
}

class _RecordsLookup {
  final Map<String, int> expensesByAsset;
  final Map<String, int> docsByAsset;
  final Map<String, int> linkedPaymentsByBill;
  final Set<String> linkedTaskIds;
  final Map<String, RecordWithBill> billById;
  final Map<String, RecordWithExpense> expenseById;

  const _RecordsLookup({
    required this.expensesByAsset,
    required this.docsByAsset,
    required this.linkedPaymentsByBill,
    required this.linkedTaskIds,
    required this.billById,
    required this.expenseById,
  });

  factory _RecordsLookup.from({
    required List<RecordWithBill> bills,
    required List<RecordWithExpense> expenses,
    required List<RecordWithTask> tasks,
    required List<RecordWithDocument> docs,
    required Set<String> activeAssetIds,
  }) {
    final expensesByAsset = <String, int>{};
    final linkedPaymentsByBill = <String, int>{};
    final expenseById = <String, RecordWithExpense>{};
    for (final exp in expenses) {
      expenseById[exp.record.id] = exp;
      final assetId = exp.expense.linkedAssetRecordId;
      if (assetId != null) {
        expensesByAsset[assetId] = (expensesByAsset[assetId] ?? 0) + 1;
      }
      final billId = exp.expense.linkedBillRecordId;
      if (billId != null) {
        linkedPaymentsByBill[billId] = (linkedPaymentsByBill[billId] ?? 0) + 1;
      }
    }

    final docsByAsset = <String, int>{};
    for (final doc in docs) {
      final assetId = doc.document.linkedAssetRecordId;
      if (assetId != null) {
        docsByAsset[assetId] = (docsByAsset[assetId] ?? 0) + 1;
      }
    }

    final linkedTaskIds = <String>{};
    for (final task in tasks) {
      final assetId = task.task.assetRecordId;
      if (assetId != null && activeAssetIds.contains(assetId)) {
        linkedTaskIds.add(task.record.id);
      }
    }

    final billById = <String, RecordWithBill>{
      for (final bill in bills) bill.record.id: bill,
    };

    return _RecordsLookup(
      expensesByAsset: expensesByAsset,
      docsByAsset: docsByAsset,
      linkedPaymentsByBill: linkedPaymentsByBill,
      linkedTaskIds: linkedTaskIds,
      billById: billById,
      expenseById: expenseById,
    );
  }
}

class _CustomFieldEntryInput {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _CustomFieldEntryInput({String key = '', String value = ''})
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class AddAssetSheet extends ConsumerStatefulWidget {
  final String? initialCategoryId;

  const AddAssetSheet({super.key, this.initialCategoryId});

  @override
  ConsumerState<AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends ConsumerState<AddAssetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  final _locationController = TextEditingController();
  final _deedNumberController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _odometerController = TextEditingController();
  final _pmsDistanceController = TextEditingController(text: '5000');
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Family member template controllers & state
  final _familyPhoneController = TextEditingController();
  final _familyIdNumberController = TextEditingController();
  final _familyMedicalNotesController = TextEditingController();
  String _familyRelationship = 'Spouse';
  DateTime? _familyBirthdate;
  String _familyBloodType = 'Unknown';

  int _pmsMonths = 6;
  String? _selectedCategoryId;
  String _condition = 'Good';
  String _selectedCurrency = AppConstants.defaultCurrency;
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiryDate;
  final List<_CustomFieldEntryInput> _customFields = [];
  bool _isWarrantyAndNotesExpanded = false;
  bool _isCustomFieldsExpanded = false;
  bool _isSubmitting = false;

  static const List<String> _currencies = [
    'PHP',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'SGD',
  ];

  static const List<String> _familyRelationships = [
    'Spouse',
    'Child',
    'Parent',
    'Sibling',
    'Pet',
    'Other',
  ];

  static const List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    'Unknown',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategoryId;
    _selectedCategoryId =
        initial == CategoryRepositoryImpl.billsExpensesCategoryId ? null : initial;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _locationController.dispose();
    _deedNumberController.dispose();
    _licensePlateController.dispose();
    _odometerController.dispose();
    _pmsDistanceController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _familyPhoneController.dispose();
    _familyIdNumberController.dispose();
    _familyMedicalNotesController.dispose();
    for (final cf in _customFields) {
      cf.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFamilyBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _familyBirthdate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _familyBirthdate = picked);
    }
  }

  DateTime _addCalendarMonths(DateTime from, int months) {
    final targetYear = from.year + (from.month + months - 1) ~/ 12;
    final targetMonth = (from.month + months - 1) % 12 + 1;
    final maxDays = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = from.day > maxDays ? maxDays : from.day;
    return DateTime(targetYear, targetMonth, targetDay, from.hour, from.minute, from.second);
  }

  String _formatDate(DateTime date) {
    final monthStr = date.month.toString().padLeft(2, '0');
    final dayStr = date.day.toString().padLeft(2, '0');
    return '${date.year}-$monthStr-$dayStr';
  }

  Future<void> _pickPurchaseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? now,
      firstDate: DateTime(1900),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _pickWarrantyExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _warrantyExpiryDate ?? now.add(const Duration(days: 365)),
      firstDate: DateTime(1990),
      lastDate: now.add(const Duration(days: 365 * 30)),
    );
    if (picked != null) {
      setState(() => _warrantyExpiryDate = picked);
    }
  }

  Future<void> _openAddCategoryDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nameController = TextEditingController();
    final dialogKey = GlobalKey<FormState>();

    try {
      final createdName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(ctx).dialogTheme.backgroundColor ?? Theme.of(ctx).cardColor,
          title: const Text('Add New Category', style: AppTypography.cardTitle),
          content: Form(
            key: dialogKey,
            child: TextFormField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Category Name *',
                hintText: 'e.g. Art & Antiques',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Category name is required';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogKey.currentState!.validate()) {
                  Navigator.of(ctx).pop(nameController.text.trim());
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      );

      if (createdName != null && createdName.isNotEmpty) {
        try {
          final now = DateTime.now().toUtc();
          final catId = 'cat-${const Uuid().v4()}';
          final newCategory = Category(
            id: catId,
            workspaceId: AppConstants.defaultWorkspaceId,
            name: createdName,
            iconKey: 'folder_outlined',
            colorHex: '#1E4B38',
            isSystem: false,
            createdAt: now,
          );

          final catRepo = ref.read(categoryRepositoryProvider);
          await catRepo.createCategory(newCategory);
          ref.invalidate(defaultCategoriesStreamProvider);

          if (mounted) {
            setState(() {
              _selectedCategoryId = catId;
            });
          }
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Failed to create category: $e'),
              backgroundColor: AppColors.statusDangerStroke,
            ),
          );
        }
      }
    } finally {
      nameController.dispose();
    }
  }

  void _addCustomField() {
    setState(() {
      _customFields.add(_CustomFieldEntryInput());
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      final item = _customFields.removeAt(index);
      item.dispose();
    });
  }

  Map<String, String> _buildCustomFieldMap({required String? categoryId}) {
    final customFieldMap = <String, String>{};
    if (categoryId == 'cat-family') {
      customFieldMap['Relationship'] = _familyRelationship;
      if (_familyBirthdate != null) {
        customFieldMap['Birthdate'] = _formatDate(_familyBirthdate!);
      }
      customFieldMap['Blood Type'] = _familyBloodType;
      if (_familyPhoneController.text.trim().isNotEmpty) {
        customFieldMap['Contact / Emergency Phone'] = _familyPhoneController.text.trim();
      }
      if (_familyIdNumberController.text.trim().isNotEmpty) {
        customFieldMap['ID / Insurance / PhilHealth No.'] = _familyIdNumberController.text.trim();
      }
      if (_familyMedicalNotesController.text.trim().isNotEmpty) {
        customFieldMap['Medical Notes & Allergies'] = _familyMedicalNotesController.text.trim();
      }
    } else {
      if (categoryId == 'cat-properties' && _deedNumberController.text.trim().isNotEmpty) {
        customFieldMap['Title / Deed Number'] = _deedNumberController.text.trim();
      }
      if (categoryId == 'cat-vehicles' && _licensePlateController.text.trim().isNotEmpty) {
        customFieldMap['License Plate'] = _licensePlateController.text.trim();
      }
    }
    for (final cf in _customFields) {
      final k = cf.keyController.text.trim();
      final v = cf.valueController.text.trim();
      if (k.isNotEmpty && v.isNotEmpty) {
        customFieldMap[k] = v;
      }
    }
    return customFieldMap;
  }

  Future<void> _submit(String? effectiveCategoryId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(recordRepositoryProvider);
      final recordId = const Uuid().v4();
      final now = DateTime.now().toUtc();

      final isFamily = effectiveCategoryId == 'cat-family';
      final isVehicle = effectiveCategoryId == 'cat-vehicles';
      final parsedAmount = isFamily ? null : double.tryParse(_amountController.text.trim());
      final int? amountMinor = parsedAmount != null && parsedAmount >= 0
          ? (parsedAmount * 100).round()
          : null;

      final parsedOdometer = isVehicle ? int.tryParse(_odometerController.text.trim()) : null;
      final parsedPmsDistance = isVehicle ? int.tryParse(_pmsDistanceController.text.trim()) : null;
      final initialTargetOdo = (isVehicle && parsedOdometer != null && parsedPmsDistance != null)
          ? parsedOdometer + parsedPmsDistance
          : null;
      final initialDueDate = isVehicle ? _addCalendarMonths(now, _pmsMonths) : null;
      final customFieldMap = _buildCustomFieldMap(categoryId: effectiveCategoryId);

      await repo.createAssetRecord(
        record: Record(
          id: recordId,
          workspaceId: AppConstants.defaultWorkspaceId,
          categoryId: effectiveCategoryId,
          recordType: 'asset',
          title: _titleController.text.trim(),
          description: isFamily
              ? (_familyMedicalNotesController.text.trim().isEmpty
                  ? null
                  : _familyMedicalNotesController.text.trim())
              : (_descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim()),
          createdAt: now,
          updatedAt: now,
        ),
        asset: Asset(
          recordId: recordId,
          brand: isFamily || _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
          model: isFamily || _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
          serialNumber: isFamily || _serialController.text.trim().isEmpty ? null : _serialController.text.trim(),
          condition: isFamily ? null : _condition,
          purchaseDate: isFamily ? null : _purchaseDate,
          purchaseAmountMinor: isFamily ? null : amountMinor,
          purchaseCurrency: isFamily ? AppConstants.defaultCurrency : _selectedCurrency,
          locationDescription: isFamily || _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          warrantyExpiryDate: isFamily ? null : _warrantyExpiryDate,
          odometerReading: isVehicle ? parsedOdometer : null,
          pmsDistanceIntervalKm: isVehicle ? parsedPmsDistance : null,
          pmsTimeIntervalMonths: isVehicle ? _pmsMonths : null,
          nextPmsOdometerTarget: initialTargetOdo,
          nextPmsDueDate: initialDueDate,
        ),
        customFields: customFieldMap.isEmpty ? null : customFieldMap,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save record: $e'),
            backgroundColor: AppColors.statusDangerStroke,
          ),
        );
      }
    }
  }

  String? _resolveEffectiveCategoryId(AsyncValue<List<Category>> categoriesAsync) {
    final loaded = categoriesAsync.asData?.value;
    if (loaded == null) {
      return _selectedCategoryId == CategoryRepositoryImpl.billsExpensesCategoryId
          ? null
          : _selectedCategoryId;
    }
    final isActiveAssetCategory = loaded.any(
      (c) => c.id == _selectedCategoryId && c.id != CategoryRepositoryImpl.billsExpensesCategoryId,
    );
    return isActiveAssetCategory ? _selectedCategoryId : null;
  }

  String _headerTitleFor(String? categoryId) {
    switch (categoryId) {
      case 'cat-vehicles':
        return 'Add Vehicle';
      case 'cat-appliances':
        return 'Add Appliance';
      case 'cat-family':
        return 'Add Family Member';
      case 'cat-properties':
        return 'Add Property';
      default:
        return 'New Asset Record';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(defaultCategoriesStreamProvider);
    final effectiveCategoryId = _resolveEffectiveCategoryId(categoriesAsync);
    final isFamily = effectiveCategoryId == 'cat-family';
    final theme = Theme.of(context);
    final sheetBg = theme.bottomSheetTheme.backgroundColor ?? theme.cardColor;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 10,
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
                    Text(
                      _headerTitleFor(effectiveCategoryId),
                      style: AppTypography.sectionTitle.copyWith(color: context.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: isFamily ? 'Full Name *' : 'Asset Title *',
                    hintText: isFamily ? 'e.g. Maria Santos' : 'e.g. Living Room Smart TV',
                  ),
                  autofocus: true,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return isFamily ? 'Full name is required' : 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                // Category Selector & "+ Add New Category" action (excluding Bills & Expenses)
                categoriesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (categories) {
                    final assetCategories = categories
                        .where((cat) => cat.id != CategoryRepositoryImpl.billsExpensesCategoryId)
                        .toList();
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: const Key('asset_category_dropdown'),
                            isExpanded: true,
                            initialValue: effectiveCategoryId,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'General / Uncategorized',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ...assetCategories.map(
                                (cat) => DropdownMenuItem<String>(
                                  value: cat.id,
                                  child: Text(cat.name, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ],
                            onChanged: (val) => setState(() => _selectedCategoryId = val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Add New Category',
                          icon: Icon(Icons.add_circle_outline, color: context.brandAccent),
                          onPressed: () => _openAddCategoryDialog(context),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Category-Specific Template Fields (Preserving all controller values non-destructively)
                _buildTemplateFields(context, effectiveCategoryId),
                if (!isFamily) ...[
                  const SizedBox(height: 8),
                  // Common Acquisition & Financial Section
                  _buildAcquisitionSection(context),
                ],
                const SizedBox(height: 8),
                // User-Defined Custom Fields Section
                _buildCustomFieldsSection(context),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submit(effectiveCategoryId),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isFamily ? 'Save Family Member' : 'Save Asset Record'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateFields(BuildContext context, String? categoryId) {
    if (categoryId == 'cat-family') {
      return _buildFamilyTemplateFields(context);
    }
    if (categoryId == 'cat-vehicles') {
      return _buildVehicleTemplateFields(context);
    }
    if (categoryId == 'cat-properties') {
      return _buildPropertyTemplateFields(context);
    }
    if (categoryId == 'cat-appliances' || categoryId == 'cat-electronics') {
      return _buildApplianceTemplateFields(context);
    }
    if (categoryId == 'cat-furniture' || categoryId == 'cat-tools') {
      return _buildFurnitureTemplateFields(context);
    }

    // General / Default Template
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Brand', hintText: 'e.g. Sony'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Model', hintText: 'e.g. Bravia 65"'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _serialController,
                decoration: const InputDecoration(labelText: 'Serial No.', hintText: 'e.g. SN-49281'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildConditionDropdown(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(labelText: 'Location', hintText: 'e.g. Living Room / Garage'),
        ),
      ],
    );
  }

  Widget _buildVehicleTemplateFields(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car_outlined, size: 18, color: context.brandAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vehicle PMS Limits & Odometer',
                  style: AppTypography.cardTitle.copyWith(fontSize: 14, color: context.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _brandController,
                  decoration: InputDecoration(
                    labelText: 'Brand / Make',
                    hintText: 'e.g. Toyota',
                    filled: true,
                    fillColor: context.surfaceCard,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    labelText: 'Model',
                    hintText: 'e.g. RAV4 Hybrid',
                    filled: true,
                    fillColor: context.surfaceCard,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _serialController,
                  decoration: InputDecoration(
                    labelText: 'VIN / Serial',
                    hintText: 'e.g. 4T1B...',
                    filled: true,
                    fillColor: context.surfaceCard,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _licensePlateController,
                  decoration: InputDecoration(
                    labelText: 'License Plate',
                    hintText: 'e.g. ABC-1234',
                    filled: true,
                    fillColor: context.surfaceCard,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _odometerController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Current Odometer (km)',
              hintText: 'e.g. 15000',
              prefixIcon: const Icon(Icons.speed, size: 20),
              filled: true,
              fillColor: context.surfaceCard,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _pmsDistanceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'PMS Distance (km)',
                    hintText: 'e.g. 5000',
                    filled: true,
                    fillColor: context.surfaceCard,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: const Key('vehicle_pms_time_dropdown'),
                  isExpanded: true,
                  initialValue: _pmsMonths,
                  decoration: InputDecoration(
                    labelText: 'PMS Time Limit',
                    filled: true,
                    fillColor: context.surfaceCard,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 3,
                      child: Text('3 months', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 6,
                      child: Text('6 months', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 12,
                      child: Text('12 months', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _pmsMonths = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Parking / Garage',
                    hintText: 'e.g. Main Garage Bay 1',
                    filled: true,
                    fillColor: context.surfaceCard,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildConditionDropdown(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTemplateFields(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home_work_outlined, size: 18, color: context.brandAccent),
              const SizedBox(width: 8),
              Text(
                'Property Details',
                style: AppTypography.cardTitle.copyWith(fontSize: 14, color: context.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Address / Location',
              hintText: 'e.g. 123 Heritage Way',
              filled: true,
              fillColor: context.surfaceCard,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _deedNumberController,
                  decoration: InputDecoration(
                    labelText: 'Title / Deed Number',
                    hintText: 'e.g. TCT-987654',
                    filled: true,
                    fillColor: context.surfaceCard,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildConditionDropdown(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplianceTemplateFields(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.devices_outlined, size: 18, color: context.brandAccent),
              const SizedBox(width: 8),
              Text(
                'Appliance / Electronic Details',
                style: AppTypography.cardTitle.copyWith(fontSize: 14, color: context.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _brandController,
                  decoration: InputDecoration(
                    labelText: 'Brand',
                    hintText: 'e.g. Sony',
                    filled: true,
                    fillColor: context.surfaceCard,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    labelText: 'Model',
                    hintText: 'e.g. Bravia 65"',
                    filled: true,
                    fillColor: context.surfaceCard,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _serialController,
                  decoration: InputDecoration(
                    labelText: 'Serial No.',
                    hintText: 'e.g. SN-49281',
                    filled: true,
                    fillColor: context.surfaceCard,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildConditionDropdown(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Location / Room',
              hintText: 'e.g. Living Room / Kitchen',
              filled: true,
              fillColor: context.surfaceCard,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFurnitureTemplateFields(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home_repair_service_outlined, size: 18, color: context.brandAccent),
              const SizedBox(width: 8),
              Text(
                'Furniture & Tools Details',
                style: AppTypography.cardTitle.copyWith(fontSize: 14, color: context.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _brandController,
                  decoration: InputDecoration(
                    labelText: 'Brand / Maker',
                    hintText: 'e.g. Herman Miller',
                    filled: true,
                    fillColor: context.surfaceCard,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    labelText: 'Model / Type',
                    hintText: 'e.g. Aeron Chair',
                    filled: true,
                    fillColor: context.surfaceCard,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location / Room',
                    hintText: 'e.g. Home Office / Workshop',
                    filled: true,
                    fillColor: context.surfaceCard,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildConditionDropdown(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _serialController,
            decoration: InputDecoration(
              labelText: 'Serial / Part No. (optional)',
              hintText: 'e.g. SN-8821',
              filled: true,
              fillColor: context.surfaceCard,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyTemplateFields(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outlined, size: 18, color: context.brandAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Family Member Details',
                  style: AppTypography.cardTitle.copyWith(fontSize: 14, color: context.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: const Key('family_relationship_dropdown'),
                  isExpanded: true,
                  initialValue: _familyRelationship,
                  decoration: InputDecoration(
                    labelText: 'Relationship',
                    filled: true,
                    fillColor: context.surfaceCard,
                  ),
                  items: _familyRelationships
                      .map(
                        (rel) => DropdownMenuItem(
                          value: rel,
                          child: Text(rel, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _familyRelationship = val);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: const Key('family_blood_type_dropdown'),
                  isExpanded: true,
                  initialValue: _familyBloodType,
                  decoration: InputDecoration(
                    labelText: 'Blood Type',
                    filled: true,
                    fillColor: context.surfaceCard,
                  ),
                  items: _bloodTypes
                      .map(
                        (bt) => DropdownMenuItem(
                          value: bt,
                          child: Text(bt, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _familyBloodType = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            key: const Key('family_birthdate_picker'),
            onTap: _pickFamilyBirthdate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: context.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(Icons.cake_outlined, size: 18, color: context.brandAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _familyBirthdate == null
                          ? 'Birthdate (optional)'
                          : 'Birthdate: ${_formatDate(_familyBirthdate!)}',
                      style: AppTypography.bodyPrimary.copyWith(
                        color: _familyBirthdate == null
                            ? context.textSecondary
                            : context.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_familyBirthdate != null)
                    GestureDetector(
                      onTap: () => setState(() => _familyBirthdate = null),
                      child: Icon(Icons.close, size: 16, color: context.textSecondary),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: const Key('family_phone_field'),
            controller: _familyPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Contact / Emergency Phone',
              hintText: 'e.g. +63 917 123 4567',
              filled: true,
              fillColor: context.surfaceCard,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: const Key('family_id_number_field'),
            controller: _familyIdNumberController,
            decoration: InputDecoration(
              labelText: 'ID / Insurance / PhilHealth No.',
              hintText: 'e.g. 12-345678901-2',
              filled: true,
              fillColor: context.surfaceCard,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: const Key('family_medical_notes_field'),
            controller: _familyMedicalNotesController,
            decoration: InputDecoration(
              labelText: 'Medical Notes & Allergies',
              hintText: 'e.g. Penicillin allergy, primary doctor...',
              filled: true,
              fillColor: context.surfaceCard,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildConditionDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _condition,
      decoration: const InputDecoration(labelText: 'Condition'),
      items: const [
        DropdownMenuItem(value: 'Mint', child: Text('Mint', overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'Good', child: Text('Good', overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'Fair', child: Text('Fair', overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(
          value: 'Needs Repair',
          child: Text('Needs Repair', overflow: TextOverflow.ellipsis),
        ),
      ],
      onChanged: (val) {
        if (val != null) setState(() => _condition = val);
      },
    );
  }

  Widget _buildAcquisitionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 95,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                isDense: true,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                items: _currencies
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCurrency = val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Purchase Amount ($_selectedCurrency)',
                  hintText: 'e.g. 45000',
                ),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null || parsed < 0) {
                      return 'Enter a valid non-negative amount';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildCollapsibleWarrantyAndNotes(context),
      ],
    );
  }

  Widget _buildCollapsibleWarrantyAndNotes(BuildContext context) {
    final hasData = _purchaseDate != null ||
        _warrantyExpiryDate != null ||
        _descriptionController.text.trim().isNotEmpty;
    final isExpanded = _isWarrantyAndNotesExpanded || hasData;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _isWarrantyAndNotesExpanded = !isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 16, color: context.brandAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Warranty, Dates & Notes',
                      style: AppTypography.cardTitle.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasData) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: context.brandAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: context.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            side: BorderSide(color: context.borderSubtle),
                          ),
                          onPressed: _pickPurchaseDate,
                          icon: const Icon(Icons.calendar_today_outlined, size: 14),
                          label: Text(
                            _purchaseDate == null
                                ? 'Purchase Date'
                                : 'Pur: ${_formatDate(_purchaseDate!)}',
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (_purchaseDate != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.clear, size: 16),
                          tooltip: 'Clear Purchase Date',
                          onPressed: () => setState(() => _purchaseDate = null),
                        ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            side: BorderSide(color: context.borderSubtle),
                          ),
                          onPressed: _pickWarrantyExpiryDate,
                          icon: const Icon(Icons.verified_user_outlined, size: 14),
                          label: Text(
                            _warrantyExpiryDate == null
                                ? 'Warranty Expiry'
                                : 'War: ${_formatDate(_warrantyExpiryDate!)}',
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (_warrantyExpiryDate != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.clear, size: 16),
                          tooltip: 'Clear Warranty Expiry Date',
                          onPressed: () => setState(() => _warrantyExpiryDate = null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Description',
                      hintText: 'Archival details, warranty terms, condition notes',
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomFieldsSection(BuildContext context) {
    final isExpanded = _isCustomFieldsExpanded || _customFields.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.tune_outlined, size: 16, color: context.brandAccent),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Custom Fields (${_customFields.length})',
                          style: AppTypography.cardTitle.copyWith(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () {
                    setState(() {
                      _isCustomFieldsExpanded = true;
                      _addCustomField();
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Add Custom Field', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          if (isExpanded && _customFields.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  for (int i = 0; i < _customFields.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _customFields[i].keyController,
                            decoration: const InputDecoration(
                              labelText: 'Field Label',
                              hintText: 'e.g. Color',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _customFields[i].valueController,
                            decoration: const InputDecoration(
                              labelText: 'Field Value',
                              hintText: 'e.g. Walnut',
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          tooltip: 'Remove Custom Field',
                          onPressed: () => _removeCustomField(i),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class AssetDetailSheet extends ConsumerWidget {
  final RecordWithAsset item;

  const AssetDetailSheet({super.key, required this.item});

  String _formatPmsTargetSummary(int? odoTarget, DateTime? dueDate) {
    final parts = <String>[];
    if (odoTarget != null) parts.add('$odoTarget km');
    if (dueDate != null) {
      final monthStr = dueDate.month.toString().padLeft(2, '0');
      final dayStr = dueDate.day.toString().padLeft(2, '0');
      parts.add('Due ${dueDate.year}-$monthStr-$dayStr');
    }
    return parts.join(' • ');
  }

  String _formatDate(DateTime d) {
    final monthStr = d.month.toString().padLeft(2, '0');
    final dayStr = d.day.toString().padLeft(2, '0');
    return '${d.year}-$monthStr-$dayStr';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = item.record;
    final asset = item.asset;
    final totalExpensesAsync = ref.watch(assetTotalExpensesProvider(record.id));
    final assetExpensesAsync = ref.watch(assetExpensesStreamProvider(record.id));
    final hasExpenseError = totalExpensesAsync.hasError;
    final maintenanceCostsMinor = totalExpensesAsync.value ?? 0;
    final hasLinkedExpenses = assetExpensesAsync.asData?.value.isNotEmpty ?? false;
    final currency = asset?.purchaseCurrency ?? 'PHP';
    final hasPurchasePrice = asset?.purchaseAmountMinor != null;
    final purchasePriceMinor = asset?.purchaseAmountMinor ?? 0;
    final totalOwnershipCostMinor = purchasePriceMinor + maintenanceCostsMinor;
    final theme = Theme.of(context);
    final sheetBg = theme.bottomSheetTheme.backgroundColor ?? theme.cardColor;

    final categoriesAsync = ref.watch(defaultCategoriesStreamProvider);
    final categoryName = categoriesAsync.when(
      data: (cats) {
        if (record.categoryId == null) return null;
        final match = cats.where((c) => c.id == record.categoryId);
        return match.isNotEmpty ? match.first.name : null;
      },
      loading: () => null,
      error: (_, _) => null,
    );

    final customFieldsAsync = ref.watch(recordCustomFieldsProvider(record.id));
    final customFields = customFieldsAsync.value ?? item.customFields;

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
                      _buildDetailRow('Record Type', record.recordType.toUpperCase()),
                      if (categoryName != null) ...[
                        const Divider(),
                        _buildDetailRow('Category', categoryName),
                      ],
                      if (asset?.brand != null) ...[
                        const Divider(),
                        _buildDetailRow('Brand / Maker', asset!.brand!),
                      ],
                      if (asset?.model != null) ...[
                        const Divider(),
                        _buildDetailRow('Model / Type', asset!.model!),
                      ],
                      if (asset?.serialNumber != null) ...[
                        const Divider(),
                        _buildDetailRow('Serial Number', asset!.serialNumber!),
                      ],
                      if (asset?.condition != null) ...[
                        const Divider(),
                        _buildDetailRow('Condition', asset!.condition!),
                      ],
                      if (asset?.locationDescription != null) ...[
                        const Divider(),
                        _buildDetailRow('Location', asset!.locationDescription!),
                      ],
                      if (asset?.odometerReading != null) ...[
                        const Divider(),
                        _buildDetailRow('Latest Odometer', '${asset!.odometerReading} km'),
                      ],
                      if (asset?.pmsDistanceIntervalKm != null || asset?.pmsTimeIntervalMonths != null) ...[
                        const Divider(),
                        _buildDetailRow(
                          'PMS Interval Limits',
                          'Every ${asset?.pmsDistanceIntervalKm ?? 5000} km or ${asset?.pmsTimeIntervalMonths ?? 6} mos',
                        ),
                      ],
                      if (asset?.nextPmsOdometerTarget != null || asset?.nextPmsDueDate != null) ...[
                        const Divider(),
                        _buildDetailRow(
                          'Next Target PMS',
                          _formatPmsTargetSummary(asset?.nextPmsOdometerTarget, asset?.nextPmsDueDate),
                        ),
                      ],
                      if (asset?.purchaseDate != null) ...[
                        const Divider(),
                        _buildDetailRow('Purchase Date', _formatDate(asset!.purchaseDate!)),
                      ],
                      if (asset?.warrantyExpiryDate != null) ...[
                        const Divider(),
                        _buildWarrantyExpiryRow(context, asset!.warrantyExpiryDate!),
                      ],
                      if (asset?.purchaseAmountMinor != null) ...[
                        const Divider(),
                        _buildDetailRow(
                          'Estimated Value',
                          '$currency ${(asset!.purchaseAmountMinor! / 100).toStringAsFixed(2)}',
                        ),
                      ],
                      if (hasExpenseError) ...[
                        const Divider(),
                        _buildDetailRow(
                          'Maintenance Costs',
                          'Failed to load',
                        ),
                      ] else if (maintenanceCostsMinor > 0) ...[
                        const Divider(),
                        _buildDetailRow(
                          'Maintenance Costs',
                          '$currency ${(maintenanceCostsMinor / 100).toStringAsFixed(2)}',
                        ),
                        if (hasPurchasePrice) ...[
                          const Divider(),
                          _buildDetailRow(
                            'Total Ownership Cost',
                            '$currency ${(totalOwnershipCostMinor / 100).toStringAsFixed(2)}',
                          ),
                        ],
                      ],
                      if (record.description != null &&
                          record.description!.trim().isNotEmpty &&
                          !customFields.any(
                            (cf) =>
                                cf.definition.label == 'Medical Notes & Allergies' &&
                                cf.value.valueText.trim() == record.description!.trim(),
                          )) ...[
                        const Divider(),
                        _buildDetailRow('Notes / Description', record.description!),
                      ],
                      if (customFields.isNotEmpty) ...[
                        for (final cf in customFields) ...[
                          const Divider(),
                          _buildDetailRow(cf.definition.label, cf.value.valueText),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              if (asset?.odometerReading != null ||
                  asset?.pmsDistanceIntervalKm != null ||
                  maintenanceCostsMinor > 0 ||
                  hasLinkedExpenses) ...[
                const SizedBox(height: 16),
                _AssetServiceHistorySection(assetRecordId: record.id, currency: currency),
              ],
              const SizedBox(height: 16),
              _AssetLinkedDocumentsSection(assetRecordId: record.id, assetTitle: record.title),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          isDismissible: false,
                          enableDrag: false,
                          builder: (_) => AddExpenseSheet(
                            initialAssetRecordId: record.id,
                            prioritizeAssetLink: true,
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: const Text('Log Maintenance / Expense'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Attach Vault Document',
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        isDismissible: false,
                        enableDrag: false,
                        builder: (_) => AddDocumentSheet(initialAssetRecordId: record.id),
                      );
                    },
                    icon: const Icon(Icons.note_add_outlined, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusDangerText,
                  side: const BorderSide(color: AppColors.statusDangerStroke),
                ),
                onPressed: () => _confirmSoftDelete(context, ref, record.id, record.title),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Move to Trash'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarrantyExpiryRow(BuildContext context, DateTime expiryDate) {
    final dateStr = _formatDate(expiryDate);
    final isExpired = expiryDate.isBefore(DateTime.now());
    final badgeColor = isExpired ? AppColors.statusDangerStroke : AppColors.brandPrimary;
    final badgeText = isExpired ? 'Expired' : 'Active';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Warranty Expiry', style: AppTypography.bodySecondary),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dateStr,
                style: AppTypography.bodyPrimary.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isExpired ? AppColors.statusDangerFill : context.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isExpired ? AppColors.statusDangerText : context.brandAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
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

  void _confirmSoftDelete(BuildContext context, WidgetRef ref, String recordId, String title) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).dialogTheme.backgroundColor ?? Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.sheetRadius),
          side: BorderSide(color: Theme.of(ctx).colorScheme.outline),
        ),
        title: const Text('Move to Trash?', style: AppTypography.cardTitle),
        content: Text(
          'Are you sure you want to remove "$title"? You can restore it later from your settings archive.',
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
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Close detail sheet

              try {
                final repo = ref.read(recordRepositoryProvider);
                await repo.softDeleteRecord(recordId);

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Moved "$title" to trash'),
                    backgroundColor: AppColors.brandPrimary,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete record: $e'),
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

class _AssetServiceHistorySection extends ConsumerWidget {
  final String assetRecordId;
  final String currency;

  const _AssetServiceHistorySection({
    required this.assetRecordId,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(assetExpensesStreamProvider(assetRecordId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.history_toggle_off_outlined, size: 18, color: context.brandAccent),
                const SizedBox(width: 6),
                Text(
                  'Service & Maintenance History',
                  style: AppTypography.cardTitle.copyWith(fontSize: 16),
                ),
              ],
            ),
            expensesAsync.when(
              data: (list) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderSubtle),
                ),
                child: Text(
                  '${list.length}',
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        expensesAsync.when(
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2, color: context.brandAccent),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(8),
            child: Text('Failed to load service logs: $err', style: AppTypography.caption),
          ),
          data: (expenses) {
            if (expenses.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderSubtle),
                ),
                child: Column(
                  children: [
                    Icon(Icons.car_repair_outlined, size: 28, color: context.textTertiary),
                    const SizedBox(height: 6),
                    Text(
                      'No maintenance logged yet',
                      style: AppTypography.bodySecondary.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Service logs and odometer updates will appear here in chronological timeline.',
                      style: AppTypography.caption.copyWith(color: context.textTertiary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = expenses[index];
                final expense = item.expense;
                final date = expense.transactionDate;
                final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

                int? deltaKm;
                if (expense.odometerReading != null && index + 1 < expenses.length) {
                  final prevOdo = expenses[index + 1].expense.odometerReading;
                  if (prevOdo != null) {
                    final diff = expense.odometerReading! - prevOdo;
                    if (diff > 0) deltaKm = diff;
                  }
                }

                return Card(
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        isDismissible: false,
                        enableDrag: false,
                        builder: (_) => ExpenseDetailSheet(item: item),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: adaptiveSageFill(context),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.build_outlined, size: 18, color: context.brandAccent),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.record.title,
                                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      'Cost: $currency ${(expense.amountMinor / 100).toStringAsFixed(2)}',
                                      style: AppTypography.cardTitle.copyWith(
                                        fontSize: 14,
                                        color: context.brandAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(dateStr, style: AppTypography.caption.copyWith(color: context.textTertiary)),
                                    if (expense.odometerReading != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: context.surfaceContainerLow,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: context.borderSubtle),
                                        ),
                                        child: Text(
                                          '${expense.odometerReading} km',
                                          style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                    if (deltaKm != null) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '+$deltaKm km delta',
                                        style: AppTypography.caption.copyWith(
                                          color: context.brandAccent,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
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
              },
            );
          },
        ),
      ],
    );
  }
}

class _AssetLinkedDocumentsSection extends ConsumerWidget {
  final String assetRecordId;
  final String assetTitle;

  const _AssetLinkedDocumentsSection({
    required this.assetRecordId,
    required this.assetTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(assetDocumentsStreamProvider(assetRecordId));

    return docsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (docs) {
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.folder_shared_outlined, size: 18, color: context.brandAccent),
                    const SizedBox(width: 6),
                    Text(
                      'Vault Documents & Attachments',
                      style: AppTypography.cardTitle.copyWith(fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, size: 20, color: context.brandAccent),
                  tooltip: 'Attach Document',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      isDismissible: false,
                      enableDrag: false,
                      builder: (_) => AddDocumentSheet(initialAssetRecordId: assetRecordId),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = docs[index];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.description_outlined, color: context.brandAccent, size: 20),
                    title: Text(item.record.title, style: AppTypography.cardTitle.copyWith(fontSize: 13)),
                    subtitle: Text(
                      '${item.document.fileName} • ${item.document.formattedFileSize}',
                      style: AppTypography.caption.copyWith(color: context.textTertiary),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        isDismissible: false,
                        enableDrag: false,
                        builder: (_) => DocumentDetailSheet(item: item),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}
