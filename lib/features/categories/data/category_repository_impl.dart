import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/category.dart';

/// Drift-backed implementation of [CategoryRepository].
class CategoryRepositoryImpl implements CategoryRepository {
  final AppDatabase _db;

  const CategoryRepositoryImpl(this._db);

  static const List<Map<String, String>> defaultCategorySeeds = [
    {'id': 'cat-properties', 'name': 'Properties', 'icon': 'home', 'color': '#1E4B38'},
    {'id': 'cat-vehicles', 'name': 'Vehicles', 'icon': 'directions_car', 'color': '#2E7D5B'},
    {'id': 'cat-appliances', 'name': 'Appliances', 'icon': 'kitchen', 'color': '#92400E'},
    {'id': 'cat-electronics', 'name': 'Electronics', 'icon': 'devices', 'color': '#1E4B38'},
    {'id': 'cat-family', 'name': 'Family', 'icon': 'people', 'color': '#5D6860'},
  ];

  @override
  Future<void> seedDefaultCategories(String workspaceId) async {
    final now = DateTime.now().toUtc();
    await _db.batch((batch) {
      for (final seed in defaultCategorySeeds) {
        batch.insert(
          _db.categories,
          CategoriesCompanion.insert(
            id: seed['id']!,
            workspaceId: workspaceId,
            name: seed['name']!,
            iconKey: Value(seed['icon']),
            colorHex: Value(seed['color']),
            isSystem: const Value(true),
            createdAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  @override
  Future<List<Category>> getCategoriesByWorkspace(String workspaceId) async {
    final entities = await (_db.select(_db.categories)
          ..where((c) => c.workspaceId.equals(workspaceId))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();

    return entities.map(_toDomain).toList();
  }

  @override
  Stream<List<Category>> watchCategoriesByWorkspace(String workspaceId) {
    return (_db.select(_db.categories)
          ..where((c) => c.workspaceId.equals(workspaceId))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch()
        .map((entities) => entities.map(_toDomain).toList());
  }

  @override
  Future<Category> createCategory(Category category) async {
    await _db.into(_db.categories).insert(_toCompanion(category));
    return category;
  }

  Category _toDomain(CategoryEntity entity) {
    return Category(
      id: entity.id,
      workspaceId: entity.workspaceId,
      name: entity.name,
      iconKey: entity.iconKey,
      colorHex: entity.colorHex,
      isSystem: entity.isSystem,
      createdAt: entity.createdAt,
    );
  }

  CategoriesCompanion _toCompanion(Category category) {
    return CategoriesCompanion(
      id: Value(category.id),
      workspaceId: Value(category.workspaceId),
      name: Value(category.name),
      iconKey: Value(category.iconKey),
      colorHex: Value(category.colorHex),
      isSystem: Value(category.isSystem),
      createdAt: Value(category.createdAt),
    );
  }
}
