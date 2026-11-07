import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:domora/core/database/app_database.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/expenses/data/expense_repository_impl.dart';
import 'package:domora/features/expenses/domain/expense_item.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/tasks/data/task_repository_impl.dart';
import 'package:domora/features/tasks/domain/task_item.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:domora/features/workspaces/domain/workspace.dart';

void main() {
  late AppDatabase db;
  late RecordRepositoryImpl recordRepo;
  late ExpenseRepositoryImpl expenseRepo;
  late TaskRepositoryImpl taskRepo;
  late WorkspaceRepositoryImpl workspaceRepo;

  const workspaceId = 'test-vehicle-workspace';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    recordRepo = RecordRepositoryImpl(db);
    expenseRepo = ExpenseRepositoryImpl(db);
    taskRepo = TaskRepositoryImpl(db);
    workspaceRepo = WorkspaceRepositoryImpl(db);

    final now = DateTime.now().toUtc();
    await workspaceRepo.saveWorkspace(Workspace(
      id: workspaceId,
      name: 'Vehicle Test Workspace',
      workspaceType: 'personal',
      createdAt: now,
      updatedAt: now,
    ));
    await CategoryRepositoryImpl(db).seedDefaultCategories(workspaceId);
  });

  tearDown(() async {
    await db.close();
  });

  group('Vehicle PMS & Maintenance Lifecycle Tests', () {
    test('Can configure vehicle PMS limits and baseline odometer on asset creation', () async {
      final now = DateTime.now().toUtc();
      final vehicleRecordId = const Uuid().v4();

      await recordRepo.createAssetRecord(
        record: Record(
          id: vehicleRecordId,
          workspaceId: workspaceId,
          categoryId: 'cat-vehicles',
          recordType: 'asset',
          title: 'Toyota RAV4 Hybrid',
          createdAt: now,
          updatedAt: now,
        ),
        asset: Asset(
          recordId: vehicleRecordId,
          brand: 'Toyota',
          model: 'RAV4 Hybrid 2024',
          odometerReading: 15000,
          pmsDistanceIntervalKm: 5000,
          pmsTimeIntervalMonths: 6,
          nextPmsOdometerTarget: 20000,
          nextPmsDueDate: now.add(const Duration(days: 180)),
        ),
      );

      final records = await recordRepo.getActiveRecordsByWorkspace(workspaceId);
      expect(records, hasLength(1));

      final vehicle = records.first;
      expect(vehicle.record.title, 'Toyota RAV4 Hybrid');
      expect(vehicle.asset?.odometerReading, 15000);
      expect(vehicle.asset?.pmsDistanceIntervalKm, 5000);
      expect(vehicle.asset?.pmsTimeIntervalMonths, 6);
      expect(vehicle.asset?.nextPmsOdometerTarget, 20000);
      expect(vehicle.asset?.nextPmsDueDate, isNotNull);
    });

    test('Logging maintenance expense updates asset latest odometer and computes next PMS milestone', () async {
      final now = DateTime.now().toUtc();
      final vehicleRecordId = const Uuid().v4();

      // 1. Create vehicle with initial odometer reading = 15,000 km
      await recordRepo.createAssetRecord(
        record: Record(
          id: vehicleRecordId,
          workspaceId: workspaceId,
          categoryId: 'cat-vehicles',
          recordType: 'asset',
          title: 'Honda Civic RS Turbo',
          createdAt: now,
          updatedAt: now,
        ),
        asset: Asset(
          recordId: vehicleRecordId,
          brand: 'Honda',
          model: 'Civic RS Turbo',
          odometerReading: 15000,
          pmsDistanceIntervalKm: 5000,
          pmsTimeIntervalMonths: 6,
          nextPmsOdometerTarget: 20000,
        ),
      );

      // 2. Perform maintenance at 15,450 km and log service expense
      final expenseRecordId = const Uuid().v4();
      const serviceOdometer = 15450;

      await expenseRepo.createExpenseRecord(
        record: Record(
          id: expenseRecordId,
          workspaceId: workspaceId,
          recordType: 'expense',
          title: '15k Periodic Maintenance Service & Oil Change',
          createdAt: now,
          updatedAt: now,
        ),
        expense: ExpenseItem(
          recordId: expenseRecordId,
          amountMinor: 485000, // PHP 4,850.00
          currencyCode: 'PHP',
          transactionDate: now,
          expenseCategory: 'maintenance',
          linkedAssetRecordId: vehicleRecordId,
          odometerReading: serviceOdometer,
        ),
      );

      // Verify asset's latest odometer reading was automatically updated to service reading
      final refreshedRecords = await recordRepo.getActiveRecordsByWorkspace(workspaceId);
      final refreshedVehicle = refreshedRecords.firstWhere((r) => r.record.id == vehicleRecordId);
      expect(refreshedVehicle.asset?.odometerReading, serviceOdometer);

      // 3. Auto-schedule next PMS task at +5,000 km (20,450 km) and +6 months
      final nextOdometerTarget = serviceOdometer + (refreshedVehicle.asset!.pmsDistanceIntervalKm ?? 5000);
      final nextDueDate = now.add(Duration(days: (refreshedVehicle.asset!.pmsTimeIntervalMonths ?? 6) * 30));
      final taskId = const Uuid().v4();

      await taskRepo.createTaskRecord(
        record: Record(
          id: taskId,
          workspaceId: workspaceId,
          recordType: 'task',
          title: 'Next PMS ($nextOdometerTarget km) - ${refreshedVehicle.record.title}',
          description: 'Auto-scheduled from 15k PMS service log at $serviceOdometer km.',
          createdAt: now,
          updatedAt: now,
        ),
        task: TaskItem(
          recordId: taskId,
          dueDate: nextDueDate,
          priority: 'medium',
          status: 'pending',
          assetRecordId: vehicleRecordId,
        ),
      );

      await recordRepo.updateAsset(
        refreshedVehicle.asset!.copyWith(
          nextPmsOdometerTarget: nextOdometerTarget,
          nextPmsDueDate: nextDueDate,
        ),
      );

      // 4. Verify task is scheduled and linked to vehicle
      final tasks = await taskRepo.getTasksByWorkspace(workspaceId);
      expect(tasks, hasLength(1));
      expect(tasks.first.record.title, contains('Next PMS (20450 km)'));
      expect(tasks.first.task.assetRecordId, vehicleRecordId);
      expect(tasks.first.task.status, 'pending');

      // 5. Verify vehicle asset reflects new PMS targets
      final finalVehicle = (await recordRepo.getActiveRecordsByWorkspace(workspaceId)).first;
      expect(finalVehicle.asset?.odometerReading, 15450);
      expect(finalVehicle.asset?.nextPmsOdometerTarget, 20450);
      expect(finalVehicle.asset?.nextPmsDueDate, isNotNull);
    });

    test('Backfilling older historical maintenance log does not downgrade current vehicle odometer', () async {
      final now = DateTime.now().toUtc();
      final vehicleRecordId = const Uuid().v4();

      // 1. Create vehicle with current odometer reading = 32,000 km
      await recordRepo.createAssetRecord(
        record: Record(
          id: vehicleRecordId,
          workspaceId: workspaceId,
          categoryId: 'cat-vehicles',
          recordType: 'asset',
          title: 'Mitsubishi Montero Sport',
          createdAt: now,
          updatedAt: now,
        ),
        asset: Asset(
          recordId: vehicleRecordId,
          brand: 'Mitsubishi',
          model: 'Montero Sport GLS',
          odometerReading: 32000,
          pmsDistanceIntervalKm: 5000,
          pmsTimeIntervalMonths: 6,
        ),
      );

      // 2. Backfill an older receipt from 1 year ago with odometer = 10,000 km
      final historicalExpenseId = const Uuid().v4();
      await expenseRepo.createExpenseRecord(
        record: Record(
          id: historicalExpenseId,
          workspaceId: workspaceId,
          recordType: 'expense',
          title: 'Historical 10,000 km Service Receipt',
          createdAt: now.subtract(const Duration(days: 365)),
          updatedAt: now.subtract(const Duration(days: 365)),
        ),
        expense: ExpenseItem(
          recordId: historicalExpenseId,
          amountMinor: 350000,
          currencyCode: 'PHP',
          transactionDate: now.subtract(const Duration(days: 365)),
          expenseCategory: 'maintenance',
          linkedAssetRecordId: vehicleRecordId,
          odometerReading: 10000, // Older reading
        ),
      );

      // 3. Verify vehicle odometer reading remains at 32,000 km and was NOT downgraded to 10,000 km
      final records = await recordRepo.getActiveRecordsByWorkspace(workspaceId);
      final vehicle = records.firstWhere((r) => r.record.id == vehicleRecordId);
      expect(vehicle.asset?.odometerReading, 32000);
    });
  });
}
