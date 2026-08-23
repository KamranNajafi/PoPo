import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../l10n/app_localizations.dart';

/// Locale-aware number formatting.
///
/// The design shows Persian numerals, but that is a property of the Persian
/// locale rather than of the app: `intl` renders ۱۲۸ under `fa` and 128 under
/// `en` from the same call. Hardcoding Persian digits would have made the
/// English build wrong.
///
/// Most numbers reach the UI through an ARB placeholder with
/// `"format": "decimalPattern"`, which does this already. This helper is for
/// the few that are composed in code.
String formatNumber(BuildContext context, num value) =>
    NumberFormat.decimalPattern(Localizations.localeOf(context).toString())
        .format(value);

/// Same, without a [BuildContext] — for use where the locale is already known.
String formatNumberIn(Locale locale, num value) =>
    NumberFormat.decimalPattern(locale.toString()).format(value);

/// Shorthand for the generated localizations.
L strings(BuildContext context) => L.of(context);

/// A counter such as `8 / 10`, pinned LTR.
///
/// Under RTL the bidi algorithm reorders a bare "8 / 10" into "10 / 8", because
/// the two numbers are separate weak runs either side of a neutral slash. The
/// pair has to be pinned to keep the order it was written in. It also cannot use
/// the mono face: IBM Plex Mono has no Persian glyphs, and the Persian locale
/// renders these digits as ۸ / ۱۰.
class RatioText extends StatelessWidget {
  const RatioText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Text(text, style: style),
      );
}
