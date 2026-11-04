import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Workspaces, Categories, Records, Assets, Tasks, Documents])
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
      },
      beforeOpen: (details) async {
        // Enforce SQLite Foreign Key constraints and enable WAL mode for concurrent reliability
        await customStatement('PRAGMA foreign_keys = ON');
        await customStatement('PRAGMA journal_mode = WAL');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'domora.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
