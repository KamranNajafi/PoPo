import 'package:flutter/widgets.dart';

import '../core/theme/tokens.dart';
import '../core/theme/typography.dart';
import '../core/util/fa.dart';
import '../core/widgets/bottom_nav.dart';
import '../core/widgets/buttons.dart';
import '../core/widgets/controls.dart';
import '../core/widgets/icons.dart';
import '../core/widgets/mono.dart';
import '../core/widgets/phone_frame.dart';
import '../core/widgets/status_hero.dart';
import '../core/widgets/surfaces.dart';

/// 01 · Search — pick engines and keywords, start a run.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  static const _engines = [
    ('DuckDuckGo', true),
    ('Google', true),
    ('Bing', true),
    ('Yahoo', true),
    ('Brave', true),
    ('Ecosia', true),
    ('Startpage', true),
    ('Yandex', true),
    ('Baidu', false),
    ('Kagi', false),
  ];

  static const _keywords = [
    'free v2ray config',
    'vless reality',
    'socks5 list',
    'کانفیگ رایگان',
    'subscription link',
  ];

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      nav: const BottomNav(items: Navs.items, activeIndex: Navs.search),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppMark(),
                const SizedBox(width: S.x10),
                Text('PoPo',
                    style: T.screenTitle.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            trailing: const RoundIconButton(AppIcons.settings),
          ),
          const SizedBox(height: S.x18),
          _SearchField(),
          const SizedBox(height: S.x12),
          Wrap(
            spacing: S.x8,
            runSpacing: S.x8,
            children: [for (final k in _keywords) AppChip(k, selected: true)],
          ),
          const SizedBox(height: S.x22),
          SectionTitle(
            'موتورهای جست‌وجو',
            trailing: FaCounter(
              faRatio(8, 10),
              style: T.chip.copyWith(color: C.primaryMuted, fontSize: 13),
            ),
          ),
          Wrap(
            spacing: S.x8,
            runSpacing: S.x8,
            children: [
              for (final (name, enabled) in _engines)
                if (enabled)
                  AppChip(name,
                      mono: true, selected: true, leading: const StatusDot(C.success))
                else
                  DisabledChip(name),
            ],
          ),
          const SizedBox(height: S.x24),
          const PrimaryButton('جست‌وجو'),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: S.x16),
      decoration: BoxDecoration(
        color: C.surfaceElevated,
        borderRadius: R.pill,
        border: hairlineBorder(),
      ),
      child: Row(
        children: [
          const AppIcon(AppIcons.search, size: 16, color: C.muted),
          const SizedBox(width: S.x10),
          Expanded(
            child: MonoText('free v2ray config',
                style: T.monoValue.copyWith(color: C.heading)),
          ),
        ],
      ),
    );
  }
}

/// 02 · Scanning — progress of a run.
class ScanningScreen extends StatelessWidget {
  const ScanningScreen({super.key});

  static const _rows = [
    ('DuckDuckGo', '۱۴ نتیجه', C.success),
    ('Google', '۱۱ نتیجه', C.success),
    ('Brave', '۹ نتیجه', C.success),
    ('Bing', 'در حال جست‌وجو', C.primary),
    ('Startpage', 'در صف', C.muted),
    ('Yandex', 'بلاک شد', C.danger),
  ];

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            leading: Text('در حال جست‌وجو', style: T.screenTitle),
            trailing: const TextLink('توقف', color: C.primary),
          ),
          const SizedBox(height: S.x24),
          const Center(child: StatusHero(state: HeroState.working)),
          const SizedBox(height: S.x18),
          Center(
            child: HeroCaption(
              title: '${fa(47)} کانفیگ',
              titleStyle: T.onboardTitle,
              body: 'تا اینجا از ${fa(5)} موتور',
            ),
          ),
          const SizedBox(height: S.x24),
          for (final (name, status, color) in _rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: S.x12),
              decoration: const BoxDecoration(border: hairlineBottom),
              child: Row(
                children: [
                  StatusDot(color),
                  const SizedBox(width: S.x10),
                  MonoText(name, style: T.monoName),
                  const Spacer(),
                  Text(status, style: T.chip.copyWith(color: color)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A result row on 03 — a config or a proxy.
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.place,
    required this.protocol,
    required this.ping,
    required this.pingColor,
    required this.age,
    required this.source,
  });

  final String place;
  final String protocol;
  final String ping;
  final Color pingColor;
  final String age;
  final String source;

  @override
  Widget build(BuildContext context) {
    return ListCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(7)),
                  border: Border.all(color: C.primaryMuted, width: 2),
                ),
              ),
              const SizedBox(width: S.x10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place, style: T.listTitle),
                    const SizedBox(height: 2),
                    MonoText(protocol, style: T.monoSub),
                  ],
                ),
              ),
              const SizedBox(width: S.x8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MonoText(ping, style: T.monoValue.copyWith(color: pingColor)),
                  const SizedBox(height: 2),
                  MonoText(age, style: T.timestamp),
                ],
              ),
            ],
          ),
          const SizedBox(height: S.x10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('منبع: $source',
                    style: T.monoSub.copyWith(fontFamily: kSans),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: S.x8),
              const GhostButton('کپی'),
            ],
          ),
        ],
      ),
    );
  }
}

/// 03 · Results — the found endpoints.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  static const _filters = [
    'همه',
    'VLESS',
    'VMess',
    'Shadowsocks',
    'Trojan',
    'HTTP/S',
    'SOCKS5',
  ];

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      nav: const BottomNav(items: Navs.items, activeIndex: Navs.results),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            leading: Text('${fa(128)} نتیجه', style: T.screenTitle),
            trailing: Text('مرتب‌سازی: پینگ', style: T.small),
          ),
          const SizedBox(height: S.x16),
          const _SegmentedTabs(labels: ['کانفیگ‌ها', 'پروکسی‌ها'], activeIndex: 0),
          const SizedBox(height: S.x14),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: S.x8),
              itemBuilder: (_, i) => AppChip(_filters[i], selected: i == 0),
            ),
          ),
          const SizedBox(height: S.x14),
          const ResultCard(
            place: 'هلند · آمستردام',
            protocol: 'VLESS · TCP · Reality',
            ping: '42 ms',
            pingColor: C.success,
            age: '2 min ago',
            source: 'DuckDuckGo',
          ),
          const SizedBox(height: S.x10),
          const ResultCard(
            place: 'فنلاند · هلسینکی',
            protocol: 'SOCKS5 · 51.15.42.7:1080',
            ping: '126 ms',
            pingColor: C.warning,
            age: '8 min ago',
            source: 'Brave',
          ),
          const SizedBox(height: S.x10),
          const ResultCard(
            place: 'لهستان · ورشو',
            protocol: 'HTTPS · 185.244.10.9:8080',
            ping: '154 ms',
            pingColor: C.warning,
            age: '14 min ago',
            source: 'Google',
          ),
          const SizedBox(height: S.x10),
          const ResultCard(
            place: 'ترکیه · استانبول',
            protocol: 'Trojan · gRPC',
            ping: '318 ms',
            pingColor: C.danger,
            age: '21 min ago',
            source: 'Bing',
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.labels, required this.activeIndex});

  final List<String> labels;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: C.surfaceElevated,
        borderRadius: R.pill,
        border: hairlineBorder(),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: S.x10),
                decoration: i == activeIndex
                    ? const BoxDecoration(gradient: C.primaryGradient, borderRadius: R.pill)
                    : null,
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: T.chip.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: i == activeIndex ? C.onPrimary : C.body,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 04 · Config detail.
class ConfigDetailScreen extends StatelessWidget {
  const ConfigDetailScreen({super.key});

  static const _raw =
      'vless://8f3c9a20-4d11-4e7a-9b62-1c0d5e8a7f34@185.199.110.12:443'
      '?encryption=none&security=reality&sni=www.microsoft.com&fp=chrome'
      '&pbk=xnQ7Ip9dK2mV0tRfLb3sYcEuHgWj&type=tcp#PoPo-NL-Amsterdam';

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            leading: Text('جزئیات کانفیگ', style: T.screenTitle),
            trailing: const RoundIconButton(AppIcons.bookmark, square: true),
          ),
          const SizedBox(height: S.x24),
          Center(
            child: StatusHero(
              state: HeroState.idle,
              size: 96,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('42',
                        style: T.mono(26, weight: FontWeight.w500, color: C.success)),
                    const SizedBox(width: 3),
                    Text('ms', style: T.mono(12, color: C.muted)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: S.x16),
          Center(
            child: Column(
              children: [
                Text('هلند · آمستردام', style: T.hero),
                const SizedBox(height: 5),
                const MonoText('VLESS · TCP · Reality', style: T.monoName),
              ],
            ),
          ),
          const SizedBox(height: S.x22),
          const MetaRow('پروتکل', 'VLESS / Reality'),
          const MetaRow('آی‌پی و پورت', '185.***.**.12 : 443'),
          const MetaRow('آخرین تست موفق', '2 min ago · 42 ms'),
          const MetaRow('منبع', 'DuckDuckGo · gist.github', showDivider: false),
          const SizedBox(height: S.x16),
          const SunkenBlock(
            child: MonoText(_raw, style: T.monoRaw, textAlign: TextAlign.left),
          ),
          const SizedBox(height: S.x16),
          const PrimaryButton('کپی لینک'),
          const SizedBox(height: S.x10),
          const SplitRow(
            start: SecondaryButton('تست دوباره'),
            end: SecondaryButton('ذخیره'),
          ),
        ],
      ),
    );
  }
}
