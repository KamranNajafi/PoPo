import 'package:flutter/foundation.dart';

import '../../core/util/prefs.dart';

/// The settings screen's values, persisted.
///
/// These are not decoration: the per-engine cap, the test timeout and the
/// auto-remove rule are read by the discovery and health runs, so changing one
/// changes what the next run does.
class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs);

  static const _autoSearchHours = 'settings.autoSearchHours';
  static const _perEngineCapKey = 'settings.perEngineCap';
  static const _timeoutKey = 'settings.testTimeoutSeconds';
  static const _autoRemoveKey = 'settings.autoRemoveDead';
  static const _failuresKey = 'settings.removeAfterFailures';
  static const _simpleModeKey = 'settings.simpleMode';

  final Prefs _prefs;

  int get autoSearchHours => _int(_autoSearchHours, 6);
  int get perEngineCap => _int(_perEngineCapKey, 50);
  int get testTimeoutSeconds => _int(_timeoutKey, 5);
  int get removeAfterFailures => _int(_failuresKey, 2);
  bool get autoRemoveDead => _bool(_autoRemoveKey, true);
  bool get simpleMode => _bool(_simpleModeKey, false);

  Duration get testTimeout => Duration(seconds: testTimeoutSeconds);

  Future<void> setAutoSearchHours(int value) =>
      _setInt(_autoSearchHours, value);
  Future<void> setPerEngineCap(int value) => _setInt(_perEngineCapKey, value);
  Future<void> setTestTimeoutSeconds(int value) => _setInt(_timeoutKey, value);
  Future<void> setRemoveAfterFailures(int value) =>
      _setInt(_failuresKey, value);
  Future<void> setAutoRemoveDead(bool value) => _setBool(_autoRemoveKey, value);
  Future<void> setSimpleMode(bool value) => _setBool(_simpleModeKey, value);

  int _int(String key, int fallback) =>
      int.tryParse(_prefs.getString(key) ?? '') ?? fallback;

  bool _bool(String key, bool fallback) => switch (_prefs.getString(key)) {
    'true' => true,
    'false' => false,
    _ => fallback,
  };

  Future<void> _setInt(String key, int value) async {
    await _prefs.setString(key, '$value');
    notifyListeners();
  }

  Future<void> _setBool(String key, bool value) async {
    await _prefs.setString(key, '$value');
    notifyListeners();
  }
}
