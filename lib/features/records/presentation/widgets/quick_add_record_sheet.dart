import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../categories/data/category_repository_impl.dart';
import '../../../categories/domain/category.dart';
import 'record_section_card.dart';

/// Typed creation intent returned by [QuickAddRecordSheet].
enum QuickAddKind {
  expense,
  bill,
  maintenance,
  asset,
}

/// Action payload selected from [QuickAddRecordSheet].
class QuickAddAction {
  final QuickAddKind kind;
  final String? categoryId;

  const QuickAddAction(this.kind, {this.categoryId});
}

/// Compact Sanctuary quick-picker sheet replacing split creation buttons on Life Records.
class QuickAddRecordSheet extends ConsumerStatefulWidget {
  const QuickAddRecordSheet({super.key});

  @override
  ConsumerState<QuickAddRecordSheet> createState() => _QuickAddRecordSheetState();
}

class _QuickAddRecordSheetState extends ConsumerState<QuickAddRecordSheet> {
  static const Set<String> _featuredCategoryIds = {
    CategoryRepositoryImpl.billsExpensesCategoryId,
    'cat-vehicles',
    'cat-appliances',
  };

  bool _showOtherSections = false;

  void _select(QuickAddAction action) {
    Navigator.of(context).pop(action);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(defaultCategoriesStreamProvider);
    final loadedCategories = categoriesAsync.asData?.value;
    final vehicleCategory =
        loadedCategories?.where((c) => c.id == 'cat-vehicles').firstOrNull;
    final applianceCategory =
        loadedCategories?.where((c) => c.id == 'cat-appliances').firstOrNull;
    final showVehicle = loadedCategories == null || vehicleCategory != null;
    final showAppliance = loadedCategories == null || applianceCategory != null;
    final vehicleTitle =
        vehicleCategory == null || vehicleCategory.name == 'Vehicles' ? 'Vehicle' : vehicleCategory.name;
    final applianceTitle = applianceCategory == null || applianceCategory.name == 'Appliances'
        ? 'Appliance'
        : applianceCategory.name;

    return Container(
      key: const Key('quick_add_record_sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Record',
                    style: AppTypography.sectionTitle.copyWith(color: context.textPrimary),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textSecondary),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _SectionLabel('MONEY & SERVICE'),
              const SizedBox(height: 8),
              _QuickAddTile(
                key: const Key('quick_add_expense'),
                icon: Icons.payments_outlined,
                title: 'Expense',
                subtitle: 'Log a purchase, payment, or transfer',
                onTap: () => _select(const QuickAddAction(QuickAddKind.expense)),
              ),
              const SizedBox(height: 8),
              _QuickAddTile(
                key: const Key('quick_add_bill'),
                icon: Icons.receipt_long_outlined,
                title: 'Bill / Subscription',
                subtitle: 'Track a recurring utility or subscription',
                onTap: () => _select(const QuickAddAction(QuickAddKind.bill)),
              ),
              const SizedBox(height: 8),
              _QuickAddTile(
                key: const Key('quick_add_maintenance'),
                icon: Icons.build_outlined,
                title: 'Maintenance',
                subtitle: 'Service or repair linked to an asset',
                onTap: () => _select(const QuickAddAction(QuickAddKind.maintenance)),
              ),
              const SizedBox(height: 16),
              _SectionLabel('ITEMS & COLLECTIONS'),
              const SizedBox(height: 8),
              if (showVehicle) ...[
                _QuickAddTile(
                  key: const Key('quick_add_vehicle'),
                  icon: Icons.directions_car_outlined,
                  title: vehicleTitle,
                  subtitle: 'Car, motorcycle, PMS & odometer',
                  onTap: () => _select(
                    const QuickAddAction(QuickAddKind.asset, categoryId: 'cat-vehicles'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (showAppliance) ...[
                _QuickAddTile(
                  key: const Key('quick_add_appliance'),
                  icon: Icons.kitchen_outlined,
                  title: applianceTitle,
                  subtitle: 'Home appliances & warranty tracking',
                  onTap: () => _select(
                    const QuickAddAction(QuickAddKind.asset, categoryId: 'cat-appliances'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              _QuickAddTile(
                key: const Key('quick_add_other_section'),
                icon: Icons.folder_outlined,
                title: 'Other / Custom Section',
                subtitle: 'Family, properties, electronics & custom',
                trailingIcon: _showOtherSections
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                onTap: () => setState(() => _showOtherSections = !_showOtherSections),
              ),
              if (_showOtherSections) ...[
                const SizedBox(height: 8),
                _buildOtherSectionsList(context, categoriesAsync),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherSectionsList(
    BuildContext context,
    AsyncValue<List<Category>> categoriesAsync,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      child: categoriesAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator(color: context.brandAccent)),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'Failed to load sections: $err',
            style: AppTypography.bodySecondary.copyWith(color: AppColors.statusDangerStroke),
          ),
        ),
        data: (categories) {
          final others = categories
              .where((cat) => !_featuredCategoryIds.contains(cat.id))
              .toList();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < others.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 14, endIndent: 14, color: context.borderSubtle),
                _SubSectionRow(
                  key: Key('quick_add_section_${others[i].id}'),
                  icon: categoryIconFromKey(others[i].iconKey),
                  label: others[i].name,
                  onTap: () => _select(
                    QuickAddAction(QuickAddKind.asset, categoryId: others[i].id),
                  ),
                ),
              ],
              if (others.isNotEmpty)
                Divider(height: 1, indent: 14, endIndent: 14, color: context.borderSubtle),
              _SubSectionRow(
                key: const Key('quick_add_section_general'),
                icon: Icons.inventory_2_outlined,
                label: 'General / Uncategorized',
                onTap: () => _select(const QuickAddAction(QuickAddKind.asset)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        fontWeight: FontWeight.w700,
        color: context.textTertiary,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _QuickAddTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final IconData trailingIcon;
  final VoidCallback onTap;

  const _QuickAddTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingIcon = Icons.chevron_right_rounded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.surfaceCard,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: context.borderSubtle),
                ),
                child: Icon(icon, size: 18, color: context.brandAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 15,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(trailingIcon, size: 20, color: context.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubSectionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SubSectionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 46),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: context.brandAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyPrimary.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: context.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
