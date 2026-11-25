import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../categories/domain/category.dart';
import '../../records/domain/record.dart';
import '../../records/presentation/widgets/asset_picker_sheet.dart';
import '../../records/presentation/widgets/record_section_card.dart';
import '../domain/bill_item.dart';

const List<String> _availableCurrencies = [
  'PHP', 'USD', 'EUR', 'JPY', 'GBP', 'SGD', 'AUD', 'CAD',
];

class _BillTypeOption {
  final String value;
  final String label;
  final IconData icon;
  final String? subCategoryId;

  const _BillTypeOption({
    required this.value,
    required this.label,
    required this.icon,
    this.subCategoryId,
  });
}

class AddBillSheet extends ConsumerStatefulWidget {
  final String? initialAssetRecordId;
  final String? initialUtilityType;

  const AddBillSheet({
    super.key,
    this.initialAssetRecordId,
    this.initialUtilityType,
  });

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
  late BillRecurrenceCycle _recurrenceCycle;
  late bool _autoLogPayment;
  String _selectedCurrency = AppConstants.defaultCurrency;
  DateTime? _dueDate;
  DateTime? _billingPeriodStart;
  DateTime? _billingPeriodEnd;
  String? _selectedAssetRecordId;
  bool _isMoreDetailsExpanded = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _utilityType = widget.initialUtilityType ?? UtilityType.electricity.value;
    final isInitialSubscription =
        _utilityType.trim().toLowerCase() == UtilityType.subscription.value;
    _recurrenceCycle =
        isInitialSubscription ? BillRecurrenceCycle.monthly : BillRecurrenceCycle.none;
    _autoLogPayment = isInitialSubscription;
    _dueDate = DateTime.now().add(const Duration(days: 7));
    _selectedAssetRecordId = widget.initialAssetRecordId;
    _isMoreDetailsExpanded = widget.initialAssetRecordId != null;
  }

  bool get _isDueDateOverdue {
    final due = _dueDate;
    if (due == null) return false;
    final now = DateTime.now();
    return DateTime.utc(due.year, due.month, due.day)
        .isBefore(DateTime.utc(now.year, now.month, now.day));
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

  String? _matchBuiltInBillSubCategoryId(UtilityType type, List<Category> subCategories) {
    final valueLower = type.value.toLowerCase();
    final labelLower = type.label.toLowerCase();
    for (final sub in subCategories) {
      final subLower = sub.name.trim().toLowerCase();
      if (subLower == valueLower || subLower == labelLower) {
        return sub.id;
      }
    }
    if (type == UtilityType.subscription) {
      return subCategories.where((s) => s.id == 'cat-sub-subscription').firstOrNull?.id;
    }
    return null;
  }

  List<_BillTypeOption> _buildTypeOptions(List<Category> subCategories) {
    final options = <_BillTypeOption>[
      for (final type in UtilityType.values)
        _BillTypeOption(
          value: type.value,
          label: type.label,
          icon: type.icon,
          subCategoryId: _matchBuiltInBillSubCategoryId(type, subCategories),
        ),
    ];

    final seenNormalized = <String>{
      for (final opt in options) opt.value.toLowerCase(),
      for (final opt in options) opt.label.toLowerCase(),
    };

    for (final sub in subCategories) {
      final normalizedName = sub.name.trim().toLowerCase();
      if (normalizedName.isEmpty || seenNormalized.contains(normalizedName)) {
        continue;
      }
      // Skip default unrenamed "Bill" since specific utility types cover bills
      if (sub.id == 'cat-sub-bill' && normalizedName == 'bill') continue;
      seenNormalized.add(normalizedName);
      options.add(
        _BillTypeOption(
          value: sub.name.trim(),
          label: sub.name.trim(),
          icon: categoryIconFromKey(sub.iconKey),
          subCategoryId: sub.id,
        ),
      );
    }

    if (!options.any((opt) => opt.value == _utilityType)) {
      options.add(
        _BillTypeOption(
          value: _utilityType,
          label: _utilityType,
          icon: Icons.receipt_long_outlined,
        ),
      );
    }

    return options;
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

  Future<void> _submit(List<_BillTypeOption> options) async {
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

      final amountMinor = CurrencyFormatter.parseMajorToMinor(_amountDueController.text);
      if (amountMinor == null || amountMinor <= 0) {
        if (mounted) setState(() => _isSubmitting = false);
        return;
      }
      final matchedOption = options.where((o) => o.value == _utilityType).firstOrNull;

      final shouldAutoLog =
          _recurrenceCycle != BillRecurrenceCycle.none && _dueDate != null && _autoLogPayment;

      await repo.createBillRecord(
        record: Record(
          id: recordId,
          workspaceId: AppConstants.defaultWorkspaceId,
          categoryId: matchedOption?.subCategoryId,
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
          recurrenceCycle:
              _recurrenceCycle == BillRecurrenceCycle.none ? null : _recurrenceCycle.value,
          autoLogPayment: shouldAutoLog,
          linkedAssetRecordId: _selectedAssetRecordId,
        ),
      );

      if (shouldAutoLog) {
        final loggedCount =
            await repo.processDueSubscriptions(AppConstants.defaultWorkspaceId);
        if (loggedCount > 0) {
          ref.invalidate(activeRecordsStreamProvider);
          ref.invalidate(dashboardRecordsStreamProvider);
          ref.invalidate(activeBillsStreamProvider);
          ref.invalidate(dashboardBillsStreamProvider);
          ref.invalidate(upcomingBillsStreamProvider);
          ref.invalidate(workspaceTotalUnpaidBillsProvider);
          ref.invalidate(activeExpensesStreamProvider);
          ref.invalidate(dashboardExpensesStreamProvider);
          ref.invalidate(workspaceTotalExpensesProvider);
        }
      }

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Added bill: $title (${CurrencyFormatter.formatMinor(amountMinor, currencyCode: _selectedCurrency)})',
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
    final subCategoriesAsync = ref.watch(billsExpensesSubCategoriesStreamProvider);
    final subCategories = subCategoriesAsync.asData?.value ?? const <Category>[];
    final typeOptions = _buildTypeOptions(subCategories);

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
                    Text(
                      'Add Utility Bill',
                      style: AppTypography.sectionTitle.copyWith(color: context.textPrimary),
                    ),
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

                // Category / Type (merged with active Bills & Expenses sub-categories)
                DropdownButtonFormField<String>(
                  key: const Key('bill_type_dropdown'),
                  isExpanded: true,
                  initialValue: _utilityType,
                  decoration: const InputDecoration(labelText: 'Category / Type'),
                  items: typeOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option.value,
                      child: Row(
                        children: [
                          Icon(option.icon, size: 18, color: context.brandAccent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              option.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _utilityType = val;
                      if (val.trim().toLowerCase() == UtilityType.subscription.value &&
                          _recurrenceCycle == BillRecurrenceCycle.none) {
                        _recurrenceCycle = BillRecurrenceCycle.monthly;
                        _autoLogPayment = true;
                      }
                    });
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

                // Billing Coverage (One-time vs Recurring cycle)
                DropdownButtonFormField<BillRecurrenceCycle>(
                  key: const Key('bill_recurrence_dropdown'),
                  isExpanded: true,
                  initialValue: _recurrenceCycle,
                  decoration: const InputDecoration(labelText: 'Billing Coverage'),
                  items: BillRecurrenceCycle.values.map((cycle) {
                    return DropdownMenuItem<BillRecurrenceCycle>(
                      value: cycle,
                      child: Text(cycle.label, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _recurrenceCycle = val;
                      if (val == BillRecurrenceCycle.none) {
                        _autoLogPayment = false;
                      }
                    });
                  },
                ),
                if (_recurrenceCycle != BillRecurrenceCycle.none) ...[
                  const SizedBox(height: 10),
                  _buildAutoLogToggleCard(context),
                ],
                const SizedBox(height: 12),

                // Responsive Currency Selector (flex 3) & Amount Due (flex 7)
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
                        inputFormatters: const [ThousandsSeparatorInputFormatter()],
                        decoration: InputDecoration(
                          labelText: 'Amount Due *',
                          hintText: 'e.g. 2,450.00',
                          prefixText: '$_selectedCurrency ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Amount is required';
                          }
                          final parsedMinor = CurrencyFormatter.parseMajorToMinor(val);
                          if (parsedMinor == null || parsedMinor <= 0) {
                            return 'Enter valid amount';
                          }
                          return null;
                        },
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
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isDueDateOverdue) ...[
                          const SizedBox(width: 8),
                          Container(
                            key: const Key('bill_due_date_overdue_badge'),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? AppColors.statusDangerStroke.withValues(alpha: 0.22)
                                  : AppColors.statusDangerFill,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Overdue',
                              style: AppTypography.badge.copyWith(
                                color: context.isDarkMode
                                    ? AppColors.statusDangerStroke
                                    : AppColors.statusDangerText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Collapsible Billing Details & Notes
                _buildBillingDetailsDrawer(context),
                const SizedBox(height: 20),

                // Save Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submit(typeOptions),
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

  Widget _buildAutoLogToggleCard(BuildContext context) {
    final canAutoLog = _dueDate != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-log payments',
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 13,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  canAutoLog
                      ? 'Automatically logs each cycle on its renewal date and advances to the next cycle.'
                      : 'Select a due date to enable automatic logging.',
                  style: AppTypography.caption.copyWith(color: context.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            key: const Key('bill_auto_log_switch'),
            value: canAutoLog && _autoLogPayment,
            onChanged: canAutoLog ? (val) => setState(() => _autoLogPayment = val) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBillingDetailsDrawer(BuildContext context) {
    final hasExtraData = _providerController.text.trim().isNotEmpty ||
        _accountController.text.trim().isNotEmpty ||
        _billingPeriodStart != null ||
        _billingPeriodEnd != null ||
        _selectedAssetRecordId != null ||
        _notesController.text.trim().isNotEmpty;

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
            key: const Key('bill_more_details_toggle'),
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
                        'Billing Details & Notes',
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _providerController,
                          decoration: InputDecoration(
                            labelText: 'Provider / Issuer',
                            hintText: 'e.g. Meralco, PLDT',
                            filled: true,
                            fillColor: context.surfaceCard,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _accountController,
                          decoration: InputDecoration(
                            labelText: 'Account / Ref No.',
                            hintText: 'e.g. 1029384756',
                            filled: true,
                            fillColor: context.surfaceCard,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildBillingPeriodRow(context),
                  const SizedBox(height: 10),
                  AssetPickerTile(
                    selectedAssetRecordId: _selectedAssetRecordId,
                    noneLabel: 'None (General Household Bill)',
                    onAssetChanged: (id) => setState(() => _selectedAssetRecordId = id),
                  ),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes / Payment Instructions',
                      hintText: 'e.g. Disconnection warning if unpaid by due date',
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

  Widget _buildBillingPeriodRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildPeriodCard(
            context: context,
            cardKey: const Key('billing_period_start_card'),
            date: _billingPeriodStart,
            placeholder: 'Period Start',
            onTap: () => _pickBillingPeriod(context, isStart: true),
            onClear: () => setState(() => _billingPeriodStart = null),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPeriodCard(
            context: context,
            cardKey: const Key('billing_period_end_card'),
            date: _billingPeriodEnd,
            placeholder: 'Period End',
            onTap: () => _pickBillingPeriod(context, isStart: false),
            onClear: () => setState(() => _billingPeriodEnd = null),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodCard({
    required BuildContext context,
    required Key cardKey,
    required DateTime? date,
    required String placeholder,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InkWell(
      key: cardKey,
      onTap: onTap,
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
                date == null ? placeholder : '${date.month}/${date.day}/${date.year}',
                style: AppTypography.caption.copyWith(
                  color: date == null ? context.textSecondary : context.textPrimary,
                  fontWeight: date == null ? FontWeight.normal : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 14, color: context.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
