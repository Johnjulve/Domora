import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../../core/constants/app_constants.dart';

/// Item counts across all entities captured in a backup.
class BackupCounts {
  final int workspaces;
  final int categories;
  final int records;
  final int assets;
  final int tasks;
  final int documents;
  final int expenses;
  final int bills;
  final int fieldDefinitions;
  final int fieldValues;

  const BackupCounts({
    required this.workspaces,
    required this.categories,
    required this.records,
    required this.assets,
    required this.tasks,
    required this.documents,
    required this.expenses,
    this.bills = 0,
    this.fieldDefinitions = 0,
    this.fieldValues = 0,
  });

  int get totalItems =>
      workspaces +
      categories +
      records +
      assets +
      tasks +
      documents +
      expenses +
      bills +
      fieldDefinitions +
      fieldValues;

  Map<String, dynamic> toJson() => {
        'workspaces': workspaces,
        'categories': categories,
        'records': records,
        'assets': assets,
        'tasks': tasks,
        'documents': documents,
        'expenses': expenses,
        'bills': bills,
        'fieldDefinitions': fieldDefinitions,
        'fieldValues': fieldValues,
      };

  factory BackupCounts.fromJson(Map<String, dynamic> json) => BackupCounts(
        workspaces: json['workspaces'] as int? ?? 0,
        categories: json['categories'] as int? ?? 0,
        records: json['records'] as int? ?? 0,
        assets: json['assets'] as int? ?? 0,
        tasks: json['tasks'] as int? ?? 0,
        documents: json['documents'] as int? ?? 0,
        expenses: json['expenses'] as int? ?? 0,
        bills: json['bills'] as int? ?? 0,
        fieldDefinitions: json['fieldDefinitions'] as int? ?? 0,
        fieldValues: json['fieldValues'] as int? ?? 0,
      );
}

/// Metadata header describing the format version, timestamp, workspace, and integrity checksum.
class BackupManifest {
  static const int currentFormatVersion = 1;

  final int version;
  final String appVersion;
  final DateTime exportedAt;
  final String workspaceId;
  final String workspaceName;
  final BackupCounts counts;
  final String payloadChecksum;

  const BackupManifest({
    required this.version,
    required this.appVersion,
    required this.exportedAt,
    required this.workspaceId,
    required this.workspaceName,
    required this.counts,
    required this.payloadChecksum,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'appVersion': appVersion,
        'exportedAt': exportedAt.toIso8601String(),
        'workspaceId': workspaceId,
        'workspaceName': workspaceName,
        'counts': counts.toJson(),
        'payloadChecksum': payloadChecksum,
      };

  factory BackupManifest.fromJson(Map<String, dynamic> json) => BackupManifest(
        version: json['version'] as int? ?? 1,
        appVersion: json['appVersion'] as String? ?? AppConstants.appVersion,
        exportedAt: DateTime.parse(json['exportedAt'] as String),
        workspaceId: json['workspaceId'] as String,
        workspaceName: json['workspaceName'] as String,
        counts: BackupCounts.fromJson(json['counts'] as Map<String, dynamic>),
        payloadChecksum: json['payloadChecksum'] as String,
      );
}

/// Complete backup archive payload containing both the manifest and data records.
class BackupPayload {
  final BackupManifest manifest;
  final List<Map<String, dynamic>> workspaces;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> records;
  final List<Map<String, dynamic>> assets;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> documents;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> bills;
  final List<Map<String, dynamic>> fieldDefinitions;
  final List<Map<String, dynamic>> fieldValues;

  const BackupPayload({
    required this.manifest,
    required this.workspaces,
    required this.categories,
    required this.records,
    required this.assets,
    required this.tasks,
    required this.documents,
    required this.expenses,
    this.bills = const [],
    this.fieldDefinitions = const [],
    this.fieldValues = const [],
  });

  Map<String, dynamic> toJson() => {
        'manifest': manifest.toJson(),
        'data': {
          'workspaces': workspaces,
          'categories': categories,
          'records': records,
          'assets': assets,
          'tasks': tasks,
          'documents': documents,
          'expenses': expenses,
          'bills': bills,
          'fieldDefinitions': fieldDefinitions,
          'fieldValues': fieldValues,
        },
      };

  /// Computes a deterministic SHA-256 checksum over the raw data map.
  static String computeChecksum(Map<String, dynamic> dataMap) {
    final rawJson = jsonEncode(dataMap);
    return sha256.convert(utf8.encode(rawJson)).toString();
  }
}

/// Validation result enum for backup archives.
enum BackupValidationStatus {
  valid,
  corrupted,
  unsupportedVersion,
  missingData,
}

/// Structured outcome of verifying a backup archive before performing restore.
class BackupValidationResult {
  final BackupValidationStatus status;
  final BackupManifest? manifest;
  final BackupPayload? payload;
  final String? errorMessage;

  const BackupValidationResult.valid({
    required this.manifest,
    required this.payload,
  })  : status = BackupValidationStatus.valid,
        errorMessage = null;

  const BackupValidationResult.invalid({
    required this.status,
    this.manifest,
    this.errorMessage,
  }) : payload = null;

  bool get isValid => status == BackupValidationStatus.valid;
}
