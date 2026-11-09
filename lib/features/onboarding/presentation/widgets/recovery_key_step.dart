import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_shared_widgets.dart';

/// Step 4: Sanctuary Recovery Key generation and confirmation.
class RecoveryKeyStep extends StatefulWidget {
  final VoidCallback onFinish;

  const RecoveryKeyStep({super.key, required this.onFinish});

  @override
  State<RecoveryKeyStep> createState() => _RecoveryKeyStepState();
}

class _RecoveryKeyStepState extends State<RecoveryKeyStep> {
  static const List<String> _recoveryWords = [
    'anchor',
    'velvet',
    'summit',
    'cedar',
    'ember',
    'orchard',
    'meadow',
    'hearth',
    'pebble',
    'clover',
    'harbor',
    'willow',
  ];

  bool _hasCopiedKey = false;
  bool _hasConfirmedKey = false;

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnboardingProgressIndicator(activeStep: 4),
          const SizedBox(height: 16),
          const OnboardingCategoryPill(icon: Icons.verified_user_outlined, label: 'Zero-Knowledge Vault'),
          const SizedBox(height: 10),
          const Text('Save your recovery key', style: AppTypography.pageHeader),
          const SizedBox(height: 4),
          const Text(
            'Keep these 12 sanctuary words somewhere safe. They are your sole master key.',
            style: AppTypography.bodySecondary,
          ),
          const SizedBox(height: 16),

          // Important Warning Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.statusWarningFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.statusWarningStroke),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield, color: AppColors.statusWarningText, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Important Security Notice',
                        style: AppTypography.cardTitle.copyWith(
                          fontSize: 13,
                          color: AppColors.statusWarningText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "You'll need this to restore your data on a new phone. Because your records are privately encrypted on-device, we cannot recover it for you.",
                        style: AppTypography.caption.copyWith(color: AppColors.statusWarningText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 12-Word Passphrase Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.key, size: 16, color: context.brandAccent),
                          const SizedBox(width: 6),
                          const Text('12-Word Passphrase', style: AppTypography.cardTitle),
                        ],
                      ),
                      Text(
                        'BIP-39 Standard',
                        style: AppTypography.badge.copyWith(color: context.textTertiary),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // 3x4 Words Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: _recoveryWords.length,
                    itemBuilder: (ctx, idx) {
                      final numStr = (idx + 1).toString().padLeft(2, '0');
                      final word = _recoveryWords[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Text(
                              numStr,
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                color: context.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                word,
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Copy Action Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _recoveryWords.join(' ')));
                      setState(() => _hasCopiedKey = true);
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text('Recovery key copied to clipboard!'),
                          backgroundColor: context.brandAccent,
                        ),
                      );
                    },
                    icon: Icon(_hasCopiedKey ? Icons.check : Icons.copy, size: 16),
                    label: Text(_hasCopiedKey ? 'Copied to Clipboard' : 'Copy 12 Words'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Checkbox confirmation
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _hasConfirmedKey = !_hasConfirmedKey),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: context.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _hasConfirmedKey ? context.brandAccent : context.borderSubtle,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _hasConfirmedKey,
                    activeColor: context.brandAccent,
                    onChanged: (val) => setState(() => _hasConfirmedKey = val ?? false),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("I've saved my recovery key", style: AppTypography.cardTitle),
                        SizedBox(height: 2),
                        Text(
                          'I understand Domora cannot restore my records without it.',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Primary Finish Button
          ElevatedButton(
            onPressed: _hasConfirmedKey ? widget.onFinish : null,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Finish & Enter Domora'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
