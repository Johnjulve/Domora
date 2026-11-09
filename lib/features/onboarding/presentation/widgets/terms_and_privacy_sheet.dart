import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// Document type displayed inside [TermsAndPrivacySheet].
enum TermsDocumentType {
  termsOfService,
  privacyPolicy,
}

/// Sanctuary-styled modal bottom sheet displaying Domora's Terms of Service and Privacy Policy.
///
/// Implements zero tracking principles, 100% on-device SQLite storage disclosures,
/// AES hardware encryption transparency, self-custody BIP-39 recovery key terms,
/// and sandboxed user-owned Google Drive backup terms.
class TermsAndPrivacySheet extends StatefulWidget {
  final TermsDocumentType documentType;

  const TermsAndPrivacySheet({
    super.key,
    this.documentType = TermsDocumentType.termsOfService,
  });

  /// Convenience helper to display the sheet in a modal bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    TermsDocumentType documentType = TermsDocumentType.termsOfService,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TermsAndPrivacySheet(documentType: documentType),
    );
  }

  @override
  State<TermsAndPrivacySheet> createState() => _TermsAndPrivacySheetState();
}

class _TermsAndPrivacySheetState extends State<TermsAndPrivacySheet> {
  late TermsDocumentType _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.documentType;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTerms = _currentTab == TermsDocumentType.termsOfService;

    return Container(
      key: const Key('terms_and_privacy_sheet'),
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).bottomSheetTheme.backgroundColor ?? context.surfaceCard,
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

          // Header with Icon, Badge & Close Button
          _buildHeader(context),
          const SizedBox(height: 14),

          // Segmented Tab Switcher (Terms of Service vs Privacy Policy)
          _buildSegmentedSwitch(context),
          const SizedBox(height: 14),
          Divider(height: 1, color: context.borderSubtle),
          const SizedBox(height: 12),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: isTerms ? _buildTermsContent(context) : _buildPrivacyContent(context),
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: context.borderSubtle),
          const SizedBox(height: 12),

          // Done Action Button
          ElevatedButton(
            key: const Key('close_terms_sheet_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.isDarkMode ? AppTheme.darkBrandPrimary : AppColors.brandPrimary,
              foregroundColor: AppColors.brandOnPrimary,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('I Understand & Agree', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? AppTheme.darkBrandSecondary.withValues(alpha: 0.15)
                : AppColors.brandAccentSage,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderSubtle),
          ),
          child: Icon(
            Icons.shield_outlined,
            color: context.brandAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: context.borderSubtle),
                    ),
                    child: Text(
                      'OFFLINE SANCTUARY • ZERO TRACKING',
                      style: AppTypography.badge.copyWith(
                        fontSize: 10,
                        color: context.brandAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Terms & Privacy Policy',
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 17,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: const Key('dismiss_terms_sheet_icon_button'),
          icon: Icon(Icons.close_rounded, color: context.textSecondary, size: 22),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }

  Widget _buildSegmentedSwitch(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
              key: const Key('terms_tab_button'),
              label: 'Terms of Service',
              isSelected: _currentTab == TermsDocumentType.termsOfService,
              onTap: () => setState(() => _currentTab = TermsDocumentType.termsOfService),
            ),
          ),
          Expanded(
            child: _buildSegmentButton(
              key: const Key('privacy_tab_button'),
              label: 'Privacy Policy',
              isSelected: _currentTab == TermsDocumentType.privacyPolicy,
              onTap: () => setState(() => _currentTab = TermsDocumentType.privacyPolicy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required Key key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.surfaceCard : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? context.brandAccent : context.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPreambleCard(
          context,
          title: 'Welcome to Domora',
          subtitle:
              'Last Updated: November 2026 • Version ${AppConstants.displayVersion}\n'
              'Domora is an offline-first private sanctuary for managing vital household records, warranties, and assets. By using Domora, you enter into this agreement on the following foundational terms.',
        ),
        const SizedBox(height: 14),
        _buildClause(
          context,
          number: '1',
          title: 'Self-Sovereign Data Custody',
          content:
              'All information, documents, property details, and personal records entered into Domora belong exclusively to you. Domora operates on an offline-first, local-storage architecture. We do not maintain user accounts on remote company servers, nor do we claim any rights to your content.',
        ),
        _buildClause(
          context,
          number: '2',
          title: 'Master Recovery Key & Encryption',
          content:
              'Domora uses hardware-backed AES encryption and a 12-word BIP-39 recovery passphrase generated locally on your device. You are the sole custodian of your recovery key. If you forget your passphrase or lose device access without a backup, no entity—including the developers of Domora—can recover your data.',
        ),
        _buildClause(
          context,
          number: '3',
          title: 'Optional Cloud Backup (Google Drive)',
          content:
              'When you connect Google Drive, data snapshots are saved directly to your personal Google Drive sandboxed application folder (appDataFolder). Backups are authenticated directly with Google via OAuth. Domora servers never mediate or access these transfers.',
        ),
        _buildClause(
          context,
          number: '4',
          title: 'Permitted Use & Software License',
          content:
              'Domora grants you a personal, non-transferable, revocable license to use the application for private household and personal archiving purposes. You may not reverse engineer, decompile, or redistribute the proprietary packaging without authorization.',
        ),
        _buildClause(
          context,
          number: '5',
          title: 'Disclaimer of Warranties & Limitation of Liability',
          content:
              'Domora is provided "AS IS" and "AS AVAILABLE" without warranties of any kind. While engineered for maximum resilience with SQLite Write-Ahead Logging (WAL) and atomic transactions, we are not liable for data loss caused by hardware failure, operating system updates, or compromised passphrases.',
        ),
      ],
    );
  }

  Widget _buildPrivacyContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPreambleCard(
          context,
          title: 'Radical Privacy by Architecture',
          subtitle:
              'Last Updated: November 2026 • Version ${AppConstants.displayVersion}\n'
              'Domora is designed under the principle that what happens in your home stays in your home. Privacy is enforced through cryptographic math and local architecture, not just legal promises.',
        ),
        const SizedBox(height: 14),
        _buildClause(
          context,
          number: '1',
          title: 'Zero Tracking & Zero Analytics',
          content:
              'Domora contains no analytics SDKs, advertising trackers, device fingerprinting, or behavior monitors. We do not know who you are, how often you open the app, or what records you store.',
        ),
        _buildClause(
          context,
          number: '2',
          title: '100% On-Device SQLite Storage',
          content:
              'All asset data, tasks, notes, warranty expirations, and utility accounts reside strictly in a sandboxed SQLite database on your device filesystem. No data is synchronized to company servers.',
        ),
        _buildClause(
          context,
          number: '3',
          title: 'Hardware Keystore Biometrics',
          content:
              'When you enable biometric lock, authentication is handled solely by Android BiometricPrompt / iOS LocalAuthentication. Raw biometric identifiers (fingerprints, face data) never leave your device hardware.',
        ),
        _buildClause(
          context,
          number: '4',
          title: 'Sandboxed Google Drive Scope',
          content:
              'If cloud redundancy is enabled, Domora requests only the minimal "drive.appdata" permission. This isolates Domora backups to a private hidden application folder, preventing the app from seeing or accessing any other files in your Google Drive.',
        ),
        _buildClause(
          context,
          number: '5',
          title: 'Total Data Erasure Rights',
          content:
              'You maintain complete control to purge your data. The "Erase All Data" function in Settings immediately wipes all SQLite tables, temporary files, cached previews, and cryptographic preferences from this device.',
        ),
      ],
    );
  }

  Widget _buildPreambleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.brandAccent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClause(
    BuildContext context, {
    required String number,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(color: context.borderSubtle),
            ),
            child: Text(
              number,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.brandAccent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
