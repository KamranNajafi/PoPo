import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/build/features.dart';
import 'package:popo/gallery/screen_catalog.dart';

void main() {
  test('the default build ships everything', () {
    // No --dart-define under `flutter test`, so this is the Android/desktop
    // build.
    expect(Features.enableDiscovery, isTrue);
    expect(Features.enableSharing, isTrue);
    expect(Features.importIsPrimaryEntry, isFalse);
    expect(shippingScreens, hasLength(kScreens.length));
  });

  test('every screen the canvas lists has an availability', () {
    for (final spec in kScreens) {
      expect(spec.availability, isNotNull, reason: 'screen ${spec.number}');
    }
  });

  test('the screens gated on Apple builds are the ones the handoff names', () {
    final gated = kScreens
        .where((s) => s.availability == Availability.noApple)
        .map((s) => s.number)
        .toSet();

    // 01, 02 and 07 are discovery; 12, 13 and 14 are sharing, which iOS cannot
    // keep alive in the background.
    expect(gated, {'01', '02', '07', '12', '13', '14'});
  });

  test('split tunnelling is marked Android-only', () {
    final androidOnly = kScreens
        .where((s) => s.availability == Availability.androidOnly)
        .map((s) => s.number);

    expect(androidOnly, ['15']);
  });
}
