import 'package:flutter/widgets.dart';

import '../core/theme/tokens.dart';
import '../core/theme/typography.dart';
import '../core/widgets/buttons.dart';
import '../core/widgets/icons.dart';
import '../core/widgets/mono.dart';
import '../core/widgets/status_hero.dart';
import '../core/widgets/surfaces.dart';

/// 17 · Desktop — a 190px sidebar and a fluid content area.
class DesktopScreen extends StatelessWidget {
  const DesktopScreen({super.key});

  static const _nav = [
    (AppIcons.dashboard, 'داشبورد', true),
    (AppIcons.results, 'نتایج', false),
    (AppIcons.bookmark, 'ذخیره‌ها', false),
    (AppIcons.share, 'اشتراک اتصال', false),
    (AppIcons.history, 'تاریخچه', false),
    (AppIcons.simple, 'حالت ساده', false),
    (AppIcons.settings, 'تنظیمات', false),
  ];

  static const _stats = [
    ('کانفیگ سالم', '۳۱'),
    ('پروکسی سالم', '۵۸'),
    ('دستگاه‌های وصل', '۳'),
    ('مصرف امروز', '۱.۴ GB'),
  ];

  static const _fastest = [
    ('هلند · آمستردام', 'VLESS · Reality', '42 ms', C.success),
    ('آلمان · فرانکفورت', 'VMess · WS+TLS', '78 ms', C.success),
    ('فنلاند · هلسینکی', 'SOCKS5 · 51.15.42.7:1080', '126 ms', C.warning),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 380),
      decoration: const BoxDecoration(
        gradient: C.screenGradient,
        borderRadius: R.lgAll,
        boxShadow: Shadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _WindowChrome(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 190,
                  padding: const EdgeInsets.all(S.x16),
                  // RTL: the sidebar sits on the right, so its inner edge is the left one.
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: C.hairline)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const AppMark(size: 26, radius: 8),
                          const SizedBox(width: S.x8),
                          Text('PoPo', style: T.listTitle.copyWith(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: S.x20),
                      for (final (icon, label, active) in _nav)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              vertical: S.x10, horizontal: S.x12),
                          decoration: active
                              ? BoxDecoration(
                                  color: C.accentTint,
                                  borderRadius: R.smAll,
                                  border: Border.all(color: C.accentBorder),
                                )
                              : null,
                          child: Row(
                            children: [
                              AppIcon(icon,
                                  size: 18,
                                  color: active ? C.primaryMuted : C.muted),
                              const SizedBox(width: S.x10),
                              Flexible(
                                child: Text(
                                  label,
                                  softWrap: false,
                                  overflow: TextOverflow.fade,
                                  style: T.chip.copyWith(
                                    fontSize: 13,
                                    color: active ? C.primaryMuted : C.body,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(S.x20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const StatusHero(state: HeroState.working, size: 56),
                            const SizedBox(width: S.x14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('متصل · هلند', style: T.hero),
                                  const SizedBox(height: 4),
                                  const MonoText('42 ms · 00:37:12',
                                      style: T.monoName),
                                ],
                              ),
                            ),
                            const SizedBox(width: S.x12),
                            const SizedBox(
                                width: 130, child: PrimaryButton('قطع اتصال')),
                            const SizedBox(width: S.x10),
                            const SizedBox(
                                width: 130, child: SecondaryButton('ستاپ دوباره')),
                          ],
                        ),
                        const SizedBox(height: S.x22),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // repeat(auto-fit, minmax(150px, 1fr))
                            final columns =
                                (constraints.maxWidth / 164).floor().clamp(1, 4);
                            return Wrap(
                              spacing: S.x14,
                              runSpacing: S.x14,
                              children: [
                                for (final (label, value) in _stats)
                                  SizedBox(
                                    width: (constraints.maxWidth -
                                            S.x14 * (columns - 1)) /
                                        columns,
                                    child: ListCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(label, style: T.small),
                                          const SizedBox(height: 6),
                                          Text(value,
                                              style: T.simpleHero
                                                  .copyWith(fontSize: 24)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: S.x22),
                        const SectionTitle('سریع‌ترین گزینه‌ها'),
                        for (final (name, proto, ping, color) in _fastest) ...[
                          Container(
                            padding: const EdgeInsets.all(S.x12),
                            decoration: BoxDecoration(
                              color: C.surfaceElevated,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(14)),
                              border: hairlineBorder(),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: T.listTitle),
                                      const SizedBox(height: 2),
                                      MonoText(proto, style: T.monoSub),
                                    ],
                                  ),
                                ),
                                MonoText(ping,
                                    style:
                                        T.monoValue.copyWith(color: color)),
                              ],
                            ),
                          ),
                          const SizedBox(height: S.x10),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowChrome extends StatelessWidget {
  const _WindowChrome();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: S.x10, horizontal: S.x14),
      decoration: const BoxDecoration(
        color: Color(0x59000000),
        border: hairlineBottom,
      ),
      child: Row(
        children: [
          for (final color in const [
            Color(0xFFFF5F57),
            Color(0xFFFEBC2E),
            Color(0xFF28C840),
          ])
            Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          Expanded(
            child: Text('PoPo', style: T.chip.copyWith(fontSize: 13),
                textAlign: TextAlign.center),
          ),
          const SizedBox(width: 60),
        ],
      ),
    );
  }
}

/// 18 · Tray menu, quick tiles, and how each platform surfaces them.
class TrayScreen extends StatelessWidget {
  const TrayScreen({super.key});

  static const _menu = [
    ('قطع اتصال', '42 ms', true),
    ('تعویض سرور', '', false),
    ('ستاپ دوباره', '', false),
    ('اشتراک اتصال · روشن', '', false),
    ('خروج', '', false),
  ];

  static const _platforms = [
    ('Android', 'کوییک‌تایل و ویجت'),
    ('iOS', 'میان‌بر و ویجت'),
    ('Windows', 'سینی سیستم'),
    ('macOS', 'نوار منو'),
    ('Linux', 'CLI و GUI'),
  ];

  @override
  Widget build(BuildContext context) {
    return PhoneFrameless(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('سینی سیستم و کوییک‌تایل', style: T.screenTitle),
          const SizedBox(height: S.x16),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0x99000000),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              border: hairlineBorder(),
            ),
            child: Column(
              children: [
                for (final (label, meta, highlighted) in _menu)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: S.x10, horizontal: S.x12),
                    decoration: highlighted
                        ? const BoxDecoration(
                            color: C.accentTint,
                            borderRadius: BorderRadius.all(Radius.circular(9)),
                          )
                        : null,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: T.chip.copyWith(
                              fontSize: 13,
                              color: highlighted ? C.primaryMuted : C.body,
                            ),
                          ),
                        ),
                        if (meta.isNotEmpty)
                          MonoText(meta,
                              style: T.monoName.copyWith(color: C.success)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: S.x18),
          const Row(
            children: [
              Expanded(child: _QuickTile(title: 'PoPo', state: 'متصل', active: true)),
              SizedBox(width: S.x12),
              Expanded(
                  child: _QuickTile(
                      title: 'اشتراک', state: '۳ دستگاه', active: false)),
            ],
          ),
          const SizedBox(height: S.x22),
          const SectionTitle('روی هر پلتفرم'),
          for (final (platform, surface) in _platforms)
            Container(
              padding: const EdgeInsets.symmetric(vertical: S.x12),
              decoration: const BoxDecoration(border: hairlineBottom),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MonoText(platform, style: T.monoName.copyWith(color: C.heading)),
                  Text(surface, style: T.caption),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.title, required this.state, required this.active});

  final String title;
  final String state;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(S.x14),
      decoration: BoxDecoration(
        color: active ? C.accentTint : C.surfaceElevated,
        borderRadius: R.mdAll,
        border: Border.all(color: active ? C.accentBorder : C.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(active ? AppIcons.power : AppIcons.share,
              size: 22, color: active ? C.primaryMuted : C.muted),
          const SizedBox(height: S.x12),
          Text(title,
              style: T.listTitle
                  .copyWith(color: active ? C.primaryMuted : C.heading)),
          const SizedBox(height: 2),
          Text(state, style: T.small),
        ],
      ),
    );
  }
}

/// The tray screen is not a phone screen, but it shares the card treatment.
class PhoneFrameless extends StatelessWidget {
  const PhoneFrameless({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: C.screenGradient,
          borderRadius: R.lgAll,
          boxShadow: Shadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(S.x18, S.x22, S.x18, S.x18),
          physics: const ClampingScrollPhysics(),
          child: child,
        ),
      );
}
