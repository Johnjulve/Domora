import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/core/theme/app_theme.dart';
import 'package:domora/features/bills/data/bill_repository_impl.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/expenses/data/expense_repository_impl.dart';
import 'package:domora/features/expenses/domain/expense_item.dart';
import 'package:domora/features/expenses/presentation/add_expense_sheet.dart';
import 'package:domora/features/expenses/presentation/expense_detail_sheet.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/tasks/data/task_repository_impl.dart';
import 'package:domora/features/tasks/domain/task_item.dart';
import 'package:domora/features/vault/data/document_repository_impl.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase db;
  late CategoryRepositoryImpl categoryRepo;
  late RecordRepositoryImpl recordRepo;
  late BillRepositoryImpl billRepo;
  late ExpenseRepositoryImpl expenseRepo;
  late TaskRepositoryImpl taskRepo;
  late DocumentRepositoryImpl documentRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final wsRepo = WorkspaceRepositoryImpl(db);
    categoryRepo = CategoryRepositoryImpl(db);
    recordRepo = RecordRepositoryImpl(db);
    billRepo = BillRepositoryImpl(db);
    expenseRepo = ExpenseRepositoryImpl(db);
    taskRepo = TaskRepositoryImpl(db);
    documentRepo = DocumentRepositoryImpl(db);

    await wsRepo.getOrCreateDefaultWorkspace();
    await categoryRepo.seedDefaultCategories(AppConstants.defaultWorkspaceId);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildApp(Widget home, {ThemeMode themeMode = ThemeMode.light}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        workspaceRepositoryProvider.overrideWithValue(WorkspaceRepositoryImpl(db)),
        categoryRepositoryProvider.overrideWithValue(categoryRepo),
        recordRepositoryProvider.overrideWithValue(recordRepo),
        billRepositoryProvider.overrideWithValue(billRepo),
        expenseRepositoryProvider.overrideWithValue(expenseRepo),
        taskRepositoryProvider.overrideWithValue(taskRepo),
        documentRepositoryProvider.overrideWithValue(documentRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: home,
      ),
    );
  }

  Future<void> flush(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<RecordWithAsset> seedVehicle({
    String id = 'veh-honda-v4',
    String title = 'Honda V4',
    int odometer = 729,
    int pmsDistance = 1000,
    int pmsMonths = 6,
    int? nextPmsOdo,
    DateTime? nextPmsDue,
  }) async {
    final now = DateTime.utc(2026, 5, 1);
    return recordRepo.createAssetRecord(
      record: Record(
        id: id,
        workspaceId: AppConstants.defaultWorkspaceId,
        categoryId: 'cat-vehicles',
        recordType: 'asset',
        title: title,
        createdAt: now,
        updatedAt: now,
      ),
      asset: Asset(
        recordId: id,
        brand: 'Honda',
        model: 'V4',
        condition: 'Good',
        odometerReading: odometer,
        pmsDistanceIntervalKm: pmsDistance,
        pmsTimeIntervalMonths: pmsMonths,
        nextPmsOdometerTarget: nextPmsOdo,
        nextPmsDueDate: nextPmsDue,
      ),
    );
  }

  Future<void> openExpenseDetailModal(
    WidgetTester tester,
    RecordWithExpense item, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpWidget(
      buildApp(
        Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: ctx,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ExpenseDetailSheet(item: item),
                  );
                },
                child: const Text('Open Expense'),
              ),
            ),
          ),
        ),
        themeMode: themeMode,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Expense'));
    await tester.pumpAndSettle();
  }

  group('Pass 3E: Link Next PMS Task & Optional Cascade-Delete', () {
    testWidgets(
      'logging maintenance in AddExpenseSheet and tapping Schedule Next PMS links expense.linkedTaskRecordId to the created Next PMS task',
      (tester) async {
        tester.view.physicalSize = const Size(520, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await seedVehicle();

        await tester.pumpWidget(
          buildApp(
            Builder(
              builder: (ctx) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: ctx,
                        isScrollControlled: true,
                        builder: (_) => const AddExpenseSheet(
                          initialAssetRecordId: 'veh-honda-v4',
                          initialExpenseCategory: 'maintenance',
                          prioritizeAssetLink: true,
                        ),
                      );
                    },
                    child: const Text('Log Maintenance'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Log Maintenance'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Expense Title *'),
          '1k Engine Oil Change',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Amount (PHP) *'),
          '850.00',
        );
        await tester.ensureVisible(
          find.widgetWithText(TextFormField, 'Odometer at Service (km)'),
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Odometer at Service (km)'),
          '729',
        );

        await tester.ensureVisible(find.text('Save Expense'));
        await tester.tap(find.text('Save Expense'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Schedule Next PMS prompt appears
        expect(find.text('Schedule Next PMS?'), findsOneWidget);
        await tester.tap(find.text('Schedule Next PMS'));
        await tester.pumpAndSettle();

        final expenses = await db.select(db.expenses).get();
        final tasks = await db.select(db.tasks).get();
        expect(expenses, hasLength(1));
        expect(tasks, hasLength(1));
        expect(expenses.first.linkedTaskRecordId, equals(tasks.first.recordId));

        final taskRecord = await (db.select(db.records)
              ..where((r) => r.id.equals(tasks.first.recordId)))
            .getSingle();
        expect(taskRecord.title, 'Next PMS (1729 km) - Honda V4');

        await flush(tester);
      },
    );

    testWidgets(
      'deleting linked maintenance expense with checkbox checked soft-deletes both expense and Next PMS task and clears vehicle Next Target PMS',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.utc(2026, 5, 1);
        await seedVehicle(
          nextPmsOdo: 1729,
          nextPmsDue: DateTime.utc(2026, 11, 1),
        );
        await taskRepo.createTaskRecord(
          record: Record(
            id: 'task-pms-1',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'task',
            title: 'Next PMS (1729 km) - Honda V4',
            createdAt: now,
            updatedAt: now,
          ),
          task: TaskItem(
            recordId: 'task-pms-1',
            dueDate: DateTime.utc(2026, 11, 1),
            status: 'pending',
            assetRecordId: 'veh-honda-v4',
          ),
        );
        await expenseRepo.createExpenseRecord(
          record: Record(
            id: 'exp-maint-1',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'expense',
            title: '1k Engine Oil Change',
            createdAt: now,
            updatedAt: now,
          ),
          expense: ExpenseItem(
            recordId: 'exp-maint-1',
            amountMinor: 85000,
            transactionDate: now,
            expenseCategory: 'maintenance',
            linkedAssetRecordId: 'veh-honda-v4',
            linkedTaskRecordId: 'task-pms-1',
            odometerReading: 729,
          ),
        );

        final loaded = await expenseRepo.getExpensesByWorkspace(AppConstants.defaultWorkspaceId);
        await openExpenseDetailModal(tester, loaded.first, themeMode: ThemeMode.dark);

        await tester.tap(find.byKey(const Key('expense_delete_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('delete_linked_pms_checkbox')), findsOneWidget);
        expect(
          tester
              .widget<CheckboxListTile>(find.byKey(const Key('delete_linked_pms_checkbox')))
              .value,
          isTrue,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('delete_linked_pms_checkbox')),
            matching: find.textContaining('Next PMS (1729 km) - Honda V4'),
          ),
          findsOneWidget,
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Move to Trash'));
        await tester.pumpAndSettle();

        // Both expense and Next PMS task soft-deleted
        final expRec =
            await (db.select(db.records)..where((r) => r.id.equals('exp-maint-1'))).getSingle();
        final taskRec =
            await (db.select(db.records)..where((r) => r.id.equals('task-pms-1'))).getSingle();
        expect(expRec.deletedAt, isNotNull);
        expect(taskRec.deletedAt, isNotNull);

        // Vehicle Next Target PMS cleared
        final vehicle = await recordRepo.getRecordWithAsset('veh-honda-v4');
        expect(vehicle?.asset?.nextPmsOdometerTarget, isNull);
        expect(vehicle?.asset?.nextPmsDueDate, isNull);

        await flush(tester);
      },
    );

    testWidgets(
      'deleting linked maintenance expense with checkbox unchecked preserves Next PMS task and vehicle Next Target PMS',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.utc(2026, 5, 1);
        final nextDue = DateTime.utc(2026, 11, 1);
        await seedVehicle(nextPmsOdo: 1729, nextPmsDue: nextDue);
        await taskRepo.createTaskRecord(
          record: Record(
            id: 'task-pms-keep',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'task',
            title: 'Next PMS (1729 km) - Honda V4',
            createdAt: now,
            updatedAt: now,
          ),
          task: TaskItem(
            recordId: 'task-pms-keep',
            dueDate: nextDue,
            status: 'pending',
            assetRecordId: 'veh-honda-v4',
          ),
        );
        await expenseRepo.createExpenseRecord(
          record: Record(
            id: 'exp-maint-keep',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'expense',
            title: '1k Engine Oil Change',
            createdAt: now,
            updatedAt: now,
          ),
          expense: ExpenseItem(
            recordId: 'exp-maint-keep',
            amountMinor: 85000,
            transactionDate: now,
            expenseCategory: 'maintenance',
            linkedAssetRecordId: 'veh-honda-v4',
            linkedTaskRecordId: 'task-pms-keep',
            odometerReading: 729,
          ),
        );

        final loaded = await expenseRepo.getExpensesByWorkspace(AppConstants.defaultWorkspaceId);
        await openExpenseDetailModal(tester, loaded.first);

        await tester.tap(find.byKey(const Key('expense_delete_button')));
        await tester.pumpAndSettle();

        // Uncheck the Next PMS cascade checkbox
        await tester.tap(find.byKey(const Key('delete_linked_pms_checkbox')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<CheckboxListTile>(find.byKey(const Key('delete_linked_pms_checkbox')))
              .value,
          isFalse,
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Move to Trash'));
        await tester.pumpAndSettle();

        // Expense deleted, Next PMS task & vehicle targets preserved
        final expRec = await (db.select(db.records)
              ..where((r) => r.id.equals('exp-maint-keep')))
            .getSingle();
        final taskRec = await (db.select(db.records)
              ..where((r) => r.id.equals('task-pms-keep')))
            .getSingle();
        expect(expRec.deletedAt, isNotNull);
        expect(taskRec.deletedAt, isNull);

        final vehicle = await recordRepo.getRecordWithAsset('veh-honda-v4');
        expect(vehicle?.asset?.nextPmsOdometerTarget, 1729);
        expect(vehicle?.asset?.nextPmsDueDate, nextDue);

        await flush(tester);
      },
    );

    testWidgets(
      'legacy unlinked maintenance expense detects pending Next PMS task on same vehicle and leaves non-PMS tasks untouched',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.utc(2026, 5, 1);
        await seedVehicle(
          nextPmsOdo: 1729,
          nextPmsDue: DateTime.utc(2026, 11, 1),
        );

        // Pending Next PMS task (legacy unlinked) + unrelated pending task on same vehicle
        await taskRepo.createTaskRecord(
          record: Record(
            id: 'task-pms-legacy',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'task',
            title: 'Next PMS (1729 km) - Honda V4',
            createdAt: now,
            updatedAt: now,
          ),
          task: TaskItem(
            recordId: 'task-pms-legacy',
            dueDate: DateTime.utc(2026, 11, 1),
            status: 'pending',
            assetRecordId: 'veh-honda-v4',
          ),
        );
        await taskRepo.createTaskRecord(
          record: Record(
            id: 'task-non-pms',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'task',
            title: 'Renew LTO Registration',
            createdAt: now,
            updatedAt: now,
          ),
          task: TaskItem(
            recordId: 'task-non-pms',
            dueDate: DateTime.utc(2026, 9, 1),
            status: 'pending',
            assetRecordId: 'veh-honda-v4',
          ),
        );

        // Legacy maintenance expense with linkedTaskRecordId == null
        await expenseRepo.createExpenseRecord(
          record: Record(
            id: 'exp-legacy-1',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'expense',
            title: 'Legacy Oil Change',
            createdAt: now,
            updatedAt: now,
          ),
          expense: ExpenseItem(
            recordId: 'exp-legacy-1',
            amountMinor: 75000,
            transactionDate: now,
            expenseCategory: 'maintenance',
            linkedAssetRecordId: 'veh-honda-v4',
            linkedTaskRecordId: null,
          ),
        );

        final loaded = await expenseRepo.getExpensesByWorkspace(AppConstants.defaultWorkspaceId);
        await openExpenseDetailModal(tester, loaded.first);

        await tester.tap(find.byKey(const Key('expense_delete_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('delete_linked_pms_checkbox')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('delete_linked_pms_checkbox')),
            matching: find.textContaining('Next PMS (1729 km) - Honda V4'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Renew LTO Registration'), findsNothing);

        await tester.tap(find.widgetWithText(ElevatedButton, 'Move to Trash'));
        await tester.pumpAndSettle();

        // Expense + legacy Next PMS task deleted; non-PMS task preserved!
        final legacyTask = await (db.select(db.records)
              ..where((r) => r.id.equals('task-pms-legacy')))
            .getSingle();
        final nonPmsTask = await (db.select(db.records)
              ..where((r) => r.id.equals('task-non-pms')))
            .getSingle();
        expect(legacyTask.deletedAt, isNotNull);
        expect(nonPmsTask.deletedAt, isNull);

        final vehicle = await recordRepo.getRecordWithAsset('veh-honda-v4');
        expect(vehicle?.asset?.nextPmsOdometerTarget, isNull);
        expect(vehicle?.asset?.nextPmsDueDate, isNull);

        await flush(tester);
      },
    );

    test(
      'softDeleteExpense preserves vehicle Next Target PMS when another active pending Next PMS task remains',
      () async {
        final now = DateTime.utc(2026, 5, 1);
        final laterDue = DateTime.utc(2027, 2, 1);
        await seedVehicle(nextPmsOdo: 3000, nextPmsDue: laterDue);

        await taskRepo.createTaskRecord(
          record: Record(
            id: 'task-pms-old',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'task',
            title: 'Next PMS (2000 km) - Honda V4',
            createdAt: now,
            updatedAt: now,
          ),
          task: TaskItem(
            recordId: 'task-pms-old',
            dueDate: DateTime.utc(2026, 11, 1),
            status: 'pending',
            assetRecordId: 'veh-honda-v4',
          ),
        );
        await taskRepo.createTaskRecord(
          record: Record(
            id: 'task-pms-newer',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'task',
            title: 'Next PMS (3000 km) - Honda V4',
            createdAt: now,
            updatedAt: now,
          ),
          task: TaskItem(
            recordId: 'task-pms-newer',
            dueDate: laterDue,
            status: 'pending',
            assetRecordId: 'veh-honda-v4',
          ),
        );
        await expenseRepo.createExpenseRecord(
          record: Record(
            id: 'exp-old-1',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'expense',
            title: 'Earlier Oil Change',
            createdAt: now,
            updatedAt: now,
          ),
          expense: ExpenseItem(
            recordId: 'exp-old-1',
            amountMinor: 85000,
            transactionDate: now,
            expenseCategory: 'maintenance',
            linkedAssetRecordId: 'veh-honda-v4',
            linkedTaskRecordId: 'task-pms-old',
          ),
        );

        await expenseRepo.softDeleteExpense(
          'exp-old-1',
          linkedTaskRecordIdsToDelete: const ['task-pms-old'],
          clearAssetNextPmsTarget: true,
        );

        final oldTask = await (db.select(db.records)
              ..where((r) => r.id.equals('task-pms-old')))
            .getSingle();
        final newerTask = await (db.select(db.records)
              ..where((r) => r.id.equals('task-pms-newer')))
            .getSingle();
        expect(oldTask.deletedAt, isNotNull);
        expect(newerTask.deletedAt, isNull);

        // Because task-pms-newer is still pending, vehicle's Next Target PMS stays intact
        final vehicle = await recordRepo.getRecordWithAsset('veh-honda-v4');
        expect(vehicle?.asset?.nextPmsOdometerTarget, 3000);
        expect(vehicle?.asset?.nextPmsDueDate, laterDue);
      },
    );

    testWidgets(
      'unlinked maintenance expense does NOT offer or delete a Next PMS task already claimed by another active expense',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.utc(2026, 5, 1);
        final nextDue = DateTime.utc(2026, 11, 1);
        await seedVehicle(nextPmsOdo: 2729, nextPmsDue: nextDue);

        await taskRepo.createTaskRecord(
          record: Record(
            id: 'task-pms-owned-by-b',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'task',
            title: 'Next PMS (2729 km) - Honda V4',
            createdAt: now,
            updatedAt: now,
          ),
          task: TaskItem(
            recordId: 'task-pms-owned-by-b',
            dueDate: nextDue,
            status: 'pending',
            assetRecordId: 'veh-honda-v4',
          ),
        );
        // Active expense B explicitly owns task-pms-owned-by-b
        await expenseRepo.createExpenseRecord(
          record: Record(
            id: 'exp-b',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'expense',
            title: '2k Maintenance',
            createdAt: now,
            updatedAt: now,
          ),
          expense: ExpenseItem(
            recordId: 'exp-b',
            amountMinor: 95000,
            transactionDate: now,
            expenseCategory: 'maintenance',
            linkedAssetRecordId: 'veh-honda-v4',
            linkedTaskRecordId: 'task-pms-owned-by-b',
          ),
        );
        // Unlinked expense A on the same vehicle
        await expenseRepo.createExpenseRecord(
          record: Record(
            id: 'exp-a-unlinked',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'expense',
            title: 'Unlinked Tire Patch',
            createdAt: now,
            updatedAt: now,
          ),
          expense: ExpenseItem(
            recordId: 'exp-a-unlinked',
            amountMinor: 25000,
            transactionDate: now,
            expenseCategory: 'maintenance',
            linkedAssetRecordId: 'veh-honda-v4',
            linkedTaskRecordId: null,
          ),
        );

        final allExpenses = await expenseRepo.getExpensesByWorkspace(AppConstants.defaultWorkspaceId);
        final expenseA = allExpenses.firstWhere((e) => e.record.id == 'exp-a-unlinked');
        await openExpenseDetailModal(tester, expenseA);

        await tester.tap(find.byKey(const Key('expense_delete_button')));
        await tester.pumpAndSettle();

        // Checkbox must NOT appear because the pending Next PMS task is claimed by exp-b
        expect(find.byKey(const Key('delete_linked_pms_checkbox')), findsNothing);

        await tester.tap(find.widgetWithText(ElevatedButton, 'Move to Trash'));
        await tester.pumpAndSettle();

        final taskB = await (db.select(db.records)
              ..where((r) => r.id.equals('task-pms-owned-by-b')))
            .getSingle();
        expect(taskB.deletedAt, isNull);

        final vehicle = await recordRepo.getRecordWithAsset('veh-honda-v4');
        expect(vehicle?.asset?.nextPmsOdometerTarget, 2729);
        expect(vehicle?.asset?.nextPmsDueDate, nextDue);

        await flush(tester);
      },
    );

    test(
      'softDeleteExpense on missing or already-deleted expense is a no-op that preserves tasks and vehicle PMS targets',
      () async {
        final now = DateTime.utc(2026, 5, 1);
        final nextDue = DateTime.utc(2026, 11, 1);
        await seedVehicle(nextPmsOdo: 1729, nextPmsDue: nextDue);

        await taskRepo.createTaskRecord(
          record: Record(
            id: 'task-pms-safe',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'task',
            title: 'Next PMS (1729 km) - Honda V4',
            createdAt: now,
            updatedAt: now,
          ),
          task: TaskItem(
            recordId: 'task-pms-safe',
            dueDate: nextDue,
            status: 'pending',
            assetRecordId: 'veh-honda-v4',
          ),
        );
        await expenseRepo.createExpenseRecord(
          record: Record(
            id: 'exp-already-deleted',
            workspaceId: AppConstants.defaultWorkspaceId,
            recordType: 'expense',
            title: 'Oil Change',
            createdAt: now,
            updatedAt: now,
          ),
          expense: ExpenseItem(
            recordId: 'exp-already-deleted',
            amountMinor: 85000,
            transactionDate: now,
            expenseCategory: 'maintenance',
            linkedAssetRecordId: 'veh-honda-v4',
            linkedTaskRecordId: 'task-pms-safe',
          ),
        );

        // First delete without cascade
        await expenseRepo.softDeleteExpense('exp-already-deleted');

        // Second stale/concurrent call with cascade flags must NOT touch task or vehicle
        await expenseRepo.softDeleteExpense(
          'exp-already-deleted',
          linkedTaskRecordIdsToDelete: const ['task-pms-safe'],
          clearAssetNextPmsTarget: true,
        );
        await expenseRepo.softDeleteExpense(
          'non-existent-expense',
          linkedTaskRecordIdsToDelete: const ['task-pms-safe'],
          clearAssetNextPmsTarget: true,
        );

        final taskRec = await (db.select(db.records)
              ..where((r) => r.id.equals('task-pms-safe')))
            .getSingle();
        expect(taskRec.deletedAt, isNull);

        final vehicle = await recordRepo.getRecordWithAsset('veh-honda-v4');
        expect(vehicle?.asset?.nextPmsOdometerTarget, 1729);
        expect(vehicle?.asset?.nextPmsDueDate, nextDue);
      },
    );
  });
}
