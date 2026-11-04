import 'package:domora/core/constants/app_constants.dart';
import 'package:domora/core/database/app_database.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:domora/features/workspaces/domain/workspace.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WorkspaceRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = WorkspaceRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('WorkspaceRepositoryImpl Tests', () {
    test('getOrCreateDefaultWorkspace creates default workspace when empty', () async {
      final workspace = await repository.getOrCreateDefaultWorkspace();

      expect(workspace.id, AppConstants.defaultWorkspaceId);
      expect(workspace.name, AppConstants.defaultWorkspaceName);
      expect(workspace.workspaceType, 'personal');
      expect(workspace.isDeleted, isFalse);

      final active = await repository.getActiveWorkspaces();
      expect(active.length, 1);
      expect(active.first.id, AppConstants.defaultWorkspaceId);
    });

    test('getOrCreateDefaultWorkspace is idempotent when called repeatedly', () async {
      final ws1 = await repository.getOrCreateDefaultWorkspace();
      final ws2 = await repository.getOrCreateDefaultWorkspace();

      expect(ws1.id, ws2.id);
      expect(ws1.name, ws2.name);

      final active = await repository.getActiveWorkspaces();
      expect(active.length, 1);
    });

    test('saveWorkspace creates a new workspace and updates on subsequent save', () async {
      final now = DateTime.utc(2026, 11, 4, 10, 0, 0);
      const customId = 'ws-custom-family';

      final newWs = Workspace(
        id: customId,
        name: 'Family Home',
        workspaceType: 'household',
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveWorkspace(newWs);

      final retrieved = await repository.getWorkspaceById(customId);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Family Home');
      expect(retrieved.workspaceType, 'household');

      // Update name
      final updatedWs = retrieved.copyWith(name: 'The Julve Household');
      await repository.saveWorkspace(updatedWs);

      final updatedRetrieved = await repository.getWorkspaceById(customId);
      expect(updatedRetrieved!.name, 'The Julve Household');
    });

    test('softDeleteWorkspace excludes workspace from active list', () async {
      final now = DateTime.utc(2026, 11, 4, 10, 0, 0);
      const customId = 'ws-to-delete';

      final ws = Workspace(
        id: customId,
        name: 'Temporary Workspace',
        workspaceType: 'project',
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveWorkspace(ws);
      expect((await repository.getActiveWorkspaces()).length, 1);

      await repository.softDeleteWorkspace(customId);

      final active = await repository.getActiveWorkspaces();
      expect(active.isEmpty, isTrue);

      final byId = await repository.getWorkspaceById(customId);
      expect(byId, isNull);
    });

    test('softDeleteWorkspace on default personal workspace throws UnsupportedError', () async {
      await repository.getOrCreateDefaultWorkspace();

      expect(
        () async => await repository.softDeleteWorkspace(AppConstants.defaultWorkspaceId),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('watchActiveWorkspaces emits updated list reactively', () async {
      final stream = repository.watchActiveWorkspaces();

      expectLater(
        stream,
        emitsThrough(hasLength(1)),
      );

      // Trigger reactive change
      await repository.getOrCreateDefaultWorkspace();
    });
  });
}
