import 'backup_manifest.dart';

/// Contract for exporting, validating, and restoring workspace backup archives.
abstract class BackupRepository {
  /// Generates an in-memory [BackupPayload] snapshot for the specified workspace.
  Future<BackupPayload> createBackup(String workspaceId);

  /// Exports the workspace data to a formatted JSON string with manifest and checksum.
  Future<String> exportBackupToJson(String workspaceId);

  /// Verifies the structural integrity, version compatibility, and checksum of a backup JSON string.
  Future<BackupValidationResult> validateBackup(String jsonContent);

  /// Atomically restores a validated backup archive into SQLite within a single transaction.
  /// If [clearExisting] is true, deletes all existing workspace records first.
  Future<void> restoreBackup(
    BackupPayload payload, {
    required bool clearExisting,
  });
}
