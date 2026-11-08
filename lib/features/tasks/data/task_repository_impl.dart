import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../records/domain/record.dart';
import '../domain/task_item.dart';
import '../domain/task_repository.dart';

/// Drift-backed implementation of [TaskRepository].
class TaskRepositoryImpl implements TaskRepository {
  final AppDatabase _db;

  const TaskRepositoryImpl(this._db);

  @override
  Future<void> createTaskRecord({
    required Record record,
    required TaskItem task,
  }) async {
    return _db.transaction(() async {
      final now = DateTime.now().toUtc();
      final stampedRecord = record.copyWith(
        recordType: 'task',
        updatedAt: now,
      );
      final syncedTask = task.copyWith(recordId: record.id);

      await _db.into(_db.records).insert(_toRecordCompanion(stampedRecord));
      await _db.into(_db.tasks).insert(_toTaskCompanion(syncedTask));
    });
  }

  @override
  Future<void> updateTaskStatus({
    required String recordId,
    required String status,
    DateTime? completedAt,
  }) async {
    final now = DateTime.now().toUtc();
    return _db.transaction(() async {
      await (_db.update(_db.tasks)..where((t) => t.recordId.equals(recordId))).write(
        TasksCompanion(
          status: Value(status),
          completedAt: Value(status == 'completed' ? (completedAt ?? now) : null),
        ),
      );
      await (_db.update(_db.records)..where((r) => r.id.equals(recordId))).write(
        RecordsCompanion(updatedAt: Value(now)),
      );
    });
  }

  @override
  Future<void> rescheduleTask({
    required String recordId,
    required DateTime newDueDate,
  }) async {
    final now = DateTime.now().toUtc();
    return _db.transaction(() async {
      await (_db.update(_db.tasks)..where((t) => t.recordId.equals(recordId))).write(
        TasksCompanion(
          dueDate: Value(newDueDate),
        ),
      );
      await (_db.update(_db.records)..where((r) => r.id.equals(recordId))).write(
        RecordsCompanion(updatedAt: Value(now)),
      );
    });
  }

  @override
  Future<void> softDeleteTask(String recordId) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.records)..where((r) => r.id.equals(recordId))).write(
      RecordsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Stream<List<RecordWithTask>> watchTasksByWorkspace(
    String workspaceId, {
    String? statusFilter,
    String? priorityFilter,
    String? assetRecordId,
  }) {
    final query = _buildTasksQuery(
      workspaceId,
      statusFilter: statusFilter,
      priorityFilter: priorityFilter,
      assetRecordId: assetRecordId,
    );
    return query.watch().map(_mapRowsToRecordsWithTasks);
  }

  @override
  Future<List<RecordWithTask>> getTasksByWorkspace(
    String workspaceId, {
    String? statusFilter,
    String? priorityFilter,
    String? assetRecordId,
  }) async {
    final query = _buildTasksQuery(
      workspaceId,
      statusFilter: statusFilter,
      priorityFilter: priorityFilter,
      assetRecordId: assetRecordId,
    );
    final rows = await query.get();
    return _mapRowsToRecordsWithTasks(rows);
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildTasksQuery(
    String workspaceId, {
    String? statusFilter,
    String? priorityFilter,
    String? assetRecordId,
  }) {
    final taskRecords = _db.records;
    final tasksTable = _db.tasks;
    final assetRecords = _db.alias(_db.records, 'asset_records');

    final query = _db.select(taskRecords).join([
      innerJoin(tasksTable, tasksTable.recordId.equalsExp(taskRecords.id)),
      leftOuterJoin(assetRecords, assetRecords.id.equalsExp(tasksTable.assetRecordId)),
    ]);

    Expression<bool> predicate = taskRecords.workspaceId.equals(workspaceId) &
        taskRecords.deletedAt.isNull() &
        taskRecords.recordType.equals('task');

    if (statusFilter != null && statusFilter != 'all') {
      if (statusFilter == 'pending') {
        predicate = predicate &
            (tasksTable.status.equals('pending') | tasksTable.status.equals('in_progress'));
      } else if (statusFilter == 'completed') {
        predicate = predicate & tasksTable.status.equals('completed');
      } else {
        predicate = predicate & tasksTable.status.equals(statusFilter);
      }
    }

    if (priorityFilter != null && priorityFilter.isNotEmpty) {
      predicate = predicate & tasksTable.priority.equals(priorityFilter);
    }

    if (assetRecordId != null && assetRecordId.isNotEmpty) {
      predicate = predicate & tasksTable.assetRecordId.equals(assetRecordId);
    }

    query.where(predicate);

    query.orderBy([
      OrderingTerm(
        expression: tasksTable.status.equals('completed'),
        mode: OrderingMode.asc,
      ),
      OrderingTerm(
        expression: tasksTable.dueDate,
        mode: OrderingMode.asc,
        nulls: NullsOrder.last,
      ),
      OrderingTerm(
        expression: taskRecords.createdAt,
        mode: OrderingMode.desc,
      ),
    ]);

    return query;
  }

  List<RecordWithTask> _mapRowsToRecordsWithTasks(List<TypedResult> rows) {
    final assetRecords = _db.alias(_db.records, 'asset_records');
    return rows.map((row) {
      final recordEntity = row.readTable(_db.records);
      final taskEntity = row.readTable(_db.tasks);
      final linkedAssetEntity = row.readTableOrNull(assetRecords);

      return RecordWithTask(
        record: _toDomainRecord(recordEntity),
        task: _toDomainTask(taskEntity),
        linkedAssetTitle: linkedAssetEntity?.title,
      );
    }).toList();
  }

  Record _toDomainRecord(RecordEntity entity) {
    return Record(
      id: entity.id,
      workspaceId: entity.workspaceId,
      categoryId: entity.categoryId,
      recordType: entity.recordType,
      title: entity.title,
      description: entity.description,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      archivedAt: entity.archivedAt,
      deletedAt: entity.deletedAt,
    );
  }

  TaskItem _toDomainTask(TaskEntity entity) {
    return TaskItem(
      recordId: entity.recordId,
      dueDate: entity.dueDate,
      priority: entity.priority,
      status: entity.status,
      completedAt: entity.completedAt,
      recurrenceRule: entity.recurrenceRule,
      assetRecordId: entity.assetRecordId,
    );
  }

  RecordsCompanion _toRecordCompanion(Record record) {
    return RecordsCompanion(
      id: Value(record.id),
      workspaceId: Value(record.workspaceId),
      categoryId: Value(record.categoryId),
      recordType: Value(record.recordType),
      title: Value(record.title),
      description: Value(record.description),
      status: Value(record.status),
      createdAt: Value(record.createdAt),
      updatedAt: Value(record.updatedAt),
      archivedAt: Value(record.archivedAt),
      deletedAt: Value(record.deletedAt),
    );
  }

  TasksCompanion _toTaskCompanion(TaskItem task) {
    return TasksCompanion(
      recordId: Value(task.recordId),
      dueDate: Value(task.dueDate),
      priority: Value(task.priority),
      status: Value(task.status),
      completedAt: Value(task.completedAt),
      recurrenceRule: Value(task.recurrenceRule),
      assetRecordId: Value(task.assetRecordId),
    );
  }
}
