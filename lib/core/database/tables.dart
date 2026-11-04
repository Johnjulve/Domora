import 'package:drift/drift.dart';

/// Table definition for Workspaces.
@DataClassName('WorkspaceEntity')
class Workspaces extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get workspaceType => text().withDefault(const Constant('personal'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // Soft-deletion timestamp

  @override
  Set<Column> get primaryKey => {id};
}

/// Universal table definition for Records.
@DataClassName('RecordEntity')
@TableIndex(name: 'records_workspace_deleted_idx', columns: {#workspaceId, #deletedAt})
class Records extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().references(Workspaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get recordType => text()(); // e.g. 'asset', 'task', 'expense', 'bill', 'document'
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // Soft-deletion timestamp

  @override
  Set<Column> get primaryKey => {id};
}

/// Specialized table definition for Assets, linked 1-to-1 to a parent Record.
@DataClassName('AssetEntity')
class Assets extends Table {
  TextColumn get recordId => text().references(Records, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  IntColumn get purchaseAmountMinor => integer().nullable()(); // Financial integer precision in minor units (e.g. cents)
  TextColumn get purchaseCurrency => text().nullable().withDefault(const Constant('PHP'))();
  TextColumn get brand => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get serialNumber => text().nullable()();
  TextColumn get condition => text().nullable()();
  TextColumn get locationDescription => text().nullable()();
  TextColumn get acquiredFrom => text().nullable()();
  DateTimeColumn get disposedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {recordId};
}
