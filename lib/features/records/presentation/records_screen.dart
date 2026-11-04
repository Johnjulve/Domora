import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/record.dart';

class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(activeRecordsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.brandPrimary),
            tooltip: 'Add Record',
            onPressed: () => _openAddAssetModal(context),
          ),
        ],
      ),
      body: recordsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandPrimary),
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
                          child: const Icon(Icons.inventory_2_outlined, color: AppColors.brandPrimary, size: 36),
                        ),
                        const SizedBox(height: 20),
                        const Text('No Life Records Yet', style: AppTypography.cardTitle),
                        const SizedBox(height: 8),
                        const Text(
                          'Keep your property, vehicle, appliance warranties, and receipts organized in one place.',
                          style: AppTypography.bodySecondary,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _openAddAssetModal(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Asset'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: records.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              final item = records[index];
              final asset = item.asset;

              return Card(
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
                        Row(
                          children: [
                            if (asset.brand != null)
                              Text('${asset.brand} ', style: AppTypography.bodySecondary),
                            if (asset.model != null)
                              Text('• ${asset.model} ', style: AppTypography.bodySecondary),
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
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openAddAssetModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddAssetSheet(),
    );
  }
}

class _AddAssetSheet extends ConsumerStatefulWidget {
  const _AddAssetSheet();

  @override
  ConsumerState<_AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends ConsumerState<_AddAssetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _amountController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _amountController.dispose();
    _locationController.dispose();
    super.dispose();
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

      await repo.createAssetRecord(
        record: Record(
          id: recordId,
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: _titleController.text.trim(),
          createdAt: now,
          updatedAt: now,
        ),
        asset: Asset(
          recordId: recordId,
          brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
          model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
          purchaseAmountMinor: amountMinor,
          purchaseCurrency: AppConstants.defaultCurrency,
          locationDescription:
              _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        ),
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

  @override
  Widget build(BuildContext context) {
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
                  const Text('New Asset Record', style: AppTypography.sectionTitle),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Brand', hintText: 'e.g. Sony'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Model', hintText: 'e.g. Bravia 65" 4K'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Purchase Amount (${AppConstants.defaultCurrency})',
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location', hintText: 'e.g. Living Room'),
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
                    : const Text('Save Asset Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
