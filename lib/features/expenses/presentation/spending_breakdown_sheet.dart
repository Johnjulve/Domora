import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../bills/domain/bill_item.dart';
import '../../categories/domain/category.dart';
import '../../records/domain/record.dart';
import '../../records/presentation/widgets/record_section_card.dart';
import '../domain/expense_item.dart';
import '../domain/spending_breakdown.dart';

/// Curated Sanctuary-harmonized palette for donut slices and category legend dots.
const List<Color> _lightChartPalette = [
  Color(0xFF1E4B38), // Forest green (brand primary)
  Color(0xFF2E7D5B), // Sage emerald
  Color(0xFFB45309), // Warm amber
  Color(0xFF2563EB), // Slate blue
  Color(0xFF7C3AED), // Muted violet
  Color(0xFFBE185D), // Deep rose
];

const List<Color> _darkChartPalette = [
  Color(0xFF86CCA4), // Soft mint (dark brand secondary)
  Color(0xFF4ADE80), // Bright sage
  Color(0xFFF59E0B), // Warm gold
  Color(0xFF60A5FA), // Sky blue
  Color(0xFFA78BFA), // Soft lavender
  Color(0xFFF472B6), // Warm rose
];

String _formatSharePercent(double sharePercent) {
  if (sharePercent > 0 && sharePercent < 1.0) return '<1%';
  return '${sharePercent.round()}%';
}

/// Modal bottom sheet displaying a proportional donut spending chart and
/// expandable category -> sub-category totals.
class SpendingBreakdownSheet extends ConsumerStatefulWidget {
  final SpendingTimeRange initialRange;

  const SpendingBreakdownSheet({
    super.key,
    this.initialRange = SpendingTimeRange.thisMonth,
  });

  @override
  ConsumerState<SpendingBreakdownSheet> createState() => _SpendingBreakdownSheetState();
}

class _SpendingBreakdownSheetState extends ConsumerState<SpendingBreakdownSheet> {
  late SpendingTimeRange _selectedRange;
  final Set<String> _expandedCategoryIds = <String>{};
  bool _hasAutoExpandedTop = false;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.initialRange;
  }

  Color _paletteColor(BuildContext context, int index) {
    final palette = context.isDarkMode ? _darkChartPalette : _lightChartPalette;
    return palette[index % palette.length];
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (!_expandedCategoryIds.remove(categoryId)) {
        _expandedCategoryIds.add(categoryId);
      }
    });
  }

  void _selectRange(SpendingTimeRange range) {
    if (_selectedRange == range) return;
    setState(() {
      _selectedRange = range;
      _hasAutoExpandedTop = false;
      _expandedCategoryIds.clear();
    });
  }

  void _retryStreams() {
    ref.invalidate(dashboardExpensesStreamProvider);
    ref.invalidate(activeAssetsStreamProvider);
    ref.invalidate(defaultCategoriesStreamProvider);
    ref.invalidate(billsExpensesSubCategoriesStreamProvider);
    ref.invalidate(dashboardBillsStreamProvider);
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(dashboardExpensesStreamProvider);
    final assetsAsync = ref.watch(activeAssetsStreamProvider);
    final categoriesAsync = ref.watch(defaultCategoriesStreamProvider);
    final subCategoriesAsync = ref.watch(billsExpensesSubCategoriesStreamProvider);
    final billsAsync = ref.watch(dashboardBillsStreamProvider);

    final sheetBg = Theme.of(context).bottomSheetTheme.backgroundColor ?? context.surfaceCard;
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        key: const Key('spending_breakdown_sheet'),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 12),
                _buildTimeRangeRow(context),
                const SizedBox(height: 16),
                Flexible(
                  child: _buildBody(
                    context: context,
                    expensesAsync: expensesAsync,
                    assetsAsync: assetsAsync,
                    categoriesAsync: categoriesAsync,
                    subCategoriesAsync: subCategoriesAsync,
                    billsAsync: billsAsync,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Spending Breakdown',
            style: AppTypography.sectionTitle.copyWith(color: context.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: context.textSecondary),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildTimeRangeRow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < SpendingTimeRange.values.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _buildRangePill(
              context: context,
              range: SpendingTimeRange.values[i],
              isSelected: _selectedRange == SpendingTimeRange.values[i],
              colorScheme: colorScheme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRangePill({
    required BuildContext context,
    required SpendingTimeRange range,
    required bool isSelected,
    required ColorScheme colorScheme,
  }) {
    return Material(
      color: isSelected ? colorScheme.primary : context.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : context.borderSubtle,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('spending_range_${range.name}'),
        onTap: () => _selectRange(range),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            range.label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? colorScheme.onPrimary : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required AsyncValue<List<RecordWithExpense>> expensesAsync,
    required AsyncValue<List<RecordWithAsset>> assetsAsync,
    required AsyncValue<List<Category>> categoriesAsync,
    required AsyncValue<List<Category>> subCategoriesAsync,
    required AsyncValue<List<RecordWithBill>> billsAsync,
  }) {
    final firstError = expensesAsync.error ??
        assetsAsync.error ??
        categoriesAsync.error ??
        subCategoriesAsync.error ??
        billsAsync.error;
    if (firstError != null) {
      return _buildErrorState(context, firstError);
    }

    final isLoading = (expensesAsync.isLoading && !expensesAsync.hasValue) ||
        (assetsAsync.isLoading && !assetsAsync.hasValue) ||
        (categoriesAsync.isLoading && !categoriesAsync.hasValue) ||
        (subCategoriesAsync.isLoading && !subCategoriesAsync.hasValue) ||
        (billsAsync.isLoading && !billsAsync.hasValue);
    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(color: context.brandAccent),
        ),
      );
    }

    final allExpenses = expensesAsync.value ?? const <RecordWithExpense>[];
    final breakdown = SpendingBreakdown.compute(
      expenses: allExpenses,
      activeAssets: assetsAsync.value ?? const <RecordWithAsset>[],
      topLevelCategories: categoriesAsync.value ?? const <Category>[],
      billsExpensesSubCategories: subCategoriesAsync.value ?? const <Category>[],
      bills: billsAsync.value ?? const <RecordWithBill>[],
      range: _selectedRange,
    );

    if (!_hasAutoExpandedTop && breakdown.categories.isNotEmpty) {
      _hasAutoExpandedTop = true;
      _expandedCategoryIds.add(breakdown.categories.first.id);
    }

    final segments = [
      for (var i = 0; i < breakdown.categories.length; i++)
        _DonutSegment(
          value: breakdown.categories[i].totalMinor.toDouble(),
          color: _paletteColor(context, i),
        ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: _SpendingDonutChart(
              segments: segments,
              totalLabel: CurrencyFormatter.formatMinor(
                breakdown.totalMinor,
                currencyCode: breakdown.currencyCode,
              ),
              countLabel:
                  '${breakdown.expenseCount} ${breakdown.expenseCount == 1 ? 'expense' : 'expenses'}',
              emptyRingColor: context.borderSubtle,
            ),
          ),
          if (breakdown.hasMixedCurrencies) ...[
            const SizedBox(height: 14),
            _buildMixedCurrencyNotice(context, breakdown.currencies),
          ],
          const SizedBox(height: 20),
          if (breakdown.categories.isEmpty)
            _buildEmptyState(context, hasExpensesInOtherRanges: allExpenses.isNotEmpty)
          else
            for (var i = 0; i < breakdown.categories.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _SpendingCategoryCard(
                category: breakdown.categories[i],
                currencyCode: breakdown.currencyCode,
                accentColor: _paletteColor(context, i),
                isExpanded: _expandedCategoryIds.contains(breakdown.categories[i].id),
                onToggle: () => _toggleCategory(breakdown.categories[i].id),
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildMixedCurrencyNotice(BuildContext context, List<String> currencies) {
    final textColor =
        context.isDarkMode ? AppColors.statusWarningStroke : AppColors.statusWarningText;
    return Container(
      key: const Key('spending_mixed_currency_notice'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? AppColors.statusWarningStroke.withValues(alpha: 0.18)
            : AppColors.statusWarningFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusWarningStroke.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mixed currencies (${currencies.join(', ')}) are summed at face value without FX conversion.',
              style: AppTypography.caption.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Container(
      key: const Key('spending_breakdown_error'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? AppColors.statusDangerStroke.withValues(alpha: 0.18)
            : AppColors.statusDangerFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.statusDangerStroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Failed to load spending breakdown: $error',
            style: AppTypography.bodySecondary.copyWith(
              color: context.isDarkMode
                  ? AppColors.statusDangerStroke
                  : AppColors.statusDangerText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _retryStreams,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required bool hasExpensesInOtherRanges,
  }) {
    return Container(
      key: const Key('spending_breakdown_empty'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(Icons.pie_chart_outline_rounded, size: 32, color: context.textTertiary),
          const SizedBox(height: 8),
          Text(
            'No expenses recorded for ${_selectedRange.label.toLowerCase()}.',
            style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (hasExpensesInOtherRanges && _selectedRange != SpendingTimeRange.allTime) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              key: const Key('spending_view_all_time_button'),
              onPressed: () => _selectRange(SpendingTimeRange.allTime),
              child: const Text('View All Time'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DonutSegment {
  final double value;
  final Color color;

  const _DonutSegment({required this.value, required this.color});
}

class _SpendingDonutChart extends StatelessWidget {
  final List<_DonutSegment> segments;
  final String totalLabel;
  final String countLabel;
  final Color emptyRingColor;

  const _SpendingDonutChart({
    required this.segments,
    required this.totalLabel,
    required this.countLabel,
    required this.emptyRingColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('spending_donut_chart'),
      width: 192,
      height: 192,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(192, 192),
            painter: _DonutRingPainter(
              segments: segments,
              emptyRingColor: emptyRingColor,
            ),
          ),
          SizedBox(
            width: 126,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Spent',
                  style: AppTypography.caption.copyWith(color: context.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    totalLabel,
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  countLabel,
                  style: AppTypography.caption.copyWith(color: context.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutRingPainter extends CustomPainter {
  final List<_DonutSegment> segments;
  final Color emptyRingColor;

  const _DonutRingPainter({
    required this.segments,
    required this.emptyRingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 22.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final positiveSegments = segments.where((s) => s.value > 0).toList();
    final total = positiveSegments.fold<double>(0.0, (sum, s) => sum + s.value);

    if (positiveSegments.isEmpty || total <= 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = emptyRingColor;
      canvas.drawArc(rect, 0, math.pi * 2, false, paint);
      return;
    }

    final gap = positiveSegments.length > 1 ? 0.03 : 0.0;
    var startAngle = -math.pi / 2;

    for (final segment in positiveSegments) {
      final rawSweep = (segment.value / total) * math.pi * 2;
      final effectiveGap = math.min(gap, rawSweep * 0.25);
      final sweep = rawSweep - effectiveGap;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = segment.color;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += rawSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutRingPainter oldDelegate) {
    if (oldDelegate.emptyRingColor != emptyRingColor) return true;
    if (oldDelegate.segments.length != segments.length) return true;
    for (var i = 0; i < segments.length; i++) {
      if (oldDelegate.segments[i].value != segments[i].value ||
          oldDelegate.segments[i].color != segments[i].color) {
        return true;
      }
    }
    return false;
  }
}

class _SpendingCategoryCard extends StatelessWidget {
  final SpendingCategorySummary category;
  final String currencyCode;
  final Color accentColor;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _SpendingCategoryCard({
    required this.category,
    required this.currencyCode,
    required this.accentColor,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('spending_category_${category.id}'),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('spending_category_toggle_${category.id}'),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      categoryIconFromKey(category.iconKey),
                      size: 18,
                      color: context.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 14,
                              color: context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatSharePercent(category.sharePercent)} • ${category.expenseCount} ${category.expenseCount == 1 ? 'item' : 'items'}',
                            style: AppTypography.caption.copyWith(color: context.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 0,
                      child: Text(
                        CurrencyFormatter.formatMinor(
                          category.totalMinor,
                          currencyCode: currencyCode,
                        ),
                        style: AppTypography.cardTitle.copyWith(
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: context.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded && category.subCategories.isNotEmpty) ...[
            Divider(height: 1, color: context.borderSubtle),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                children: [
                  for (var i = 0; i < category.subCategories.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _SubCategoryRow(
                      subCategory: category.subCategories[i],
                      currencyCode: currencyCode,
                      barColor: accentColor,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubCategoryRow extends StatelessWidget {
  final SpendingSubCategorySummary subCategory;
  final String currencyCode;
  final Color barColor;

  const _SubCategoryRow({
    required this.subCategory,
    required this.currencyCode,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final fillFactor = (subCategory.sharePercent / 100.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                subCategory.name,
                style: AppTypography.bodySecondary.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${subCategory.expenseCount}x',
              style: AppTypography.caption.copyWith(color: context.textTertiary),
            ),
            const SizedBox(width: 8),
            Text(
              CurrencyFormatter.formatMinor(
                subCategory.totalMinor,
                currencyCode: currencyCode,
              ),
              style: AppTypography.bodySecondary.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 5,
          decoration: BoxDecoration(
            color: context.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fillFactor,
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
