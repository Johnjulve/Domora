import '../../records/domain/record.dart';
import 'task_item.dart';

/// Repository interface governing Tasks & Responsibilities persistence.
abstract class TaskRepository {
  /// Creates a unified Record and its associated Task metadata within a database transaction.
  Future<void> createTaskRecord({
    required Record record,
    required TaskItem task,
  });

  /// Updates task status (e.g. pending <-> completed) and records completion timestamp.
  Future<void> updateTaskStatus({
    required String recordId,
    required String status,
    DateTime? completedAt,
  });

  /// Soft deletes a task record.
  Future<void> softDeleteTask(String recordId);

  /// Reactively observes active tasks for a specific workspace.
  Stream<List<RecordWithTask>> watchTasksByWorkspace(
    String workspaceId, {
    String? statusFilter,
    String? priorityFilter,
    String? assetRecordId,
  });

  /// Queries active tasks for a specific workspace.
  Future<List<RecordWithTask>> getTasksByWorkspace(
    String workspaceId, {
    String? statusFilter,
    String? priorityFilter,
    String? assetRecordId,
  });
}
