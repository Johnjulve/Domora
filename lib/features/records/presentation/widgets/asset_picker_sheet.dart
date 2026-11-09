import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/record.dart';

/// Reusable modal sheet to select an associated asset.
Future<String?> showAssetPickerModal({
  required BuildContext context,
  required List<RecordWithAsset> assets,
  required String? selectedAssetRecordId,
  String noneLabel = 'None (General)',
}) {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final sheetBg = Theme.of(ctx).bottomSheetTheme.backgroundColor ?? ctx.surfaceCard;
      return Material(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select Associated Asset', style: AppTypography.cardTitle),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ListTile(
                      leading: Icon(Icons.do_not_disturb_alt_outlined, color: ctx.textSecondary),
                      title: Text(noneLabel),
                      trailing: selectedAssetRecordId == null
                          ? Icon(Icons.check, color: ctx.brandAccent)
                          : null,
                      onTap: () => Navigator.of(ctx).pop(null),
                    ),
                    ...assets.map((item) {
                      final isSelected = item.record.id == selectedAssetRecordId;
                      final subtitleParts = [
                        if (item.asset?.brand != null && item.asset!.brand!.isNotEmpty) item.asset!.brand!,
                        if (item.asset?.model != null && item.asset!.model!.isNotEmpty) item.asset!.model!,
                        if (item.asset?.odometerReading != null) '${item.asset!.odometerReading} km',
                      ];
                      return ListTile(
                        leading: Icon(
                          item.record.categoryId == 'cat-vehicles'
                              ? Icons.directions_car_outlined
                              : Icons.inventory_2_outlined,
                          color: ctx.brandAccent,
                        ),
                        title: Text(item.record.title, style: AppTypography.bodyPrimary),
                        subtitle: subtitleParts.isNotEmpty
                            ? Text(subtitleParts.join(' • '), style: AppTypography.caption)
                            : null,
                        trailing: isSelected
                            ? Icon(Icons.check, color: ctx.brandAccent)
                            : null,
                        onTap: () => Navigator.of(ctx).pop(item.record.id),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Reusable form field tile that displays the selected asset with active async state handling.
class AssetPickerTile extends ConsumerWidget {
  final String? selectedAssetRecordId;
  final ValueChanged<String?> onAssetChanged;
  final String noneLabel;

  const AssetPickerTile({
    super.key,
    required this.selectedAssetRecordId,
    required this.onAssetChanged,
    this.noneLabel = 'None (General)',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(activeAssetsStreamProvider);

    return assetsAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderSubtle),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: context.brandAccent),
            ),
            const SizedBox(width: 12),
            const Text('Loading registered assets...', style: AppTypography.caption),
          ],
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.statusDangerFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.statusDangerStroke),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 18, color: AppColors.statusDangerText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Could not load assets: $err',
                style: AppTypography.caption.copyWith(color: AppColors.statusDangerText),
              ),
            ),
          ],
        ),
      ),
      data: (assets) {
        if (assets.isEmpty) return const SizedBox.shrink();

        final selectedAsset = selectedAssetRecordId == null
            ? null
            : assets.where((a) => a.record.id == selectedAssetRecordId).firstOrNull;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () async {
              final picked = await showAssetPickerModal(
                context: context,
                assets: assets,
                selectedAssetRecordId: selectedAssetRecordId,
                noneLabel: noneLabel,
              );
              onAssetChanged(picked);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, size: 20, color: context.brandAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Associated Property / Asset',
                          style: AppTypography.caption.copyWith(color: context.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedAsset != null ? selectedAsset.record.title : noneLabel,
                          style: AppTypography.bodyPrimary.copyWith(
                            color: selectedAsset != null
                                ? context.textPrimary
                                : context.textSecondary,
                            fontWeight: selectedAsset != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (selectedAsset != null)
                    IconButton(
                      icon: Icon(Icons.clear, size: 18, color: context.textSecondary),
                      onPressed: () => onAssetChanged(null),
                      tooltip: 'Unlink asset',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else
                    Icon(Icons.keyboard_arrow_down, size: 20, color: context.textSecondary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
