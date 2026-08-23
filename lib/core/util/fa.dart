import 'package:flutter/widgets.dart';

/// Persian numerals.
///
/// The design shows every user-facing number in Persian digits (۱۲۸ نتیجه) while
/// every technical value stays Latin (`42 ms`, `192.168.43.1 : 8888`). Those are
/// two different decisions, so they get two different call sites: [fa] converts,
/// [MonoText] deliberately does not.
const _fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

/// Converts the ASCII digits in [input] to Persian digits.
String fa(Object? input) {
  final s = '$input';
  final buf = StringBuffer();
  for (final rune in s.runes) {
    if (rune >= 0x30 && rune <= 0x39) {
      buf.write(_fa[rune - 0x30]);
    } else {
      buf.writeCharCode(rune);
    }
  }
  return buf.toString();
}

/// `۸ / ۱۰` style counters.
String faRatio(int a, int b) => '${fa(a)} / ${fa(b)}';

/// A counter rendered with Persian digits.
///
/// Two things make this its own widget. Persian digits force the sans face,
/// because IBM Plex Mono has no glyphs for them. And a bare "۸ / ۱۰" inside an
/// RTL paragraph is reordered by the bidi algorithm into "۱۰ / ۸", so the run
/// has to be pinned LTR to keep the pair in the order it was written.
class FaCounter extends StatelessWidget {
  const FaCounter(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Text(text, style: style),
      );
}
