# Domora — Personal Life OS

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

> **Know what you have, what needs attention, what it costs, and what you need to do next.**

Domora is an offline-first, local-ownership personal and household management platform built with **Flutter**. It unifies everyday possessions, schedules, expenses, documents, utilities, and responsibilities into one structured, relational workspace.

---

## 🌟 Core Pillars

1. **Capture Once, Reuse Everywhere**: An invoice or receipt connects to an asset, maintenance record, and expense without duplicate entry.
2. **Offline-First by Default**: Core capture, search, filtering, and local reminders work seamlessly without an internet connection or mandatory account creation.
3. **Structured Yet Extensible**: Strongly typed core entities (assets, tasks, bills, expenses) with user-defined custom categories, tags, and field definitions.
4. **Data Ownership & Portability**: Complete local database persistence with versioned export/import archives.

---

## 🏗 Architecture & Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart 3.x) — mobile-first (Android target)
- **Local Persistence**: SQLite via [Drift](https://drift.simonbinder.eu/) (strongly-typed queries, transactions, and explicit schema migrations)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Local Reminders**: Flutter Local Notifications

---

## 📁 Project Structure

```text
lib/
├── core/             # Shared contracts, database, design tokens, error handlers
├── features/         # Modular feature slices (assets, tasks, bills, expenses, dashboard)
│   ├── assets/
│   ├── bills/
│   ├── dashboard/
│   ├── documents/
│   ├── expenses/
│   ├── records/
│   ├── reminders/
│   └── tasks/
└── main.dart         # App entrypoint and provider bootstrap
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

# Run on connected device or emulator
flutter run
```

---

## 📖 Documentation
- [Domora Product & Technical Blueprint](docs/product/Domora_Product_Blueprint.md)

---

## 📄 License

This project is licensed under the **GNU General Public License v3.0** (GPL-3.0). See the [LICENSE](LICENSE) file for details.

Copyright (c) 2026 John Andrei Julve.
