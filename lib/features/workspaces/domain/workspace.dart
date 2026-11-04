/// Pure domain entity for a Workspace in Domora.
class Workspace {
  final String id;
  final String name;
  final String workspaceType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final DateTime? deletedAt;

  const Workspace({
    required this.id,
    required this.name,
    required this.workspaceType,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get isArchived => archivedAt != null;

  Workspace copyWith({
    String? id,
    String? name,
    String? workspaceType,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
    DateTime? deletedAt,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      workspaceType: workspaceType ?? this.workspaceType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Workspace &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          workspaceType == other.workspaceType &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          archivedAt == other.archivedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        workspaceType,
        createdAt,
        updatedAt,
        archivedAt,
        deletedAt,
      );
}

/// Abstract contract for workspace persistence operations.
abstract class WorkspaceRepository {
  /// Retrieves or creates the default personal workspace atomically.
  Future<Workspace> getOrCreateDefaultWorkspace();

  /// Retrieves all active (non-soft-deleted) workspaces as a snapshot.
  Future<List<Workspace>> getActiveWorkspaces();

  /// Watches all active workspaces reactively as a stream.
  Stream<List<Workspace>> watchActiveWorkspaces();

  /// Retrieves a specific workspace by ID, returning null if not found or deleted.
  Future<Workspace?> getWorkspaceById(String id);

  /// Saves or updates a workspace, updating the modified timestamp.
  Future<void> saveWorkspace(Workspace workspace);

  /// Soft deletes a workspace. Throws [UnsupportedError] if called on default workspace.
  Future<void> softDeleteWorkspace(String id);
}
