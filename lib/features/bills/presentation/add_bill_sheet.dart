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

const List<String> _availableCurrencies = [
  'PHP', 'USD', 'EUR', 'JPY', 'GBP', 'SGD', 'AUD', 'CAD',
];

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
  String _selectedCurrency = AppConstants.defaultCurrency;
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
          currencyCode: _selectedCurrency,
          paymentStatus: BillPaymentStatus.unpaid.value,
          linkedAssetRecordId: _selectedAssetRecordId,
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added bill: $title ($_selectedCurrency ${parsedAmount.toStringAsFixed(2)})',
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
    final sheetBg = Theme.of(context).bottomSheetTheme.backgroundColor ?? context.surfaceCard;

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

                // Utility Type (Full-width for non-cramped display)
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _utilityType,
                  decoration: const InputDecoration(labelText: 'Utility Type'),
                  items: UtilityType.values.map((type) {
                    return DropdownMenuItem<String>(
                      value: type.value,
                      child: Row(
                        children: [
                          Icon(type.icon, size: 18, color: context.brandAccent),
                          const SizedBox(width: 10),
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
                const SizedBox(height: 12),

                // Responsive Currency Selector (flex 3) & Amount Due (flex 7) -> No truncation!
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        key: const Key('bill_currency_dropdown'),
                        initialValue: _selectedCurrency,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                        ),
                        isExpanded: true,
                        items: _availableCurrencies.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCurrency = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 7,
                      child: TextFormField(
                        key: const Key('bill_amount_due_field'),
                        controller: _amountDueController,
                        decoration: InputDecoration(
                          labelText: 'Amount Due *',
                          hintText: 'e.g. 2450.00',
                          prefixText: '$_selectedCurrency ',
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

                // Due Date Selector (Dark-adapted touch target >= 48px)
                InkWell(
                  onTap: () => _pickDueDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_outlined, size: 20, color: context.brandAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _dueDate == null
                                ? 'Select Due Date *'
                                : 'Due Date: ${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}',
                            style: AppTypography.bodyPrimary.copyWith(
                              color: _dueDate == null ? context.textSecondary : context.textPrimary,
                              fontWeight: _dueDate == null ? FontWeight.normal : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Billing Period Selectors (High-contrast, touch-friendly cards >= 44px)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        key: const Key('billing_period_start_card'),
                        onTap: () => _pickBillingPeriod(context, isStart: true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 44),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.date_range_outlined, size: 16, color: context.brandAccent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _billingPeriodStart == null
                                      ? 'Period Start'
                                      : '${_billingPeriodStart!.month}/${_billingPeriodStart!.day}/${_billingPeriodStart!.year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _billingPeriodStart == null ? context.textSecondary : context.textPrimary,
                                    fontWeight: _billingPeriodStart == null ? FontWeight.normal : FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_billingPeriodStart != null)
                                GestureDetector(
                                  onTap: () => setState(() => _billingPeriodStart = null),
                                  child: Icon(Icons.close, size: 14, color: context.textSecondary),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        key: const Key('billing_period_end_card'),
                        onTap: () => _pickBillingPeriod(context, isStart: false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 44),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.date_range_outlined, size: 16, color: context.brandAccent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _billingPeriodEnd == null
                                      ? 'Period End'
                                      : '${_billingPeriodEnd!.month}/${_billingPeriodEnd!.day}/${_billingPeriodEnd!.year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _billingPeriodEnd == null ? context.textSecondary : context.textPrimary,
                                    fontWeight: _billingPeriodEnd == null ? FontWeight.normal : FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_billingPeriodEnd != null)
                                GestureDetector(
                                  onTap: () => setState(() => _billingPeriodEnd = null),
                                  child: Icon(Icons.close, size: 14, color: context.textSecondary),
                                ),
                            ],
                          ),
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
                            color: Colors.white,
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
