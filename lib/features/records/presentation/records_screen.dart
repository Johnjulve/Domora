import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../bills/presentation/add_bill_sheet.dart';
import '../../bills/presentation/bill_detail_sheet.dart';
import '../../categories/domain/category.dart';
import '../../expenses/presentation/add_expense_sheet.dart';
import '../../expenses/presentation/expense_detail_sheet.dart';
import '../../vault/presentation/vault_screen.dart';
import '../domain/record.dart';

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  late final TextEditingController _searchController;

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

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(activeRecordsStreamProvider);
    final categoriesAsync = ref.watch(defaultCategoriesStreamProvider);
    final selectedCategoryId = ref.watch(selectedCategoryFilterProvider);
    final searchQuery = ref.watch(recordSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Records'),
        actions: [
          IconButton(
            icon: Icon(Icons.receipt_long_outlined, color: context.brandAccent),
            tooltip: 'Add Utility Bill',
            onPressed: () => _openAddBillModal(context),
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: context.brandAccent),
            tooltip: 'Add Record',
            onPressed: () => _openAddAssetModal(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
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
          ),

          // Category Filter Chips
          categoriesAsync.when(
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
                          onTap: () => ref.read(selectedCategoryFilterProvider.notifier).selectCategory(cat.id),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Records List
          Expanded(
            child: recordsAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: context.brandAccent),
              ),
              error: (err, stack) => Center(
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
              ),
              data: (records) {
                if (records.isEmpty) {
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
                                decoration: const BoxDecoration(
                                  color: AppColors.brandAccentSage,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.inventory_2_outlined, color: context.brandAccent, size: 36),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                searchQuery.isNotEmpty || selectedCategoryId != null
                                    ? 'No Matching Records'
                                    : 'No Life Records Yet',
                                style: AppTypography.cardTitle,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                searchQuery.isNotEmpty || selectedCategoryId != null
                                    ? 'Try adjusting your search query or selecting a different category.'
                                    : 'Keep your property, vehicle, appliance warranties, and receipts organized in one place.',
                                style: AppTypography.bodySecondary,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              if (searchQuery.isEmpty && selectedCategoryId == null)
                                ElevatedButton.icon(
                                  onPressed: () => _openAddAssetModal(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add First Asset'),
                                )
                              else
                                OutlinedButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(recordSearchQueryProvider.notifier).clear();
                                    ref.read(selectedCategoryFilterProvider.notifier).selectCategory(null);
                                  },
                                  child: const Text('Clear Filters'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, index) {
                    final item = records[index];
                    final asset = item.asset;

                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _openRecordDetailModal(context, item),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.record.title,
                                      style: AppTypography.cardTitle,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandAccentSage,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.record.recordType.toUpperCase(),
                                      style: AppTypography.badge,
                                    ),
                                  ),
                                ],
                              ),
                              if (asset != null) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 2,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (asset.brand != null)
                                      Text(asset.brand!, style: AppTypography.bodySecondary),
                                    if (asset.model != null)
                                      Text('• ${asset.model}', style: AppTypography.bodySecondary),
                                    if (asset.locationDescription != null)
                                      Text('• ${asset.locationDescription}', style: AppTypography.bodySecondary),
                                  ],
                                ),
                                if (asset.purchaseAmountMinor != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Value: ${asset.purchaseCurrency} ${(asset.purchaseAmountMinor! / 100).toStringAsFixed(2)}',
                                    style: AppTypography.bodyPrimary.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: context.brandAccent,
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
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
              color: isSelected ? AppColors.brandPrimary : context.surfaceCard,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? AppColors.brandPrimary : context.borderSubtle,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.brandOnPrimary : context.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
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

  void _openAddAssetModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddAssetSheet(),
    );
  }

  Future<void> _openRecordDetailModal(BuildContext context, RecordWithAsset item) async {
    if (item.record.recordType == 'bill') {
      final billRepo = ref.read(billRepositoryProvider);
      final billItem = await billRepo.getBillById(item.record.id);
      if (billItem != null && context.mounted) {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => BillDetailSheet(item: billItem),
        );
      }
    } else {
      _openAssetDetailModal(context, item);
    }
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
  const AddAssetSheet({super.key});

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
    for (final cf in _customFields) {
      cf.dispose();
    }
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(recordRepositoryProvider);
      final recordId = const Uuid().v4();
      final now = DateTime.now().toUtc();

      final parsedAmount = double.tryParse(_amountController.text.trim());
      final int? amountMinor = parsedAmount != null && parsedAmount >= 0
          ? (parsedAmount * 100).round()
          : null;

      final isVehicle = _selectedCategoryId == 'cat-vehicles';
      final parsedOdometer = isVehicle ? int.tryParse(_odometerController.text.trim()) : null;
      final parsedPmsDistance = isVehicle ? int.tryParse(_pmsDistanceController.text.trim()) : null;

      final initialTargetOdo = (isVehicle && parsedOdometer != null && parsedPmsDistance != null)
          ? parsedOdometer + parsedPmsDistance
          : null;
      final initialDueDate = isVehicle ? _addCalendarMonths(now, _pmsMonths) : null;

      final customFieldMap = <String, String>{};
      if (_isProperty && _deedNumberController.text.trim().isNotEmpty) {
        customFieldMap['Title / Deed Number'] = _deedNumberController.text.trim();
      }
      if (_isVehicle && _licensePlateController.text.trim().isNotEmpty) {
        customFieldMap['License Plate'] = _licensePlateController.text.trim();
      }
      for (final cf in _customFields) {
        final k = cf.keyController.text.trim();
        final v = cf.valueController.text.trim();
        if (k.isNotEmpty && v.isNotEmpty) {
          customFieldMap[k] = v;
        }
      }

      await repo.createAssetRecord(
        record: Record(
          id: recordId,
          workspaceId: AppConstants.defaultWorkspaceId,
          categoryId: _selectedCategoryId,
          recordType: 'asset',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          createdAt: now,
          updatedAt: now,
        ),
        asset: Asset(
          recordId: recordId,
          brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
          model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
          serialNumber: _serialController.text.trim().isEmpty ? null : _serialController.text.trim(),
          condition: _condition,
          purchaseDate: _purchaseDate,
          purchaseAmountMinor: amountMinor,
          purchaseCurrency: _selectedCurrency,
          locationDescription:
              _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
          warrantyExpiryDate: _warrantyExpiryDate,
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

  bool get _isVehicle => _selectedCategoryId == 'cat-vehicles';
  bool get _isProperty => _selectedCategoryId == 'cat-properties';
  bool get _isApplianceOrElectronics =>
      _selectedCategoryId == 'cat-appliances' || _selectedCategoryId == 'cat-electronics';
  bool get _isFurnitureOrTools =>
      _selectedCategoryId == 'cat-furniture' || _selectedCategoryId == 'cat-tools';

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(defaultCategoriesStreamProvider);
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
                    const Text('New Asset Record', style: AppTypography.sectionTitle),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Asset Title *', hintText: 'e.g. Living Room Smart TV'),
                  autofocus: true,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                // Category Selector & "+ Add New Category" action
                categoriesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (categories) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCategoryId,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('General / Uncategorized'),
                              ),
                              ...categories.map(
                                (cat) => DropdownMenuItem<String>(
                                  value: cat.id,
                                  child: Text(cat.name),
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
                _buildTemplateFields(context),
                const SizedBox(height: 8),
                // Common Acquisition & Financial Section
                _buildAcquisitionSection(context),
                const SizedBox(height: 8),
                // User-Defined Custom Fields Section
                _buildCustomFieldsSection(context),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Asset Record'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateFields(BuildContext context) {
    if (_isVehicle) {
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
                Text(
                  'Vehicle PMS Limits & Odometer',
                  style: AppTypography.cardTitle.copyWith(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(labelText: 'Brand / Make', hintText: 'e.g. Toyota'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(labelText: 'Model', hintText: 'e.g. RAV4 Hybrid'),
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
                    decoration: const InputDecoration(labelText: 'VIN / Serial Number', hintText: 'e.g. 4T1B...'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _licensePlateController,
                    decoration: const InputDecoration(labelText: 'License Plate', hintText: 'e.g. ABC-1234'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _odometerController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Starting / Current Odometer (km)',
                hintText: 'e.g. 15000',
                prefixIcon: Icon(Icons.speed, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pmsDistanceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'PMS Distance (km)',
                      hintText: 'e.g. 5000',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _pmsMonths,
                    decoration: const InputDecoration(labelText: 'PMS Time Limit'),
                    items: const [
                      DropdownMenuItem(value: 3, child: Text('Every 3 mos')),
                      DropdownMenuItem(value: 6, child: Text('Every 6 mos')),
                      DropdownMenuItem(value: 12, child: Text('Every 12 mos')),
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
                    decoration: const InputDecoration(
                      labelText: 'Parking / Garage Location',
                      hintText: 'e.g. Main Garage Bay 1',
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

    if (_isProperty) {
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
                  style: AppTypography.cardTitle.copyWith(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Address / Location',
                hintText: 'e.g. 123 Heritage Way',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _deedNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Title / Deed Number',
                      hintText: 'e.g. TCT-987654',
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

    if (_isApplianceOrElectronics) {
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
                  style: AppTypography.cardTitle.copyWith(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location / Room', hintText: 'e.g. Living Room / Kitchen'),
            ),
          ],
        ),
      );
    }

    if (_isFurnitureOrTools) {
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
                  style: AppTypography.cardTitle.copyWith(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(labelText: 'Brand / Maker', hintText: 'e.g. Herman Miller'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(labelText: 'Model / Type', hintText: 'e.g. Aeron Chair'),
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
                    decoration: const InputDecoration(labelText: 'Location / Room', hintText: 'e.g. Home Office / Workshop'),
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
              decoration: const InputDecoration(
                labelText: 'Serial / Part No. (optional)',
                hintText: 'e.g. SN-8821',
              ),
            ),
          ],
        ),
      );
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

  Widget _buildConditionDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _condition,
      decoration: const InputDecoration(labelText: 'Condition'),
      items: const [
        DropdownMenuItem(value: 'Mint', child: Text('Mint')),
        DropdownMenuItem(value: 'Good', child: Text('Good')),
        DropdownMenuItem(value: 'Fair', child: Text('Fair')),
        DropdownMenuItem(value: 'Needs Repair', child: Text('Needs Repair')),
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
                  Text(
                    'Warranty, Dates & Notes',
                    style: AppTypography.cardTitle.copyWith(fontSize: 13),
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
                  const Spacer(),
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
                            side: BorderSide(color: context.borderSubtle),
                          ),
                          onPressed: _pickPurchaseDate,
                          icon: const Icon(Icons.calendar_today_outlined, size: 14),
                          label: Text(
                            _purchaseDate == null
                                ? 'Purchase Date'
                                : 'Pur: ${_formatDate(_purchaseDate!)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      if (_purchaseDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          tooltip: 'Clear Purchase Date',
                          onPressed: () => setState(() => _purchaseDate = null),
                        ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            side: BorderSide(color: context.borderSubtle),
                          ),
                          onPressed: _pickWarrantyExpiryDate,
                          icon: const Icon(Icons.verified_user_outlined, size: 14),
                          label: Text(
                            _warrantyExpiryDate == null
                                ? 'Warranty Expiry'
                                : 'War: ${_formatDate(_warrantyExpiryDate!)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      if (_warrantyExpiryDate != null)
                        IconButton(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune_outlined, size: 16, color: context.brandAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Custom Fields (${_customFields.length})',
                      style: AppTypography.cardTitle.copyWith(fontSize: 13),
                    ),
                  ],
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
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
    final hasExpenseError = totalExpensesAsync.hasError;
    final maintenanceCostsMinor = totalExpensesAsync.value ?? 0;
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
                      if (record.description != null && record.description!.trim().isNotEmpty) ...[
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
              if (asset?.odometerReading != null || asset?.pmsDistanceIntervalKm != null || maintenanceCostsMinor > 0) ...[
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
                          builder: (_) => AddExpenseSheet(initialAssetRecordId: record.id),
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
                              color: AppColors.brandAccentSage,
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
