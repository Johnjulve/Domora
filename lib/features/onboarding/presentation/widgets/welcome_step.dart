import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import 'terms_and_privacy_sheet.dart';

/// Step 0: Welcome presentation screen with mandatory Terms & Privacy gate.
class WelcomeStep extends ConsumerStatefulWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onOpenBackupSheet;

  const WelcomeStep({
    super.key,
    required this.onGetStarted,
    required this.onOpenBackupSheet,
  });

  @override
  ConsumerState<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends ConsumerState<WelcomeStep> {
  bool _hasAcceptedTerms = false;

  @override
  void initState() {
    super.initState();
    try {
      _hasAcceptedTerms = ref.read(appPreferencesProvider).hasAcceptedTerms;
    } catch (_) {
      _hasAcceptedTerms = false;
    }
  }

  Future<void> _openSheet(TermsDocumentType type) async {
    final agreed = await TermsAndPrivacySheet.show(context, documentType: type);
    if (agreed == true && mounted) {
      setState(() => _hasAcceptedTerms = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Brand Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.isDarkMode ? AppTheme.darkBrandPrimary : AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.eco,
                  color: AppColors.brandOnPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Domora',
                style: AppTypography.pageHeader.copyWith(
                  color: context.brandAccent,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Hero Visual Card
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: context.isDarkMode ? AppTheme.darkSurfaceCard : AppColors.brandPrimary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.borderSubtle),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.isDarkMode
                    ? [
                        AppTheme.darkSurfaceCard,
                        AppTheme.darkSurfaceContainerLow,
                        const Color(0xFF1B2820),
                      ]
                    : [
                        AppColors.brandHover,
                        AppColors.brandPrimary,
                        const Color(0xFF265A44),
                      ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.cottage_outlined,
                    size: 90,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                // Top-right Vault badge
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.surfaceCard.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: context.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield, size: 14, color: context.brandAccent),
                        const SizedBox(width: 4),
                        Text(
                          'VAULT',
                          style: AppTypography.badge.copyWith(
                            color: context.brandAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom-left Sanctuary label
                Positioned(
                  bottom: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.surfaceCard.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.spa, size: 14, color: context.brandAccent),
                        const SizedBox(width: 6),
                        Text(
                          'Living Sanctuary',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.brandAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Headline & Description
          Text(
            'Your home & life, in one safe place',
            style: AppTypography.pageHeader.copyWith(color: context.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'A calm, private archive for everything about your property, health, warranties, and vital records.',
            style: AppTypography.bodyPrimary.copyWith(color: context.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Feature Highlights Badges
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _FeatureBadge(icon: Icons.lock_outline, label: '100% on-device encryption'),
              _FeatureBadge(icon: Icons.visibility_off_outlined, label: 'Zero cloud tracking'),
            ],
          ),
          const SizedBox(height: 28),

          // Consent Checkbox & Legal Links (Mandatory Gate)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: context.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hasAcceptedTerms
                    ? context.brandAccent.withValues(alpha: 0.35)
                    : context.borderSubtle,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  key: const Key('terms_acceptance_checkbox'),
                  value: _hasAcceptedTerms,
                  activeColor: context.isDarkMode ? AppTheme.darkBrandPrimary : AppColors.brandPrimary,
                  checkColor: AppColors.brandOnPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  side: BorderSide(
                    color: context.borderSubtle,
                    width: 1.5,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _hasAcceptedTerms = val ?? false;
                    });
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _hasAcceptedTerms = !_hasAcceptedTerms),
                        child: Text(
                          'I agree to the ',
                          style: AppTypography.caption.copyWith(
                            color: context.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      GestureDetector(
                        key: const Key('terms_of_service_link'),
                        onTap: () => _openSheet(TermsDocumentType.termsOfService),
                        child: Text(
                          'Terms of Service',
                          style: AppTypography.caption.copyWith(
                            color: context.brandAccent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: context.brandAccent,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _hasAcceptedTerms = !_hasAcceptedTerms),
                        child: Text(
                          ' and ',
                          style: AppTypography.caption.copyWith(
                            color: context.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      GestureDetector(
                        key: const Key('privacy_policy_link'),
                        onTap: () => _openSheet(TermsDocumentType.privacyPolicy),
                        child: Text(
                          'Privacy Policy',
                          style: AppTypography.caption.copyWith(
                            color: context.brandAccent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: context.brandAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons (Gated by _hasAcceptedTerms)
          ElevatedButton(
            onPressed: _hasAcceptedTerms
                ? () async {
                    try {
                      await ref.read(appPreferencesProvider).setAcceptedTerms(true);
                    } catch (_) {}
                    if (!mounted) return;
                    widget.onGetStarted();
                  }
                : null,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Get Started'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _hasAcceptedTerms
                ? () async {
                    try {
                      await ref.read(appPreferencesProvider).setAcceptedTerms(true);
                    } catch (_) {}
                    if (!mounted) return;
                    widget.onOpenBackupSheet();
                  }
                : null,
            child: Text(
              'I already have a backup',
              style: AppTypography.bodySecondary.copyWith(
                color: _hasAcceptedTerms ? context.brandAccent : context.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 12, color: context.textTertiary),
              const SizedBox(width: 4),
              Text(
                'Private and encrypted. Only you can see your data.',
                style: AppTypography.caption.copyWith(color: context.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.brandAccent),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: context.brandAccent,
            ),
          ),
        ],
      ),
    );
  }
}
