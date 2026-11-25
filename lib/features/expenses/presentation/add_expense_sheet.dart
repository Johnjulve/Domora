import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../categories/domain/category.dart';
import '../../records/domain/record.dart';
import '../../records/presentation/widgets/asset_picker_sheet.dart';
import '../../tasks/domain/task_item.dart';
import '../domain/expense_item.dart';

class _ExpenseCategoryOption {
  final String value;
  final String label;
  final String? subCategoryId;

  const _ExpenseCategoryOption({
    required this.value,
    required this.label,
    this.subCategoryId,
  });
}

class AddExpenseSheet extends ConsumerStatefulWidget {
  final String? initialAssetRecordId;
  final String? initialTaskRecordId;
  final String? initialExpenseCategory;
  final bool prioritizeAssetLink;

  const AddExpenseSheet({
    super.key,
    this.initialAssetRecordId,
    this.initialTaskRecordId,
    this.initialExpenseCategory,
    this.prioritizeAssetLink = false,
  });

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _odometerController = TextEditingController();

  late String _expenseCategory;
  late DateTime _transactionDate;
  String? _paymentMethod = 'card';
  String? _selectedAssetRecordId;
  bool _isMoreDetailsExpanded = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _expenseCategory = widget.initialExpenseCategory ?? ExpenseCategory.maintenance.value;
    _transactionDate = DateTime.now();
    _selectedAssetRecordId = widget.initialAssetRecordId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  bool get _shouldShowAssetProminently =>
      widget.prioritizeAssetLink ||
      widget.initialAssetRecordId != null ||
      _expenseCategory == ExpenseCategory.maintenance.value;

  String? _matchBuiltInExpenseSubCategoryId(ExpenseCategory cat, List<Category> subCategories) {
    final valueLower = cat.value.toLowerCase();
    final labelLower = cat.label.toLowerCase();
    for (final sub in subCategories) {
      final subLower = sub.name.trim().toLowerCase();
      if (subLower == valueLower || subLower == labelLower) {
        return sub.id;
      }
    }
    switch (cat) {
      case ExpenseCategory.maintenance:
        return subCategories.where((s) => s.id == 'cat-sub-maintenance').firstOrNull?.id;
      case ExpenseCategory.subscription:
        return subCategories.where((s) => s.id == 'cat-sub-subscription').firstOrNull?.id;
      case ExpenseCategory.other:
        return subCategories.where((s) => s.id == 'cat-sub-general-expense').firstOrNull?.id;
      default:
        return null;
    }
  }

  List<_ExpenseCategoryOption> _buildCategoryOptions(List<Category> subCategories) {
    final options = <_ExpenseCategoryOption>[
      for (final cat in ExpenseCategory.values)
        _ExpenseCategoryOption(
          value: cat.value,
          label: cat.label,
          subCategoryId: _matchBuiltInExpenseSubCategoryId(cat, subCategories),
        ),
    ];

    final seenNormalized = <String>{
      for (final opt in options) opt.value.toLowerCase(),
      for (final opt in options) opt.label.toLowerCase(),
    };

    for (final sub in subCategories) {
      final normalized = sub.name.trim().toLowerCase();
      if (normalized.isEmpty || seenNormalized.contains(normalized)) continue;
      if (sub.id == 'cat-sub-general-expense' && normalized == 'general expense') continue;
      seenNormalized.add(normalized);
      options.add(
        _ExpenseCategoryOption(
          value: sub.name.trim(),
          label: sub.name.trim(),
          subCategoryId: sub.id,
        ),
      );
    }

    if (!options.any((opt) => opt.value == _expenseCategory)) {
      options.add(
        _ExpenseCategoryOption(value: _expenseCategory, label: _expenseCategory),
      );
    }
    return options;
  }

  bool _isVehicleAsset(RecordWithAsset? asset) {
    if (asset == null) return false;
    return asset.record.categoryId == 'cat-vehicles' ||
        asset.asset?.odometerReading != null ||
        asset.asset?.pmsDistanceIntervalKm != null;
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _transactionDate = picked);
    }
  }

  /// Exact calendar month addition avoiding 30-day interval drift.
  DateTime _addCalendarMonths(DateTime from, int months) {
    final targetYear = from.year + (from.month + months - 1) ~/ 12;
    final targetMonth = (from.month + months - 1) % 12 + 1;
    final maxDays = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = from.day > maxDays ? maxDays : from.day;
    return DateTime(targetYear, targetMonth, targetDay, from.hour, from.minute, from.second);
  }

  Future<void> _submit(
    List<RecordWithAsset> activeAssets,
    List<_ExpenseCategoryOption> categoryOptions,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final primaryColor = Theme.of(context).colorScheme.primary;
    final repo = ref.read(expenseRepositoryProvider);
    final recordId = const Uuid().v4();
    final now = DateTime.now().toUtc();
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();

    final parsedAmount = double.parse(_amountController.text.trim());
    final amountMinor = (parsedAmount * 100).round();
    final selectedAsset = _selectedAssetRecordId == null
        ? null
        : activeAssets.where((a) => a.record.id == _selectedAssetRecordId).firstOrNull;
    final parsedOdometer = _isVehicleAsset(selectedAsset)
        ? int.tryParse(_odometerController.text.trim())
        : null;
    final matchedOption = categoryOptions.where((o) => o.value == _expenseCategory).firstOrNull;

    // 1. Persist the primary expense record first
    try {
      await repo.createExpenseRecord(
        record: Record(
          id: recordId,
          workspaceId: AppConstants.defaultWorkspaceId,
          categoryId: matchedOption?.subCategoryId,
          recordType: 'expense',
          title: title,
          description: notes.isNotEmpty ? notes : null,
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: recordId,
          amountMinor: amountMinor,
          currencyCode: AppConstants.defaultCurrency,
          transactionDate: _transactionDate,
          paymentMethod: _paymentMethod,
          expenseCategory: _expenseCategory,
          linkedAssetRecordId: _selectedAssetRecordId,
          linkedTaskRecordId: widget.initialTaskRecordId,
          odometerReading: parsedOdometer,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expense: $e'),
            backgroundColor: AppColors.statusDangerStroke,
          ),
        );
      }
      return;
    }

    // 2. Coordinate optional PMS scheduling loop before closing sheet
    bool scheduledPms = false;
    if (mounted &&
        selectedAsset != null &&
        parsedOdometer != null &&
        _expenseCategory == ExpenseCategory.maintenance.value) {
      final intervalKm = selectedAsset.asset?.pmsDistanceIntervalKm ?? 5000;
      final intervalMonths = selectedAsset.asset?.pmsTimeIntervalMonths ?? 6;
      final nextTargetMileage = parsedOdometer + intervalKm;
      final nextTargetDate = _addCalendarMonths(_transactionDate, intervalMonths);
      final nextDateStr =
          '${nextTargetDate.year}-${nextTargetDate.month.toString().padLeft(2, '0')}-${nextTargetDate.day.toString().padLeft(2, '0')}';

      final shouldSchedule = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ctx.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            side: BorderSide(color: ctx.borderSubtle),
          ),
          title: Text(
            'Schedule Next PMS?',
            style: AppTypography.cardTitle.copyWith(color: ctx.textPrimary),
          ),
          content: Text(
            'Maintenance logged at $parsedOdometer km.\n\n'
            'Based on configured limits ($intervalKm km / $intervalMonths months), the next recommended PMS milestone is:\n\n'
            '• Target Odometer: $nextTargetMileage km\n'
            '• Target Due Date: $nextDateStr\n\n'
            'Would you like to auto-create the next PMS reminder task?',
            style: AppTypography.bodyPrimary.copyWith(color: ctx.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Not Now', style: TextStyle(color: ctx.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.primary,
                foregroundColor: Theme.of(ctx).colorScheme.onPrimary,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Schedule Next PMS'),
            ),
          ],
        ),
      );

      if (shouldSchedule == true && mounted) {
        scheduledPms = true;
        try {
          final taskRepo = ref.read(taskRepositoryProvider);
          final recordRepo = ref.read(recordRepositoryProvider);
          final taskId = const Uuid().v4();

          await taskRepo.createTaskRecord(
            record: Record(
              id: taskId,
              workspaceId: AppConstants.defaultWorkspaceId,
              recordType: 'task',
              title: 'Next PMS ($nextTargetMileage km) - ${selectedAsset.record.title}',
              description: 'Auto-scheduled from maintenance log recorded at $parsedOdometer km.',
              createdAt: now,
              updatedAt: now,
            ),
            task: TaskItem(
              recordId: taskId,
              dueDate: nextTargetDate,
              priority: 'medium',
              status: 'pending',
              assetRecordId: selectedAsset.record.id,
            ),
          );

          if (selectedAsset.asset != null) {
            await recordRepo.updateAsset(
              selectedAsset.asset!.copyWith(
                odometerReading: parsedOdometer,
                nextPmsOdometerTarget: nextTargetMileage,
                nextPmsDueDate: nextTargetDate,
              ),
            );
          }
        } catch (_) {
          // Task scheduling failure does not abort already-persisted primary expense
        }
      }
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          scheduledPms
              ? 'Logged expense & scheduled next PMS for ${selectedAsset?.record.title}'
              : 'Logged expense: $title (${AppConstants.defaultCurrency} ${parsedAmount.toStringAsFixed(2)})',
        ),
        backgroundColor: primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(activeAssetsStreamProvider);
    final activeAssets = assetsAsync.value ?? <RecordWithAsset>[];
    final subCategoriesAsync = ref.watch(billsExpensesSubCategoriesStreamProvider);
    final subCategories = subCategoriesAsync.asData?.value ?? const <Category>[];
    final categoryOptions = _buildCategoryOptions(subCategories);

    final selectedAsset = _selectedAssetRecordId == null
        ? null
        : activeAssets.where((a) => a.record.id == _selectedAssetRecordId).firstOrNull;
    final showOdometer =
        _expenseCategory == ExpenseCategory.maintenance.value && _isVehicleAsset(selectedAsset);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomSheetTheme.backgroundColor ?? context.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
        border: Border(
          top: BorderSide(color: context.borderSubtle),
          left: BorderSide(color: context.borderSubtle),
          right: BorderSide(color: context.borderSubtle),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                      widget.prioritizeAssetLink ? 'Log Maintenance' : 'Log Expense',
                      style: AppTypography.sectionTitle.copyWith(color: context.textPrimary),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: context.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Expense Title *',
                    hintText: widget.prioritizeAssetLink
                        ? 'e.g. Engine Oil & Filter Change'
                        : 'e.g. Groceries, Fuel, Deposit',
                    filled: true,
                    fillColor: context.surfaceContainerLow,
                  ),
                  autofocus: true,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('expense_category_dropdown'),
                  isExpanded: true,
                  dropdownColor: context.surfaceCard,
                  initialValue: _expenseCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: context.surfaceContainerLow,
                  ),
                  items: categoryOptions.map((cat) {
                    return DropdownMenuItem(
                      value: cat.value,
                      child: Text(
                        cat.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _expenseCategory = val);
                  },
                ),
                if (subCategoriesAsync.hasError) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Custom categories unavailable: ${subCategoriesAsync.error}',
                    style: AppTypography.caption.copyWith(color: AppColors.statusDangerStroke),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _amountController,
                        style: TextStyle(color: context.textPrimary),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount (${AppConstants.defaultCurrency}) *',
                          hintText: 'e.g. 1250.00',
                          filled: true,
                          fillColor: context.surfaceContainerLow,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Amount is required';
                          }
                          final parsed = double.tryParse(val.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a positive amount';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () => _pickDate(context),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date',
                            filled: true,
                            fillColor: context.surfaceContainerLow,
                          ),
                          child: Text(
                            '${_transactionDate.year}-${_transactionDate.month.toString().padLeft(2, '0')}-${_transactionDate.day.toString().padLeft(2, '0')}',
                            style: AppTypography.bodyPrimary.copyWith(color: context.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_shouldShowAssetProminently)
                  AssetPickerTile(
                    selectedAssetRecordId: _selectedAssetRecordId,
                    noneLabel: 'None (General Expense)',
                    onAssetChanged: (id) => setState(() => _selectedAssetRecordId = id),
                  ),
                if (showOdometer) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: TextFormField(
                      controller: _odometerController,
                      style: TextStyle(color: context.textPrimary),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Odometer at Service (km)',
                        hintText: selectedAsset?.asset?.odometerReading != null
                            ? 'Last recorded: ${selectedAsset!.asset!.odometerReading} km'
                            : 'e.g. 15200',
                        prefixIcon: Icon(Icons.speed, size: 20, color: context.brandAccent),
                        filled: true,
                        fillColor: context.surfaceContainerLow,
                      ),
                    ),
                  ),
                ],
                _buildMoreDetailsDrawer(context),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: _isSubmitting ? null : () => _submit(activeAssets, categoryOptions),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Expense'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreDetailsDrawer(BuildContext context) {
    final hasExtraData = _notesController.text.trim().isNotEmpty ||
        (!_shouldShowAssetProminently && _selectedAssetRecordId != null);

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const Key('expense_more_details_toggle'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _isMoreDetailsExpanded = !_isMoreDetailsExpanded),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 46),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 17, color: context.brandAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment Method & Notes',
                        style: AppTypography.cardTitle.copyWith(
                          fontSize: 13,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    if (hasExtraData) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: context.brandAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      _isMoreDetailsExpanded
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
          if (_isMoreDetailsExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    dropdownColor: context.surfaceCard,
                    initialValue: _paymentMethod,
                    decoration: InputDecoration(
                      labelText: 'Payment Method',
                      filled: true,
                      fillColor: context.surfaceCard,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'card',
                        child: Text('Credit/Debit Card', style: TextStyle(color: context.textPrimary)),
                      ),
                      DropdownMenuItem(
                        value: 'cash',
                        child: Text('Cash', style: TextStyle(color: context.textPrimary)),
                      ),
                      DropdownMenuItem(
                        value: 'bank_transfer',
                        child: Text('Bank Transfer', style: TextStyle(color: context.textPrimary)),
                      ),
                      DropdownMenuItem(
                        value: 'e_wallet',
                        child: Text('E-Wallet', style: TextStyle(color: context.textPrimary)),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text('Other', style: TextStyle(color: context.textPrimary)),
                      ),
                    ],
                    onChanged: (val) => setState(() => _paymentMethod = val),
                  ),
                  const SizedBox(height: 10),
                  if (!_shouldShowAssetProminently)
                    AssetPickerTile(
                      selectedAssetRecordId: _selectedAssetRecordId,
                      noneLabel: 'None (General Expense)',
                      onAssetChanged: (id) => setState(() => _selectedAssetRecordId = id),
                    ),
                  TextFormField(
                    controller: _notesController,
                    style: TextStyle(color: context.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Notes / Description (Optional)',
                      hintText: 'Warranty status, technician details, invoice notes...',
                      filled: true,
                      fillColor: context.surfaceCard,
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
}
