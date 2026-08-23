import 'package:flutter/widgets.dart';

import '../core/theme/tokens.dart';
import '../core/theme/typography.dart';
import '../core/util/fa.dart';
import '../core/widgets/buttons.dart';
import '../core/widgets/controls.dart';
import '../core/widgets/icons.dart';
import '../core/widgets/mono.dart';
import '../core/widgets/phone_frame.dart';
import '../core/widgets/status_hero.dart';
import '../core/widgets/surfaces.dart';

/// 12 · Proxy server — the local HTTP + SOCKS5 listener other devices route through.
///
/// Android and desktop only: iOS cannot keep a background listener alive, so this
/// screen sits behind the same kind of build flag as discovery.
class ProxyServerScreen extends StatelessWidget {
  const ProxyServerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            leading: Text('اشتراک اتصال', style: T.screenTitle),
            trailing: const AppToggle(true),
          ),
          const SizedBox(height: S.x24),
          const Center(child: StatusHero(state: HeroState.ready, size: 96)),
          const SizedBox(height: S.x18),
          Center(child: Text('سرور روشن است', style: T.connectedHero)),
          const SizedBox(height: S.x10),
          const Center(
            child: MonoText(
              '192.168.43.1 : 8888',
              style: TextStyle(
                fontFamily: kMono,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: C.success,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text('${fa(3)} دستگاه وصل است · ۱.۴ GB امروز', style: T.small),
          ),
          const SizedBox(height: S.x22),
          const MetaRow('آدرس پروکسی', '192.168.43.1'),
          const MetaRow('پورت HTTP', '8888'),
          const MetaRow('پورت SOCKS5', '1080'),
          const MetaRow('نام کاربری', 'popo'),
          const MetaRow('رمز', '•••• ••••', showDivider: false),
          const SizedBox(height: S.x18),
          const PrimaryButton('نمایش کد QR اتصال'),
          const SizedBox(height: S.x10),
          const SplitRow(
            start: SecondaryButton('تغییر رمز'),
            end: SecondaryButton('روشن‌کردن هات‌اسپات'),
          ),
        ],
      ),
    );
  }
}

/// 13 · Connected devices.
class ConnectedDevicesScreen extends StatelessWidget {
  const ConnectedDevicesScreen({super.key});

  static const _devices = [
    (AppIcons.laptop, 'لپ‌تاپ کار', '192.168.43.24', 'فعال', C.success, '۸۴۰ MB امروز'),
    (AppIcons.tv, 'تلویزیون پذیرایی', '192.168.43.31', 'فعال', C.success, '۴۹۰ MB امروز'),
    (AppIcons.phone, 'موبایل دوم', '192.168.43.47', 'در انتظار تأیید', C.warning, '—'),
  ];

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('دستگاه‌های وصل', style: T.screenTitle),
          const SizedBox(height: S.x16),
          for (final (icon, name, ip, state, color, usage) in _devices) ...[
            ListCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppIcon(icon, size: 22),
                      const SizedBox(width: S.x12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: T.listTitle),
                            const SizedBox(height: 2),
                            MonoText(ip, style: T.monoSub),
                          ],
                        ),
                      ),
                      const SizedBox(width: S.x8),
                      Text(state, style: T.chip.copyWith(color: color)),
                    ],
                  ),
                  const SizedBox(height: S.x12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(usage, style: T.small)),
                      const SizedBox(width: S.x8),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GhostButton('محدودکردن'),
                          SizedBox(width: S.x8),
                          GhostButton.destructive('قطع'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: S.x12),
          ],
          const SizedBox(height: S.x8),
          const SecondaryButton('فقط دستگاه‌های تأییدشده وصل شوند'),
        ],
      ),
    );
  }
}

/// 14 · Pairing guide — how a second device joins.
class PairingGuideScreen extends StatelessWidget {
  const PairingGuideScreen({super.key});

  static const _steps = [
    ('هات‌اسپات گوشی را روشن کنید', 'از تنظیمات گوشی، اشتراک اینترنت را فعال کنید.'),
    ('روی دستگاه دوم به تنظیمات Wi-Fi بروید', 'به همان هات‌اسپات وصل شوید.'),
    ('پروکسی را روی Manual بگذارید', 'آدرس و پورت زیر را وارد کنید.'),
    ('ذخیره کنید یا QR را اسکن کنید', 'بعد از ذخیره، اینترنت از تونل عبور می‌کند.'),
  ];

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('راهنمای اتصال', style: T.screenTitle),
          const SizedBox(height: S.x18),
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: C.heading,
                borderRadius: R.mdAll,
              ),
              child: const Center(
                child: AppIcon(AppIcons.qr, size: 104, color: C.gradientBottom),
              ),
            ),
          ),
          const SizedBox(height: S.x22),
          for (var i = 0; i < _steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: C.accentTint,
                    shape: BoxShape.circle,
                    border: Border.all(color: C.accentBorder),
                  ),
                  child: Center(
                    child: Text(fa(i + 1),
                        style: T.chip.copyWith(color: C.primaryMuted, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: S.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_steps[i].$1, style: T.stepTitle),
                      const SizedBox(height: 3),
                      Text(_steps[i].$2, style: T.caption),
                      if (i == 2) ...[
                        const SizedBox(height: S.x8),
                        const SunkenBlock(
                          padding: EdgeInsets.symmetric(vertical: S.x10, horizontal: S.x12),
                          child: MonoText('192.168.43.1 : 8888',
                              style: TextStyle(
                                fontFamily: kMono,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: C.heading,
                              )),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: S.x16),
          ],
          const SizedBox(height: S.x4),
          const PrimaryButton('کپی آدرس و پورت'),
        ],
      ),
    );
  }
}

/// 15 · Split tunneling. Android only — iOS has no per-app routing API.
class SplitTunnelScreen extends StatelessWidget {
  const SplitTunnelScreen({super.key});

  static const _apps = [
    (AppIcons.browser, 'مرورگر', 'از تونل عبور می‌کند', true),
    (AppIcons.chat, 'پیام‌رسان', 'از تونل عبور می‌کند', true),
    (AppIcons.bank, 'بانک', 'مستقیم وصل می‌شود', false),
    (AppIcons.video, 'پخش ویدیو', 'مستقیم وصل می‌شود', false),
  ];

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('تفکیک ترافیک', style: T.screenTitle),
          const SizedBox(height: 6),
          Text('انتخاب کنید کدام برنامه از تونل رد شود.', style: T.caption),
          const SizedBox(height: S.x16),
          for (final (icon, name, note, on) in _apps)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: const BoxDecoration(border: hairlineBottom),
              child: Row(
                children: [
                  AppIcon(icon, size: 22),
                  const SizedBox(width: S.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: T.settingLabel),
                        const SizedBox(height: 3),
                        Text(note, style: T.small),
                      ],
                    ),
                  ),
                  AppToggle(on),
                ],
              ),
            ),
          const SizedBox(height: S.x22),
          const SplitRow(
            start: SecondaryButton('همه از تونل'),
            end: SecondaryButton('هیچ‌کدام'),
          ),
        ],
      ),
    );
  }
}

/// 16 · Security & sync.
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  static const _rows = [
    ('قطع اینترنت هنگام افت تونل', 'Kill switch', true),
    ('DNS امن', '1.1.1.1 · DoH', true),
    ('اتصال خودکار هنگام روشن شدن', 'همیشه', true),
    ('همگام‌سازی لیست‌ها بین دستگاه‌ها', 'موبایل و دسکتاپ', false),
  ];

  static const _log = [
    ('12:04:11', 'tunnel up · vless/reality · nl-ams', C.success),
    ('12:04:11', 'dns → 1.1.1.1 (DoH)', C.body),
    ('12:19:48', 'probe 42 ms · stable', C.body),
    ('12:31:02', 'handshake retry (1/3)', C.warning),
    ('12:31:04', 'recovered', C.success),
  ];

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('امنیت و همگام‌سازی', style: T.screenTitle),
          const SizedBox(height: S.x14),
          for (final (label, caption, on) in _rows)
            SettingRow(label: label, caption: caption, trailing: AppToggle(on)),
          const SizedBox(height: S.x22),
          const SectionTitle('لاگ اتصال'),
          SunkenBlock(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (ts, msg, color) in _log)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ts, style: T.monoRaw.copyWith(color: C.muted)),
                          const SizedBox(width: S.x10),
                          Expanded(
                            child: Text(msg, style: T.monoRaw.copyWith(color: color)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
