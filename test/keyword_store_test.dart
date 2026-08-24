import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/discovery/keywords.dart';
import 'package:popo/core/util/prefs.dart';
import 'package:popo/features/keywords/keyword_store.dart';

void main() {
  late MemoryPrefs prefs;
  late KeywordStore store;

  setUp(() {
    prefs = MemoryPrefs();
    store = KeywordStore(
      prefs: prefs,
      generator: KeywordGenerator(now: DateTime(2026, 3)),
    );
  });

  test('starts with the generated phrases and no custom ones', () {
    expect(store.custom, isEmpty);
    expect(store.activeGenerated, isNotEmpty);
    expect(store.effective.length, store.activeGenerated.length);
  });

  test('a users own phrase outranks generated ones', () async {
    await store.add('my private list');

    expect(store.custom, ['my private list']);
    expect(
      store.effective.first.text,
      'my private list',
      reason: 'an explicit choice must be searched before a generated guess',
    );
    expect(
      store.effective.first.weight,
      greaterThan(store.activeGenerated.first.weight),
    );
  });

  test('rejects blank and duplicate phrases', () async {
    expect(await store.add('  '), isFalse);
    expect(await store.add('vless'), isTrue);
    expect(
      await store.add('VLESS'),
      isFalse,
      reason: 'duplicates are case-insensitive',
    );
    expect(store.custom, ['vless']);
  });

  test('removing a custom phrase drops it from the run', () async {
    await store.add('temporary');
    await store.removeCustom('temporary');

    expect(store.custom, isEmpty);
    expect(store.effective.any((k) => k.text == 'temporary'), isFalse);
  });

  test('switching off a category removes exactly that category', () async {
    final before = store.activeGenerated.length;
    final persianCount = store.countIn(KeywordSet.persian);
    expect(persianCount, greaterThan(0));

    await store.setSetEnabled(KeywordSet.persian, false);

    expect(store.isSetEnabled(KeywordSet.persian), isFalse);
    expect(
      store.activeGenerated.any((k) => k.tags.contains('persian')),
      isFalse,
    );
    expect(store.activeGenerated.length, lessThan(before));
  });

  test(
    'a hidden generated phrase stays hidden when the list regenerates',
    () async {
      final phrase = store.activeGenerated.first.text;
      await store.hideGenerated(phrase);

      // A fresh store over the same storage stands in for the next app launch,
      // by which point the generator may have produced a different list.
      final reopened = KeywordStore(
        prefs: prefs,
        generator: KeywordGenerator(now: DateTime(2026, 4)),
      );

      expect(reopened.isHidden(phrase), isTrue);
      expect(reopened.activeGenerated.any((k) => k.text == phrase), isFalse);
    },
  );

  test('edits survive a restart', () async {
    await store.add('persisted phrase');
    await store.setSetEnabled(KeywordSet.siteScoped, false);

    final reopened = KeywordStore(
      prefs: prefs,
      generator: KeywordGenerator(now: DateTime(2026, 3)),
    );

    expect(reopened.custom, ['persisted phrase']);
    expect(reopened.isSetEnabled(KeywordSet.siteScoped), isFalse);
  });

  test('restoring defaults clears every edit', () async {
    await store.add('mine');
    await store.setSetEnabled(KeywordSet.persian, false);
    await store.hideGenerated(store.activeGenerated.first.text);

    await store.restoreDefaults();

    expect(store.custom, isEmpty);
    expect(store.isSetEnabled(KeywordSet.persian), isTrue);
    expect(store.activeGenerated.length, store.generated.length);
  });

  test('re-adding a hidden phrase un-hides it', () async {
    final phrase = store.activeGenerated.first.text;
    await store.hideGenerated(phrase);
    expect(store.isHidden(phrase), isTrue);

    await store.add(phrase);

    expect(store.isHidden(phrase), isFalse);
    expect(
      store.effective.where((k) => k.text == phrase),
      hasLength(1),
      reason: 'it should come back once, not twice',
    );
  });

  test('notifies listeners on every edit', () async {
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.add('a');
    await store.removeCustom('a');
    await store.setSetEnabled(KeywordSet.freshness, false);

    expect(notifications, 3);
  });
}
