import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../records/domain/record.dart';
import '../domain/document_item.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(activeDocumentsStreamProvider);
    final selectedFilter = ref.watch(selectedVaultFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add_outlined, color: AppColors.brandPrimary),
            tooltip: 'Add Document',
            onPressed: () => _openAddDocumentModal(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _VaultFilterChips(
            selectedFilter: selectedFilter,
            onFilterSelected: (filter) => ref.read(selectedVaultFilterProvider.notifier).setFilter(filter),
          ),

          // Documents List
          Expanded(
            child: docsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.brandPrimary),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.statusDangerStroke, size: 48),
                      const SizedBox(height: 12),
                      const Text('Failed to load documents', style: AppTypography.cardTitle),
                      const SizedBox(height: 8),
                      Text(err.toString(), style: AppTypography.bodySecondary, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              data: (docs) {
                if (docs.isEmpty) {
                  return _VaultEmptyState(
                    selectedFilter: selectedFilter,
                    onAddDocumentPressed: () => _openAddDocumentModal(context),
                    onResetFilterPressed: () => ref.read(selectedVaultFilterProvider.notifier).setFilter('all'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = docs[index];
                    return _DocumentCard(
                      item: item,
                      onTap: () => _openDocumentDetailModal(context, item),
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

  void _openAddDocumentModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddDocumentSheet(),
    );
  }

  void _openDocumentDetailModal(BuildContext context, RecordWithDocument item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DocumentDetailSheet(item: item),
    );
  }
}

class _VaultFilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  const _VaultFilterChips({
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filterOptions = [
      (label: 'All', value: 'all'),
      (label: DocumentType.warranty.label, value: DocumentType.warranty.value),
      (label: DocumentType.receipt.label, value: DocumentType.receipt.value),
      (label: DocumentType.manual.label, value: DocumentType.manual.value),
      (label: DocumentType.deed.label, value: DocumentType.deed.value),
      (label: DocumentType.idCard.label, value: DocumentType.idCard.value),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: filterOptions.map((opt) {
          final isSelected = selectedFilter == opt.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onFilterSelected(opt.value),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandPrimary : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.brandPrimary : AppColors.borderSubtle,
                  ),
                ),
                child: Text(
                  opt.label,
                  style: isSelected
                      ? AppTypography.bodyPrimary.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        )
                      : AppTypography.bodySecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VaultEmptyState extends StatelessWidget {
  final String selectedFilter;
  final VoidCallback onAddDocumentPressed;
  final VoidCallback onResetFilterPressed;

  const _VaultEmptyState({
    required this.selectedFilter,
    required this.onAddDocumentPressed,
    required this.onResetFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
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
                  child: const Icon(Icons.lock_outline, color: AppColors.brandPrimary, size: 36),
                ),
                const SizedBox(height: 20),
                Text(
                  selectedFilter != 'all' ? 'No Matching Documents' : 'Encrypted Vault Empty',
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  selectedFilter != 'all'
                      ? 'Try selecting a different filter chip or adding a new document.'
                      : 'Store appliance warranties, purchase receipts, vehicle titles, and user manuals offline.',
                  style: AppTypography.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (selectedFilter == 'all')
                  ElevatedButton.icon(
                    onPressed: onAddDocumentPressed,
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Document'),
                  )
                else
                  OutlinedButton(
                    onPressed: onResetFilterPressed,
                    child: const Text('View All Documents'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final RecordWithDocument item;
  final VoidCallback onTap;

  const _DocumentCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final record = item.record;
    final doc = item.document;
    final docType = DocumentType.fromString(doc.documentType);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document Type Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.brandAccentSage,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getDocumentIcon(docType),
                  color: AppColors.brandPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Title and Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: AppTypography.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${doc.fileName} • ${doc.formattedFileSize}',
                      style: AppTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Type Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Text(
                            docType.label.toUpperCase(),
                            style: AppTypography.badge,
                          ),
                        ),

                        // Linked Asset Badge
                        if (item.linkedAssetTitle != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.brandAccentSage,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.link, size: 12, color: AppColors.brandPrimary),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 140),
                                  child: Text(
                                    item.linkedAssetTitle!,
                                    style: AppTypography.badge.copyWith(color: AppColors.brandPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
  }

  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.warranty:
        return Icons.verified_outlined;
      case DocumentType.receipt:
        return Icons.receipt_long_outlined;
      case DocumentType.manual:
        return Icons.menu_book_outlined;
      case DocumentType.deed:
        return Icons.home_work_outlined;
      case DocumentType.idCard:
        return Icons.badge_outlined;
      case DocumentType.general:
        return Icons.description_outlined;
    }
  }
}

class AddDocumentSheet extends ConsumerStatefulWidget {
  const AddDocumentSheet({super.key});

  @override
  ConsumerState<AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends ConsumerState<AddDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _fileNameController = TextEditingController();
  final _fileSizeController = TextEditingController();
  final _notesController = TextEditingController();
  String _documentType = DocumentType.warranty.value;
  String? _selectedAssetRecordId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _fileNameController.dispose();
    _fileSizeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _detectMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.txt')) return 'text/plain';
    return 'application/octet-stream';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(documentRepositoryProvider);
      final recordId = const Uuid().v4();
      final now = DateTime.now().toUtc();
      final fileName = _fileNameController.text.trim();
      final notes = _notesController.text.trim();

      final parsedSizeKb = int.tryParse(_fileSizeController.text.trim());
      final int? fileSizeBytes = parsedSizeKb != null && parsedSizeKb > 0
          ? parsedSizeKb * 1024
          : null;

      await repo.createDocumentRecord(
        record: Record(
          id: recordId,
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'document',
          title: _titleController.text.trim(),
          description: notes.isNotEmpty ? notes : null,
          createdAt: now,
          updatedAt: now,
        ),
        document: DocumentItem(
          recordId: recordId,
          fileName: fileName,
          documentType: _documentType,
          fileSizeBytes: fileSizeBytes,
          mimeType: _detectMimeType(fileName),
          linkedAssetRecordId: _selectedAssetRecordId,
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
            content: Text('Failed to save document: $e'),
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
                  const Text('New Vault Document', style: AppTypography.sectionTitle),
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
                  labelText: 'Document Title *',
                  hintText: 'e.g. Samsung Refrigerator Warranty',
                ),
                autofocus: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Document title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fileNameController,
                decoration: const InputDecoration(
                  labelText: 'File Name *',
                  hintText: 'e.g. warranty_card.pdf',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'File name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _documentType,
                      decoration: const InputDecoration(labelText: 'Document Type'),
                      items: DocumentType.values.map((t) {
                        return DropdownMenuItem(value: t.value, child: Text(t.label));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _documentType = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _fileSizeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'File Size (KB)',
                        hintText: 'e.g. 1024',
                      ),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final parsed = int.tryParse(val.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Enter positive number';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Coverage duration, claim procedures, policy numbers...',
                ),
                maxLines: 2,
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
                      hintText: 'Associate with property or possession',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('None (General Document)', overflow: TextOverflow.ellipsis),
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Document'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DocumentDetailSheet extends ConsumerWidget {
  final RecordWithDocument item;

  const DocumentDetailSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = item.record;
    final doc = item.document;
    final docType = DocumentType.fromString(doc.documentType);

    return Padding(
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
                    _buildDetailRow('Document Type', docType.label.toUpperCase()),
                    const Divider(),
                    _buildDetailRow('File Name', doc.fileName),
                    const Divider(),
                    _buildDetailRow('File Size', doc.formattedFileSize),
                    if (item.linkedAssetTitle != null) ...[
                      const Divider(),
                      _buildDetailRow('Linked Asset', item.linkedAssetTitle!),
                    ],
                    if (record.description != null && record.description!.isNotEmpty) ...[
                      const Divider(),
                      _buildDetailRow('Notes', record.description!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.statusDangerText,
                side: const BorderSide(color: AppColors.statusDangerStroke),
              ),
              onPressed: () => _confirmDeleteDocument(context, ref, record.id, record.title),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Move to Trash'),
            ),
          ],
        ),
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

  void _confirmDeleteDocument(BuildContext context, WidgetRef ref, String recordId, String title) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        title: const Text('Move to Trash?', style: AppTypography.cardTitle),
        content: Text(
          'Are you sure you want to remove "$title"?',
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
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();

              try {
                final repo = ref.read(documentRepositoryProvider);
                await repo.softDeleteDocument(recordId);

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Moved "$title" to trash'),
                    backgroundColor: AppColors.brandPrimary,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete document: $e'),
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
