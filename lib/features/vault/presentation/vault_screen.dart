import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../records/domain/record.dart';
import '../../records/presentation/widgets/asset_picker_sheet.dart';
import '../../records/presentation/widgets/record_section_card.dart';
import '../domain/document_item.dart';
import '../domain/vault_asset_matcher.dart';

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
            icon: Icon(Icons.note_add_outlined, color: context.brandAccent),
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
              loading: () => Center(
                child: CircularProgressIndicator(color: context.brandAccent),
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
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const AddDocumentSheet(),
    );
  }

  void _openDocumentDetailModal(BuildContext context, RecordWithDocument item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
              borderRadius: BorderRadius.circular(999),
              onTap: () => onFilterSelected(opt.value),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandPrimary : context.surfaceCard,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected ? AppColors.brandPrimary : context.borderSubtle,
                  ),
                ),
                child: Text(
                  opt.label,
                  style: isSelected
                      ? AppTypography.bodyPrimary.copyWith(
                          color: AppColors.brandOnPrimary,
                          fontWeight: FontWeight.w600,
                        )
                      : AppTypography.bodySecondary.copyWith(
                          color: context.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
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
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? context.surfaceContainerLow : AppColors.brandAccentSage,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_outline, color: context.brandAccent, size: 36),
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
                decoration: BoxDecoration(
                  color: context.isDarkMode ? context.surfaceContainerLow : AppColors.brandAccentSage,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getDocumentIcon(docType),
                  color: context.brandAccent,
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
                            color: context.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: context.borderSubtle),
                          ),
                          child: Text(
                            docType.label.toUpperCase(),
                            style: AppTypography.badge.copyWith(color: context.textSecondary),
                          ),
                        ),

                        // Linked Asset Badge
                        if (item.linkedAssetTitle != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.isDarkMode ? context.surfaceContainerLow : AppColors.brandAccentSage,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.link, size: 12, color: context.brandAccent),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 140),
                                  child: Text(
                                    item.linkedAssetTitle!,
                                    style: AppTypography.badge.copyWith(color: context.brandAccent),
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
  final String? initialAssetRecordId;

  const AddDocumentSheet({super.key, this.initialAssetRecordId});

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
  String? _pickedFilePath;
  String? _pickedMimeType;
  bool _isSubmitting = false;
  bool _userDismissedAutoMatch = false;
  bool _wasAutoMatched = false;
  String? _autoMatchedReason;
  VaultAssetMatch? _topMatch;

  @override
  void initState() {
    super.initState();
    _selectedAssetRecordId = widget.initialAssetRecordId;
    _titleController.addListener(_onMetadataChanged);
    _fileNameController.addListener(_onMetadataChanged);
    _notesController.addListener(_onMetadataChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluateAutoMatch());
  }

  @override
  void dispose() {
    _titleController.removeListener(_onMetadataChanged);
    _fileNameController.removeListener(_onMetadataChanged);
    _notesController.removeListener(_onMetadataChanged);
    _titleController.dispose();
    _fileNameController.dispose();
    _fileSizeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<VaultAssetCandidate> _buildCandidates(
    List<RecordWithAsset> activeAssets,
    Map<String, String> plates,
  ) {
    return [
      for (final asset in activeAssets)
        VaultAssetCandidate(
          asset: asset,
          licensePlate: plates[asset.record.id],
        ),
    ];
  }

  void _onMetadataChanged() {
    _evaluateAutoMatch(rebuildAlways: true);
  }

  void _evaluateAutoMatch({bool rebuildAlways = false}) {
    if (!mounted) return;
    if (widget.initialAssetRecordId != null) {
      if (rebuildAlways) setState(() {});
      return;
    }

    final activeAssets = ref.read(activeAssetsStreamProvider).asData?.value ?? const [];
    final plates = ref.read(workspaceLicensePlatesStreamProvider).asData?.value ?? const {};
    final topMatch = VaultAssetMatcher.findMatchingAssetsForDocument(
      title: _titleController.text,
      fileName: _fileNameController.text,
      description: _notesController.text,
      candidates: _buildCandidates(activeAssets, plates),
    ).firstOrNull;

    var nextSelectedId = _selectedAssetRecordId;
    var nextWasAutoMatched = _wasAutoMatched;
    var nextReason = _autoMatchedReason;

    if (_wasAutoMatched) {
      if (topMatch != null && topMatch.shouldAutoPreselect && !_userDismissedAutoMatch) {
        nextSelectedId = topMatch.asset.record.id;
        nextReason = topMatch.reason;
      } else {
        nextSelectedId = null;
        nextWasAutoMatched = false;
        nextReason = null;
      }
    } else if (_selectedAssetRecordId == null &&
        topMatch != null &&
        topMatch.shouldAutoPreselect &&
        !_userDismissedAutoMatch) {
      nextSelectedId = topMatch.asset.record.id;
      nextWasAutoMatched = true;
      nextReason = topMatch.reason;
    }

    final changed = nextSelectedId != _selectedAssetRecordId ||
        nextWasAutoMatched != _wasAutoMatched ||
        nextReason != _autoMatchedReason ||
        topMatch?.asset.record.id != _topMatch?.asset.record.id ||
        topMatch?.reason != _topMatch?.reason;

    if (changed || rebuildAlways) {
      setState(() {
        _topMatch = topMatch;
        _selectedAssetRecordId = nextSelectedId;
        _wasAutoMatched = nextWasAutoMatched;
        _autoMatchedReason = nextReason;
      });
    }
  }

  String _detectMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return 'application/msword';
    if (lower.endsWith('.csv')) return 'text/csv';
    return 'application/octet-stream';
  }

  Future<void> _pickFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'txt', 'doc', 'docx', 'csv'],
      );

      if (file != null) {
        final fileSize = file.lengthSync() ?? await file.length();
        if (!mounted) return;
        setState(() {
          _pickedFilePath = file.path;
          _fileNameController.text = file.name;
          if (fileSize != null && fileSize > 0) {
            _fileSizeController.text = (fileSize / 1024).round().toString();
          }
          _pickedMimeType = _detectMimeType(file.name);
          if (_titleController.text.trim().isEmpty) {
            _titleController.text = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
          }
          final nameLower = file.name.toLowerCase();
          if (nameLower.contains('warranty')) {
            _documentType = DocumentType.warranty.value;
          } else if (nameLower.contains('receipt') || nameLower.contains('invoice')) {
            _documentType = DocumentType.receipt.value;
          } else if (nameLower.contains('manual') || nameLower.contains('guide')) {
            _documentType = DocumentType.manual.value;
          } else if (nameLower.contains('deed') || nameLower.contains('title') || nameLower.contains('or_cr')) {
            _documentType = DocumentType.deed.value;
          } else if (nameLower.contains('id') || nameLower.contains('license') || nameLower.contains('passport')) {
            _documentType = DocumentType.idCard.value;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File picker error: $e'),
            backgroundColor: AppColors.statusDangerStroke,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(documentRepositoryProvider);
      final recordId = const Uuid().v4();
      final now = DateTime.now().toUtc();
      final notes = _notesController.text.trim();
      final title = _titleController.text.trim();
      final fileName = _fileNameController.text.trim();

      String? savedFilePath;
      if (_pickedFilePath != null) {
        try {
          final appDocDir = await getApplicationDocumentsDirectory();
          final vaultDir = Directory('${appDocDir.path}/vault');
          if (!await vaultDir.exists()) {
            await vaultDir.create(recursive: true);
          }
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final safeFileName = '${timestamp}_${p.basename(fileName)}';
          final targetPath = '${vaultDir.path}/$safeFileName';
          await File(_pickedFilePath!).copy(targetPath);
          savedFilePath = targetPath;
        } catch (_) {
          savedFilePath = _pickedFilePath;
        }
      }

      final parsedSizeKb = int.tryParse(_fileSizeController.text.trim());
      final int? fileSizeBytes = parsedSizeKb != null && parsedSizeKb > 0
          ? parsedSizeKb * 1024
          : null;

      final mimeType = _pickedMimeType ?? _detectMimeType(fileName);

      await repo.createDocumentRecord(
        record: Record(
          id: recordId,
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'document',
          title: title,
          description: notes.isNotEmpty ? notes : null,
          createdAt: now,
          updatedAt: now,
        ),
        document: DocumentItem(
          recordId: recordId,
          fileName: fileName,
          filePath: savedFilePath,
          documentType: _documentType,
          fileSizeBytes: fileSizeBytes,
          mimeType: mimeType,
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
    ref.listen(activeAssetsStreamProvider, (_, _) => _evaluateAutoMatch());
    ref.listen(workspaceLicensePlatesStreamProvider, (_, _) => _evaluateAutoMatch());

    final sheetBg = Theme.of(context).bottomSheetTheme.backgroundColor ?? context.surfaceCard;
    final activeAssets = ref.watch(activeAssetsStreamProvider).asData?.value ?? const [];
    ref.watch(workspaceLicensePlatesStreamProvider);
    final topMatch = _topMatch;
    final linkedAssetTitle = _selectedAssetRecordId == null
        ? null
        : activeAssets
            .where((a) => a.record.id == _selectedAssetRecordId)
            .firstOrNull
            ?.record
            .title;

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
                    const Text('New Vault Document', style: AppTypography.sectionTitle),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Choose File Interactive Card
                InkWell(
                  onTap: _pickFile,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _pickedFilePath != null
                          ? (context.isDarkMode ? context.surfaceContainerLow : AppColors.brandAccentSage)
                          : context.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _pickedFilePath != null
                            ? (context.isDarkMode ? context.brandAccent : AppColors.brandAccentBorder)
                            : context.borderSubtle,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _pickedFilePath != null ? Icons.check_circle_outline : Icons.upload_file_outlined,
                          color: context.brandAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pickedFilePath != null ? 'File Attached from Device' : 'Choose File from Device',
                                style: AppTypography.cardTitle.copyWith(fontSize: 14),
                              ),
                              Text(
                                _pickedFilePath != null ? _fileNameController.text : 'Tap to auto-fill name, size & save copy',
                                style: AppTypography.caption.copyWith(color: context.textTertiary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _pickFile,
                          child: Text(_pickedFilePath != null ? 'Change' : 'Browse'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Document Title *',
                    hintText: 'e.g. Samsung Refrigerator Warranty',
                  ),
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
                        isExpanded: true,
                        initialValue: _documentType,
                        decoration: const InputDecoration(labelText: 'Document Type'),
                        items: DocumentType.values.map((t) {
                          return DropdownMenuItem(
                            value: t.value,
                            child: Text(t.label, overflow: TextOverflow.ellipsis),
                          );
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
                const SizedBox(height: 16),

                if (_wasAutoMatched && _selectedAssetRecordId != null && _autoMatchedReason != null) ...[
                  _buildAutoMatchBanner(
                    context,
                    assetTitle: linkedAssetTitle ?? 'Asset',
                    reason: _autoMatchedReason!,
                  ),
                  const SizedBox(height: 10),
                ] else if (widget.initialAssetRecordId == null &&
                    _selectedAssetRecordId == null &&
                    topMatch != null &&
                    !topMatch.shouldAutoPreselect) ...[
                  _buildSuggestedMatchBanner(context, topMatch),
                  const SizedBox(height: 10),
                ],

                // Reusable AssetPickerTile eliminating popup dropdown misalignment
                AssetPickerTile(
                  selectedAssetRecordId: _selectedAssetRecordId,
                  onAssetChanged: (assetId) {
                    setState(() {
                      _selectedAssetRecordId = assetId;
                      _wasAutoMatched = false;
                      _autoMatchedReason = null;
                      if (assetId == null) {
                        _userDismissedAutoMatch = true;
                      }
                    });
                  },
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Save Document'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoMatchBanner(
    BuildContext context, {
    required String assetTitle,
    required String reason,
  }) {
    return Container(
      key: const Key('vault_auto_match_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: adaptiveSageFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.brandAccent.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_outlined, size: 18, color: context.brandAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Auto-linked to $assetTitle ($reason)',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            key: const Key('vault_auto_match_unlink_button'),
            onPressed: () {
              setState(() {
                _userDismissedAutoMatch = true;
                _wasAutoMatched = false;
                _autoMatchedReason = null;
                _selectedAssetRecordId = null;
              });
            },
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedMatchBanner(BuildContext context, VaultAssetMatch match) {
    return Container(
      key: const Key('vault_suggested_match_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(Icons.link_outlined, size: 18, color: context.brandAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Suggested match: ${match.asset.record.title} (${match.reason})',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            key: const Key('vault_suggested_match_link_button'),
            onPressed: () {
              setState(() {
                _selectedAssetRecordId = match.asset.record.id;
                _wasAutoMatched = false;
                _autoMatchedReason = null;
              });
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }
}

class DocumentDetailSheet extends ConsumerStatefulWidget {
  final RecordWithDocument item;

  const DocumentDetailSheet({super.key, required this.item});

  @override
  ConsumerState<DocumentDetailSheet> createState() => _DocumentDetailSheetState();
}

class _DocumentDetailSheetState extends ConsumerState<DocumentDetailSheet> {
  bool _isUpdatingLink = false;

  Future<void> _updateLink({
    required RecordWithDocument currentItem,
    required String? targetAssetId,
    required String successMessage,
  }) async {
    if (_isUpdatingLink) return;
    setState(() => _isUpdatingLink = true);

    final previousAssetId = currentItem.document.linkedAssetRecordId;
    final colorScheme = Theme.of(context).colorScheme;

    try {
      await ref.read(documentRepositoryProvider).updateDocumentAssetLink(
            documentRecordId: currentItem.record.id,
            linkedAssetRecordId: targetAssetId,
          );
      ref.invalidate(activeDocumentsStreamProvider);
      ref.invalidate(dashboardDocumentsStreamProvider);
      if (previousAssetId != null) {
        ref.invalidate(assetDocumentsStreamProvider(previousAssetId));
      }
      if (targetAssetId != null) {
        ref.invalidate(assetDocumentsStreamProvider(targetAssetId));
      }

      if (!mounted) return;
      setState(() => _isUpdatingLink = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage, style: TextStyle(color: colorScheme.onPrimary)),
          backgroundColor: colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingLink = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update document link: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.statusDangerStroke,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveDocs = ref.watch(dashboardDocumentsStreamProvider).asData?.value;
    final currentItem =
        liveDocs?.where((d) => d.record.id == widget.item.record.id).firstOrNull ?? widget.item;
    final record = currentItem.record;
    final doc = currentItem.document;
    final docType = DocumentType.fromString(doc.documentType);
    final sheetBg = Theme.of(context).bottomSheetTheme.backgroundColor ?? context.surfaceCard;
    final dangerForeground =
        context.isDarkMode ? AppColors.statusDangerStroke : AppColors.statusDangerText;

    final activeAssets = ref.watch(activeAssetsStreamProvider).asData?.value ?? const [];
    final plates = ref.watch(workspaceLicensePlatesStreamProvider).asData?.value ?? const {};
    final suggestedMatch = doc.linkedAssetRecordId != null
        ? null
        : VaultAssetMatcher.findMatchingAssetsForDocument(
            title: record.title,
            fileName: doc.fileName,
            description: record.description,
            candidates: [
              for (final a in activeAssets)
                VaultAssetCandidate(asset: a, licensePlate: plates[a.record.id]),
            ],
          ).firstOrNull;

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
                      style: AppTypography.pageHeader.copyWith(
                        fontSize: 22,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textSecondary),
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
                      _buildDetailRow(context, 'Document Type', docType.label.toUpperCase()),
                      const Divider(),
                      _buildDetailRow(context, 'File Name', doc.fileName),
                      const Divider(),
                      _buildDetailRow(context, 'File Size', doc.formattedFileSize),
                      if (doc.mimeType != null) ...[
                        const Divider(),
                        _buildDetailRow(context, 'MIME Type', doc.mimeType!),
                      ],
                      if (doc.linkedAssetRecordId != null) ...[
                        const Divider(),
                        _buildLinkedAssetRow(context, currentItem),
                      ],
                      if (record.description != null && record.description!.isNotEmpty) ...[
                        const Divider(),
                        _buildDetailRow(context, 'Notes', record.description!),
                      ],
                    ],
                  ),
                ),
              ),
              if (suggestedMatch != null) ...[
                const SizedBox(height: 14),
                _buildSuggestedMatchCard(context, currentItem, suggestedMatch),
              ],
              const SizedBox(height: 16),
              if (doc.filePath != null && doc.filePath!.isNotEmpty) ...[
                FilledButton.icon(
                  onPressed: () async {
                    final result = await OpenFilex.open(doc.filePath!);
                    if (result.type != ResultType.done && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not open file: ${result.message}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: AppColors.statusDangerStroke,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.file_open_outlined),
                  label: const Text('Open / View Document'),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: dangerForeground,
                  side: const BorderSide(color: AppColors.statusDangerStroke),
                ),
                onPressed: _isUpdatingLink
                    ? null
                    : () => _confirmDeleteDocument(context, ref, record.id, record.title),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Move to Trash'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkedAssetRow(BuildContext context, RecordWithDocument currentItem) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            'Linked Asset',
            style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              currentItem.linkedAssetTitle ?? 'Archived / Deleted Asset',
              textAlign: TextAlign.end,
              style: AppTypography.bodyPrimary.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            key: const Key('vault_unlink_asset_button'),
            onPressed: _isUpdatingLink
                ? null
                : () => _updateLink(
                      currentItem: currentItem,
                      targetAssetId: null,
                      successMessage: 'Unlinked "${currentItem.record.title}" from asset.',
                    ),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedMatchCard(
    BuildContext context,
    RecordWithDocument currentItem,
    VaultAssetMatch match,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('vault_detail_suggested_match_card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: adaptiveSageFill(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.brandAccent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_outlined, size: 20, color: context.brandAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Asset Match',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.brandAccent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  match.asset.record.title,
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 14,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  match.reason,
                  style: AppTypography.caption.copyWith(color: context.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            key: const Key('vault_detail_connect_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: _isUpdatingLink
                ? null
                : () => _updateLink(
                      currentItem: currentItem,
                      targetAssetId: match.asset.record.id,
                      successMessage: 'Connected to ${match.asset.record.title}.',
                    ),
            child: _isUpdatingLink
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.bodyPrimary.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDocument(BuildContext context, WidgetRef ref, String recordId, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.sheetRadius),
          side: BorderSide(color: ctx.borderSubtle),
        ),
        title: Text(
          'Move to Trash?',
          style: AppTypography.cardTitle.copyWith(color: ctx.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove "$title"?',
          style: AppTypography.bodyPrimary.copyWith(color: ctx.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDangerStroke,
              foregroundColor: Colors.white,
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
                    content: Text(
                      'Moved "$title" to trash',
                      style: TextStyle(color: colorScheme.onPrimary),
                    ),
                    backgroundColor: colorScheme.primary,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to delete document: $e',
                      style: const TextStyle(color: Colors.white),
                    ),
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
