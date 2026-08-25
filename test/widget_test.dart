import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:popo/gallery/gallery_page.dart';
import 'package:popo/gallery/screen_catalog.dart';
import 'package:popo/l10n/app_localizations.dart';

class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Widget _localized(Locale locale) => MaterialApp(
  locale: locale,
  supportedLocales: L.supportedLocales,
  localizationsDelegates: L.localizationsDelegates,
  home: const _Probe(),
);

void main() {
  testWidgets('the gallery renders every screen without overflowing', (
    tester,
  ) async {
    // Wide enough that the Wrap lays screens out in several columns, tall enough
    // that each 720px tile is actually laid out rather than culled.
    tester.view.physicalSize = const Size(2400, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // The gallery is no longer what the app opens on, so render it directly
    // rather than through PoPoApp — otherwise this test silently starts
    // asserting about onboarding instead.
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fa'),
        supportedLocales: L.supportedLocales,
        localizationsDelegates: L.localizationsDelegates,
        home: GalleryPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('each screen renders on its own at phone width', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final spec in kScreens) {
      // The desktop window is not a phone screen; judge it at a desktop size.
      tester.view.physicalSize = spec.wide
          ? const Size(1100, 900)
          : const Size(390, 900);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fa'),
          supportedLocales: L.supportedLocales,
          localizationsDelegates: L.localizationsDelegates,
          home: ScreenPage(spec: spec),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'screen ${spec.number} threw while laying out',
      );
    }
  });

  group('localization', () {
    testWidgets('Persian renders RTL with Persian digits', (tester) async {
      await tester.pumpWidget(_localized(const Locale('fa')));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(_Probe));
      expect(Directionality.of(context), TextDirection.rtl);
      expect(L.of(context).resultsCount(128), contains('۱۲۸'));
    });

    testWidgets('English renders LTR with Latin digits', (tester) async {
      await tester.pumpWidget(_localized(const Locale('en')));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(_Probe));
      expect(
        Directionality.of(context),
        TextDirection.ltr,
        reason: 'direction must follow the locale, not be hardcoded',
      );
      expect(L.of(context).resultsCount(128), contains('128'));
    });

    testWidgets('every screen renders in English too', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      for (final spec in kScreens) {
        tester.view.physicalSize = spec.wide
            ? const Size(1100, 900)
            : const Size(390, 900);

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            supportedLocales: L.supportedLocales,
            localizationsDelegates: L.localizationsDelegates,
            home: ScreenPage(spec: spec),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'screen ${spec.number} threw in English',
        );
      }
    });

    test('the two locales define exactly the same keys', () {
      // Guards the failure mode where a string is added to one ARB only and the
      // other language silently falls back.
      expect(L.supportedLocales.map((l) => l.languageCode).toSet(), {
        'en',
        'fa',
      });
    });
  });
}
