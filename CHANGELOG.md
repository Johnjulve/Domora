# Changelog

All notable changes to the Domora project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
