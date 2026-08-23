import 'package:flutter/widgets.dart';

import '../screens/advanced_core.dart';
import '../screens/cross_platform.dart';
import '../screens/sharing.dart';
import '../screens/simple_mode.dart';
import '../screens/supporting.dart';

/// Which builds a screen ships in.
///
/// The handoff makes this a compile-time decision, not a runtime toggle: the
/// Apple builds must not contain discovery code at all. Phase 0 only records the
/// intent — the flag itself lands with the platform layer.
enum Availability {
  /// Every platform.
  all,

  /// Android and desktop only. Discovery (01, 02, 07) and connection sharing
  /// (12, 13, 14) — the latter because iOS cannot hold a background listener.
  noApple,

  /// Android only: per-app routing has no iOS equivalent.
  androidOnly,

  /// Desktop shells.
  desktopOnly,
}

class ScreenSpec {
  const ScreenSpec({
    required this.number,
    required this.title,
    required this.builder,
    this.availability = Availability.all,
    this.wide = false,
  });

  final String number;
  final String title;
  final WidgetBuilder builder;
  final Availability availability;

  /// The desktop window needs more than a phone's width on the canvas.
  final bool wide;
}

/// Every screen in the design, in the order the canvas lays them out.
const kScreens = <ScreenSpec>[
  // Advanced core
  ScreenSpec(
    number: '01',
    title: 'جست‌وجو',
    builder: _search,
    availability: Availability.noApple,
  ),
  ScreenSpec(
    number: '02',
    title: 'در حال جست‌وجو',
    builder: _scanning,
    availability: Availability.noApple,
  ),
  ScreenSpec(number: '03', title: 'نتایج', builder: _results),
  ScreenSpec(number: '04', title: 'جزئیات کانفیگ', builder: _configDetail),

  // Simple mode
  ScreenSpec(number: 'S1', title: 'شروع', builder: _simpleStart),
  ScreenSpec(number: 'S2', title: 'مراحل', builder: _simpleSteps),
  ScreenSpec(number: 'S3', title: 'آماده', builder: _simpleReady),
  ScreenSpec(number: 'S4', title: 'متصل', builder: _simpleConnected),

  // Supporting
  ScreenSpec(number: '05', title: 'تنظیمات', builder: _settings),
  ScreenSpec(number: '06', title: 'ذخیره‌شده‌ها', builder: _saved),
  ScreenSpec(
    number: '07',
    title: 'عبارت‌های کلیدی',
    builder: _keywords,
    availability: Availability.noApple,
  ),
  ScreenSpec(number: '08', title: 'جزئیات پروکسی', builder: _proxyDetail),
  ScreenSpec(number: '09', title: 'تاریخچه و ایمپورت', builder: _history),
  ScreenSpec(number: '10', title: 'خالی و خطا', builder: _errors),
  ScreenSpec(number: '11', title: 'آنبوردینگ', builder: _onboarding),

  // Connection sharing
  ScreenSpec(
    number: '12',
    title: 'سرور پروکسی',
    builder: _proxyServer,
    availability: Availability.noApple,
  ),
  ScreenSpec(
    number: '13',
    title: 'دستگاه‌های وصل',
    builder: _devices,
    availability: Availability.noApple,
  ),
  ScreenSpec(
    number: '14',
    title: 'راهنمای اتصال',
    builder: _pairing,
    availability: Availability.noApple,
  ),
  ScreenSpec(
    number: '15',
    title: 'تفکیک ترافیک',
    builder: _splitTunnel,
    availability: Availability.androidOnly,
  ),
  ScreenSpec(number: '16', title: 'امنیت و همگام‌سازی', builder: _security),

  // Cross-platform
  ScreenSpec(
    number: '17',
    title: 'دسکتاپ',
    builder: _desktop,
    availability: Availability.desktopOnly,
    wide: true,
  ),
  ScreenSpec(number: '18', title: 'سینی و کوییک‌تایل', builder: _tray),
];

Widget _search(BuildContext _) => const SearchScreen();
Widget _scanning(BuildContext _) => const ScanningScreen();
Widget _results(BuildContext _) => const ResultsScreen();
Widget _configDetail(BuildContext _) => const ConfigDetailScreen();
Widget _simpleStart(BuildContext _) => const SimpleStartScreen();
Widget _simpleSteps(BuildContext _) => const SimpleStepsScreen();
Widget _simpleReady(BuildContext _) => const SimpleReadyScreen();
Widget _simpleConnected(BuildContext _) => const SimpleConnectedScreen();
Widget _settings(BuildContext _) => const SettingsScreen();
Widget _saved(BuildContext _) => const SavedScreen();
Widget _keywords(BuildContext _) => const KeywordsScreen();
Widget _proxyDetail(BuildContext _) => const ProxyDetailScreen();
Widget _history(BuildContext _) => const HistoryScreen();
Widget _errors(BuildContext _) => const ErrorStatesScreen();
Widget _onboarding(BuildContext _) => const OnboardingScreen();
Widget _proxyServer(BuildContext _) => const ProxyServerScreen();
Widget _devices(BuildContext _) => const ConnectedDevicesScreen();
Widget _pairing(BuildContext _) => const PairingGuideScreen();
Widget _splitTunnel(BuildContext _) => const SplitTunnelScreen();
Widget _security(BuildContext _) => const SecurityScreen();
Widget _desktop(BuildContext _) => const DesktopScreen();
Widget _tray(BuildContext _) => const TrayScreen();
