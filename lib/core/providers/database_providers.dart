import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../../features/records/data/record_repository_impl.dart';
import '../../features/records/domain/record.dart';
import '../../features/workspaces/data/workspace_repository_impl.dart';
import '../../features/workspaces/domain/workspace.dart';

/// Provider for the singleton Drift [AppDatabase].
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Provider for [WorkspaceRepository].
final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return WorkspaceRepositoryImpl(db);
});

/// Provider for [RecordRepository].
final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return RecordRepositoryImpl(db);
});

/// FutureProvider that guarantees the default personal workspace is initialized.
final defaultWorkspaceProvider = FutureProvider<Workspace>((ref) async {
  final repository = ref.watch(workspaceRepositoryProvider);
  return repository.getOrCreateDefaultWorkspace();
});
