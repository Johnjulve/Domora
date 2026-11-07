import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../constants/app_constants.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Workspaces, Categories, Records, Assets, Tasks, Documents, Expenses, Bills])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => AppConstants.schemaVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(categories);
          await m.addColumn(records, records.categoryId);
        }
        if (from < 3) {
          await m.createTable(tasks);
        }
        if (from < 4) {
          await m.createTable(documents);
        }
        if (from < 5) {
          await m.createTable(expenses);
        }
        if (from < 6) {
          await m.createTable(bills);
          await m.addColumn(expenses, expenses.linkedBillRecordId);
        }
        if (from < 7) {
          await m.addColumn(assets, assets.odometerReading);
          await m.addColumn(assets, assets.pmsDistanceIntervalKm);
          await m.addColumn(assets, assets.pmsTimeIntervalMonths);
          await m.addColumn(assets, assets.nextPmsDueDate);
          await m.addColumn(assets, assets.nextPmsOdometerTarget);
          await m.addColumn(expenses, expenses.odometerReading);
        }
      },
      beforeOpen: (details) async {
        // Enforce SQLite Foreign Key constraints and enable WAL mode for concurrent reliability
        await customStatement('PRAGMA foreign_keys = ON');
        await customStatement('PRAGMA journal_mode = WAL');
      },
    );
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'domora',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
