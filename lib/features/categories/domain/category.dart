/// Pure domain entity representing a category tag in Domora.
class Category {
  final String id;
  final String workspaceId;
  final String name;
  final String? iconKey;
  final String? colorHex;
  final bool isSystem;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.iconKey,
    this.colorHex,
    this.isSystem = true,
    required this.createdAt,
  });

  Category copyWith({
    String? id,
    String? workspaceId,
    String? name,
    String? iconKey,
    String? colorHex,
    bool? isSystem,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          name == other.name &&
          iconKey == other.iconKey &&
          colorHex == other.colorHex &&
          isSystem == other.isSystem &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        workspaceId,
        name,
        iconKey,
        colorHex,
        isSystem,
        createdAt,
      );
}

/// Abstract contract for category persistence operations.
abstract class CategoryRepository {
  /// Retrieves all categories belonging to a workspace.
  Future<List<Category>> getCategoriesByWorkspace(String workspaceId);

  /// Watches categories belonging to a workspace reactively.
  Stream<List<Category>> watchCategoriesByWorkspace(String workspaceId);

  /// Idempotently seeds default Sanctuary categories (Properties, Vehicles, Appliances, Electronics, Family).
  Future<void> seedDefaultCategories(String workspaceId);

  /// Creates a new user-defined category.
  Future<Category> createCategory(Category category);
}
