import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:popo/core/util/fa.dart';
import 'package:popo/gallery/screen_catalog.dart';
import 'package:popo/main.dart';

void main() {
  testWidgets('the gallery renders every screen without overflowing',
      (tester) async {
    // Wide enough that the Wrap lays screens out in several columns, tall enough
    // that each 720px tile is actually laid out rather than culled.
    tester.view.physicalSize = const Size(2400, 8000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PoPoApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('each screen renders on its own at phone width', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final spec in kScreens) {
      // The desktop window is not a phone screen; judge it at a desktop size.
      tester.view.physicalSize =
          spec.wide ? const Size(1100, 900) : const Size(390, 900);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fa'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ScreenPage(spec: spec),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'screen ${spec.number} (${spec.title}) threw while laying out');
    }
  });

  group('Persian digits', () {
    test('converts ASCII digits and leaves everything else alone', () {
      expect(fa(128), '۱۲۸');
      expect(fa('۳ روز پیش'), '۳ روز پیش');
      expect(fa('42 ms'), '۴۲ ms');
    });

    test('formats the engine counter', () {
      expect(faRatio(8, 10), '۸ / ۱۰');
    });
  });
}
