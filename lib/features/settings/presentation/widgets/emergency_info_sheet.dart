import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/app_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../bills/domain/bill_item.dart';
import '../../../records/domain/record.dart';
import '../../../vault/domain/document_item.dart';

/// Modal bottom sheet providing a physical/offline Emergency Household Dossier.
///
/// Bundles primary identity, essential property serial numbers/VINs,
/// active utility account numbers, and archival vault policies for rapid
/// reference during emergencies or legal handover.
class EmergencyInfoSheet extends ConsumerStatefulWidget {
  const EmergencyInfoSheet({super.key});

  @override
  ConsumerState<EmergencyInfoSheet> createState() => _EmergencyInfoSheetState();
}

class _EmergencyInfoSheetState extends ConsumerState<EmergencyInfoSheet> {
  bool _copied = false;

  String _formatDossierText({
    required String householdName,
    required String householdAddress,
    required List<RecordWithAsset> assets,
    required List<RecordWithBill> bills,
    required List<RecordWithDocument> documents,
  }) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    buffer.writeln('# EMERGENCY HOUSEHOLD DOSSIER');
    buffer.writeln('Generated: $dateStr • Domora ${AppConstants.displayVersion}');
    buffer.writeln('Confidential offline sanctuary dossier for household, property & utilities.');
    buffer.writeln();

    buffer.writeln('## 1. HOUSEHOLD & PRIMARY IDENTITY');
    buffer.writeln('- Household Name: $householdName');
    buffer.writeln('- Physical Address: $householdAddress');
    buffer.writeln('- Primary Sanctuary Workspace: ${AppConstants.defaultWorkspaceName}');
    buffer.writeln();

    buffer.writeln('## 2. ESSENTIAL PROPERTY & VEHICLES');
    if (assets.isEmpty) {
      buffer.writeln('- No property or vehicle records recorded.');
    } else {
      for (final item in assets) {
        final asset = item.asset;
        final details = <String>[];
        final brand = asset?.brand?.trim();
        if (brand != null && brand.isNotEmpty) {
          details.add('Brand: $brand');
        }
        final model = asset?.model?.trim();
        if (model != null && model.isNotEmpty) {
          details.add('Model: $model');
        }
        final serial = asset?.serialNumber?.trim();
        if (serial != null && serial.isNotEmpty) {
          details.add('Serial/VIN: $serial');
        }
        final loc = asset?.locationDescription?.trim();
        if (loc != null && loc.isNotEmpty) {
          details.add('Location: $loc');
        }
        final extra = details.isNotEmpty ? ' (${details.join(', ')})' : '';
        buffer.writeln('- ${item.record.title}$extra');
      }
    }
    buffer.writeln();

    buffer.writeln('## 3. UTILITY OBLIGATIONS & PROVIDERS');
    if (bills.isEmpty) {
      buffer.writeln('- No utility accounts recorded.');
    } else {
      for (final item in bills) {
        final bill = item.bill;
        final details = <String>[];
        final provider = bill.providerName?.trim();
        if (provider != null && provider.isNotEmpty) {
          details.add('Provider: $provider');
        }
        final utility = bill.utilityType.trim();
        if (utility.isNotEmpty) {
          details.add('Utility: $utility');
        }
        final account = bill.accountNumber?.trim();
        if (account != null && account.isNotEmpty) {
          details.add('Account: $account');
        }
        final extra = details.isNotEmpty ? ' [${details.join(' | ')}]' : '';
        buffer.writeln('- ${item.record.title}$extra');
      }
    }
    buffer.writeln();

    buffer.writeln('## 4. IMPORTANT DOCUMENTS & POLICIES');
    if (documents.isEmpty) {
      buffer.writeln('- No vault documents recorded.');
    } else {
      for (final item in documents) {
        final details = <String>[];
        details.add('Type: ${item.document.documentType}');
        final linked = item.linkedAssetTitle?.trim();
        if (linked != null && linked.isNotEmpty) {
          details.add('Linked Asset: $linked');
        }
        buffer.writeln('- ${item.record.title} (${details.join(', ')})');
      }
    }

    return buffer.toString();
  }

  Future<void> _handleCopyDossier({
    required String householdName,
    required String householdAddress,
    required List<RecordWithAsset> assets,
    required List<RecordWithBill> bills,
    required List<RecordWithDocument> documents,
  }) async {
    final text = _formatDossierText(
      householdName: householdName,
      householdAddress: householdAddress,
      assets: assets,
      bills: bills,
      documents: documents,
    );

    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      setState(() => _copied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency Household Dossier copied to clipboard'),
          backgroundColor: AppColors.brandPrimary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPreferencesProvider);
    final householdName = prefs.householdName;
    final householdAddress = prefs.householdAddress;

    // Use unfiltered streams for cross-feature aggregations to prevent active UI filters from masking records
    final assetsAsync = ref.watch(activeAssetsStreamProvider);
    final billsAsync = ref.watch(dashboardBillsStreamProvider);
    final documentsAsync = ref.watch(dashboardDocumentsStreamProvider);

    final assets = assetsAsync.value ?? const <RecordWithAsset>[];
    final bills = billsAsync.value ?? const <RecordWithBill>[];
    final documents = documentsAsync.value ?? const <RecordWithDocument>[];

    final mediaQuery = MediaQuery.of(context);
    final sheetBg = Theme.of(context).bottomSheetTheme.backgroundColor ?? context.surfaceCard;

    return Container(
      key: const Key('emergency_info_sheet'),
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
        border: Border(
          top: BorderSide(color: context.borderSubtle),
          left: BorderSide(color: context.borderSubtle),
          right: BorderSide(color: context.borderSubtle),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: mediaQuery.viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sanctuary Grab Handle (36x4)
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: BoxDecoration(
                color: context.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Sanctuary Header
          _buildHeader(context, householdName, householdAddress),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.borderSubtle),
          const SizedBox(height: 12),

          // Scrollable Sections
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card 1: Household & Primary Identity
                  _buildIdentityCard(context, householdName, householdAddress),
                  const SizedBox(height: 16),

                  // Card 2: Essential Property & Vehicles
                  _buildPropertySection(context, assetsAsync),
                  const SizedBox(height: 16),

                  // Card 3: Utility Obligations & Providers
                  _buildUtilitiesSection(context, billsAsync),
                  const SizedBox(height: 16),

                  // Card 4: Important Documents & Policies
                  _buildDocumentsSection(context, documentsAsync),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: context.borderSubtle),
          const SizedBox(height: 12),

          // Action Bar
          _buildActionBar(
            context: context,
            householdName: householdName,
            householdAddress: householdAddress,
            assets: assets,
            bills: bills,
            documents: documents,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String householdName, String householdAddress) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.isDarkMode ? context.surfaceContainerLow : AppColors.brandAccentSage,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.isDarkMode ? context.borderSubtle : AppColors.brandAccentBorder,
            ),
          ),
          child: Icon(
            Icons.shield_outlined,
            color: context.brandAccent,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emergency Household Dossier',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$householdName • $householdAddress',
                style: TextStyle(
                  fontSize: 12.5,
                  color: context.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.close_rounded, color: context.textSecondary),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildIdentityCard(BuildContext context, String householdName, String householdAddress) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home_outlined, size: 18, color: context.brandAccent),
              const SizedBox(width: 8),
              Text(
                'Household & Primary Identity',
                style: AppTypography.cardTitle.copyWith(fontSize: 14, color: context.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow(context, 'Household Name', householdName),
          const SizedBox(height: 6),
          _buildInfoRow(context, 'Physical Address', householdAddress),
          const SizedBox(height: 6),
          _buildInfoRow(context, 'Sanctuary Workspace', AppConstants.defaultWorkspaceName),
        ],
      ),
    );
  }

  Widget _buildPropertySection(BuildContext context, AsyncValue<List<RecordWithAsset>> assetsAsync) {
    return _buildSectionContainer(
      context: context,
      icon: Icons.directions_car_outlined,
      title: 'Essential Property & Vehicles',
      child: assetsAsync.when(
        loading: () => Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CircularProgressIndicator(strokeWidth: 2, color: context.brandAccent),
          ),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Error loading assets: $err', style: const TextStyle(color: AppColors.statusDangerText, fontSize: 13)),
        ),
        data: (assets) {
          if (assets.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No property or vehicle records recorded yet.',
                style: TextStyle(fontSize: 13, color: context.textSecondary),
              ),
            );
          }

          return Column(
            children: assets.map((item) {
              final asset = item.asset;
              final details = <String>[];
              if (asset?.brand != null && asset!.brand!.isNotEmpty) {
                details.add(asset.brand!);
              }
              if (asset?.model != null && asset!.model!.isNotEmpty) {
                details.add(asset.model!);
              }
              final modelSubtitle = details.isNotEmpty ? details.join(' ') : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.record.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        if (modelSubtitle != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            modelSubtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (asset?.serialNumber != null && asset!.serialNumber!.isNotEmpty)
                          Expanded(
                            child: Text(
                              'Serial/VIN: ${asset.serialNumber}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: context.brandAccent,
                              ),
                            ),
                          ),
                        if (asset?.locationDescription != null && asset!.locationDescription!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Loc: ${asset.locationDescription}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildUtilitiesSection(BuildContext context, AsyncValue<List<RecordWithBill>> billsAsync) {
    return _buildSectionContainer(
      context: context,
      icon: Icons.bolt_outlined,
      title: 'Utility Obligations & Providers',
      child: billsAsync.when(
        loading: () => Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CircularProgressIndicator(strokeWidth: 2, color: context.brandAccent),
          ),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Error loading utilities: $err', style: const TextStyle(color: AppColors.statusDangerText, fontSize: 13)),
        ),
        data: (bills) {
          if (bills.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No utility accounts recorded yet.',
                style: TextStyle(fontSize: 13, color: context.textSecondary),
              ),
            );
          }

          return Column(
            children: bills.map((item) {
              final bill = item.bill;
              final providerTitle = (bill.providerName != null && bill.providerName!.trim().isNotEmpty)
                  ? bill.providerName!
                  : item.record.title;
              final accountSubtitle = (bill.accountNumber != null && bill.accountNumber!.trim().isNotEmpty)
                  ? bill.accountNumber!
                  : 'N/A';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            providerTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Account: $accountSubtitle',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? context.surfaceContainerLow : AppColors.brandAccentSage,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bill.utilityType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.brandAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildDocumentsSection(BuildContext context, AsyncValue<List<RecordWithDocument>> documentsAsync) {
    return _buildSectionContainer(
      context: context,
      icon: Icons.description_outlined,
      title: 'Important Documents & Policies',
      child: documentsAsync.when(
        loading: () => Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CircularProgressIndicator(strokeWidth: 2, color: context.brandAccent),
          ),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Error loading documents: $err', style: const TextStyle(color: AppColors.statusDangerText, fontSize: 13)),
        ),
        data: (documents) {
          if (documents.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No vault documents recorded yet.',
                style: TextStyle(fontSize: 13, color: context.textSecondary),
              ),
            );
          }

          return Column(
            children: documents.map((item) {
              final doc = item.document;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.record.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                          if (item.linkedAssetTitle != null && item.linkedAssetTitle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Linked Asset: ${item.linkedAssetTitle}',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: context.borderSubtle),
                      ),
                      child: Text(
                        doc.documentType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildSectionContainer({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: context.brandAccent),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.cardTitle.copyWith(fontSize: 14, color: context.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar({
    required BuildContext context,
    required String householdName,
    required String householdAddress,
    required List<RecordWithAsset> assets,
    required List<RecordWithBill> bills,
    required List<RecordWithDocument> documents,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            key: const Key('copy_dossier_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.brandAccent,
              foregroundColor: context.isDarkMode ? AppColors.surfaceCanvas : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(
              _copied ? Icons.check_circle_outline_rounded : Icons.content_copy_rounded,
              size: 18,
            ),
            label: Text(
              _copied ? 'Dossier Copied' : 'Copy Dossier',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            onPressed: () => _handleCopyDossier(
              householdName: householdName,
              householdAddress: householdAddress,
              assets: assets,
              bills: bills,
              documents: documents,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: OutlinedButton(
            key: const Key('close_dossier_button'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.textPrimary,
              side: BorderSide(color: context.borderSubtle),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }
}
