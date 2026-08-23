import 'package:flutter/widgets.dart';

import '../core/theme/tokens.dart';
import '../core/theme/typography.dart';
import '../core/widgets/buttons.dart';
import '../core/widgets/controls.dart';
import '../core/widgets/icons.dart';
import '../core/widgets/mono.dart';
import '../core/widgets/phone_frame.dart';
import '../core/widgets/status_hero.dart';
import '../core/widgets/surfaces.dart';

/// S1 · Start — the whole app reduced to one button.
class SimpleStartScreen extends StatelessWidget {
  const SimpleStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      simpleMode: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          const Center(child: AppMark(size: 88, radius: 26)),
          const SizedBox(height: S.x22),
          const Center(child: Text('PoPo', style: T.wordmark)),
          const SizedBox(height: S.x14),
          Text(
            'یک دکمه را بزنید تا خودش بهترین راه اتصال را\nپیدا کند و وصل شوید.',
            style: T.simpleBody,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 44),
          const PrimaryButton('شروع ستاپ', oversized: true),
          const SizedBox(height: S.x18),
          const Center(child: TextLink('حالت پیشرفته')),
        ],
      ),
    );
  }
}

/// S2 · Steps running — three automatic steps, no technical error copy.
class SimpleStepsScreen extends StatelessWidget {
  const SimpleStepsScreen({super.key});

  static const _steps = [
    ('جست‌وجو در موتورها', '۱۰ موتور · ۱۲۸ نتیجه', 'انجام شد', StepState.done, C.success),
    ('بررسی سلامت و سرعت', '۳۱ مورد سالم', 'در حال انجام', StepState.running, C.primary),
    ('انتخاب بهترین گزینه', 'کم‌ترین پینگ', 'در انتظار', StepState.waiting, C.muted),
  ];

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      simpleMode: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: S.x20),
          const Center(child: StatusHero(state: HeroState.working, size: 112)),
          const SizedBox(height: S.x22),
          Center(
            child: HeroCaption(
              title: 'کمی صبر کنید',
              titleStyle: T.hero,
              body: 'مرحلهٔ ۲ از ۳',
            ),
          ),
          const SizedBox(height: S.x26),
          for (final (title, note, state, circle, color) in _steps) ...[
            ListCard(
              child: Row(
                children: [
                  StepCircle(circle),
                  const SizedBox(width: S.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: T.simpleListItem.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(note, style: T.small),
                      ],
                    ),
                  ),
                  const SizedBox(width: S.x8),
                  Text(state, style: T.chip.copyWith(color: color)),
                ],
              ),
            ),
            const SizedBox(height: S.x10),
          ],
          const SizedBox(height: S.x14),
          const SecondaryButton('انصراف'),
        ],
      ),
    );
  }
}

/// S3 · Ready — the setup finished; one button left.
class SimpleReadyScreen extends StatelessWidget {
  const SimpleReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      simpleMode: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 36),
          const Center(child: StatusHero(state: HeroState.ready, size: 112)),
          const SizedBox(height: S.x22),
          Center(child: Text('آماده است', style: T.simpleHero)),
          const SizedBox(height: S.x14),
          Text(
            'یک سرور سریع پیدا شد.\nبرای وصل شدن دکمهٔ زیر را بزنید.',
            style: T.simpleBody,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: S.x16),
          const Center(
            child: MonoText(
              'NL · Amsterdam · 42 ms',
              style: TextStyle(
                fontFamily: kMono,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: C.success,
              ),
            ),
          ),
          const SizedBox(height: 40),
          const PrimaryButton('اتصال', oversized: true),
          const SizedBox(height: S.x12),
          const SecondaryButton('انتخاب دستی از لیست'),
        ],
      ),
    );
  }
}

/// S4 · Connected + switch — the only screen a simple-mode user sees day to day.
class SimpleConnectedScreen extends StatelessWidget {
  const SimpleConnectedScreen({super.key});

  static const _servers = [
    ('هلند · آمستردام', '42 ms', C.success, true),
    ('آلمان · فرانکفورت', '78 ms', C.success, false),
    ('فنلاند · هلسینکی', '126 ms', C.warning, false),
  ];

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      simpleMode: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: S.x14),
          const Center(child: StatusHero(state: HeroState.working, size: 104)),
          const SizedBox(height: S.x18),
          Center(child: Text('متصل هستید', style: T.simpleHero)),
          const SizedBox(height: S.x10),
          const Center(
            child: MonoText(
              '42 ms · 00:37:12',
              style: TextStyle(
                fontFamily: kMono,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: C.success,
              ),
            ),
          ),
          const SizedBox(height: S.x24),
          const SectionTitle('انتخاب سرور'),
          for (final (name, ping, color, selected) in _servers)
            Container(
              padding: const EdgeInsets.symmetric(vertical: S.x12),
              decoration: const BoxDecoration(border: hairlineBottom),
              child: Row(
                children: [
                  AppRadio(selected),
                  const SizedBox(width: S.x12),
                  Expanded(child: Text(name, style: T.simpleListItem)),
                  MonoText(ping, style: T.monoValue.copyWith(color: color)),
                ],
              ),
            ),
          const SizedBox(height: S.x24),
          const PrimaryButton('قطع اتصال', oversized: true, showConnectedDot: true),
          const SizedBox(height: S.x12),
          const GhostButton(
            'ستاپ دوباره و لیست تازه',
            expand: true,
            large: true,
            color: C.primaryMuted,
            leading: AppIcon(AppIcons.refresh, size: 16, color: C.primaryMuted),
          ),
        ],
      ),
    );
  }
}
