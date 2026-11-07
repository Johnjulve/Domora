import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../database/app_database.dart';
import '../../features/backup/data/backup_repository_impl.dart';
import '../../features/backup/domain/backup_repository.dart';
import '../../features/categories/data/category_repository_impl.dart';
import '../../features/categories/domain/category.dart';
import '../../features/expenses/data/expense_repository_impl.dart';
import '../../features/expenses/domain/expense_item.dart';
import '../../features/expenses/domain/expense_repository.dart';
import '../../features/records/data/record_repository_impl.dart';
import '../../features/records/domain/record.dart';
import '../../features/tasks/data/task_repository_impl.dart';
import '../../features/tasks/domain/task_item.dart';
import '../../features/tasks/domain/task_repository.dart';
import '../../features/vault/data/document_repository_impl.dart';
import '../../features/vault/domain/document_item.dart';
import '../../features/vault/domain/document_repository.dart';
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

/// Provider for [TaskRepository].
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TaskRepositoryImpl(db);
});

/// Provider for [DocumentRepository].
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DocumentRepositoryImpl(db);
});

/// Provider for [ExpenseRepository].
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ExpenseRepositoryImpl(db);
});

/// Provider for [BackupRepository].
final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BackupRepositoryImpl(db);
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

/// Unfiltered stream provider of active records for dashboard summary and cross-feature feeds.
final dashboardRecordsStreamProvider = StreamProvider<List<RecordWithAsset>>((ref) {
  final repository = ref.watch(recordRepositoryProvider);
  return repository.watchActiveRecordsByWorkspace(AppConstants.defaultWorkspaceId);
});

/// Notifier for task status filtering ('pending', 'completed', 'all').
class TaskFilterNotifier extends Notifier<String> {
  @override
  String build() => 'pending';

  void setFilter(String filter) => state = filter;
}

final selectedTaskFilterProvider = NotifierProvider<TaskFilterNotifier, String>(
  TaskFilterNotifier.new,
);

/// Reactive stream provider for tasks in the default workspace with active status filter.
final activeTasksStreamProvider = StreamProvider<List<RecordWithTask>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final filter = ref.watch(selectedTaskFilterProvider);

  return repository.watchTasksByWorkspace(
    AppConstants.defaultWorkspaceId,
    statusFilter: filter == 'all' ? null : filter,
  );
});

/// Unfiltered stream provider of active tasks for dashboard summary and focus computation.
final dashboardTasksStreamProvider = StreamProvider<List<RecordWithTask>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasksByWorkspace(AppConstants.defaultWorkspaceId);
});

/// Notifier for document vault filter ('all', 'warranty', 'receipt', 'manual', 'deed', 'id').
class VaultFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String filter) => state = filter;
}

final selectedVaultFilterProvider = NotifierProvider<VaultFilterNotifier, String>(
  VaultFilterNotifier.new,
);

/// Reactive stream provider for documents in the default workspace with active type filter.
final activeDocumentsStreamProvider = StreamProvider<List<RecordWithDocument>>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  final filter = ref.watch(selectedVaultFilterProvider);

  return repository.watchDocumentsByWorkspace(
    AppConstants.defaultWorkspaceId,
    documentType: filter == 'all' ? null : filter,
  );
});

/// Unfiltered stream provider of active documents for cross-feature aggregations.
final dashboardDocumentsStreamProvider = StreamProvider<List<RecordWithDocument>>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  return repository.watchDocumentsByWorkspace(AppConstants.defaultWorkspaceId);
});

/// Reactive stream provider for active assets in the default workspace (for document linking and asset selectors).
final activeAssetsStreamProvider = StreamProvider<List<RecordWithAsset>>((ref) {
  final repository = ref.watch(recordRepositoryProvider);
  return repository.watchActiveRecordsByWorkspace(
    AppConstants.defaultWorkspaceId,
    recordType: 'asset',
  );
});

/// Notifier for expense category filter ('all', 'maintenance', 'purchase', 'utility', 'service', 'subscription', 'other').
class ExpenseFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String filter) => state = filter;
}

final selectedExpenseFilterProvider = NotifierProvider<ExpenseFilterNotifier, String>(
  ExpenseFilterNotifier.new,
);

/// Reactive stream provider for expenses in the default workspace with active category filter.
final activeExpensesStreamProvider = StreamProvider<List<RecordWithExpense>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  final filter = ref.watch(selectedExpenseFilterProvider);

  return repository.watchExpensesByWorkspace(
    AppConstants.defaultWorkspaceId,
    category: filter == 'all' ? null : filter,
  );
});

/// Unfiltered stream provider of active expenses for dashboard aggregations.
final dashboardExpensesStreamProvider = StreamProvider<List<RecordWithExpense>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.watchExpensesByWorkspace(AppConstants.defaultWorkspaceId);
});

/// Reactive stream provider for total maintenance/expense amount in minor units for a specific asset.
final assetTotalExpensesProvider = StreamProvider.family<int, String>((ref, assetId) {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.watchTotalExpensesByAsset(assetId);
});

/// Reactive stream provider for total workspace expenses in minor units.
final workspaceTotalExpensesProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.watchTotalWorkspaceExpenses(AppConstants.defaultWorkspaceId);
});
