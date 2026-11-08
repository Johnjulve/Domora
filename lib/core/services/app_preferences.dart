import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Local JSON-backed persistence service for non-relational client state (e.g. onboarding completion).
class AppPreferences {
  final File _file;
  final Map<String, dynamic> _data;

  AppPreferences._(this._file, this._data);

  static Future<AppPreferences> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_preferences.json');
      if (await file.exists()) {
        final text = await file.readAsString();
        final map = jsonDecode(text) as Map<String, dynamic>;
        return AppPreferences._(file, map);
      }
      return AppPreferences._(file, {});
    } catch (_) {
      // In-memory fallback for test harnesses and platforms without path_provider bindings
      return AppPreferences._(File(''), {});
    }
  }

  bool get isOnboardingCompleted => _data['onboarding_completed'] == true;

  Future<void> setOnboardingCompleted(bool value) async {
    _data['onboarding_completed'] = value;
    await _save();
  }

  String get storageMode => _data['storage_mode'] as String? ?? 'offline';

  Future<void> setStorageMode(String mode) async {
    _data['storage_mode'] = mode;
    await _save();
  }

  bool get isBiometricsEnabled => _data['biometrics_enabled'] == true;

  Future<void> setBiometricsEnabled(bool enabled) async {
    _data['biometrics_enabled'] = enabled;
    await _save();
  }

  Future<void> _save() async {
    try {
      if (_file.path.isNotEmpty) {
        await _file.writeAsString(jsonEncode(_data));
      }
    } catch (_) {}
  }
}

/// Provider exposing loaded [AppPreferences]. Defaults to in-memory instance for testing safety.
final appPreferencesProvider = Provider<AppPreferences>((ref) {
  return AppPreferences._(File(''), {});
});
