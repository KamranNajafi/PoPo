import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import 'prefs.dart';

/// The app's language.
///
/// `null` means "follow the device", which is the standard default: an app that
/// forces one language is wrong for every user whose device says otherwise.
class LocaleController extends ChangeNotifier {
  LocaleController(this._prefs) {
    final saved = _prefs.getString(_key);
    if (saved != null && saved.isNotEmpty) _locale = Locale(saved);
  }

  static const _key = 'locale';

  final Prefs _prefs;
  Locale? _locale;

  Locale? get locale => _locale;

  /// The locales the app actually ships, straight from the generated
  /// localizations so this list cannot drift from the ARB files.
  static List<Locale> get supported => L.supportedLocales;

  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;
    _locale = locale;
    if (locale == null) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, locale.languageCode);
    }
    notifyListeners();
  }
}

/// Endonyms — a language is always listed in its own language, never translated
/// into the current one, so a user who cannot read the current language can
/// still find theirs.
const kLanguageNames = <String, String>{'fa': 'فارسی', 'en': 'English'};
