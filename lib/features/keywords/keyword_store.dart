import 'package:flutter/foundation.dart';

import '../../core/discovery/keywords.dart';
import '../../core/discovery/models.dart';
import '../../core/util/prefs.dart';

/// A switchable group of generated phrases, matching the generator's tag axes.
enum KeywordSet {
  protocol('protocol'),
  freshness('fresh'),
  persian('persian'),
  siteScoped('site'),
  rawLinks('raw');

  const KeywordSet(this.tag);

  /// The tag [KeywordGenerator] stamps on phrases from this axis.
  final String tag;
}

/// The phrases a run will actually use: generated ones the user can switch off
/// by category, plus their own additions, minus anything they removed.
///
/// The generated list is not editable phrase-by-phrase on purpose. It is
/// regenerated whenever the month changes, so per-phrase edits to it would
/// silently disappear; the user gets category switches over the generated set
/// and full control over their own list, and both survive regeneration.
class KeywordStore extends ChangeNotifier {
  KeywordStore({
    required this.prefs,
    this.generator = const KeywordGenerator(),
    this.limit = 60,
  }) {
    _custom = prefs.getStringList(_customKey) ?? [];
    _removed = (prefs.getStringList(_removedKey) ?? []).toSet();
    final disabled = prefs.getStringList(_disabledSetsKey) ?? const [];
    _disabledSets = disabled
        .map((name) => KeywordSet.values.where((s) => s.name == name).firstOrNull)
        .nonNulls
        .toSet();
  }

  static const _customKey = 'keywords.custom';
  static const _removedKey = 'keywords.removed';
  static const _disabledSetsKey = 'keywords.disabledSets';

  final Prefs prefs;
  final KeywordGenerator generator;
  final int limit;

  late List<String> _custom;
  late Set<String> _removed;
  late Set<KeywordSet> _disabledSets;

  /// Everything the generator produced, before the user's switches.
  List<Keyword> get generated => generator.generate(limit: limit);

  /// The generated phrases that survive the category switches and removals.
  List<Keyword> get activeGenerated => generated
      .where((k) => !_removed.contains(k.text))
      .where((k) => !k.tags.any((t) => _disabledSets.any((s) => s.tag == t)))
      .toList();

  /// The user's own phrases.
  List<String> get custom => List.unmodifiable(_custom);

  /// What a run searches for: the user's phrases first, since an explicit
  /// choice should outrank a generated guess.
  ///
  /// Deduplicated by text, because a user can type a phrase the generator also
  /// produces — searching it twice would waste a slot of the run's budget.
  List<Keyword> get effective {
    final seen = <String>{};
    final out = <Keyword>[];
    for (final keyword in [
      for (final text in _custom) Keyword(text, weight: 2.0, tags: const {'custom'}),
      ...activeGenerated,
    ]) {
      if (seen.add(keyword.text.toLowerCase())) out.add(keyword);
    }
    return out;
  }

  bool isSetEnabled(KeywordSet set) => !_disabledSets.contains(set);

  int countIn(KeywordSet set) =>
      generated.where((k) => k.tags.contains(set.tag)).length;

  bool isHidden(String text) => _removed.contains(text);

  /// Adds a phrase. Returns false when it is blank or already present — the
  /// caller shows that as a message rather than silently doing nothing.
  Future<bool> add(String text) async {
    final phrase = text.trim();
    if (phrase.isEmpty) return false;
    if (_custom.any((k) => k.toLowerCase() == phrase.toLowerCase())) return false;

    _custom = [..._custom, phrase];
    // Adding back something previously removed should un-remove it.
    _removed.remove(phrase);
    await _persist();
    return true;
  }

  Future<void> removeCustom(String text) async {
    _custom = _custom.where((k) => k != text).toList();
    await _persist();
  }

  /// Hides one generated phrase. Recorded by text so it stays hidden across
  /// regenerations.
  Future<void> hideGenerated(String text) async {
    _removed.add(text);
    await _persist();
  }

  Future<void> setSetEnabled(KeywordSet set, bool enabled) async {
    if (enabled) {
      _disabledSets.remove(set);
    } else {
      _disabledSets.add(set);
    }
    await _persist();
  }

  Future<void> restoreDefaults() async {
    _custom = [];
    _removed = {};
    _disabledSets = {};
    await _persist();
  }

  Future<void> _persist() async {
    await prefs.setStringList(_customKey, _custom);
    await prefs.setStringList(_removedKey, _removed.toList());
    await prefs.setStringList(
        _disabledSetsKey, _disabledSets.map((s) => s.name).toList());
    notifyListeners();
  }
}
