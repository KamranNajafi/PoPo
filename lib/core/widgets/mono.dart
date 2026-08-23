import 'package:flutter/widgets.dart';

import '../theme/typography.dart';

/// Technical data — IP, port, ping, timestamps, protocol strings.
///
/// The app is RTL end to end, but these values are meaningless mirrored, so this
/// widget pins them to LTR. Using it everywhere is the point: the failure mode of
/// doing it by hand is that a handful of values silently flip in production.
class MonoText extends StatelessWidget {
  const MonoText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.softWrap = true,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool softWrap;
  final TextOverflow? overflow;

  /// IBM Plex Mono carries no Persian glyphs, so Persian digits inside a mono
  /// style render as tofu. That is invisible in a widget test and easy to miss
  /// in a screenshot, so fail loudly in debug instead: a value with Persian
  /// digits is UI text, not technical data, and belongs in the sans face.
  static bool _hasPersianDigits(String s) =>
      s.runes.any((r) => r >= 0x06F0 && r <= 0x06F9);

  @override
  Widget build(BuildContext context) {
    assert(
      !_hasPersianDigits(text),
      'MonoText was given Persian digits ("$text"). IBM Plex Mono cannot render '
      'them. Use a sans style for counters and prose; keep MonoText for IP, '
      'port, ping, timestamps and protocol strings.',
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        text,
        style: style ?? T.monoValue,
        textAlign: textAlign,
        softWrap: softWrap,
        overflow: overflow,
      ),
    );
  }
}
