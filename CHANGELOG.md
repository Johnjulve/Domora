# Changelog

All notable changes to the Domora project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
