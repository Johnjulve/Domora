import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/categories/domain/category.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:domora/features/workspaces/domain/workspace.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase db;
  late CategoryRepository categoryRepo;
  late WorkspaceRepository workspaceRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    categoryRepo = CategoryRepositoryImpl(db);
    workspaceRepo = WorkspaceRepositoryImpl(db);

    await workspaceRepo.getOrCreateDefaultWorkspace();
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryRepositoryImpl Tests', () {
    test('seedDefaultCategories seeds all 8 top-level sanctuary categories and excludes sub-categories from top-level queries', () async {
      await categoryRepo.seedDefaultCategories(AppConstants.defaultWorkspaceId);

      final categories = await categoryRepo.getCategoriesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(categories.length, 8);
      expect(categories.every((c) => !c.isSubCategory && c.parentCategoryId == null), isTrue);

      final names = categories.map((c) => c.name).toSet();
      expect(
        names,
        containsAll([
          'Properties',
          'Vehicles',
          'Appliances',
          'Electronics',
          'Family',
          'Furniture',
          'Tools',
          'Bills & Expenses',
        ]),
      );
    });

    test('seedDefaultCategories seeds all 5 default Bills & Expenses sub-categories idempotently', () async {
      await categoryRepo.seedDefaultCategories(AppConstants.defaultWorkspaceId);
      await categoryRepo.seedDefaultCategories(AppConstants.defaultWorkspaceId);

      final topLevel = await categoryRepo.getCategoriesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(topLevel.length, 8);

      final subCategories = await categoryRepo.getSubCategories(
        CategoryRepositoryImpl.billsExpensesCategoryId,
      );
      expect(subCategories.length, 5);
      expect(
        subCategories.every(
          (c) => c.isSubCategory && c.parentCategoryId == CategoryRepositoryImpl.billsExpensesCategoryId,
        ),
        isTrue,
      );
      expect(
        subCategories.map((c) => c.name).toList(),
        equals([
          'Bill',
          'General Expense',
          'Maintenance',
          'Subscription',
          'Withdraw / Deposit',
        ]),
      );
      expect(
        subCategories.map((c) => c.id).toSet(),
        containsAll([
          'cat-sub-bill',
          'cat-sub-subscription',
          'cat-sub-withdraw-deposit',
          'cat-sub-maintenance',
          'cat-sub-general-expense',
        ]),
      );
    });

    test('Can create, rename, and archive custom top-level categories', () async {
      final now = DateTime.utc(2026, 11, 4, 12, 0, 0);
      final custom = Category(
        id: 'cat-custom-jewelry',
        workspaceId: AppConstants.defaultWorkspaceId,
        name: 'Heirlooms & Jewelry',
        iconKey: 'diamond',
        colorHex: '#B91C1C',
        isSystem: false,
        createdAt: now,
      );

      await categoryRepo.createCategory(custom);

      final categories = await categoryRepo.getCategoriesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(categories.length, 1);
      expect(categories.first.name, 'Heirlooms & Jewelry');
      expect(categories.first.isSystem, isFalse);
      expect(categories.first.isSubCategory, isFalse);

      await categoryRepo.renameCategory('cat-custom-jewelry', '  Family Heirlooms  ');
      final renamed = await categoryRepo.getCategoriesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(renamed.single.name, 'Family Heirlooms');

      await categoryRepo.archiveCategory('cat-custom-jewelry');
      final afterArchive = await categoryRepo.getCategoriesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(afterArchive, isEmpty);
    });

    test('Can create, rename, and archive custom sub-categories under Bills & Expenses', () async {
      await categoryRepo.seedDefaultCategories(AppConstants.defaultWorkspaceId);
      final now = DateTime.utc(2026, 11, 25, 10, 0, 0);

      final customSub = Category(
        id: 'cat-sub-insurance',
        workspaceId: AppConstants.defaultWorkspaceId,
        name: 'Insurance',
        iconKey: 'shield',
        isSystem: false,
        parentCategoryId: CategoryRepositoryImpl.billsExpensesCategoryId,
        createdAt: now,
      );

      await categoryRepo.createCategory(customSub);

      // Must not appear in top-level workspace query
      final topLevel = await categoryRepo.getCategoriesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(topLevel.length, 8);
      expect(topLevel.any((c) => c.id == 'cat-sub-insurance'), isFalse);

      // Appears in sub-category query
      final subs = await categoryRepo.getSubCategories(CategoryRepositoryImpl.billsExpensesCategoryId);
      expect(subs.length, 6);
      final created = subs.firstWhere((c) => c.id == 'cat-sub-insurance');
      expect(created.name, 'Insurance');
      expect(created.isSubCategory, isTrue);
      expect(created.parentCategoryId, CategoryRepositoryImpl.billsExpensesCategoryId);

      // Rename sub-category (verifying whitespace trimming)
      await categoryRepo.renameCategory('cat-sub-insurance', '  Health Insurance  ');
      final renamedSubs = await categoryRepo.getSubCategories(CategoryRepositoryImpl.billsExpensesCategoryId);
      expect(renamedSubs.firstWhere((c) => c.id == 'cat-sub-insurance').name, 'Health Insurance');

      // Archive sub-category
      await categoryRepo.archiveCategory('cat-sub-insurance');
      final afterArchive = await categoryRepo.getSubCategories(CategoryRepositoryImpl.billsExpensesCategoryId);
      expect(afterArchive.length, 5);
      expect(afterArchive.any((c) => c.id == 'cat-sub-insurance'), isFalse);
    });

    test('watchCategoriesByWorkspace emits only top-level active categories reactively', () async {
      final stream = categoryRepo.watchCategoriesByWorkspace(AppConstants.defaultWorkspaceId);

      final expectation = expectLater(
        stream,
        emitsThrough(
          allOf(
            hasLength(8),
            everyElement(predicate<Category>((c) => !c.isSubCategory)),
          ),
        ),
      );

      await categoryRepo.seedDefaultCategories(AppConstants.defaultWorkspaceId);
      await expectation;
    });

    test('watchSubCategories emits active sub-categories reactively', () async {
      final stream = categoryRepo.watchSubCategories(CategoryRepositoryImpl.billsExpensesCategoryId);

      final expectation = expectLater(
        stream,
        emitsThrough(
          allOf(
            hasLength(5),
            everyElement(
              predicate<Category>(
                (c) => c.parentCategoryId == CategoryRepositoryImpl.billsExpensesCategoryId,
              ),
            ),
          ),
        ),
      );

      await categoryRepo.seedDefaultCategories(AppConstants.defaultWorkspaceId);
      await expectation;
    });

    test('createCategory validates name trimming, blank names, self-parenting, depth > 1, and cross-workspace parents', () async {
      await categoryRepo.seedDefaultCategories(AppConstants.defaultWorkspaceId);
      final now = DateTime.utc(2026, 11, 25, 12, 0, 0);

      // Trims whitespace and returns normalized category
      final trimmed = await categoryRepo.createCategory(
        Category(
          id: 'cat-custom-trimmed',
          workspaceId: AppConstants.defaultWorkspaceId,
          name: '  Hobbies  ',
          isSystem: false,
          createdAt: now,
        ),
      );
      expect(trimmed.name, 'Hobbies');

      // Blank / whitespace-only name rejected
      await expectLater(
        categoryRepo.createCategory(
          Category(
            id: 'cat-blank',
            workspaceId: AppConstants.defaultWorkspaceId,
            name: '   ',
            isSystem: false,
            createdAt: now,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Self-parenting cycle rejected
      await expectLater(
        categoryRepo.createCategory(
          Category(
            id: 'cat-self-loop',
            workspaceId: AppConstants.defaultWorkspaceId,
            name: 'Self Loop',
            isSystem: false,
            parentCategoryId: 'cat-self-loop',
            createdAt: now,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Grandchild (depth >= 2) rejected
      await expectLater(
        categoryRepo.createCategory(
          Category(
            id: 'cat-grandchild',
            workspaceId: AppConstants.defaultWorkspaceId,
            name: 'Grandchild',
            isSystem: false,
            parentCategoryId: 'cat-sub-bill',
            createdAt: now,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Cross-workspace parent rejected
      await db.into(db.workspaces).insert(
            WorkspacesCompanion.insert(
              id: 'ws-other',
              name: 'Other Workspace',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await expectLater(
        categoryRepo.createCategory(
          Category(
            id: 'cat-cross-ws',
            workspaceId: 'ws-other',
            name: 'Leaked Child',
            isSystem: false,
            parentCategoryId: CategoryRepositoryImpl.billsExpensesCategoryId,
            createdAt: now,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('renameCategory updates name cleanly and rejects empty or whitespace-only names', () async {
      await categoryRepo.seedDefaultCategories(AppConstants.defaultWorkspaceId);

      await categoryRepo.renameCategory('cat-furniture', '  Living Room Furniture  ');

      final categories = await categoryRepo.getCategoriesByWorkspace(AppConstants.defaultWorkspaceId);
      final updated = categories.firstWhere((c) => c.id == 'cat-furniture');
      expect(updated.name, 'Living Room Furniture');

      await expectLater(
        categoryRepo.renameCategory('cat-furniture', ''),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        categoryRepo.renameCategory('cat-furniture', '   \t\n  '),
        throwsA(isA<ArgumentError>()),
      );

      // Verify name remained unchanged after rejected renames
      final afterReject = await categoryRepo.getCategoriesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(afterReject.firstWhere((c) => c.id == 'cat-furniture').name, 'Living Room Furniture');
    });

    test('archiveCategory hides category and cascades archive to active sub-categories without overwriting existing timestamps', () async {
      await categoryRepo.seedDefaultCategories(AppConstants.defaultWorkspaceId);

      // Pre-archive one child with a known historical timestamp
      final earlierArchive = DateTime.utc(2026, 1, 1, 0, 0, 0);
      await (db.update(db.categories)..where((c) => c.id.equals('cat-sub-bill')))
          .write(CategoriesCompanion(archivedAt: Value(earlierArchive)));

      await categoryRepo.archiveCategory(CategoryRepositoryImpl.billsExpensesCategoryId);

      final activeTopLevel = await categoryRepo.getCategoriesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(activeTopLevel.length, 7);
      expect(
        activeTopLevel.any((c) => c.id == CategoryRepositoryImpl.billsExpensesCategoryId),
        isFalse,
      );

      final activeSubs = await categoryRepo.getSubCategories(
        CategoryRepositoryImpl.billsExpensesCategoryId,
      );
      expect(activeSubs, isEmpty);

      // Verify pre-archived child kept its original timestamp
      final preArchivedRow = await (db.select(db.categories)
            ..where((c) => c.id.equals('cat-sub-bill')))
          .getSingle();
      expect(preArchivedRow.archivedAt?.toUtc(), equals(earlierArchive));
    });

    test('Drift v8 to v9 migration preserves existing categories and enables parentCategoryId FK under PRAGMA foreign_keys = ON', () async {
      final rawDb = sqlite3.openInMemory();
      rawDb.execute('''
        CREATE TABLE workspaces (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          workspace_type TEXT NOT NULL DEFAULT 'personal',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          archived_at INTEGER,
          deleted_at INTEGER
        );
        CREATE TABLE categories (
          id TEXT NOT NULL PRIMARY KEY,
          workspace_id TEXT NOT NULL REFERENCES workspaces (id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          icon_key TEXT,
          color_hex TEXT,
          is_system INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL,
          archived_at INTEGER
        );
        CREATE INDEX categories_workspace_name_idx ON categories (workspace_id, name);
        CREATE TABLE records (
          id TEXT NOT NULL PRIMARY KEY,
          workspace_id TEXT NOT NULL REFERENCES workspaces (id) ON DELETE CASCADE,
          category_id TEXT REFERENCES categories (id) ON DELETE SET NULL,
          record_type TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          status TEXT NOT NULL DEFAULT 'active',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          archived_at INTEGER,
          deleted_at INTEGER
        );
        CREATE TABLE bills (
          record_id TEXT NOT NULL PRIMARY KEY REFERENCES records (id) ON DELETE CASCADE,
          utility_type TEXT NOT NULL DEFAULT 'utility',
          provider_name TEXT,
          account_number TEXT,
          billing_period_start INTEGER,
          billing_period_end INTEGER,
          due_date INTEGER,
          amount_due_minor INTEGER NOT NULL,
          currency_code TEXT NOT NULL DEFAULT 'PHP',
          payment_status TEXT NOT NULL DEFAULT 'unpaid',
          paid_at INTEGER,
          linked_asset_record_id TEXT REFERENCES records (id) ON DELETE SET NULL,
          linked_expense_record_id TEXT REFERENCES records (id) ON DELETE SET NULL
        );
        PRAGMA user_version = 8;
      ''');

      final epochSeconds = DateTime.utc(2026, 11, 10).millisecondsSinceEpoch ~/ 1000;
      rawDb.execute('''
        INSERT INTO workspaces (id, name, created_at, updated_at)
        VALUES ('ws-v8', 'Legacy v8 Workspace', $epochSeconds, $epochSeconds);

        INSERT INTO categories (id, workspace_id, name, icon_key, color_hex, is_system, created_at)
        VALUES ('cat-v8-parent', 'ws-v8', 'Legacy Utilities', 'receipt_long', '#1E4B38', 1, $epochSeconds);
      ''');

      final migratedDb = AppDatabase.forTesting(NativeDatabase.opened(rawDb));
      addTearDown(migratedDb.close);

      final migratedRepo = CategoryRepositoryImpl(migratedDb);

      // 1. Existing v8 category survives with null parentCategoryId
      final existingTopLevel = await migratedRepo.getCategoriesByWorkspace('ws-v8');
      expect(existingTopLevel.length, 1);
      expect(existingTopLevel.single.id, 'cat-v8-parent');
      expect(existingTopLevel.single.name, 'Legacy Utilities');
      expect(existingTopLevel.single.parentCategoryId, isNull);
      expect(existingTopLevel.single.isSubCategory, isFalse);

      // 2. Verify PRAGMA foreign_keys = ON is active
      final fkPragma = await migratedDb.customSelect('PRAGMA foreign_keys').getSingle();
      expect(fkPragma.read<int>('foreign_keys'), 1);

      // 3. Can insert a child category referencing the existing v8 parent
      await migratedRepo.createCategory(
        Category(
          id: 'cat-v9-child',
          workspaceId: 'ws-v8',
          name: 'Electricity',
          iconKey: 'bolt',
          isSystem: false,
          parentCategoryId: 'cat-v8-parent',
          createdAt: DateTime.utc(2026, 11, 25),
        ),
      );

      final subs = await migratedRepo.getSubCategories('cat-v8-parent');
      expect(subs.length, 1);
      expect(subs.single.id, 'cat-v9-child');
      expect(subs.single.parentCategoryId, 'cat-v8-parent');

      // 4. SQLite FK directly rejects inserting a child referencing a missing parent
      await expectLater(
        migratedDb.into(migratedDb.categories).insert(
              CategoriesCompanion.insert(
                id: 'cat-v9-orphan',
                workspaceId: 'ws-v8',
                name: 'Orphan',
                isSystem: const Value(false),
                parentCategoryId: const Value('cat-does-not-exist'),
                createdAt: DateTime.utc(2026, 11, 25),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}
