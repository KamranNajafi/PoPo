import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// The two families in the design. Persian and Latin UI text is Plex Arabic;
/// anything technical (IP, port, ping, timestamps, protocol names) is Plex Mono
/// and always rendered LTR — see [MonoText].
const kSans = 'PlexArabic';
const kMono = 'PlexMono';

/// The type scale, named by the role it plays in the design rather than by size,
/// so a screen reads as intent and not as a pile of magic numbers.
///
/// Sizes in use: 26 · 24 · 22 · 20 · 19 · 17 · 16 · 15 · 14 · 13 · 12 · 11 · 10.
abstract final class T {
  static const _h = 1.18; // headings 1.15–1.2
  static const _b = 1.5; // body 1.4–1.6

  static TextStyle _s(double size, FontWeight w, Color c, double h) =>
      TextStyle(
        fontFamily: kSans,
        fontSize: size,
        fontWeight: w,
        color: c,
        height: h,
      );

  // Simple mode leans one step larger than the equivalent advanced screen.
  static const wordmark = TextStyle(
    fontFamily: kSans,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: C.heading,
    height: _h,
  );
  static final simpleHero = _s(24, FontWeight.w700, C.heading, _h);
  static final onboardTitle = _s(22, FontWeight.w700, C.heading, _h);
  static final hero = _s(20, FontWeight.w700, C.heading, _h);
  static final connectedHero = _s(19, FontWeight.w700, C.heading, _h);
  static final screenTitle = _s(17, FontWeight.w700, C.heading, _h);
  static final simpleBody = _s(17, FontWeight.w400, C.body, 1.6);
  static final buttonPrimary = _s(16, FontWeight.w700, C.onPrimary, 1.2);
  static final simpleListItem = _s(16, FontWeight.w500, C.heading, 1.3);
  static final buttonSecondary = _s(15, FontWeight.w600, C.heading, 1.2);
  static final stepTitle = _s(15, FontWeight.w600, C.heading, 1.3);
  static final listTitle = _s(14, FontWeight.w600, C.heading, 1.3);
  static final settingLabel = _s(14, FontWeight.w500, C.heading, 1.3);
  static final body = _s(14, FontWeight.w400, C.body, _b);
  static final caption = _s(13, FontWeight.w400, C.body, _b);
  static final navLabel = _s(13, FontWeight.w600, C.primaryMuted, 1.2);
  static final chip = _s(12, FontWeight.w500, C.body, 1.2);
  static final small = _s(12, FontWeight.w400, C.muted, 1.45);

  // Mono roles.
  static const _m = TextStyle(fontFamily: kMono, color: C.body, height: 1.35);
  static const monoHero = TextStyle(
    fontFamily: kMono,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: C.heading,
    height: 1.2,
  );
  static const monoValue = TextStyle(
    fontFamily: kMono,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: C.body,
    height: 1.3,
  );
  static const monoName = TextStyle(
    fontFamily: kMono,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: C.body,
    height: 1.3,
  );
  static const monoSub = TextStyle(
    fontFamily: kMono,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: C.muted,
    height: 1.45,
  );
  static const monoRaw = TextStyle(
    fontFamily: kMono,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: C.body,
    height: 1.6,
  );
  static const screenNumber = TextStyle(
    fontFamily: kMono,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: C.muted,
    height: 1.2,
  );
  static const timestamp = TextStyle(
    fontFamily: kMono,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: C.muted,
    height: 1.3,
  );

  static TextStyle mono(double size, {FontWeight? weight, Color? color}) =>
      _m.copyWith(fontSize: size, fontWeight: weight, color: color);
}
