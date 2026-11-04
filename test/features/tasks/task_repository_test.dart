import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/tasks/data/task_repository_impl.dart';
import 'package:domora/features/tasks/domain/task_item.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';

void main() {
  late AppDatabase db;
  late TaskRepositoryImpl taskRepo;
  late RecordRepositoryImpl recordRepo;
  late WorkspaceRepositoryImpl workspaceRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    taskRepo = TaskRepositoryImpl(db);
    recordRepo = RecordRepositoryImpl(db);
    workspaceRepo = WorkspaceRepositoryImpl(db);

    await workspaceRepo.getOrCreateDefaultWorkspace();
  });

  tearDown(() async {
    await db.close();
  });

  group('TaskRepositoryImpl Tests', () {
    test('Can create a task record linked to an asset and retrieve it', () async {
      final now = DateTime.now().toUtc();

      // Create an asset record first
      await recordRepo.createAssetRecord(
        record: Record(
          id: 'asset-car',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Honda Civic',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'asset-car', brand: 'Honda', model: 'Civic'),
      );

      // Create a task linked to the asset
      final taskDueDate = now.add(const Duration(days: 7));
      await taskRepo.createTaskRecord(
        record: Record(
          id: 'task-oil-change',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'task',
          title: 'Engine Oil Change',
          description: 'Synthetic 0W-20 oil with OEM filter',
          createdAt: now,
          updatedAt: now,
        ),
        task: TaskItem(
          recordId: 'task-oil-change',
          dueDate: taskDueDate,
          priority: 'high',
          status: 'pending',
          assetRecordId: 'asset-car',
        ),
      );

      final tasks = await taskRepo.getTasksByWorkspace(AppConstants.defaultWorkspaceId);
      expect(tasks.length, 1);
      final item = tasks.first;
      expect(item.record.title, 'Engine Oil Change');
      expect(item.task.priority, 'high');
      expect(item.task.status, 'pending');
      expect(item.task.assetRecordId, 'asset-car');
      expect(item.linkedAssetTitle, 'Honda Civic');
      expect(item.task.isCompleted, isFalse);
      expect(item.task.isPending, isTrue);
    });

    test('toggleTaskStatus updates status and completedAt accurately', () async {
      final now = DateTime.now().toUtc();
      await taskRepo.createTaskRecord(
        record: Record(
          id: 'task-1',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'task',
          title: 'Pay Water Bill',
          createdAt: now,
          updatedAt: now,
        ),
        task: const TaskItem(
          recordId: 'task-1',
          priority: 'urgent',
          status: 'pending',
        ),
      );

      // Mark complete
      final completionTime = DateTime.now().toUtc();
      await taskRepo.updateTaskStatus(
        recordId: 'task-1',
        status: 'completed',
        completedAt: completionTime,
      );

      var tasks = await taskRepo.getTasksByWorkspace(
        AppConstants.defaultWorkspaceId,
        statusFilter: 'completed',
      );
      expect(tasks.length, 1);
      expect(tasks.first.task.isCompleted, isTrue);
      expect(tasks.first.task.completedAt, isNotNull);

      // Re-open task to pending
      await taskRepo.updateTaskStatus(
        recordId: 'task-1',
        status: 'pending',
      );

      tasks = await taskRepo.getTasksByWorkspace(
        AppConstants.defaultWorkspaceId,
        statusFilter: 'pending',
      );
      expect(tasks.length, 1);
      expect(tasks.first.task.isCompleted, isFalse);
      expect(tasks.first.task.completedAt, isNull);
    });

    test('softDeleteTask sets deletedAt and excludes task from active queries', () async {
      final now = DateTime.now().toUtc();
      await taskRepo.createTaskRecord(
        record: Record(
          id: 'task-del',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'task',
          title: 'Temporary Task',
          createdAt: now,
          updatedAt: now,
        ),
        task: const TaskItem(recordId: 'task-del'),
      );

      expect((await taskRepo.getTasksByWorkspace(AppConstants.defaultWorkspaceId)).length, 1);

      await taskRepo.softDeleteTask('task-del');

      // Excluded from query
      expect((await taskRepo.getTasksByWorkspace(AppConstants.defaultWorkspaceId)).length, 0);

      // Still in database with deletedAt set
      final rawRecord = await (db.select(db.records)..where((r) => r.id.equals('task-del'))).getSingle();
      expect(rawRecord.deletedAt, isNotNull);
    });

    test('Deleting an asset cascades setNull on linked task assetRecordId', () async {
      final now = DateTime.now().toUtc();

      await recordRepo.createAssetRecord(
        record: Record(
          id: 'parent-asset',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'asset',
          title: 'Kitchen Refrigerator',
          createdAt: now,
          updatedAt: now,
        ),
        asset: const Asset(recordId: 'parent-asset', brand: 'LG'),
      );

      await taskRepo.createTaskRecord(
        record: Record(
          id: 'task-filter',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'task',
          title: 'Replace Water Filter',
          createdAt: now,
          updatedAt: now,
        ),
        task: const TaskItem(
          recordId: 'task-filter',
          assetRecordId: 'parent-asset',
        ),
      );

      // Verify link initially
      var tasks = await taskRepo.getTasksByWorkspace(AppConstants.defaultWorkspaceId);
      expect(tasks.first.linkedAssetTitle, 'Kitchen Refrigerator');

      // Hard delete parent asset record
      await (db.delete(db.records)..where((r) => r.id.equals('parent-asset'))).go();

      // Task still exists, but assetRecordId is cleanly set to NULL
      tasks = await taskRepo.getTasksByWorkspace(AppConstants.defaultWorkspaceId);
      expect(tasks.length, 1);
      expect(tasks.first.task.assetRecordId, isNull);
      expect(tasks.first.linkedAssetTitle, isNull);
    });

    test('watchTasksByWorkspace emits updates reactively', () async {
      final stream = taskRepo.watchTasksByWorkspace(AppConstants.defaultWorkspaceId);
      expect(
        stream,
        emitsInOrder([
          isEmpty,
          hasLength(1),
        ]),
      );

      final now = DateTime.now().toUtc();
      await taskRepo.createTaskRecord(
        record: Record(
          id: 'stream-task',
          workspaceId: AppConstants.defaultWorkspaceId,
          recordType: 'task',
          title: 'Reactive Test Task',
          createdAt: now,
          updatedAt: now,
        ),
        task: const TaskItem(recordId: 'stream-task'),
      );
    });
  });
}
