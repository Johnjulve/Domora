import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../database/app_database.dart';
import '../../features/categories/data/category_repository_impl.dart';
import '../../features/categories/domain/category.dart';
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

/// Provider for [CategoryRepository].
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CategoryRepositoryImpl(db);
});

/// Provider for [RecordRepository].
final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return RecordRepositoryImpl(db);
});

/// FutureProvider that guarantees the default personal workspace & categories are initialized.
final defaultWorkspaceProvider = FutureProvider<Workspace>((ref) async {
  final wsRepo = ref.watch(workspaceRepositoryProvider);
  final catRepo = ref.watch(categoryRepositoryProvider);

  final workspace = await wsRepo.getOrCreateDefaultWorkspace();
  await catRepo.seedDefaultCategories(workspace.id);
  return workspace;
});

/// Reactive stream provider for categories in the default workspace.
final defaultCategoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchCategoriesByWorkspace(AppConstants.defaultWorkspaceId);
});

/// Notifier for real-time search query on records.
class RecordSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
  void clear() => state = '';
}

final recordSearchQueryProvider = NotifierProvider<RecordSearchNotifier, String>(
  RecordSearchNotifier.new,
);

/// Notifier for active category filter (null means 'All').
class SelectedCategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectCategory(String? categoryId) => state = categoryId;
}

final selectedCategoryFilterProvider = NotifierProvider<SelectedCategoryFilterNotifier, String?>(
  SelectedCategoryFilterNotifier.new,
);

/// Reactive stream provider for all active records in the default workspace with live filters.
final activeRecordsStreamProvider = StreamProvider<List<RecordWithAsset>>((ref) {
  final repository = ref.watch(recordRepositoryProvider);
  final query = ref.watch(recordSearchQueryProvider);
  final categoryId = ref.watch(selectedCategoryFilterProvider);

  return repository.watchActiveRecordsByWorkspace(
    AppConstants.defaultWorkspaceId,
    searchQuery: query.trim().isEmpty ? null : query.trim(),
    categoryId: categoryId,
  );
});
