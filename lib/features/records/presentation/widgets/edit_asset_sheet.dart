import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/record.dart';
import 'record_section_card.dart';

class _EditableCustomField {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _EditableCustomField({String keyText = '', String valueText = ''})
      : keyController = TextEditingController(text: keyText),
        valueController = TextEditingController(text: valueText);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

/// Sanctuary modal sheet for editing mutable attributes of an existing Asset / Record
/// while keeping hardware identity (`brand`, `model`, `serialNumber`) and `categoryId` locked.
class EditAssetSheet extends ConsumerStatefulWidget {
  final RecordWithAsset item;
  final List<CustomFieldEntry> initialCustomFields;
  final String? categoryName;

  const EditAssetSheet({
    super.key,
    required this.item,
    required this.initialCustomFields,
    this.categoryName,
  });

  @override
  ConsumerState<EditAssetSheet> createState() => _EditAssetSheetState();
}

class _EditAssetSheetState extends ConsumerState<EditAssetSheet> {
  static const List<String> _conditions = ['Mint', 'Good', 'Fair', 'Needs Repair'];
  static const List<String> _currencies = ['PHP', 'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'SGD'];
  static const List<int?> _defaultPmsMonths = [null, 3, 6, 12];
  static const List<String> _familyRelationships = [
    'Spouse', 'Child', 'Parent', 'Sibling', 'Pet', 'Other',
  ];
  static const List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown',
  ];
  static const Set<String> _familyTemplateKeys = {
    'Relationship',
    'Birthdate',
    'Blood Type',
    'Contact / Emergency Phone',
    'ID / Insurance / PhilHealth No.',
    'Medical Notes & Allergies',
  };

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _deedNumberController;
  late final TextEditingController _licensePlateController;
  late final TextEditingController _odometerController;
  late final TextEditingController _pmsDistanceController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  // Family member controllers & state
  late final TextEditingController _familyPhoneController;
  late final TextEditingController _familyIdNumberController;
  late final TextEditingController _familyMedicalNotesController;
  late String _familyRelationship;
  DateTime? _familyBirthdate;
  late String _familyBloodType;

  late String _condition;
  late String _selectedCurrency;
  int? _pmsTimeMonths;
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiryDate;
  late bool _isWarrantyAndNotesExpanded;
  final List<_EditableCustomField> _customFields = [];

  bool _isSubmitting = false;
  String? _saveError;

  bool get _isFamily => widget.item.record.categoryId == 'cat-family';
  bool get _isVehicle => widget.item.record.categoryId == 'cat-vehicles';
  bool get _isProperty => widget.item.record.categoryId == 'cat-properties';

  @override
  void initState() {
    super.initState();
    final record = widget.item.record;
    final asset = widget.item.asset;
    final existingMap = <String, String>{
      for (final cf in widget.initialCustomFields) cf.definition.label: cf.value.valueText,
    };

    _titleController = TextEditingController(text: record.title);
    _locationController = TextEditingController(text: asset?.locationDescription ?? '');
    _deedNumberController = TextEditingController(text: existingMap['Title / Deed Number'] ?? '');
    _licensePlateController = TextEditingController(text: existingMap['License Plate'] ?? '');
    _odometerController = TextEditingController(
      text: asset?.odometerReading != null ? '${asset!.odometerReading}' : '',
    );
    _pmsDistanceController = TextEditingController(
      text: asset?.pmsDistanceIntervalKm != null ? '${asset!.pmsDistanceIntervalKm}' : '',
    );
    _amountController = TextEditingController(
      text: asset?.purchaseAmountMinor != null
          ? CurrencyFormatter.formatMinorNumber(asset!.purchaseAmountMinor!)
          : '',
    );
    _notesController = TextEditingController(text: record.description ?? '');

    _condition = asset?.condition ?? 'Good';
    _selectedCurrency = asset?.purchaseCurrency ?? AppConstants.defaultCurrency;
    _pmsTimeMonths = asset?.pmsTimeIntervalMonths;
    _purchaseDate = asset?.purchaseDate;
    _warrantyExpiryDate = asset?.warrantyExpiryDate;
    _isWarrantyAndNotesExpanded = _purchaseDate != null ||
        _warrantyExpiryDate != null ||
        (record.description != null && record.description!.trim().isNotEmpty);

    // Family member pre-population
    _familyRelationship = existingMap['Relationship'] ?? 'Spouse';
    _familyBloodType = existingMap['Blood Type'] ?? 'Unknown';
    final rawBirthdate = existingMap['Birthdate'];
    final parsedBirthdate = rawBirthdate != null ? DateTime.tryParse(rawBirthdate) : null;
    _familyBirthdate = parsedBirthdate == null
        ? null
        : DateTime.utc(parsedBirthdate.year, parsedBirthdate.month, parsedBirthdate.day);
    _familyPhoneController = TextEditingController(
      text: existingMap['Contact / Emergency Phone'] ?? '',
    );
    _familyIdNumberController = TextEditingController(
      text: existingMap['ID / Insurance / PhilHealth No.'] ?? '',
    );
    _familyMedicalNotesController = TextEditingController(
      text: existingMap['Medical Notes & Allergies'] ?? record.description ?? '',
    );

    // Extra custom fields not owned by a template
    final handledKeys = _handledTemplateKeys();
    for (final cf in widget.initialCustomFields) {
      if (handledKeys.contains(cf.definition.label)) continue;
      _customFields.add(
        _EditableCustomField(
          keyText: cf.definition.label,
          valueText: cf.value.valueText,
        ),
      );
    }
  }

  Set<String> _handledTemplateKeys() {
    if (_isFamily) return _familyTemplateKeys;
    if (_isVehicle) return const {'License Plate'};
    if (_isProperty) return const {'Title / Deed Number'};
    return const {};
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _deedNumberController.dispose();
    _licensePlateController.dispose();
    _odometerController.dispose();
    _pmsDistanceController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _familyPhoneController.dispose();
    _familyIdNumberController.dispose();
    _familyMedicalNotesController.dispose();
    for (final cf in _customFields) {
      cf.dispose();
    }
    super.dispose();
  }

  String _formatIsoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _addCalendarMonths(DateTime fromUtc, int months) {
    final targetYear = fromUtc.year + (fromUtc.month + months - 1) ~/ 12;
    final targetMonth = (fromUtc.month + months - 1) % 12 + 1;
    final maxDays = DateTime.utc(targetYear, targetMonth + 1, 0).day;
    final targetDay = fromUtc.day > maxDays ? maxDays : fromUtc.day;
    return DateTime.utc(targetYear, targetMonth, targetDay);
  }

  Future<void> _pickCalendarDate({
    required DateTime? current,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    var initial = current != null
        ? DateTime(current.year, current.month, current.day)
        : DateTime(now.year, now.month, now.day);
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null && mounted) {
      setState(() => onPicked(DateTime.utc(picked.year, picked.month, picked.day)));
    }
  }

  Map<String, String> _buildCustomFieldsMap() {
    final map = <String, String>{};
    if (_isFamily) {
      map['Relationship'] = _familyRelationship;
      if (_familyBirthdate != null) {
        map['Birthdate'] = _formatIsoDate(_familyBirthdate!);
      }
      map['Blood Type'] = _familyBloodType;
      final phone = _familyPhoneController.text.trim();
      if (phone.isNotEmpty) map['Contact / Emergency Phone'] = phone;
      final idNo = _familyIdNumberController.text.trim();
      if (idNo.isNotEmpty) map['ID / Insurance / PhilHealth No.'] = idNo;
      final medical = _familyMedicalNotesController.text.trim();
      if (medical.isNotEmpty) map['Medical Notes & Allergies'] = medical;
    } else {
      if (_isProperty && _deedNumberController.text.trim().isNotEmpty) {
        map['Title / Deed Number'] = _deedNumberController.text.trim();
      }
      if (_isVehicle && _licensePlateController.text.trim().isNotEmpty) {
        map['License Plate'] = _licensePlateController.text.trim();
      }
    }

    for (final cf in _customFields) {
      final key = cf.keyController.text.trim();
      final val = cf.valueController.text.trim();
      if (key.isNotEmpty && val.isNotEmpty) {
        map[key] = val;
      }
    }
    return map;
  }

  DateTime? _computeNextPmsDueDate(Asset? existingAsset) {
    if (!_isVehicle || _pmsTimeMonths == null) return null;
    final monthsChanged = _pmsTimeMonths != existingAsset?.pmsTimeIntervalMonths;
    if (monthsChanged || existingAsset?.nextPmsDueDate == null) {
      final now = DateTime.now();
      return _addCalendarMonths(DateTime.utc(now.year, now.month, now.day), _pmsTimeMonths!);
    }
    return existingAsset!.nextPmsDueDate;
  }

  ({Record record, Asset asset}) _buildUpdatedRecordAndAsset() {
    final existingRecord = widget.item.record;
    final existingAsset = widget.item.asset;
    final description = _isFamily
        ? (_familyMedicalNotesController.text.trim().isEmpty
            ? null
            : _familyMedicalNotesController.text.trim())
        : (_notesController.text.trim().isEmpty ? null : _notesController.text.trim());

    final int? amountMinor = _isFamily || _amountController.text.trim().isEmpty
        ? null
        : CurrencyFormatter.parseMajorToMinor(_amountController.text);

    final parsedOdometer = _isVehicle ? int.tryParse(_odometerController.text.trim()) : null;
    final parsedPmsDistance = _isVehicle ? int.tryParse(_pmsDistanceController.text.trim()) : null;
    final nextOdoTarget = (_isVehicle &&
            parsedOdometer != null &&
            parsedPmsDistance != null &&
            parsedOdometer >= 0 &&
            parsedPmsDistance > 0)
        ? parsedOdometer + parsedPmsDistance
        : null;

    final updatedRecord = Record(
      id: existingRecord.id,
      workspaceId: existingRecord.workspaceId,
      categoryId: existingRecord.categoryId,
      recordType: existingRecord.recordType,
      title: _titleController.text.trim(),
      description: description,
      status: existingRecord.status,
      createdAt: existingRecord.createdAt,
      updatedAt: DateTime.now().toUtc(),
      archivedAt: existingRecord.archivedAt,
      deletedAt: existingRecord.deletedAt,
    );

    final updatedAsset = Asset(
      recordId: existingRecord.id,
      brand: existingAsset?.brand,
      model: existingAsset?.model,
      serialNumber: existingAsset?.serialNumber,
      condition: _isFamily ? null : _condition,
      locationDescription: _isFamily || _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      purchaseDate: _isFamily ? null : _purchaseDate,
      purchaseAmountMinor: _isFamily ? null : amountMinor,
      purchaseCurrency: _isFamily ? AppConstants.defaultCurrency : _selectedCurrency,
      warrantyExpiryDate: _isFamily ? null : _warrantyExpiryDate,
      odometerReading: _isVehicle ? parsedOdometer : null,
      pmsDistanceIntervalKm: _isVehicle ? parsedPmsDistance : null,
      pmsTimeIntervalMonths: _isVehicle ? _pmsTimeMonths : null,
      nextPmsOdometerTarget: _isVehicle ? nextOdoTarget : null,
      nextPmsDueDate: _computeNextPmsDueDate(existingAsset),
    );

    return (record: updatedRecord, asset: updatedAsset);
  }

  void _invalidateAssetProviders(String recordId) {
    ref.invalidate(recordCustomFieldsProvider(recordId));
    ref.invalidate(activeRecordsStreamProvider);
    ref.invalidate(activeAssetsStreamProvider);
    ref.invalidate(dashboardRecordsStreamProvider);
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _saveError = null;
    });

    try {
      final updated = _buildUpdatedRecordAndAsset();
      await ref.read(recordRepositoryProvider).updateAssetRecord(
            record: updated.record,
            asset: updated.asset,
            customFields: _buildCustomFieldsMap(),
          );
      _invalidateAssetProviders(updated.record.id);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _saveError = 'Failed to save changes: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetBg = Theme.of(context).bottomSheetTheme.backgroundColor ?? context.surfaceCard;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: const Key('edit_asset_sheet'),
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
                _buildHeader(context),
                const SizedBox(height: 12),
                _buildLockedIdentityCard(context),
                const SizedBox(height: 14),
                if (_saveError != null) ...[
                  _buildErrorBanner(context, _saveError!),
                  const SizedBox(height: 12),
                ],
                _buildTitleField(),
                const SizedBox(height: 12),
                if (_isFamily) ...[
                  _buildFamilyFields(context),
                ] else ...[
                  _buildConditionAndLocationFields(context),
                  if (_isProperty) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deedNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Title / Deed Number',
                        hintText: 'e.g. TCT-123456',
                      ),
                    ),
                  ],
                  if (_isVehicle) ...[
                    const SizedBox(height: 12),
                    _buildVehicleFields(context),
                  ],
                  const SizedBox(height: 12),
                  _buildValueFields(),
                  const SizedBox(height: 12),
                  _buildWarrantyAndNotesDrawer(context),
                ],
                const SizedBox(height: 12),
                _buildCustomFieldsSection(context),
                const SizedBox(height: 20),
                ElevatedButton(
                  key: const Key('edit_asset_save_button'),
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            _isFamily ? 'Edit Family Member' : 'Edit Record',
            style: AppTypography.sectionTitle.copyWith(color: context.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: context.textSecondary),
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }

  Widget _buildLockedIdentityCard(BuildContext context) {
    final asset = widget.item.asset;
    final categoryLabel = widget.categoryName ??
        (_isFamily
            ? 'Family'
            : _isVehicle
                ? 'Vehicles'
                : _isProperty
                    ? 'Properties'
                    : 'Asset');

    final lockedRows = <(String, String)>[
      if (!_isFamily && asset?.brand != null && asset!.brand!.trim().isNotEmpty)
        ('Brand / Maker', asset.brand!.trim()),
      if (!_isFamily && asset?.model != null && asset!.model!.trim().isNotEmpty)
        ('Model / Type', asset.model!.trim()),
      if (!_isFamily && asset?.serialNumber != null && asset!.serialNumber!.trim().isNotEmpty)
        ('VIN / Serial No.', asset.serialNumber!.trim()),
    ];

    return Container(
      key: const Key('locked_identity_card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: context.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Locked Identity',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: adaptiveSageFill(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    categoryLabel,
                    style: AppTypography.badge.copyWith(color: context.brandAccent),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          if (lockedRows.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: context.borderSubtle),
            const SizedBox(height: 8),
            for (final (label, val) in lockedRows)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: AppTypography.caption.copyWith(color: context.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        val,
                        textAlign: TextAlign.end,
                        style: AppTypography.bodySecondary.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      key: const Key('edit_asset_error_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? AppColors.statusDangerStroke.withValues(alpha: 0.2)
            : AppColors.statusDangerFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.statusDangerStroke),
      ),
      child: Text(
        message,
        style: AppTypography.caption.copyWith(
          color: context.isDarkMode ? AppColors.statusDangerStroke : AppColors.statusDangerText,
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      key: const Key('edit_asset_title_field'),
      controller: _titleController,
      decoration: InputDecoration(
        labelText: _isFamily ? 'Full Name *' : 'Title *',
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return _isFamily ? 'Full name is required' : 'Title is required';
        }
        return null;
      },
    );
  }

  Widget _buildConditionAndLocationFields(BuildContext context) {
    final conditionOptions = [
      ..._conditions,
      if (!_conditions.contains(_condition)) _condition,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('edit_asset_condition_dropdown'),
          isExpanded: true,
          initialValue: _condition,
          decoration: const InputDecoration(labelText: 'Condition'),
          items: conditionOptions
              .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _condition = val);
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('edit_asset_location_field'),
          controller: _locationController,
          decoration: InputDecoration(
            labelText: _isVehicle ? 'Location / Parking' : 'Location',
            hintText: _isVehicle ? 'e.g. Garage Slot B2' : 'e.g. Living Room',
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleFields(BuildContext context) {
    final pmsOptions = <int?>[
      ..._defaultPmsMonths,
      if (_pmsTimeMonths != null && !_defaultPmsMonths.contains(_pmsTimeMonths)) _pmsTimeMonths,
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car_outlined, size: 18, color: context.brandAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vehicle & PMS Settings',
                  style: AppTypography.cardTitle.copyWith(fontSize: 14, color: context.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('edit_asset_license_plate_field'),
            controller: _licensePlateController,
            decoration: const InputDecoration(
              labelText: 'License Plate',
              hintText: 'e.g. ABC 1234',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('edit_asset_odometer_field'),
            controller: _odometerController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Current Odometer (km)',
              hintText: 'e.g. 12500',
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return null;
              final parsed = int.tryParse(val.trim());
              if (parsed == null || parsed < 0) return 'Enter valid km';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('edit_asset_pms_distance_field'),
                  controller: _pmsDistanceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'PMS Distance (km)',
                    hintText: 'e.g. 5000',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return null;
                    final parsed = int.tryParse(val.trim());
                    if (parsed == null || parsed <= 0) return 'Enter positive km';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  key: const Key('edit_asset_pms_time_dropdown'),
                  isExpanded: true,
                  initialValue: _pmsTimeMonths,
                  decoration: const InputDecoration(labelText: 'PMS Time Limit'),
                  items: pmsOptions.map((months) {
                    final label = months == null
                        ? 'None'
                        : '$months ${months == 1 ? 'month' : 'months'}';
                    return DropdownMenuItem<int?>(
                      value: months,
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _pmsTimeMonths = val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueFields() {
    final currencyOptions = [
      ..._currencies,
      if (!_currencies.contains(_selectedCurrency)) _selectedCurrency,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<String>(
            key: const Key('edit_asset_currency_dropdown'),
            isExpanded: true,
            initialValue: _selectedCurrency,
            decoration: const InputDecoration(labelText: 'Currency'),
            items: currencyOptions
                .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCurrency = val);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 7,
          child: TextFormField(
            key: const Key('edit_asset_amount_field'),
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [ThousandsSeparatorInputFormatter()],
            decoration: InputDecoration(
              labelText: 'Estimated Value ($_selectedCurrency)',
              hintText: 'e.g. 45,000.00',
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return null;
              if (CurrencyFormatter.parseMajorToMinor(val) == null) {
                return 'Enter a valid non-negative amount';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWarrantyAndNotesDrawer(BuildContext context) {
    final now = DateTime.now();
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
            key: const Key('edit_asset_warranty_notes_toggle'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _isWarrantyAndNotesExpanded = !_isWarrantyAndNotesExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.event_note_outlined, size: 18, color: context.brandAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Warranty, Purchase Date & Notes',
                      style: AppTypography.bodySecondary.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _isWarrantyAndNotesExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: context.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_isWarrantyAndNotesExpanded) ...[
            Divider(height: 1, color: context.borderSubtle),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDatePickerTile(
                    context: context,
                    label: _purchaseDate == null
                        ? 'Purchase Date (optional)'
                        : 'Purchase Date: ${_formatIsoDate(_purchaseDate!)}',
                    icon: Icons.shopping_bag_outlined,
                    hasValue: _purchaseDate != null,
                    onTap: () => _pickCalendarDate(
                      current: _purchaseDate,
                      firstDate: DateTime(1950),
                      lastDate: DateTime(now.year + 1, now.month, now.day),
                      onPicked: (d) => _purchaseDate = d,
                    ),
                    onClear: () => setState(() => _purchaseDate = null),
                  ),
                  const SizedBox(height: 10),
                  _buildDatePickerTile(
                    context: context,
                    label: _warrantyExpiryDate == null
                        ? 'Warranty Expiry (optional)'
                        : 'Warranty Expiry: ${_formatIsoDate(_warrantyExpiryDate!)}',
                    icon: Icons.verified_user_outlined,
                    hasValue: _warrantyExpiryDate != null,
                    onTap: () => _pickCalendarDate(
                      current: _warrantyExpiryDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(now.year + 25, now.month, now.day),
                      onPicked: (d) => _warrantyExpiryDate = d,
                    ),
                    onClear: () => setState(() => _warrantyExpiryDate = null),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const Key('edit_asset_notes_field'),
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Service notes, reminders, or accessories...',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFamilyFields(BuildContext context) {
    final now = DateTime.now();
    final relOptions = [
      ..._familyRelationships,
      if (!_familyRelationships.contains(_familyRelationship)) _familyRelationship,
    ];
    final bloodOptions = [
      ..._bloodTypes,
      if (!_bloodTypes.contains(_familyBloodType)) _familyBloodType,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: const Key('edit_family_relationship_dropdown'),
                isExpanded: true,
                initialValue: _familyRelationship,
                decoration: const InputDecoration(labelText: 'Relationship'),
                items: relOptions
                    .map((r) => DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _familyRelationship = val);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                key: const Key('edit_family_blood_type_dropdown'),
                isExpanded: true,
                initialValue: _familyBloodType,
                decoration: const InputDecoration(labelText: 'Blood Type'),
                items: bloodOptions
                    .map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _familyBloodType = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDatePickerTile(
          key: const Key('edit_family_birthdate_picker'),
          context: context,
          label: _familyBirthdate == null
              ? 'Birthdate (optional)'
              : 'Birthdate: ${_formatIsoDate(_familyBirthdate!)}',
          icon: Icons.cake_outlined,
          hasValue: _familyBirthdate != null,
          onTap: () => _pickCalendarDate(
            current: _familyBirthdate,
            firstDate: DateTime(1900),
            lastDate: DateTime(now.year, now.month, now.day),
            onPicked: (d) => _familyBirthdate = d,
          ),
          onClear: () => setState(() => _familyBirthdate = null),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('edit_family_phone_field'),
          controller: _familyPhoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Contact / Emergency Phone',
            hintText: 'e.g. +63 917 123 4567',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('edit_family_id_field'),
          controller: _familyIdNumberController,
          decoration: const InputDecoration(
            labelText: 'ID / Insurance / PhilHealth No.',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('edit_family_medical_notes_field'),
          controller: _familyMedicalNotesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Medical Notes & Allergies',
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerTile({
    Key? key,
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool hasValue,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: context.brandAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySecondary.copyWith(
                  color: hasValue ? context.textPrimary : context.textSecondary,
                  fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasValue)
              IconButton(
                tooltip: 'Clear date',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close, size: 18, color: context.textSecondary),
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomFieldsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.tune_outlined, size: 18, color: context.brandAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Custom Fields',
                  style: AppTypography.bodySecondary.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                key: const Key('edit_asset_add_custom_field'),
                onPressed: () => setState(() => _customFields.add(_EditableCustomField())),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
              ),
            ],
          ),
          if (_customFields.isEmpty)
            Text(
              'No extra custom fields.',
              style: AppTypography.caption.copyWith(color: context.textTertiary),
            )
          else
            for (var i = 0; i < _customFields.length; i++) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _customFields[i].keyController,
                      decoration: const InputDecoration(labelText: 'Label'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _customFields[i].valueController,
                      decoration: const InputDecoration(labelText: 'Value'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove field',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline, color: AppColors.statusDangerStroke),
                    onPressed: () {
                      setState(() {
                        final removed = _customFields.removeAt(i);
                        removed.dispose();
                      });
                    },
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }
}
