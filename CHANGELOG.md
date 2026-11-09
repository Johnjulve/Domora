# Changelog

All notable changes to the Domora project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0-alpha.12] - 2026-11-09

### Added
- Visual Contrast & Dark Mode Collision Remediations:
  - Base Typography Dynamic Color Inheritance: Removed hardcoded `color` properties across all `AppTypography` base styles (`displayHero`, `pageHeader`, `sectionTitle`, `cardTitle`, `bodyPrimary`, `bodySecondary`, `caption`), allowing widgets to inherit the ambient text color from `DefaultTextStyle.of(context)`. Explicitly configured `lightTheme.textTheme` with light tokens and `darkTheme.textTheme` with calibrated dark tokens.
  - Zero-Boilerplate Theme Extension: Added `SanctuaryThemeContext` on `BuildContext` (`context.isDarkMode`, `context.surfaceCanvas`, `context.surfaceCard`, `context.textPrimary`, `context.textSecondary`, `context.textTertiary`, `context.borderSubtle`, `context.surfaceContainerLow`, `context.brandAccent`).
  - Onboarding Flow Dark Mode Harmonization: Removed hardcoded canvas backgrounds from `OnboardingScreen` `Scaffold` and `AppBar`. Converted option cards in `StorageChoiceStep` and recovery containers in `RecoveryKeyStep` to `context.surfaceCard`, eliminating white-on-white text collision on Dark Mode canvas. Themed `OnboardingProgressIndicator` active/inactive steps with high contrast tokens.
  - Records Screen Sheet & Metric Contrast: Updated `AddAssetSheet` and `AssetDetailSheet` container backgrounds to resolve `Theme.of(context).bottomSheetTheme.backgroundColor ?? Theme.of(context).cardColor`, eliminating stark white sheet clash with dark input fields. Replaced `AppColors.brandPrimary` on asset value, maintenance cost, and odometer metrics with `context.brandAccent` (`darkBrandSecondary` `#86CCA4`, achieving 8.9:1 WCAG AAA contrast against `darkSurfaceCard`).
- Sanctuary Archival Dark Theme Engine:
  - Centralized Semantic Dark Tokens on `AppTheme`: Added 9 dark design constants (`darkSurfaceCanvas`, `darkSurfaceCard`, `darkSurfaceContainerLow`, `darkBorderSubtle`, `darkBrandPrimary`, `darkBrandSecondary`, `darkTextPrimary`, `darkTextSecondary`, `darkTextTertiary`).
  - Material 3 Dark `ThemeData`: Configured dark canvas (`#121614`), elevated slate cards (`#1A201C`), inputs (`#222925`), and borders (`#2B342F`) matching Sanctuary Archival geometry.
  - Reactive `themeModeProvider`: State notifier in `app_preferences.dart` coordinating instant app-wide theme switching across `'light'`, `'dark'`, and `'system'` without app restarts.
  - Connected `MaterialApp` in `main.dart` with `theme: AppTheme.lightTheme`, `darkTheme: AppTheme.darkTheme`, and `themeMode: themeMode`.
  - Upgraded Appearance Segmented Control in `SettingsProfileScreen` to dynamically highlight active theme and reactively trigger theme switches.
- Direct APK 1-Tap Download on GitHub Release Update Checker:
  - Extracted release asset parsing engine checking for binaries ending in `.apk` with non-null `browser_download_url`.
  - Prominent "Download APK" button with `Icons.download_rounded` launching direct APK download via `LaunchMode.externalApplication`.
  - Honest fallback to "View Release" with `Icons.open_in_new_rounded` when an update tag has no uploaded APK asset yet.
- Native Biometric Hardware Enclave Authentication & App Lock Engine (Stage 11):
  - Integrated `local_auth` cross-platform biometric framework and updated Android `MainActivity` to `FlutterFragmentActivity` to support hardware enclave biometric dialogs.
  - `BiometricService`: Safe platform wrapper providing `isDeviceSupported`, `canCheckBiometrics`, and `authenticate` with defensive fallback on unsupported platforms and unit test harnesses.
  - `AppLockScreen` (Screen 4): Sanctuary-designed lock screen with warm canvas, concentric sage circle branding, fingerprint glyph, and primary "Unlock with Biometrics" trigger plus "Quick Unlock (Alpha Fallback)".
  - Lifecycle Auto-Lock Observer: `WidgetsBindingObserver` in `main.dart` monitoring backgrounding elapsed time against configured `autoLockDuration` ('Immediately', 'After 1 minute', 'After 5 minutes', 'After 15 minutes') to automatically re-lock the vault.
  - Navigator Leak Protection: Implemented global lock overlay via `MaterialApp.builder` and `Offstage`, ensuring all backgrounded routes, dialogs, and sheets are completely concealed while locked and restored intact upon authentication.
  - Onboarding Security Step Integration: Removed under-construction notice on `SecurityStep` biometric shield, allowing direct toggle and live visual feedback.
- Google Drive Cloud Redundancy UI & Zero-Knowledge Confirmation Sheet (Design Screens 11 & 12):
  - Live Google OAuth2 Web Client ID Integration: Added `google_sign_in: ^7.2.0`, configured Client ID `767402822106-btgbm208ccgv8n6fsh2g8umnajsimg44.apps.googleusercontent.com` in `web/index.html` meta tags and `GoogleAuthService`.
  - Sandboxed `drive.appdata` Scope: Restricts authorization strictly to Domora's isolated application folder on Google Drive, preserving complete zero-knowledge isolation from personal user documents.
  - `ConnectGoogleDriveConfirmationSheet` (Screen 12): Upgraded to interactive stateful modal with `PopScope(canPop: !_isLoading)` gesture lock during in-flight OAuth2 handshake, real-time loading feedback, error fallback snackbars, and authentic account email resolution (`account.email`).
  - Settings Backup & Restore Active State (Screen 11): Interactive Google Drive Backup card displaying active/paused status, connected email badge, master synchronization switch, "Back up on Wi-Fi only" toggle, and "Back up now" manual trigger with honest timestamp tracking.
  - 12-Word Recovery Passphrase Sheet: Added "Recovery Key" access row under the active Google Drive card allowing users to review and copy their BIP-39 recovery passphrase anytime.
  - Sign Out & Disconnect Flow: Added "Sign out of Google" action safely disconnecting from `GoogleSignIn`, clearing account metadata, and reverting storage mode to pure local offline.
  - Onboarding Integration: Replaced under-construction placeholder on Option 2 ("Continue with Google") in `StorageChoiceStep` with direct launch of `ConnectGoogleDriveConfirmationSheet`.
  - Refactored `_buildBackupCard` with extracted row components (`_buildExportDataRow`, `_buildPrintEmergencySheetRow`, `_buildSanctuaryRestoreRow`), ensuring consistent access to JSON vault snapshots and emergency info in both connected and disconnected states.
- Emergency Household Dossier & Export Engine (Stage 11):
  - `EmergencyInfoSheet` Sanctuary-styled modal bottom sheet compiling critical household information for family or executors.
  - Reactive extraction of household identity (name & address from `AppPreferences`), essential property & vehicles with VIN/plate and serials, utility obligations & account numbers, and vital documents/policies with registration metadata.
  - Unfiltered Cross-Feature Stream Binding: Wired to `dashboardBillsStreamProvider` and `dashboardDocumentsStreamProvider` to guarantee transient UI tab filters do not inadvertently mask utility accounts or legal deeds in the dossier.
  - 1-Tap "Copy Dossier" Action: Formats an organized markdown/plain-text emergency dossier with timestamps and writes directly to system clipboard (`Clipboard.setData`) with visual SnackBar feedback.
  - Robust UI Protections: Fully tokenized with Sanctuary design tokens (`AppColors`, `AppTypography`), layout overflow protection for long addresses, and solid `AppColors.surfaceCard` with `AppTheme.sheetRadius` (24px).
  - Integrated into `SettingsProfileScreen` replacing legacy under-construction notice on the 'Print Emergency Info Sheet' row.
- UI Versioning Standardization:
  - Standardized consumer-facing UI surfaces (e.g. Settings footer and headers) to display clean `Domora v0.1.0` (`AppConstants.displayVersion`), removing pre-release channel noise from primary user touchpoints.
  - Preserved full technical versioning (`Build 12 • Offline Sanctuary (alpha.12)`) in the technical "App Version & Updates" diagnostic tile for GitHub releases tracking.
- 47 new automated unit and widget tests covering emergency dossier rendering, Google Drive live redundancy flows, native biometric lock enforcement, dark theme switching, and visual contrast collision verification (153 total passing tests, 0 analysis issues).

## [0.1.0-alpha.11] - 2026-11-09

### Added
- Tasks & Routines Screen Overhaul (Stage 10):
  - Visual Agenda Hierarchy: Overdue bucket, Today counter badge, and Upcoming cadence routines with visual recurrence tags (`Every 3 months`, `Weekly`, `Yearly`).
  - Mindful Home Pace Banner: Encouraging progress summary and daily cadence pacing.
  - Interactive Snooze & Reschedule Action: Modal sheet allowing 1-tap rescheduling (`Tomorrow`, `Next Week`, or custom calendar date) updating Drift database in an atomic transaction.
  - Task Creation Flow: Reusable `AssetPickerTile` integration, recurrence selector, and status chips.
- First-Run Sanctuary Onboarding Flow:
  - 5-Step Carousel: Welcome hero screen with encryption assurance, How It Works zero-knowledge cards, Local Storage choice, Biometric App Lock configuration, and 12-Word BIP-39 Passphrase Recovery screen.
  - App Preferences Persistence: Local JSON-backed persistence (`app_preferences.json`) tracking onboarding completion, storage mode, and biometric lock state across app launches.
  - Modal Surface Opacity & Radius Standardization: Standardized all 9 bottom sheets to use solid `surfaceCard` backgrounds with `AppTheme.sheetRadius` (24px), eliminating transparency bleed-through.
- Full Settings & Profile Screen:
  - Sanctuary Profile Card: Editable household name and address with persistent storage in `AppPreferences`.
  - Privacy & Security Management: Biometric App Lock toggle, configurable Auto-lock duration ('Immediately', 'After 1 minute', 'After 5 minutes', 'After 15 minutes'), and *"How your data is protected"* explainer sheet.
  - Storage Usage Breakdown: Calculated on-device SQLite database and document vault sizes with a one-tap cache-clearing action.
  - Danger Zone Data Wipe: Red warning card opening confirmation modal requiring typing exact token "ERASE" to confirm, purging all Drift database tables in foreign-key order, wiping preferences, and resetting to the onboarding flow.
  - GitHub Releases Update Checker: Embedded update checking with release tier detection and external download launcher.
- Background Local Notifications Engine:
  - Added `flutter_local_notifications` and `timezone` for cross-platform local notification scheduling.
  - `NotificationService`: Channel registration (`domora_household_channel`, High importance), timezone-aware daily household digest scheduling, task due date alerts, and defensive non-crashing fallbacks for unit test harnesses and desktop platforms.
  - Seamlessly bound daily reminder time picker in `SettingsProfileScreen` to schedule daily recurring household notifications.
- 23 new automated unit and widget tests covering tasks overhaul, onboarding flow, settings screen interactions, and notification scheduling (106 total passing tests, 0 analysis issues).

## [0.1.0-alpha.10] - 2026-11-08

### Added
- Vehicle PMS Limits & Maintenance Auto-Scheduling Engine (Stage 9):
  - Drift SQLite Schema Migration (v6 -> v7): Added `odometerReading`, `pmsDistanceIntervalKm`, `pmsTimeIntervalMonths`, `nextPmsDueDate`, and `nextPmsOdometerTarget` to `Assets` table. Added `odometerReading` to `Expenses` table.
  - Chronological Odometer Integrity: `ExpenseRepositoryImpl` synchronizes vehicle mileage on maintenance logging, with monotonic guards preventing older backfilled receipts from overwriting a higher current odometer reading. Zero-drift calendar month math replaces 30-day interval approximations.
  - Automated Next-PMS Reminder Workflow: Logging maintenance with an odometer reading prompts the user to auto-schedule the upcoming PMS reminder task (`Next PMS ($nextTargetMileage km) - $vehicleTitle`) and persists target milestones to the vehicle asset.
  - Reusable UI & Usability Polish:
    - Extracted `AssetPickerTile` and `showAssetPickerModal` with full Riverpod `AsyncValue` loading and error states, eliminating floating popup dropdown menu misalignments in bottom sheets.
    - Added Vehicle PMS Limits & Odometer configuration section to `AddAssetSheet` and inspection rows to `AssetDetailSheet`.
    - Protected bottom sheets against accidental dismissal and draft reset during app switching.
    - Added subtle version indicator (`Domora v0.1.0 • Offline Sanctuary`) at the footer of `TodayScreen`.
- Vehicle Service History Timeline & Asset Attachments:
  - Interactive `_AssetServiceHistorySection` in `AssetDetailSheet` rendering chronological maintenance events, recorded odometer mileage, mileage delta from previous service (`+$delta km delta`), and costs.
  - Direct 1-tap document attachment button on assets and reactive `_AssetLinkedDocumentsSection` displaying attached warranties, manuals, or titles.
- Device File Picker & Sanctuary Document Vault Storage:
  - Integrated `file_picker` and Android storage permissions in `AddDocumentSheet` to select device files (PDF, images, Office docs, text) with automatic extraction of file name, byte size, and MIME type.
  - Local persistence copying picked files into the app documents vault folder (`app_flutter/vault/`) with persistent `filePath`.
  - Integrated `open_filex` for 1-tap local document opening and inspection in `DocumentDetailSheet`.
- App Settings & Live GitHub Software Update Checker:
  - Added Settings & Preferences sheet (`SettingsSheet`) triggered from upper-right app bar action in `TodayScreen`.
  - Declared `INTERNET` and `ACCESS_NETWORK_STATE` permissions in `AndroidManifest.xml`.
  - Automated network update checker querying GitHub Releases API with offline fallback and direct release download launcher via `url_launcher`.
- Automated test suites in `test/features/records/service_history_test.dart` and `test/features/today/settings_sheet_test.dart` (83 total passing tests, 0 analyzer issues).

## [0.1.0-alpha.9] - 2026-11-07

### Added
- Household Utilities & Recurring Bills Engine (Stage 8):
  - Schema Migration (v5 -> v6): Added `Bills` specialized table linked 1-to-1 to a parent universal `Record` with financial integer precision in minor units (`amountDueMinor`), ISO currency codes (`currencyCode`), utility type taxonomy (`electricity`, `water`, `internet`, `rent`, `insurance`, `subscription`, `trash`, `other`), provider/account details, billing period, due date, payment status (`unpaid`, `paid`, `overdue`, `cancelled`), and payment timestamp (`paidAt`). Added `linkedBillRecordId` on `Expenses` table.
  - Automated Transactional Bridge: Calling `markBillAsPaid` automatically logs a linked `Expense` entity with `expenseCategory: 'utility'`, bridges relationships between the bills and expenses tables, and updates bill status atomically within a single SQLite transaction, preventing duplicate entry and rolling into total workspace expenses.
  - Backup & Dataset Portability Integration (Schema v6): `BackupManifest` and `BackupRepositoryImpl` serialize, validate SHA-256 integrity, and atomically restore `bills` with complete topological foreign-key ordering and zero data corruption.
  - Presentation & UI Engine:
    - `AddBillSheet`: Full utility bill obligation creation with utility type selector, integer minor precision, date pickers for billing period and due date, optional asset linking, and validation.
    - `BillDetailSheet`: Detailed inspection modal showing utility type icons, due date, account/provider details, 1-tap "Mark as Paid" with payment confirmation dialog, and "Move to Trash" soft deletion.
    - `TodayScreen`: Dedicated "Upcoming & Overdue Bills" focus section with `_BillFocusTile`, status badges (`DUE SOON`, `OVERDUE`), and reactive update feeds.
    - `RecordsScreen`: Added `Add Utility Bill` action in AppBar and polymorphic card tapping routing `bill` records directly to `BillDetailSheet`.
- 8 new automated unit and widget tests covering Drift schema v6, automated expense bridge, date boundary logic (`isDueToday`, `isPastDueAt`), backup/restore integrity, and AppShell UI navigation flows (76 total passing tests, 0 analysis issues).

## [0.1.0-alpha.8] - 2026-11-06

### Added
- Reliability, Backup & Dataset Portability Engine (Stage 7):
  - Pure domain models `BackupCounts`, `BackupManifest`, `BackupPayload`, and `BackupValidationResult` with cryptographic SHA-256 integrity verification.
  - `BackupRepositoryImpl` extracting and restoring all 7 workspace tables (`workspaces`, `categories`, `records`, `assets`, `tasks`, `documents`, `expenses`) with topological foreign-key ordering.
  - Atomic transactional restore routine (`_db.transaction`) guaranteeing complete rollback on corrupted archives or foreign-key violations, preventing database corruption.
  - Sanctuary Archival Presentation Sheet (`BackupSheet`):
    - Export Vault: live vault statistics, one-click backup generation, manifest summary, SHA-256 fingerprint chip, clipboard copy, and expandable JSON preview.
    - Restore Vault: clipboard paste, pre-restore schema & SHA-256 verification, destructive overwrite warning dialog, complete workspace replacement toggle, and automatic multi-feature reactive stream invalidation.
  - Interactive Sanctuary Badge on `TodayScreen` app bar providing instant one-tap access to Sanctuary Archival & Backup engine.
- 10 new automated unit and widget tests covering backup creation, format version validation, checksum tampering rejection, atomic rollback, and UI backup/restore workflows (68 total passing tests, 0 analysis issues).

## [0.1.0-alpha.7] - 2026-11-06

### Added
- Schema Migration (v4 -> v5): Added `Expenses` table with foreign key indices on `linkedAssetRecordId`, `linkedTaskRecordId`, and `transactionDate`. Enforces exact financial minor-unit integer precision (`amountMinor`), ISO currency codes (`currencyCode`), and `ON DELETE SET NULL` upon parent asset or task deletion.
- Pure domain models `ExpenseItem`, `RecordWithExpense`, and `ExpenseCategory` enum (`maintenance`, `purchase`, `utility`, `service`, `subscription`, `other`) with currency formatting and payment method mapping.
- `ExpenseRepositoryImpl` providing atomic dual-table record transactions, reactive filtered streams (`watchExpensesByWorkspace`), and parent-decoupling outer joins enforcing `deletedAt.isNull()`.
- Total Cost of Ownership (TCO) Engine:
  - `AssetDetailSheet` computes and displays purchase price, accumulated maintenance/expenses, and Total Ownership Cost (Purchase Price + Maintenance) via reactive `assetTotalExpensesProvider`.
  - Direct "Log Maintenance / Expense" shortcut action on `AssetDetailSheet` pre-populating the linked asset record.
- Today Dashboard Financial Rollup:
  - Added live `Recorded Expenses` metric card bound to `workspaceTotalExpensesProvider`.
  - Added `Log Cost` quick action button opening `AddExpenseSheet`.
  - Integrated expense activity into `Recent Records Activity` feed with dedicated `EXPENSE` tag and `ExpenseDetailSheet` inspection.
- 9 new automated unit and widget tests covering expense lifecycle, task/asset linking, cascading nullification, TCO calculations, and dashboard financial feeds (58 total passing tests, 0 analysis issues).

## [0.1.0-alpha.6] - 2026-11-05

### Added
- Flutter Web platform compilation support with `drift_flutter` and official WebAssembly SQLite binaries (`sqlite3.wasm` and `drift_worker.js` in `web/`).
- Shared database connection abstraction (`_openConnection`) providing native SQLite on mobile/desktop and WebAssembly in browsers.

## [0.1.0-alpha.5] - 2026-11-05

### Added
- Schema Migration (v3 -> v4): Added `Documents` table with dedicated foreign key index on `linkedAssetRecordId` and `documentType`, supporting full cascading deletes and `ON DELETE SET NULL` upon parent asset deletion.
- Pure domain models `DocumentItem`, `RecordWithDocument`, and calibrated `DocumentType` enum (`warranty`, `receipt`, `manual`, `deed`, `idCard`, `general`) with formatted file size computation.
- `DocumentRepositoryImpl` with transactional atomic record insertion, soft-deletion, and reactive filtered streams (`watchDocumentsByWorkspace`, `getDocumentsByWorkspace`).
- Interactive `VaultScreen` in persistent 4-tab application shell replacing the final placeholder:
  - Horizontal filter chips (`All`, `Warranty`, `Receipt`, `Manual`, `Deed / Title`, `ID Card`).
  - Document cards with document type iconography, file metadata, and linked asset association badges.
  - Quick document creation modal (`AddDocumentSheet`) supporting file title, filename, category selection, file size, optional notes, MIME type auto-detection, and optional asset association.
  - Document detail inspection sheet (`DocumentDetailSheet`) with full archival metadata and soft-delete confirmation dialog.
- Riverpod providers (`documentRepositoryProvider`, `selectedVaultFilterProvider`, `activeDocumentsStreamProvider`, `dashboardDocumentsStreamProvider`, `activeAssetsStreamProvider`).
- Comprehensive unit and widget tests in `test/features/vault/document_repository_test.dart` and `test/features/navigation/app_shell_test.dart` (49 total passing tests, 0 analyzer issues).
- Full application milestone reached: 100% of all 4 bottom tabs (`Today`, `Records`, `Vault`, `Tasks`) are interactive and powered by offline-first SQLite queries with zero mock metrics or inert placeholder screens.

## [0.1.0-alpha.4] - 2026-11-04

### Added
- Interactive `TodayScreen` dashboard replacing placeholder in the persistent 4-tab application shell.
- Dedicated, unfiltered dashboard stream providers (`dashboardTasksStreamProvider`, `dashboardRecordsStreamProvider`) guaranteeing strict metric isolation from transient UI tab filters.
- Temporal Sanctuary greeting header with time-calibrated greetings ("Good morning", "Good afternoon", "Good evening") and localized date headers.
- Real-time summary metric cards displaying live counts for Pending Tasks, Overdue alerts, and Total Registered Assets with scale-down overflow protection.
- Quick action shortcuts to launch `AddTaskSheet` and `AddAssetSheet` modals directly from the dashboard.
- "Today's Focus & Deadlines" agenda with priority-sorted overdue/due-today tasks, direct completion checkoff, and calm reassurance card when all items are caught up.
- Recent activity feed displaying chronological updates across assets and tasks with direct modal inspection.
- 2 new widget tests covering live dashboard metrics, focus completion, quick asset creation, and strict filter tab isolation (42 total passing tests).

## [0.1.0-alpha.3] - 2026-11-04

### Added
- Schema Migration (v2 -> v3): Added `Tasks` table with composite index (`status`, `dueDate`) and foreign key relationships (`taskRecord` cascade delete, `tasksForAsset` setNull on asset delete).
- Domain entities `TaskItem`, `RecordWithTask`, `TaskPriority`, and `TaskStatus` with deadline calculation helpers (`isDueToday`, `isOverdue`).
- `TaskRepositoryImpl` with transactional creation, status toggles, soft deletion, and reactive Drift streams.
- Interactive `TasksScreen` in persistent 4-tab shell with:
  - Scrollable filter chips (`Pending`, `Completed`, `All`).
  - Interactive status checkbox toggles with immediate database persistence.
  - Priority badges (`Urgent`, `High`, `Medium`, `Low`) aligned with Sanctuary design tokens.
  - Overflow-protected linked asset badges and deadline indicators.
  - Quick task creation bottom sheet (`_AddTaskSheet`) with date picker and optional asset linking.
  - Task detail inspection sheet (`_TaskDetailSheet`) with status toggles and safe soft-delete confirmation.
- 7 new automated unit and widget tests covering task creation, asset link cascading `setNull`, deadline discrimination, and UI tab workflows (40 total passing tests).

## [0.1.0-alpha.2] - 2026-11-04

### Added
- Schema Migration (v1 -> v2): Added `Categories` table with composite indexing and `categoryId` column to `Records` table with foreign key constraint.
- `Category` domain entity and `CategoryRepositoryImpl` providing category queries, custom creation, and reactive stream watching.
- Automatic seeding of 5 core sanctuary categories (`Properties`, `Vehicles`, `Appliances`, `Electronics`, `Family`) during cold boot.
- Multi-field search (title, description, brand, model, serial number, location) and category filtering in `RecordRepositoryImpl`.
- Real-time search bar and horizontal category chips on `RecordsScreen` wired to Riverpod notifiers (`recordSearchQueryProvider`, `selectedCategoryFilterProvider`).
- Asset inspection bottom sheet (`_AssetDetailSheet`) displaying full metadata, hardware specs, purchase value, and soft-delete confirmation dialog.
- 8 new unit and widget tests verifying schema migration, category repository seeding, real-time search filtering, and detail inspection sheet soft-deletion (33 total passing tests).

## [0.1.0-alpha.1] - 2026-11-04

### Added
- Offline-first SQLite persistence engine using Drift with WAL mode, foreign key cascade enforcement, and composite indexing.
- Pure domain models and repository contracts for `Workspace`, `Record`, and specialized `Asset` entities.
- Sanctuary Archival design system tokens (`AppColors`, `AppTypography`, `AppTheme`) based on Stitch design specs.
- Core 4-tab mobile application shell (`AppShell`) with active Riverpod state management and tab persistence via `IndexedStack`.
- Interactive `RecordsScreen` bound to live Drift reactive streams with real-time asset capture bottom sheet.
- Noticeable in-progress feedback dialogs (`showUnderConstructionNotice`) adhering to anti-mocking discipline.
- Automated test suite covering relational schemas, repositories, widget navigation, and stream lifecycle (25 passing tests).

## [0.1.0-alpha.0] - 2026-11-04

### Added
- Initialized repository and linked remote origin (`https://github.com/Johnjulve/Domora.git`).
- Integrated comprehensive product and architectural blueprint in `docs/product/Domora_Product_Blueprint.md`.
- Bootstrapped Flutter application skeleton (`com.domora.domora`) targeting Dart 3.12+ and Flutter 3.44+.
- Established standard Flutter and platform-specific `.gitignore`.
- Documented project vision, architectural stack, and roadmap in `README.md`.
