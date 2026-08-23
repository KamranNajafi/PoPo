import 'package:flutter/widgets.dart';

/// Design tokens for PoPo.
///
/// These come from `design-system.md` ("Dark Purple Mobile UI") with the amber
/// accent variant this product uses: that system prescribes overriding only
/// `brand.primary` and `accent.success` per app, and PoPo does exactly that.
///
/// Nothing outside this file should hardcode a color, radius or shadow.
abstract final class C {
  // Background
  static const gradientTop = Color(0xFF2A1B3D);
  static const gradientBottom = Color(0xFF1A1A1A);
  static const page = Color(0xFF121016);
  static const surface = Color(0xCC241B33); // rgba(36,27,51,0.80)
  static const surfaceElevated = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)

  // Brand (overridden from the base system's purple)
  static const primary = Color(0xFFFF7A2F);
  static const primaryStrong = Color(0xFFE1580C);
  static const primaryMuted = Color(0xFFFDBA74);

  // Accent
  static const success = Color(0xFFA3E635);
  static const warning = Color(0xFFFBBF24);
  static const danger = Color(0xFFF87171);

  // Text
  static const heading = Color(0xFFFFFFFF);
  static const body = Color(0xFFB8AFC4);
  static const muted = Color(0xFF7A7285);
  static const onPrimary = Color(0xFFFFFFFF);

  // Nav
  static const navBg = Color(0xD9000000); // rgba(0,0,0,0.85)
  static const navInactive = Color(0xB3E5E5E5); // #E5E5E5 @ .7

  // Lines
  static const hairline = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  // Controls
  static const toggleTrackOn = Color(0x59FF7A2F); // rgba(255,122,47,0.35)
  static const toggleTrackOff = surfaceElevated;
  static const toggleKnobOff = muted;

  /// Selected chips, badges, ghost buttons, tray highlight.
  static const accentTint = Color(0x24FF7A2F); // rgba(255,122,47,0.14)
  static const accentBorder = Color(0x73FF7A2F); // rgba(255,122,47,0.45)

  /// Off chip dot and the "waiting" step ring.
  static const offRing = Color(0xFF4A4453);

  /// Console / raw-link blocks.
  static const sunken = Color(0x80000000); // rgba(0,0,0,0.5)

  static const warnPanelBg = Color(0x1AFBBF24); // rgba(251,191,36,0.10)
  static const warnPanelBorder = Color(0x59FBBF24); // rgba(251,191,36,0.35)
  static const dangerBorder = Color(0x59F87171); // rgba(248,113,113,0.35)

  /// Primary buttons are always this vertical gradient, never a flat fill.
  static const primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryStrong],
  );

  /// The connected/working status hero.
  static const heroGradient = RadialGradient(
    center: Alignment(-0.4, -0.5), // circle at 30% 25%
    radius: 0.9,
    colors: [primary, primaryStrong],
    stops: [0.0, 0.7],
  );

  /// The screen card / phone body.
  static const screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientTop, gradientBottom],
  );
}

/// Space scale: 4 / 8 / 10 / 12 / 14 / 16 / 18 / 20 / 22 / 24 / 26.
abstract final class S {
  static const x4 = 4.0;
  static const x8 = 8.0;
  static const x10 = 10.0;
  static const x12 = 12.0;
  static const x14 = 14.0;
  static const x16 = 16.0;
  static const x18 = 18.0;
  static const x20 = 20.0;
  static const x22 = 22.0;
  static const x24 = 24.0;
  static const x26 = 26.0;
}

abstract final class R {
  static const sm = Radius.circular(12);
  static const md = Radius.circular(18);
  static const lg = Radius.circular(22);
  static const squircle = Radius.circular(26);

  static const smAll = BorderRadius.all(sm);
  static const mdAll = BorderRadius.all(md);
  static const lgAll = BorderRadius.all(lg);
  static const squircleAll = BorderRadius.all(squircle);
  static const pill = BorderRadius.all(Radius.circular(999));
}

abstract final class Shadows {
  static const card = [
    BoxShadow(color: Color(0x73000000), blurRadius: 60, offset: Offset(0, 24)),
  ];
  static const primaryButton = [
    BoxShadow(color: Color(0x59000000), blurRadius: 26, offset: Offset(0, 10)),
  ];
  static const connectedHero = [
    BoxShadow(color: Color(0x1AFF7A2F), blurRadius: 0, spreadRadius: 10),
    BoxShadow(color: Color(0x80000000), blurRadius: 40, offset: Offset(0, 18)),
  ];
}

/// A hairline border. Every divider and outline in the design is this one value.
BoxBorder hairlineBorder([Color color = C.hairline]) =>
    Border.all(color: color, width: 1);

const hairlineBottom = Border(
  bottom: BorderSide(color: C.hairline),
);
