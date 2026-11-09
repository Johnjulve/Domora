# Domora — Personal Life OS

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Version](https://img.shields.io/badge/Version-0.1.0--alpha.12-emerald.svg)](CHANGELOG.md)
[![Automated Tests](https://img.shields.io/badge/Tests-163%20Passing-success.svg)](CHANGELOG.md)
[![Aesthetic](https://img.shields.io/badge/Design-Sanctuary%20Archival-1E4B38.svg)](docs/design/Design/domora_design.md)

> **Know what you have, what needs attention, what it costs, and what you need to do next.**

Domora is an offline-first, local-ownership personal and household management platform built with **Flutter**. It unifies everyday possessions, schedules, expenses, documents, utilities, and responsibilities into one structured, relational sanctuary.

---

## 🌟 Core Pillars

1. **Capture Once, Reuse Everywhere**: An invoice or receipt connects to an asset, maintenance record, and expense without duplicate entry.
2. **Offline-First by Default**: 100% on-device SQLite database with zero telemetric tracking, local AES encryption, and BIP-39 recovery keys.
3. **Structured Yet Extensible**: Strongly typed core entities (assets, tasks, bills, expenses) with user-defined custom categories, tags, and field definitions.
4. **Hardware Enclave Security & App Lock**: Hardware-backed biometric authentication (Face ID / Fingerprint) paired with offstage navigator masking to conceal sensitive records on app backgrounding.
5. **Zero-Knowledge Cloud Redundancy**: Optional backup to Google Drive sandboxed strictly to Domora's private application folder (`drive.appdata`), isolated from personal files.
6. **Sanctuary Archival Design Engine**: Minimalist tactile stationery aesthetic with dual light parchment and dark woodland-slate palettes calibrated for **8.9:1 WCAG AAA** contrast.
7. **Emergency Household Dossier**: 1-tap compilation and markdown clipboard export of critical property, vehicle, utility, and legal deed records for family or executors.

---

## 🏗 Architecture & Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart 3.x) — mobile-first (Android target)
- **Local Persistence**: SQLite via [Drift](https://drift.simonbinder.eu/) (strongly-typed DAOs, transactions, and schema migrations through v7)
- **State Management**: [Riverpod 3.x](https://riverpod.dev/) (reactive `StreamProvider` bindings)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) with offstage route concealing
- **Hardware Enclave Security**: [`local_auth`](https://pub.dev/packages/local_auth) running on `FlutterFragmentActivity`
- **Cloud Redundancy**: [`google_sign_in`](https://pub.dev/packages/google_sign_in) with restricted `drive.appdata` scope
- **Local Reminders**: [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) with timezone-aware scheduling

---

## 📁 Project Structure

```text
lib/
├── core/             # Shared contracts, database, design tokens, background services
│   ├── database/     # Drift SQLite tables, DAOs, and v1-v7 migrations
│   ├── services/     # Biometric, GoogleAuth, Notification, and Backup services
│   └── theme/        # Sanctuary Archival light & dark themes, typography, tokens
├── features/         # Modular feature slices
│   ├── assets/       # Vehicles, properties, appliances, and PMS limits
│   ├── bills/        # Recurring utilities, due dates, and payment status
│   ├── dashboard/    # Reactive today metrics, focus tasks, and life binders
│   ├── documents/    # Vault file attachments, warranties, and receipts
│   ├── expenses/     # Financial minor-unit ledger & multi-linked expenses
│   ├── onboarding/   # 5-step sanctuary carousel & mandatory legal consent gate
│   ├── records/      # Universal records, custom attributes, and categories
│   ├── reminders/    # Task alarms and domestic cadence digests
│   ├── security/     # AppLockScreen and biometric hardware barriers
│   ├── settings/     # Emergency dossier, Google Drive sync, and updates
│   └── tasks/        # Cadence routines, snooze modal, and completion logs
└── main.dart         # Entrypoint, theme mode provider, and lock observer
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>= 3.22.0)
- Dart SDK (>= 3.12.0)
- Android Studio or Xcode (for mobile emulator / physical device execution)

### Installation
```bash
# Clone the repository
git clone https://github.com/Johnjulve/Domora.git
cd Domora

# Install dependencies
flutter pub get

# Run test suite (163 tests)
flutter test

# Run on connected device or emulator
flutter run
```

---

## 📖 Documentation
- [Domora Product & Technical Blueprint](docs/product/Domora_Product_Blueprint.md)
- [Sanctuary Archival Design System & Flow Curves](docs/design/Design/domora_design.md)
- [Project Changelog](CHANGELOG.md)

---

## 📄 License

This project is licensed under the **GNU General Public License v3.0** (GPL-3.0). See the [LICENSE](LICENSE) file for details.

Copyright (c) 2026 John Andrei Julve.
