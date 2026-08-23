import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper so the rest of the app depends on an interface rather than on
/// shared_preferences directly, and so tests can run against memory.
abstract interface class Prefs {
  String? getString(String key);
  Future<void> setString(String key, String value);
  List<String>? getStringList(String key);
  Future<void> setStringList(String key, List<String> value);
  Future<void> remove(String key);
}

class SharedPrefs implements Prefs {
  SharedPrefs(this._prefs);

  static Future<SharedPrefs> load() async =>
      SharedPrefs(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  @override
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  @override
  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// In-memory implementation, for tests and for the first frame before disk is read.
class MemoryPrefs implements Prefs {
  final Map<String, Object> _store = {};

  @override
  String? getString(String key) => _store[key] as String?;

  @override
  Future<void> setString(String key, String value) async => _store[key] = value;

  @override
  List<String>? getStringList(String key) => _store[key] as List<String>?;

  @override
  Future<void> setStringList(String key, List<String> value) async =>
      _store[key] = value;

  @override
  Future<void> remove(String key) async => _store.remove(key);
}
