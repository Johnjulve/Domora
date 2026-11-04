import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/features/categories/data/category_repository_impl.dart';
import 'package:domora/features/categories/domain/category.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:domora/features/workspaces/domain/workspace.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    test('seedDefaultCategories seeds all 5 sanctuary categories', () async {
      await categoryRepo.seedDefaultCategories(AppConstants.defaultWorkspaceId);

      final categories = await categoryRepo.getCategoriesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(categories.length, 5);

      final names = categories.map((c) => c.name).toSet();
      expect(names, containsAll(['Properties', 'Vehicles', 'Appliances', 'Electronics', 'Family']));
    });

    test('seedDefaultCategories is idempotent on repeated execution', () async {
      await categoryRepo.seedDefaultCategories(AppConstants.defaultWorkspaceId);
      await categoryRepo.seedDefaultCategories(AppConstants.defaultWorkspaceId);

      final categories = await categoryRepo.getCategoriesByWorkspace(AppConstants.defaultWorkspaceId);
      expect(categories.length, 5);
    });

    test('Can create a custom category and retrieve it', () async {
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
    });

    test('watchCategoriesByWorkspace emits updates reactively', () async {
      final stream = categoryRepo.watchCategoriesByWorkspace(AppConstants.defaultWorkspaceId);

      expectLater(
        stream,
        emitsThrough(hasLength(5)),
      );

      await categoryRepo.seedDefaultCategories(AppConstants.defaultWorkspaceId);
    });
  });
}
