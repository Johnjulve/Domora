import 'package:drift/drift.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../domain/workspace.dart';

/// Drift-backed implementation of [WorkspaceRepository].
class WorkspaceRepositoryImpl implements WorkspaceRepository {
  final AppDatabase _db;

  const WorkspaceRepositoryImpl(this._db);

  @override
  Future<Workspace> getOrCreateDefaultWorkspace() async {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.workspaces)
            ..where((w) => w.id.equals(AppConstants.defaultWorkspaceId)))
          .getSingleOrNull();

      if (existing != null) {
        if (existing.deletedAt != null) {
          // If default workspace was marked deleted, restore it without cascade-triggering replacements
          final now = DateTime.now().toUtc();
          await (_db.update(_db.workspaces)..where((w) => w.id.equals(existing.id))).write(
            WorkspacesCompanion(
              deletedAt: const Value(null),
              updatedAt: Value(now),
            ),
          );
          return _toDomain(existing).copyWith(deletedAt: null, updatedAt: now);
        }
        return _toDomain(existing);
      }

      final now = DateTime.now().toUtc();
      final defaultWorkspace = Workspace(
        id: AppConstants.defaultWorkspaceId,
        name: AppConstants.defaultWorkspaceName,
        workspaceType: 'personal',
        createdAt: now,
        updatedAt: now,
      );

      // Use insertOrIgnore to prevent SQLite's INSERT OR REPLACE from triggering cascade deletes
      await _db.into(_db.workspaces).insert(
            _toCompanion(defaultWorkspace),
            mode: InsertMode.insertOrIgnore,
          );

      return defaultWorkspace;
    });
  }

  @override
  Future<List<Workspace>> getActiveWorkspaces() async {
    final entities = await (_db.select(_db.workspaces)
          ..where((w) => w.deletedAt.isNull())
          ..orderBy([(w) => OrderingTerm.asc(w.createdAt)]))
        .get();

    return entities.map(_toDomain).toList();
  }

  @override
  Stream<List<Workspace>> watchActiveWorkspaces() {
    return (_db.select(_db.workspaces)
          ..where((w) => w.deletedAt.isNull())
          ..orderBy([(w) => OrderingTerm.asc(w.createdAt)]))
        .watch()
        .map((entities) => entities.map(_toDomain).toList());
  }

  @override
  Future<Workspace?> getWorkspaceById(String id) async {
    final entity = await (_db.select(_db.workspaces)
          ..where((w) => w.id.equals(id) & w.deletedAt.isNull()))
        .getSingleOrNull();

    return entity != null ? _toDomain(entity) : null;
  }

  @override
  Future<void> saveWorkspace(Workspace workspace) async {
    final now = DateTime.now().toUtc();
    final companion = _toCompanion(workspace.copyWith(updatedAt: now));
    await _db.into(_db.workspaces).insertOnConflictUpdate(companion);
  }

  @override
  Future<void> softDeleteWorkspace(String id) async {
    if (id == AppConstants.defaultWorkspaceId) {
      throw UnsupportedError('The default personal workspace cannot be soft deleted.');
    }

    final now = DateTime.now().toUtc();
    await (_db.update(_db.workspaces)..where((w) => w.id.equals(id))).write(
      WorkspacesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Workspace _toDomain(WorkspaceEntity entity) {
    return Workspace(
      id: entity.id,
      name: entity.name,
      workspaceType: entity.workspaceType,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      archivedAt: entity.archivedAt,
      deletedAt: entity.deletedAt,
    );
  }

  WorkspacesCompanion _toCompanion(Workspace workspace) {
    return WorkspacesCompanion(
      id: Value(workspace.id),
      name: Value(workspace.name),
      workspaceType: Value(workspace.workspaceType),
      createdAt: Value(workspace.createdAt),
      updatedAt: Value(workspace.updatedAt),
      archivedAt: Value(workspace.archivedAt),
      deletedAt: Value(workspace.deletedAt),
    );
  }
}
