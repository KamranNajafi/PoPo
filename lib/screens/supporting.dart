import 'package:flutter/widgets.dart';

import '../core/theme/tokens.dart';
import '../core/theme/typography.dart';
import '../core/util/locale_controller.dart';
import '../l10n/app_localizations.dart';
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
  const SettingsScreen({
    super.key,
    this.onOpenKeywords,
    this.onOpenLanguage,
    this.keywordCount,
  });

  /// Null on the design canvas, where the rows are display-only.
  final VoidCallback? onOpenKeywords;
  final VoidCallback? onOpenLanguage;

  /// The live phrase count, when there is a store to read it from.
  final int? keywordCount;

  static List<(String, String, bool)> _rows(L l) => [
        (l.settingAutoSearch, l.settingEveryHours(6), true),
        (l.settingPerEngineCap, l.settingItems(50), true),
        (l.settingTestTimeout, l.settingSeconds(5), true),
        (l.settingAutoRemoveDead, l.settingAfterFailedTests(2), true),
        (l.settingSimpleMode, l.settingSimpleModeNote, false),
      ];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.settings, style: T.screenTitle),
          const SizedBox(height: S.x14),
          for (final (label, caption, on) in _rows(l))
            SettingRow(label: label, caption: caption, trailing: AppToggle(on)),
          SettingRow(
            label: l.settingKeywords,
            caption: keywordCount == null
                ? l.keywordsIntro
                : l.settingKeywordsValue(keywordCount!),
            trailing: _chevron(onOpenKeywords),
          ),
          SettingRow(
            label: l.settingLanguage,
            // Listed in its own language: a user who cannot read the current
            // one must still be able to find theirs.
            caption: kLanguageNames[languageCode] ?? languageCode,
            trailing: _chevron(onOpenLanguage),
          ),
          SettingRow(
            label: l.settingTheme,
            caption: l.settingThemeValue,
            trailing: const AppIcon(AppIcons.swap, size: 18, color: C.muted),
          ),
          const SizedBox(height: S.x24),
          DestructiveButton(l.clearAllResults),
        ],
      ),
    );
  }

  Widget _chevron(VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: AppIcon(AppIcons.swap,
            size: 18, color: onTap == null ? C.muted : C.primaryMuted),
      );
}

/// 06 · Saved + bulk actions.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  static List<(String, String, String, Color, bool)> _rows(L l) => [
        (l.placeNlAmsterdam, 'VLESS · Reality', '42 ms', C.success, true),
        (l.placeDeFrankfurt, 'VMess · WS+TLS', '78 ms', C.success, true),
        (l.placePlWarsaw, 'HTTPS · 185.244.10.9:8080', '154 ms', C.warning, false),
        (l.placeTrIstanbul, 'Trojan · gRPC', '—', C.danger, false),
      ];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return PhoneFrame(
      nav: BottomNav(items: Navs.items(l), activeIndex: Navs.saved),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            leading: Text(l.savedTitle, style: T.screenTitle),
            trailing: Text(l.selectedCount(2), style: T.small),
          ),
          const SizedBox(height: S.x16),
          Wrap(
            spacing: S.x8,
            runSpacing: S.x8,
            children: [
              AppChip(l.copyAll, filled: true),
              AppChip(l.exportSubscription),
              AppChip(l.qr),
              AppChip(l.testAll),
            ],
          ),
          const SizedBox(height: S.x16),
          for (final (name, proto, ping, color, checked) in _rows(l)) ...[
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

/// 08 · Proxy detail.
class ProxyDetailScreen extends StatelessWidget {
  const ProxyDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.proxyDetailTitle, style: T.screenTitle),
          const SizedBox(height: S.x24),
          const Center(child: MonoText('51.15.42.7:1080', style: T.monoHero)),
          const SizedBox(height: S.x10),
          Center(
            child: Text(l.placeFiHelsinki,
                style: T.buttonSecondary.copyWith(fontSize: 15)),
          ),
          const SizedBox(height: S.x14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Badge(l.badgePortOpen, C.success),
              const SizedBox(width: S.x8),
              const _Badge('Elite', C.primaryMuted),
            ],
          ),
          const SizedBox(height: S.x22),
          MetaRow(l.metaType, 'SOCKS5'),
          MetaRow(l.metaAddress, '51.15.42.7 : 1080'),
          MetaRow(l.metaAnonymity, 'Elite'),
          MetaRow(l.metaHttpsSupport, 'yes'),
          MetaRow(l.metaLastPortTest, 'open · 126 ms', showDivider: false),
          const SizedBox(height: S.x18),
          PrimaryButton(l.copyIpPort),
          const SizedBox(height: S.x10),
          SplitRow(
            start: SecondaryButton(l.testPort),
            end: SecondaryButton(l.openInV2rayNG),
          ),
          const SizedBox(height: S.x14),
          Center(child: TextLink(l.reportBroken, color: C.danger)),
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

  static List<(String, String)> _runs(L l) => [
        (l.historyToday('14:20'), l.runSummary(128, 31, 8)),
        (l.historyYesterday('09:05'), l.runSummary(94, 22, 8)),
        (l.historyDaysAgo(3), l.runSummary(151, 40, 10)),
      ];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.historyTitle, style: T.screenTitle),
          const SizedBox(height: S.x14),
          for (final (at, meta) in _runs(l))
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
                  GhostButton(l.runAgain),
                ],
              ),
            ),
          const SizedBox(height: S.x24),
          SectionTitle(l.importTitle),
          SplitRow(
            start: SecondaryButton(l.subscriptionLink),
            end: SecondaryButton(l.fromClipboard),
          ),
        ],
      ),
    );
  }
}

/// 10 · Empty & error states. Every one names a next action.
class ErrorStatesScreen extends StatelessWidget {
  const ErrorStatesScreen({super.key});

  static List<(Color, String, String, String)> _states(L l) => [
        (
          C.muted,
          l.emptyNoResultsTitle,
          l.emptyNoResultsBody,
          l.emptyNoResultsAction,
        ),
        (
          C.danger,
          l.errorOfflineTitle,
          l.errorOfflineBody,
          l.errorOfflineAction,
        ),
        (
          C.warning,
          l.errorCaptchaTitle('Yandex'),
          l.errorCaptchaBody,
          l.errorCaptchaAction,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.errorStatesTitle, style: T.screenTitle),
          const SizedBox(height: S.x16),
          for (final (dot, title, body, action) in _states(l)) ...[
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
    final l = L.of(context);
    return PhoneFrame(
      simpleMode: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: S.x20),
          const Center(child: AppMark(size: 88, radius: 26)),
          const SizedBox(height: S.x22),
          Center(child: Text(l.onboardTitle, style: T.onboardTitle)),
          const SizedBox(height: S.x14),
          Text(
            l.onboardBody,
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
                Text(l.warningTitle,
                    style: T.listTitle.copyWith(color: C.warning)),
                const SizedBox(height: S.x8),
                Text(l.warningBody, style: T.caption),
              ],
            ),
          ),
          const SizedBox(height: S.x24),
          PrimaryButton(l.gotIt),
          const SizedBox(height: S.x14),
          Center(child: TextLink(l.skip)),
        ],
      ),
    );
  }
}
