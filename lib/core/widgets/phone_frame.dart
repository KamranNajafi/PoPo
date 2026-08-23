import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'bottom_nav.dart';

/// The phone screen card: gradient body, radius 22, max width 390.
///
/// Padding is `22 18 18`, and 26 at the top in simple mode — the design gives
/// simple mode more breathing room to go with its larger type.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({
    super.key,
    required this.child,
    this.nav,
    this.simpleMode = false,
    this.scrollable = true,
  });

  final Widget child;

  /// The floating pill nav, drawn over the content rather than in the flow.
  final BottomNav? nav;
  final bool simpleMode;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.fromLTRB(
      S.x18,
      simpleMode ? S.x26 : S.x22,
      S.x18,
      nav == null ? S.x18 : 76,
    );

    Widget body = Padding(padding: padding, child: child);
    if (scrollable) {
      body = SingleChildScrollView(
        padding: padding,
        physics: const ClampingScrollPhysics(),
        child: child,
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 390),
      decoration: const BoxDecoration(
        gradient: C.screenGradient,
        borderRadius: R.lgAll,
        boxShadow: Shadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: body),
          if (nav != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: S.x18,
              child: nav!,
            ),
        ],
      ),
    );
  }
}

/// One screen as it appears on the gallery canvas: the small mono number and
/// title above the card, matching the labels in the prototype.
class GalleryTile extends StatelessWidget {
  const GalleryTile({
    super.key,
    required this.number,
    required this.title,
    required this.child,
    this.width = 330,
    this.height = 720,
  });

  final String number;
  final String title;
  final Widget child;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: S.x10, right: 2),
            child: Row(
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(number, style: T.screenNumber),
                ),
                const SizedBox(width: S.x8),
                Flexible(
                  child: Text(title,
                      style: T.chip.copyWith(color: C.body),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}
