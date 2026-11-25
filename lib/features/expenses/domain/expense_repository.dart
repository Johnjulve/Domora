import '../../records/domain/record.dart';
import 'expense_item.dart';

/// Abstract contract for Expense persistence and aggregation operations.
abstract class ExpenseRepository {
  /// Atomically creates a universal record and its linked specialized expense.
  Future<void> createExpenseRecord({
    required Record record,
    required ExpenseItem expense,
  });

  /// Links an existing active task record to an active expense record atomically.
  Future<void> linkTaskToExpense({
    required String expenseRecordId,
    required String taskRecordId,
  });

  /// Soft deletes an expense record by setting its `deletedAt` timestamp.
  ///
  /// Optionally soft-deletes linked active task records ([linkedTaskRecordIdsToDelete])
  /// and clears the linked asset's `nextPmsOdometerTarget` / `nextPmsDueDate`
  /// ([clearAssetNextPmsTarget]) when no other active pending `Next PMS` tasks remain.
  Future<void> softDeleteExpense(
    String recordId, {
    List<String> linkedTaskRecordIdsToDelete = const [],
    bool clearAssetNextPmsTarget = false,
  });

  /// Watches expenses for a workspace reactively with optional category, asset, or task filters.
  Stream<List<RecordWithExpense>> watchExpensesByWorkspace(
    String workspaceId, {
    String? category,
    String? linkedAssetRecordId,
    String? linkedTaskRecordId,
  });

  /// Retrieves active expenses for a workspace once with optional filters.
  Future<List<RecordWithExpense>> getExpensesByWorkspace(
    String workspaceId, {
    String? category,
    String? linkedAssetRecordId,
    String? linkedTaskRecordId,
  });

  /// Watches the total accumulated maintenance/expense amount in minor units for a specific asset.
  Stream<int> watchTotalExpensesByAsset(String assetRecordId);

  /// Watches total accumulated expenses in minor units across the entire workspace.
  Stream<int> watchTotalWorkspaceExpenses(String workspaceId);
}
