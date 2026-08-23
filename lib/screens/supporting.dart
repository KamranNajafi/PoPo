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

/// 05 · Settings.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _rows = [
    ('جست‌وجوی خودکار', 'هر ۶ ساعت', true),
    ('سقف نتایج هر موتور', '۵۰ مورد', true),
    ('تایم‌اوت تست', '۵ ثانیه', true),
    ('حذف خودکار کانفیگ مرده', 'پس از ۲ تست ناموفق', true),
    ('حالت ساده', 'یک دکمه، بدون تنظیمات', false),
  ];

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('تنظیمات', style: T.screenTitle),
          const SizedBox(height: S.x14),
          for (final (label, caption, on) in _rows)
            SettingRow(label: label, caption: caption, trailing: AppToggle(on)),
          const SettingRow(
            label: 'تم',
            caption: 'کهربا · تیره',
            trailing: AppIcon(AppIcons.swap, size: 18, color: C.muted),
          ),
          const SizedBox(height: S.x24),
          const DestructiveButton('پاک‌کردن همهٔ نتایج'),
        ],
      ),
    );
  }
}

/// 06 · Saved + bulk actions.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  static const _rows = [
    ('هلند · آمستردام', 'VLESS · Reality', '42 ms', C.success, true),
    ('آلمان · فرانکفورت', 'VMess · WS+TLS', '78 ms', C.success, true),
    ('لهستان · ورشو', 'HTTPS · 185.244.10.9:8080', '154 ms', C.warning, false),
    ('ترکیه · استانبول', 'Trojan · gRPC', '—', C.danger, false),
  ];

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      nav: const BottomNav(items: Navs.items, activeIndex: Navs.saved),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            leading: Text('ذخیره‌شده‌ها', style: T.screenTitle),
            trailing: Text('${fa(2)} انتخاب‌شده', style: T.small),
          ),
          const SizedBox(height: S.x16),
          const Wrap(
            spacing: S.x8,
            runSpacing: S.x8,
            children: [
              AppChip('کپی همه', filled: true),
              AppChip('خروجی سابسکریپشن'),
              AppChip('QR'),
              AppChip('تست همه'),
            ],
          ),
          const SizedBox(height: S.x16),
          for (final (name, proto, ping, color, checked) in _rows) ...[
            ListCard(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  AppCheckbox(checked),
                  const SizedBox(width: S.x12),
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
                  const SizedBox(width: S.x8),
                  MonoText(ping, style: T.monoValue.copyWith(color: color)),
                ],
              ),
            ),
            const SizedBox(height: S.x10),
          ],
        ],
      ),
    );
  }
}

/// 07 · Keywords. Compiled out of the Apple builds along with discovery.
class KeywordsScreen extends StatelessWidget {
  const KeywordsScreen({super.key});

  static const _keywords = [
    'free v2ray config',
    'vless reality',
    'socks5 list',
    'کانفیگ رایگان',
    'subscription link',
    'trojan server',
  ];

  static const _sets = [
    ('ست v2ray', '۱۲ عبارت', true),
    ('ست پروکسی socks/http', '۹ عبارت', true),
    ('ست کانال‌های تلگرام', '۷ عبارت', false),
  ];

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('عبارت‌های کلیدی', style: T.screenTitle),
          const SizedBox(height: S.x16),
          Container(
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
                Expanded(child: Text('افزودن عبارت تازه…', style: T.caption)),
              ],
            ),
          ),
          const SizedBox(height: S.x14),
          Wrap(
            spacing: S.x8,
            runSpacing: S.x8,
            children: [
              for (final k in _keywords)
                AppChip(
                  k,
                  selected: true,
                  trailing: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: C.primaryMuted),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: S.x24),
          const SectionTitle('ست‌های آماده'),
          for (final (name, count, on) in _sets)
            SettingRow(label: name, caption: count, trailing: AppToggle(on)),
        ],
      ),
    );
  }
}

/// 08 · Proxy detail.
class ProxyDetailScreen extends StatelessWidget {
  const ProxyDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('جزئیات پروکسی', style: T.screenTitle),
          const SizedBox(height: S.x24),
          const Center(child: MonoText('51.15.42.7:1080', style: T.monoHero)),
          const SizedBox(height: S.x10),
          Center(
            child: Text('فنلاند · هلسینکی',
                style: T.buttonSecondary.copyWith(fontSize: 15)),
          ),
          const SizedBox(height: S.x14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Badge('پورت باز', C.success),
              SizedBox(width: S.x8),
              _Badge('Elite', C.primaryMuted),
            ],
          ),
          const SizedBox(height: S.x22),
          const MetaRow('نوع', 'SOCKS5'),
          const MetaRow('آدرس', '51.15.42.7 : 1080'),
          const MetaRow('آنونیمیتی', 'Elite'),
          const MetaRow('پشتیبانی HTTPS', 'yes'),
          const MetaRow('آخرین تست پورت', 'open · 126 ms', showDivider: false),
          const SizedBox(height: S.x18),
          const PrimaryButton('کپی ip:port'),
          const SizedBox(height: S.x10),
          const SplitRow(
            start: SecondaryButton('تست پورت'),
            end: SecondaryButton('بازکردن در V2rayNG'),
          ),
          const SizedBox(height: S.x14),
          const Center(child: TextLink('گزارش خراب‌بودن', color: C.danger)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: S.x12),
        decoration: BoxDecoration(
          borderRadius: R.pill,
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Text(label, style: T.chip.copyWith(color: color)),
      );

}

/// 09 · History + import. On iOS the import block is the app's primary entry point.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const _runs = [
    ('امروز ۱۴:۲۰', '۱۲۸ نتیجه · ۳۱ سالم · ۸ موتور'),
    ('دیروز ۰۹:۰۵', '۹۴ نتیجه · ۲۲ سالم · ۸ موتور'),
    ('۳ روز پیش', '۱۵۱ نتیجه · ۴۰ سالم · ۱۰ موتور'),
  ];

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('تاریخچه', style: T.screenTitle),
          const SizedBox(height: S.x14),
          for (final (at, meta) in _runs)
            Container(
              padding: const EdgeInsets.symmetric(vertical: S.x14),
              decoration: const BoxDecoration(border: hairlineBottom),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(at, style: T.listTitle),
                        const SizedBox(height: 3),
                        Text(meta, style: T.small),
                      ],
                    ),
                  ),
                  const SizedBox(width: S.x8),
                  const GhostButton('اجرای دوباره'),
                ],
              ),
            ),
          const SizedBox(height: S.x24),
          const SectionTitle('ایمپورت'),
          const SplitRow(
            start: SecondaryButton('لینک سابسکریپشن'),
            end: SecondaryButton('از کلیپ‌بورد'),
          ),
        ],
      ),
    );
  }
}

/// 10 · Empty & error states. Every one names a next action.
class ErrorStatesScreen extends StatelessWidget {
  const ErrorStatesScreen({super.key});

  static const _states = [
    (
      C.muted,
      'نتیجه‌ای پیدا نشد',
      'عبارت‌های کلیدی را کم‌تر خاص کنید یا موتور بیشتری روشن کنید.',
      'تغییر عبارت‌ها'
    ),
    (
      C.danger,
      'اینترنت قطع است',
      'اتصال دستگاه را بررسی کنید و دوباره تلاش کنید.',
      'تلاش دوباره'
    ),
    (
      C.warning,
      'Yandex کپچا خواست',
      'این موتور موقتاً کنار گذاشته شد؛ بقیه ادامه دادند.',
      'رد کردن این موتور'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('حالت‌های خالی و خطا', style: T.screenTitle),
          const SizedBox(height: S.x16),
          for (final (dot, title, body, action) in _states) ...[
            ListCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusDot(dot),
                      const SizedBox(width: S.x10),
                      Expanded(child: Text(title, style: T.listTitle)),
                    ],
                  ),
                  const SizedBox(height: S.x8),
                  Text(body, style: T.caption),
                  const SizedBox(height: S.x12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GhostButton(action),
                  ),
                ],
              ),
            ),
            const SizedBox(height: S.x12),
          ],
        ],
      ),
    );
  }
}

/// 11 · Onboarding + safety.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      simpleMode: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: S.x20),
          const Center(child: AppMark(size: 88, radius: 26)),
          const SizedBox(height: S.x22),
          Center(child: Text('لیست‌های رایگان، یک‌جا', style: T.onboardTitle)),
          const SizedBox(height: S.x14),
          Text(
            'PoPo سرورهای عمومی را جمع می‌کند، سرعتشان را می‌سنجد\nو سریع‌ترین را به شما می‌دهد.',
            style: T.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: S.x20),
          const PagerDots(count: 2, active: 0),
          const SizedBox(height: S.x24),
          Container(
            padding: const EdgeInsets.all(S.x16),
            decoration: BoxDecoration(
              color: C.warnPanelBg,
              borderRadius: R.mdAll,
              border: Border.all(color: C.warnPanelBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('یک نکتهٔ مهم',
                    style: T.listTitle.copyWith(color: C.warning)),
                const SizedBox(height: S.x8),
                Text(
                  'این سرورها را افراد ناشناس روی اینترنت گذاشته‌اند. برای عبور از '
                  'محدودیت خوب‌اند، ولی نام کاربری و رمز بانکی خود را روی آن‌ها وارد نکنید.',
                  style: T.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: S.x24),
          const PrimaryButton('متوجه شدم، شروع کنیم'),
          const SizedBox(height: S.x14),
          const Center(child: TextLink('رد کردن')),
        ],
      ),
    );
  }
}
