import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../records/domain/record.dart';
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(expenseRepositoryProvider);
      final recordId = const Uuid().v4();
      final now = DateTime.now().toUtc();
      final title = _titleController.text.trim();
      final notes = _notesController.text.trim();

      final parsedAmount = double.parse(_amountController.text.trim());
      final amountMinor = (parsedAmount * 100).round();

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
        ),
      );

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Logged expense: $title (${AppConstants.defaultCurrency} ${parsedAmount.toStringAsFixed(2)})'),
            backgroundColor: AppColors.brandPrimary,
          ),
        );
      }
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(activeAssetsStreamProvider);

    return Padding(
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
                  hintText: 'e.g. AC Filter Replacement & Freon',
                ),
                autofocus: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Expense title is required';
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

              // Optional Asset Link
              assetsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Failed to load assets: $err',
                    style: AppTypography.caption.copyWith(color: AppColors.statusDangerStroke),
                  ),
                ),
                data: (assets) {
                  if (assets.isEmpty) return const SizedBox.shrink();

                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedAssetRecordId,
                    decoration: const InputDecoration(
                      labelText: 'Link to Asset (Optional)',
                      hintText: 'Associate cost with a registered asset',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('None (General Expense)', overflow: TextOverflow.ellipsis),
                      ),
                      ...assets.map(
                        (item) => DropdownMenuItem<String>(
                          value: item.record.id,
                          child: Text(item.record.title, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedAssetRecordId = val),
                  );
                },
              ),
              const SizedBox(height: 12),
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
                onPressed: _isSubmitting ? null : _submit,
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
    );
  }
}
