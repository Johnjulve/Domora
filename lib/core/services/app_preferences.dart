import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Local JSON-backed persistence service for non-relational client state (e.g. onboarding completion).
class AppPreferences {
  final File _file;
  final Map<String, dynamic> _data;

  AppPreferences._(this._file, this._data);

  AppPreferences.forTesting([Map<String, dynamic>? initialData])
      : _file = File(''),
        _data = initialData ?? {};

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

  String get householdName => _data['household_name'] as String? ?? 'Elena Miller';

  Future<void> setHouseholdName(String value) async {
    _data['household_name'] = value;
    await _save();
  }

  String get householdAddress => _data['household_address'] as String? ?? '428 Elmwood';

  Future<void> setHouseholdAddress(String value) async {
    _data['household_address'] = value;
    await _save();
  }

  String get autoLockDuration => _data['auto_lock_duration'] as String? ?? 'Immediately';

  Future<void> setAutoLockDuration(String value) async {
    _data['auto_lock_duration'] = value;
    await _save();
  }

  String get reminderTime => _data['reminder_time'] as String? ?? '8:30 AM';

  Future<void> setReminderTime(String value) async {
    _data['reminder_time'] = value;
    await _save();
  }

  String get themeMode => _data['theme_mode'] as String? ?? 'system';

  Future<void> setThemeMode(String value) async {
    _data['theme_mode'] = value;
    await _save();
  }

  Future<void> resetAll() async {
    _data.clear();
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
