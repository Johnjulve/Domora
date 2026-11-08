import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../records/domain/record.dart';
import '../../records/presentation/widgets/asset_picker_sheet.dart';
import '../domain/bill_item.dart';

class AddBillSheet extends ConsumerStatefulWidget {
  final String? initialAssetRecordId;

  const AddBillSheet({super.key, this.initialAssetRecordId});

  @override
  ConsumerState<AddBillSheet> createState() => _AddBillSheetState();
}

class _AddBillSheetState extends ConsumerState<AddBillSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _providerController = TextEditingController();
  final _accountController = TextEditingController();
  final _amountDueController = TextEditingController();
  final _notesController = TextEditingController();

  late String _utilityType;
  DateTime? _dueDate;
  DateTime? _billingPeriodStart;
  DateTime? _billingPeriodEnd;
  String? _selectedAssetRecordId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _utilityType = UtilityType.electricity.value;
    _dueDate = DateTime.now().add(const Duration(days: 7));
    _selectedAssetRecordId = widget.initialAssetRecordId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _providerController.dispose();
    _accountController.dispose();
    _amountDueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickBillingPeriod(BuildContext context, {required bool isStart}) async {
    final initialDate = isStart
        ? (_billingPeriodStart ?? DateTime.now().subtract(const Duration(days: 30)))
        : (_billingPeriodEnd ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _billingPeriodStart = picked;
        } else {
          _billingPeriodEnd = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(billRepositoryProvider);
      final recordId = const Uuid().v4();
      final now = DateTime.now().toUtc();
      final title = _titleController.text.trim();
      final provider = _providerController.text.trim();
      final account = _accountController.text.trim();
      final notes = _notesController.text.trim();

      final parsedAmount = double.parse(_amountDueController.text.trim());
      final amountMinor = (parsedAmount * 100).round();

      await repo.createBillRecord(
        record: Record(
          id: recordId,
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'bill',
          title: title,
          description: notes.isNotEmpty ? notes : null,
          createdAt: now,
          updatedAt: now,
        ),
        bill: BillItem(
          recordId: recordId,
          utilityType: _utilityType,
          providerName: provider.isNotEmpty ? provider : null,
          accountNumber: account.isNotEmpty ? account : null,
          billingPeriodStart: _billingPeriodStart,
          billingPeriodEnd: _billingPeriodEnd,
          dueDate: _dueDate,
          amountDueMinor: amountMinor,
          currencyCode: AppConstants.defaultCurrency,
          paymentStatus: BillPaymentStatus.unpaid.value,
          linkedAssetRecordId: _selectedAssetRecordId,
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added bill: $title (${AppConstants.defaultCurrency} ${parsedAmount.toStringAsFixed(2)})',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save bill: $e'),
            backgroundColor: AppColors.statusDangerStroke,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
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
                    const Text('Add Utility Bill', style: AppTypography.sectionTitle),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Bill Title *',
                    hintText: 'e.g. Meralco Electricity Bill - Oct',
                  ),
                  autofocus: true,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Bill title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Amount Due & Utility Type
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextFormField(
                        controller: _amountDueController,
                        decoration: const InputDecoration(
                          labelText: 'Amount Due (PHP) *',
                          hintText: 'e.g. 2450.00',
                          prefixText: '₱ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Amount is required';
                          }
                          final parsed = double.tryParse(val.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Enter valid amount';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _utilityType,
                        decoration: const InputDecoration(labelText: 'Utility Type'),
                        items: UtilityType.values.map((type) {
                          return DropdownMenuItem<String>(
                            value: type.value,
                            child: Row(
                              children: [
                                Icon(type.icon, size: 16, color: AppColors.brandPrimary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    type.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _utilityType = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Provider & Account/Ref No.
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _providerController,
                        decoration: const InputDecoration(
                          labelText: 'Provider / Issuer',
                          hintText: 'e.g. Meralco, PLDT',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _accountController,
                        decoration: const InputDecoration(
                          labelText: 'Account / Ref No.',
                          hintText: 'e.g. 1029384756',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Due Date Selector
                InkWell(
                  onTap: () => _pickDueDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event, size: 20, color: AppColors.brandPrimary),
                        const SizedBox(width: 10),
                        Text(
                          _dueDate == null
                              ? 'Select Due Date *'
                              : 'Due Date: ${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}',
                          style: AppTypography.bodyPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Billing Period Row (Optional)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _pickBillingPeriod(context, isStart: true),
                        icon: const Icon(Icons.date_range, size: 16),
                        label: Text(
                          _billingPeriodStart == null
                              ? 'Period Start'
                              : '${_billingPeriodStart!.month}/${_billingPeriodStart!.day}/${_billingPeriodStart!.year}',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _pickBillingPeriod(context, isStart: false),
                        icon: const Icon(Icons.date_range, size: 16),
                        label: Text(
                          _billingPeriodEnd == null
                              ? 'Period End'
                              : '${_billingPeriodEnd!.month}/${_billingPeriodEnd!.day}/${_billingPeriodEnd!.year}',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Linked Asset Selector (Clean reusable widget with async states)
                AssetPickerTile(
                  selectedAssetRecordId: _selectedAssetRecordId,
                  noneLabel: 'None (General Household Bill)',
                  onAssetChanged: (id) => setState(() => _selectedAssetRecordId = id),
                ),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Payment Instructions',
                    hintText: 'e.g. Disconnection warning if unpaid by due date',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brandOnPrimary,
                          ),
                        )
                      : const Text('Save Bill'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
