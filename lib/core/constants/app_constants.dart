/// Application-wide constants for Domora.
class AppConstants {
  AppConstants._();

  /// Product name and active release version
  static const String appName = 'Domora';
  static const String appVersion = '0.1.0';
  static const String appReleaseChannel = 'alpha.12';
  static const String displayVersion = 'v$appVersion';
  static const String fullVersionTag = 'v$appVersion-$appReleaseChannel';

  /// SQLite schema version for Drift (v6: Household Utilities & Recurring Bills Engine)
  static const int schemaVersion = 7;

  /// Default personal workspace identifier (deterministic fallback before multi-workspace)
  static const String defaultWorkspaceId = 'default-personal-workspace';
  static const String defaultWorkspaceName = 'Personal';

  /// Standard currency code ISO 4217 fallback
  static const String defaultCurrency = 'PHP';
}
