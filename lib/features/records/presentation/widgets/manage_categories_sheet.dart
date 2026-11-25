import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../categories/data/category_repository_impl.dart';
import '../../../categories/domain/category.dart';
import 'record_section_card.dart';

enum _ManageCategoriesTab { sections, billsSubCategories }

/// Sanctuary modal bottom sheet for managing top-level Life Records sections
/// and `Bills & Expenses` sub-categories.
class ManageCategoriesSheet extends ConsumerStatefulWidget {
  const ManageCategoriesSheet({super.key});

  @override
  ConsumerState<ManageCategoriesSheet> createState() => _ManageCategoriesSheetState();
}

class _ManageCategoriesSheetState extends ConsumerState<ManageCategoriesSheet> {
  _ManageCategoriesTab _activeTab = _ManageCategoriesTab.sections;

  bool get _isSubCategoryMode => _activeTab == _ManageCategoriesTab.billsSubCategories;

  Set<String> _activeNormalizedNames({String? excludeId}) {
    final asyncList = _isSubCategoryMode
        ? ref.read(billsExpensesSubCategoriesStreamProvider)
        : ref.read(defaultCategoriesStreamProvider);
    final items = asyncList.asData?.value ?? const <Category>[];
    return {
      for (final cat in items)
        if (cat.id != excludeId) cat.name.trim().toLowerCase(),
    };
  }

  Future<void> _openCreateDialog() async {
    final isSub = _isSubCategoryMode;
    final messenger = ScaffoldMessenger.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final existingNames = _activeNormalizedNames();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _CategoryNameDialog(
        title: isSub ? 'Add Sub-Category' : 'Add Section',
        fieldLabel: isSub ? 'Sub-Category Name *' : 'Section Name *',
        hintText: isSub ? 'e.g. Insurance, Groceries' : 'e.g. Collectibles, Pets',
        confirmLabel: 'Create',
        existingNames: existingNames,
        onSubmit: (trimmedName) async {
          final now = DateTime.now().toUtc();
          final cat = Category(
            id: isSub ? 'cat-sub-${const Uuid().v4()}' : 'cat-${const Uuid().v4()}',
            workspaceId: AppConstants.defaultWorkspaceId,
            name: trimmedName,
            iconKey: isSub ? 'payments' : 'folder_outlined',
            isSystem: false,
            parentCategoryId: isSub ? CategoryRepositoryImpl.billsExpensesCategoryId : null,
            createdAt: now,
          );
          await ref.read(categoryRepositoryProvider).createCategory(cat);
        },
      ),
    );

    if (result != null && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Added "$result"'),
          backgroundColor: primaryColor,
        ),
      );
    }
  }

  Future<void> _openRenameDialog(Category category) async {
    final messenger = ScaffoldMessenger.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final existingNames = _activeNormalizedNames(excludeId: category.id);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _CategoryNameDialog(
        title: category.isSubCategory ? 'Rename Sub-Category' : 'Rename Section',
        fieldLabel: 'Name *',
        hintText: category.name,
        initialValue: category.name,
        confirmLabel: 'Save',
        existingNames: existingNames,
        onSubmit: (trimmedName) async {
          await ref.read(categoryRepositoryProvider).renameCategory(category.id, trimmedName);
        },
      ),
    );

    if (result != null && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Renamed to "$result"'),
          backgroundColor: primaryColor,
        ),
      );
    }
  }

  Future<void> _confirmArchive(Category category) async {
    final messenger = ScaffoldMessenger.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceCard,
        title: Text(
          category.isSubCategory ? 'Archive Sub-Category?' : 'Archive Section?',
          style: AppTypography.cardTitle.copyWith(color: ctx.textPrimary),
        ),
        content: Text(
          'Archive "${category.name}"? Existing records will remain safely preserved.',
          style: AppTypography.bodyPrimary.copyWith(color: ctx.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDangerStroke,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(categoryRepositoryProvider).archiveCategory(category.id);
      if (ref.read(selectedCategoryFilterProvider) == category.id) {
        ref.read(selectedCategoryFilterProvider.notifier).selectCategory(null);
      }
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Archived "${category.name}"'),
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to archive "${category.name}": $e'),
            backgroundColor: AppColors.statusDangerStroke,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = _isSubCategoryMode
        ? ref.watch(billsExpensesSubCategoriesStreamProvider)
        : ref.watch(defaultCategoriesStreamProvider);

    return Container(
      key: const Key('manage_categories_sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manage Categories',
                    style: AppTypography.sectionTitle.copyWith(color: context.textPrimary),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textSecondary),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildSegmentedSwitcher(context),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('manage_add_category_button'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  foregroundColor: context.brandAccent,
                  side: BorderSide(color: context.borderSubtle),
                ),
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.add, size: 18),
                label: Text(_isSubCategoryMode ? 'Add Sub-Category' : 'Add Section'),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: categoriesAsync.when(
                  loading: () => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: context.brandAccent),
                    ),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Failed to load categories: $err',
                      style: AppTypography.bodySecondary.copyWith(
                        color: AppColors.statusDangerStroke,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          _isSubCategoryMode
                              ? 'No active sub-categories yet.'
                              : 'No active sections yet.',
                          style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: context.borderSubtle),
                      itemBuilder: (ctx, index) => _buildCategoryRow(ctx, items[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedSwitcher(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentOption(
              key: const Key('manage_tab_sections'),
              label: 'Sections',
              isSelected: _activeTab == _ManageCategoriesTab.sections,
              onTap: () => setState(() => _activeTab = _ManageCategoriesTab.sections),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _SegmentOption(
              key: const Key('manage_tab_subcategories'),
              label: 'Bills & Expenses',
              isSelected: _activeTab == _ManageCategoriesTab.billsSubCategories,
              onTap: () => setState(() => _activeTab = _ManageCategoriesTab.billsSubCategories),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context, Category category) {
    final isCoreBillsSection = category.id == CategoryRepositoryImpl.billsExpensesCategoryId;

    return Padding(
      key: Key('manage_category_row_${category.id}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.surfaceContainerLow,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              categoryIconFromKey(category.iconKey),
              size: 18,
              color: context.brandAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    category.name,
                    style: AppTypography.bodyPrimary.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCoreBillsSection) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: adaptiveSageFill(context),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'CORE',
                      style: AppTypography.badge.copyWith(color: context.brandAccent),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            key: Key('rename_category_${category.id}'),
            icon: Icon(Icons.edit_outlined, size: 19, color: context.textSecondary),
            tooltip: 'Rename',
            onPressed: () => _openRenameDialog(category),
          ),
          if (isCoreBillsSection)
            Tooltip(
              message: 'Core section cannot be deleted',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.lock_outline, size: 18, color: context.textTertiary),
              ),
            )
          else
            IconButton(
              key: Key('archive_category_${category.id}'),
              icon: const Icon(
                Icons.delete_outline,
                size: 19,
                color: AppColors.statusDangerStroke,
              ),
              tooltip: 'Archive',
              onPressed: () => _confirmArchive(category),
            ),
        ],
      ),
    );
  }
}

class _SegmentOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentOption({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? context.surfaceCard : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: context.borderSubtle) : null,
        ),
        child: Text(
          label,
          style: AppTypography.bodySecondary.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? context.brandAccent : context.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CategoryNameDialog extends StatefulWidget {
  final String title;
  final String fieldLabel;
  final String hintText;
  final String initialValue;
  final String confirmLabel;
  final Set<String> existingNames;
  final Future<void> Function(String trimmedName) onSubmit;

  const _CategoryNameDialog({
    required this.title,
    required this.fieldLabel,
    required this.hintText,
    this.initialValue = '',
    required this.confirmLabel,
    required this.existingNames,
    required this.onSubmit,
  });

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  static const int _maxCategoryNameLength = 100;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Name is required';
    }
    if (trimmed.length > _maxCategoryNameLength) {
      return 'Name must be $_maxCategoryNameLength characters or fewer';
    }
    if (widget.existingNames.contains(trimmed.toLowerCase())) {
      return 'A category with this name already exists';
    }
    return null;
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    final trimmed = _controller.text.trim();

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await widget.onSubmit(trimmed);
      if (mounted) {
        Navigator.of(context).pop(trimmed);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorText = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.surfaceCard,
      title: Text(
        widget.title,
        style: AppTypography.cardTitle.copyWith(color: context.textPrimary),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('category_name_input'),
              controller: _controller,
              autofocus: true,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: widget.fieldLabel,
                hintText: widget.hintText,
              ),
              validator: _validateName,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: AppTypography.caption.copyWith(color: AppColors.statusDangerStroke),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('category_dialog_confirm'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: _isSubmitting ? null : _handleConfirm,
          child: _isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
