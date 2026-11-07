import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../records/domain/record.dart';
import '../../records/presentation/widgets/asset_picker_sheet.dart';
import '../../tasks/domain/task_item.dart';
import '../domain/expense_item.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  final String? initialAssetRecordId;
  final String? initialTaskRecordId;

  const AddExpenseSheet({
    super.key,
    this.initialAssetRecordId,
    this.initialTaskRecordId,
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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _expenseCategory = ExpenseCategory.maintenance.value;
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

  Future<void> _submit(List<RecordWithAsset> activeAssets) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final repo = ref.read(expenseRepositoryProvider);
    final recordId = const Uuid().v4();
    final now = DateTime.now().toUtc();
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();

    final parsedAmount = double.parse(_amountController.text.trim());
    final amountMinor = (parsedAmount * 100).round();
    final parsedOdometer = int.tryParse(_odometerController.text.trim());

    // 1. Persist the primary expense record first
    try {
      await repo.createExpenseRecord(
        record: Record(
          id: recordId,
          workspaceId: AppConstants.defaultWorkspaceId,
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
    final selectedAsset = _selectedAssetRecordId == null
        ? null
        : activeAssets.where((a) => a.record.id == _selectedAssetRecordId).firstOrNull;

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
          title: const Text('Schedule Next PMS?'),
          content: Text(
            'Maintenance logged at $parsedOdometer km.\n\n'
            'Based on configured limits ($intervalKm km / $intervalMonths mos), the next recommended PMS milestone is:\n\n'
            '• Target Odometer: $nextTargetMileage km\n'
            '• Target Due Date: $nextDateStr\n\n'
            'Would you like to auto-create the next PMS reminder task?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: AppColors.brandOnPrimary,
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
          // Task scheduling failure logged; does not abort main expense completion
        }
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          scheduledPms
              ? 'Logged expense & scheduled next PMS for ${selectedAsset?.record.title}'
              : 'Logged expense: $title (${AppConstants.defaultCurrency} ${parsedAmount.toStringAsFixed(2)})',
        ),
        backgroundColor: AppColors.brandPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(activeAssetsStreamProvider);
    final activeAssets = assetsAsync.value ?? <RecordWithAsset>[];

    final selectedAsset = _selectedAssetRecordId == null
        ? null
        : activeAssets.where((a) => a.record.id == _selectedAssetRecordId).firstOrNull;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    const Text('Log Expense / Maintenance', style: AppTypography.sectionTitle),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Expense Title *',
                    hintText: 'e.g. Engine Oil & Filter Change',
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount (${AppConstants.defaultCurrency}) *',
                          hintText: 'e.g. 1250.00',
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
                          decoration: const InputDecoration(labelText: 'Date'),
                          child: Text(
                            '${_transactionDate.year}-${_transactionDate.month.toString().padLeft(2, '0')}-${_transactionDate.day.toString().padLeft(2, '0')}',
                            style: AppTypography.bodyPrimary,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _expenseCategory,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: ExpenseCategory.values.map((cat) {
                          return DropdownMenuItem(
                            value: cat.value,
                            child: Text(cat.label, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _expenseCategory = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _paymentMethod,
                        decoration: const InputDecoration(labelText: 'Payment Method'),
                        items: const [
                          DropdownMenuItem(value: 'card', child: Text('Credit/Debit Card')),
                          DropdownMenuItem(value: 'cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                          DropdownMenuItem(value: 'e_wallet', child: Text('E-Wallet')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (val) => setState(() => _paymentMethod = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Reusable Asset Link Picker with active AsyncValue handling
                AssetPickerTile(
                  selectedAssetRecordId: _selectedAssetRecordId,
                  noneLabel: 'None (General Expense)',
                  onAssetChanged: (id) => setState(() => _selectedAssetRecordId = id),
                ),

                // Odometer at Service (Shown for maintenance logs on vehicle/asset)
                if (_expenseCategory == ExpenseCategory.maintenance.value && _selectedAssetRecordId != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: TextFormField(
                      controller: _odometerController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Odometer at Service (km)',
                        hintText: selectedAsset?.asset?.odometerReading != null
                            ? 'Last recorded: ${selectedAsset!.asset!.odometerReading} km'
                            : 'e.g. 15200',
                        prefixIcon: const Icon(Icons.speed, size: 20, color: AppColors.brandPrimary),
                      ),
                    ),
                  ),
                ],

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Description (Optional)',
                    hintText: 'Warranty status, technician details, invoice notes...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submit(activeAssets),
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
}
