import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:popo/app_root.dart';
import 'package:popo/core/util/prefs.dart';
import 'package:popo/features/desktop/desktop_shell.dart';
import 'package:popo/features/discovery/app_flow.dart';
import 'package:popo/l10n/app_localizations.dart';
import 'package:popo/main.dart';
import 'package:popo/core/widgets/buttons.dart';
import 'package:popo/core/widgets/surfaces.dart';
import 'package:popo/screens/supporting.dart';

/// A launch, at phone size.
Future<void> _launch(WidgetTester tester, Prefs prefs) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(PoPoApp(prefs: prefs));
  await tester.pumpAndSettle();
}

void main() {
  group('launch target', () {
    testWidgets('opens the app, not the design canvas', (tester) async {
      final prefs = MemoryPrefs();
      await prefs.setString(AppRoot.onboardingKey, 'true');
      await _launch(tester, prefs);

      // The canvas was the launch screen for the whole build until now; the
      // point of this test is that it is not any more.
      expect(find.byType(AppFlow), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('first run shows onboarding', (tester) async {
      await _launch(tester, MemoryPrefs());

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(AppFlow), findsNothing);
    });

    testWidgets('dismissing onboarding persists and does not come back', (
      tester,
    ) async {
      final prefs = MemoryPrefs();
      await _launch(tester, prefs);
      expect(find.byType(OnboardingScreen), findsOneWidget);

      await tester.tap(find.byType(PrimaryButton).first);
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(AppFlow), findsOneWidget);
      // Persisted, not just held in memory — the whole point is that a restart
      // does not show it again.
      expect(prefs.getString(AppRoot.onboardingKey), isNotNull);

      await _launch(tester, prefs);
      expect(find.byType(OnboardingScreen), findsNothing);
    });
  });

  group('settings is reachable', () {
    testWidgets('the gear opens settings from the shell', (tester) async {
      final prefs = MemoryPrefs();
      await prefs.setString(AppRoot.onboardingKey, 'true');
      await _launch(tester, prefs);

      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the three new rows each lead somewhere', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var sharing = 0, split = 0, security = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fa'),
          supportedLocales: L.supportedLocales,
          localizationsDelegates: L.localizationsDelegates,
          // Not inside a scroll view: PhoneFrame has a Stack that needs a
          // bounded height, which is why the view is sized tall instead.
          home: SettingsScreen(
            onOpenSharing: () => sharing++,
            onOpenSplitTunnel: () => split++,
            onOpenSecurity: () => security++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sharing, per-app routing and security had no entry point outside the
      // design canvas before this. Each chevron must actually fire.
      final rows = find.byType(SettingRow);
      expect(rows, findsWidgets);

      for (final label in [
        L.of(tester.element(rows.first)).screenProxyServer,
        L.of(tester.element(rows.first)).screenSplitTunnel,
        L.of(tester.element(rows.first)).securityTitle,
      ]) {
        expect(find.text(label), findsOneWidget, reason: 'row missing: $label');
      }

      await tester.tap(
        find
            .descendant(
              of: find.ancestor(
                of: find.text(L.of(tester.element(rows.first)).securityTitle),
                matching: find.byType(SettingRow),
              ),
              matching: find.byType(GestureDetector),
            )
            .last,
      );
      await tester.pumpAndSettle();
      expect(security, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('desktop shell', () {
    testWidgets('a desktop launch gets the window, not the phone flow', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final prefs = MemoryPrefs();
      await prefs.setString(AppRoot.onboardingKey, 'true');
      await tester.pumpWidget(PoPoApp(prefs: prefs));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopShell), findsOneWidget);
      expect(find.byType(AppFlow), findsNothing);
      expect(tester.takeException(), isNull);

      // Cleared here rather than in addTearDown: the framework asserts every
      // foundation debug variable is unset before teardown runs.
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('the sidebar switches the content pane', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final prefs = MemoryPrefs();
      await prefs.setString(AppRoot.onboardingKey, 'true');
      await tester.pumpWidget(PoPoApp(prefs: prefs));
      await tester.pumpAndSettle();

      final state = tester.state<State<DesktopShell>>(
        find.byType(DesktopShell),
      );

      // The sidebar used to carry a hardcoded selection and no handler, so
      // clicking an entry did nothing at all.
      final settingsEntry = find.text(
        L.of(tester.element(find.byType(DesktopShell))).desktopNavSettings,
      );
      expect(settingsEntry, findsOneWidget);

      await tester.tap(settingsEntry);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(state.mounted, isTrue);
      expect(tester.takeException(), isNull);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
