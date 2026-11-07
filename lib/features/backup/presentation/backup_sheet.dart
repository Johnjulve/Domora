import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/backup_manifest.dart';

/// Modal bottom sheet for exporting, validating, and restoring Domora offline vaults.
class BackupSheet extends ConsumerStatefulWidget {
  const BackupSheet({super.key});

  @override
  ConsumerState<BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends ConsumerState<BackupSheet> {
  int _selectedTab = 0; // 0: Export Vault, 1: Restore Vault

  // Export State
  bool _isExporting = false;
  String? _exportedJson;
  BackupPayload? _exportedPayload;
  bool _showRawJson = false;

  // Restore State
  final _restoreController = TextEditingController();
  bool _isValidating = false;
  bool _isRestoring = false;
  BackupValidationResult? _validationResult;
  bool _clearExistingOnRestore = true;

  @override
  void dispose() {
    _restoreController.dispose();
    super.dispose();
  }

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final repo = ref.read(backupRepositoryProvider);
      final payload = await repo.createBackup(AppConstants.defaultWorkspaceId);
      final json = await repo.exportBackupToJson(AppConstants.defaultWorkspaceId);

      if (mounted) {
        setState(() {
          _exportedPayload = payload;
          _exportedJson = json;
          _isExporting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate backup: $e'),
            backgroundColor: AppColors.statusDangerStroke,
          ),
        );
      }
    }
  }

  Future<void> _handleValidate() async {
    final text = _restoreController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste a backup archive JSON payload first.')),
      );
      return;
    }

    setState(() {
      _isValidating = true;
      _validationResult = null;
    });

    try {
      final repo = ref.read(backupRepositoryProvider);
      final result = await repo.validateBackup(text);

      if (mounted) {
        setState(() {
          _validationResult = result;
          _isValidating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationResult = BackupValidationResult.invalid(
            status: BackupValidationStatus.corrupted,
            errorMessage: 'Validation exception: $e',
          );
          _isValidating = false;
        });
      }
    }
  }

  Future<void> _confirmAndRestore() async {
    final payload = _validationResult?.payload;
    final manifest = _validationResult?.manifest;
    if (payload == null || manifest == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Vault Restore'),
        content: Text(
          'This will atomically restore ${manifest.counts.totalItems} items into your workspace.\n\n'
          '${_clearExistingOnRestore ? "Existing workspace records will be cleared and replaced with this archive." : "Existing records will be updated with archive data."}\n\n'
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDangerStroke,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Restore Vault'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isRestoring = true;
    });

    try {
      final repo = ref.read(backupRepositoryProvider);
      await repo.restoreBackup(payload, clearExisting: _clearExistingOnRestore);

      // Invalidate all reactive streams across all features to refresh UI immediately
      ref.invalidate(defaultWorkspaceProvider);
      ref.invalidate(defaultCategoriesStreamProvider);
      ref.invalidate(activeRecordsStreamProvider);
      ref.invalidate(dashboardRecordsStreamProvider);
      ref.invalidate(activeTasksStreamProvider);
      ref.invalidate(dashboardTasksStreamProvider);
      ref.invalidate(activeDocumentsStreamProvider);
      ref.invalidate(dashboardDocumentsStreamProvider);
      ref.invalidate(activeAssetsStreamProvider);
      ref.invalidate(activeExpensesStreamProvider);
      ref.invalidate(dashboardExpensesStreamProvider);
      ref.invalidate(workspaceTotalExpensesProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sanctuary Vault restored successfully (${manifest.counts.totalItems} items imported).',
            ),
            backgroundColor: AppColors.brandPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore archive: $e'),
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
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Center drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandAccentSage,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.brandAccentBorder),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.brandPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sanctuary Archival',
                        style: AppTypography.cardTitle,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Portable offline vault & cryptographic backup engine',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Segmented Tab Selector
            Row(
              children: [
                Expanded(
                  child: _TabButton(
                    title: 'Export Vault',
                    icon: Icons.upload_file_outlined,
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TabButton(
                    title: 'Restore Vault',
                    icon: Icons.download_outlined,
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tab Content
            if (_selectedTab == 0) _buildExportSection() else _buildRestoreSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    final recordsAsync = ref.watch(dashboardRecordsStreamProvider);
    final tasksAsync = ref.watch(dashboardTasksStreamProvider);
    final docsAsync = ref.watch(dashboardDocumentsStreamProvider);
    final expensesAsync = ref.watch(dashboardExpensesStreamProvider);

    final String recordsDisplay = recordsAsync.when(
      data: (items) => '${items.length}',
      loading: () => '...',
      error: (_, _) => '!',
    );
    final String tasksDisplay = tasksAsync.when(
      data: (items) => '${items.length}',
      loading: () => '...',
      error: (_, _) => '!',
    );
    final String docsDisplay = docsAsync.when(
      data: (items) => '${items.length}',
      loading: () => '...',
      error: (_, _) => '!',
    );
    final String expensesDisplay = expensesAsync.when(
      data: (items) => '${items.length}',
      loading: () => '...',
      error: (_, _) => '!',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live Vault Stats Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Vault State',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  _SanctuaryStatusTag(label: 'Verified SQLite'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MetricPill(label: 'Records', value: recordsDisplay),
                  _MetricPill(label: 'Tasks', value: tasksDisplay),
                  _MetricPill(label: 'Vault Docs', value: docsDisplay),
                  _MetricPill(label: 'Expenses', value: expensesDisplay),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Generate Backup Button
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _handleExport,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
            foregroundColor: AppColors.brandOnPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: _isExporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.cloud_download_outlined, size: 20),
          label: Text(
            _isExporting ? 'Generating Archive...' : 'Create Backup Archive',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),

        // Export Results Card
        if (_exportedPayload != null && _exportedJson != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.statusSuccessFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.statusSuccessStroke.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.statusSuccessStroke,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Archive Generated & Verified',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.statusSuccessText,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Format v${_exportedPayload!.manifest.version}',
                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Contains ${_exportedPayload!.manifest.counts.totalItems} total entities from ${_exportedPayload!.manifest.workspaceName}.',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),

                // Checksum Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fingerprint, size: 16, color: AppColors.brandPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'SHA-256: ${_exportedPayload!.manifest.payloadChecksum}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: Colors.white,
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _exportedJson!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Backup archive JSON copied to clipboard.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy JSON'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                      onPressed: () => setState(() => _showRawJson = !_showRawJson),
                      icon: Icon(
                        _showRawJson ? Icons.visibility_off : Icons.visibility,
                        size: 16,
                      ),
                      label: Text(_showRawJson ? 'Hide' : 'Preview'),
                    ),
                  ],
                ),

                if (_showRawJson) ...[
                  const SizedBox(height: 10),
                  Container(
                    height: 120,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _exportedJson!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRestoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Integrity Advisory Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.brandAccentSage,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.brandAccentBorder),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined, color: AppColors.brandPrimary, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Restore operations verify format versions, JSON schema, and SHA-256 cryptographic checksums before touching the database. Unverified or altered archives are rolled back cleanly.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Paste JSON Text Area
        TextField(
          controller: _restoreController,
          maxLines: 5,
          minLines: 3,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: InputDecoration(
            labelText: 'Backup Archive JSON *',
            hintText: 'Paste the contents of your Domora backup archive here...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),

        // Helper Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data != null && data.text != null) {
                  _restoreController.text = data.text!;
                  setState(() => _validationResult = null);
                }
              },
              icon: const Icon(Icons.paste, size: 16),
              label: const Text('Paste'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                _restoreController.clear();
                setState(() => _validationResult = null);
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Validate Button
        OutlinedButton.icon(
          onPressed: _isValidating ? null : _handleValidate,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: _isValidating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.rule_outlined, size: 18),
          label: Text(_isValidating ? 'Validating Payload...' : 'Validate Archive Integrity'),
        ),

        // Validation Results Card
        if (_validationResult != null) ...[
          const SizedBox(height: 16),
          if (_validationResult!.isValid) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.statusSuccessFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.statusSuccessStroke.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        color: AppColors.statusSuccessStroke,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Archive Integrity Verified',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.statusSuccessText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Format v${_validationResult!.manifest!.version}',
                        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Workspace: ${_validationResult!.manifest!.workspaceName}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total items: ${_validationResult!.manifest!.counts.totalItems} '
                    '(${_validationResult!.manifest!.counts.records} records, '
                    '${_validationResult!.manifest!.counts.tasks} tasks, '
                    '${_validationResult!.manifest!.counts.documents} docs, '
                    '${_validationResult!.manifest!.counts.expenses} expenses)',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 12),
                  // Clear existing checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _clearExistingOnRestore,
                        activeColor: AppColors.brandPrimary,
                        onChanged: (val) {
                          setState(() {
                            _clearExistingOnRestore = val ?? true;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Replace existing workspace data completely',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isRestoring ? null : _confirmAndRestore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusDangerStroke,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isRestoring
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.restore, size: 20),
                    label: Text(
                      _isRestoring ? 'Restoring...' : 'Restore Vault Now',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.statusDangerFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.statusDangerStroke.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.statusDangerStroke,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Archive Rejected: ${_validationResult!.status.name.toUpperCase()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.statusDangerText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _validationResult!.errorMessage ?? 'Unknown validation failure.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.statusDangerText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.brandPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _SanctuaryStatusTag extends StatelessWidget {
  final String label;

  const _SanctuaryStatusTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.brandAccentSage,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.brandAccentBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.brandPrimary,
        ),
      ),
    );
  }
}
