/// Application-wide constants for Domora.
class AppConstants {
  AppConstants._();

  /// Product name
  static const String appName = 'Domora';

  /// SQLite schema version for Drift (v3: Tasks & Responsibilities table)
  static const int schemaVersion = 3;

  /// Default personal workspace identifier (deterministic fallback before multi-workspace)
  static const String defaultWorkspaceId = 'default-personal-workspace';
  static const String defaultWorkspaceName = 'Personal';

  /// Standard currency code ISO 4217 fallback
  static const String defaultCurrency = 'PHP';
}
