import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'icons.dart';

class NavItem {
  const NavItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// The floating pill nav. Max three items: the active one shows icon + label,
/// the rest are icon-only at 70% opacity.
class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.items, required this.activeIndex});

  final List<NavItem> items;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: S.x10, horizontal: S.x18),
        decoration: const BoxDecoration(color: C.navBg, borderRadius: R.pill),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: S.x20),
              _NavEntry(item: items[i], active: i == activeIndex),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavEntry extends StatelessWidget {
  const _NavEntry({required this.item, required this.active});

  final NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(
          item.icon,
          size: 20,
          color: active ? C.primaryMuted : C.navInactive,
        ),
        if (active) ...[
          const SizedBox(width: 6),
          Text(item.label, style: T.navLabel),
        ],
      ],
    );
  }
}

/// The three nav configurations the design uses.
abstract final class Navs {
  static const items = [
    NavItem('جست‌وجو', AppIcons.search),
    NavItem('نتایج', AppIcons.results),
    NavItem('ذخیره‌ها', AppIcons.bookmark),
  ];

  static const search = 0;
  static const results = 1;
  static const saved = 2;
}
