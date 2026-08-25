import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'core/build/features.dart';
import 'core/theme/tokens.dart';
import 'features/discovery/app_flow.dart';
import 'gallery/gallery_page.dart';
import 'features/desktop/desktop_shell.dart';
import 'screens/supporting.dart';

/// What the app opens on.
///
/// Until now that was the design canvas, which is a review tool: every screen
/// existed but the only way to reach the working app was a button on a page of
/// previews. This picks the real destination instead — onboarding on the first
/// launch, then the shell that suits the platform.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  /// Set once the user has dismissed onboarding. Stored rather than kept in
  /// memory because the whole point is that it does not come back.
  static const onboardingKey = 'onboarding_done';

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool? _needsOnboarding;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Prefs are already loaded before runApp, so this is a synchronous read and
    // there is no loading frame to flash.
    _needsOnboarding ??=
        AppScope.of(context).prefs.getString(AppRoot.onboardingKey) == null;
  }

  Future<void> _finishOnboarding() async {
    final prefs = AppScope.of(context).prefs;
    setState(() => _needsOnboarding = false);
    await prefs.setString(AppRoot.onboardingKey, 'true');
  }

  @override
  Widget build(BuildContext context) {
    // The design canvas is still one dart-define away, for judging the screens
    // side by side. It is just no longer what the app *is*.
    if (Features.showGallery) return const GalleryPage();

    if (_needsOnboarding ?? true) {
      return Scaffold(
        backgroundColor: C.page,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Padding(
                padding: const EdgeInsets.all(S.x16),
                child: OnboardingScreen(onDone: _finishOnboarding),
              ),
            ),
          ),
        ),
      );
    }

    if (_isDesktop) return const DesktopShell();

    // Simple mode is a saved preference, so someone who chose it stays in it
    // across launches instead of landing back in the advanced shell.
    return AppFlow(startInSimpleMode: AppScope.of(context).settings.simpleMode);
  }
}

/// True on the platforms that get the window layout rather than the phone one.
///
/// Deliberately keyed to the target platform rather than to a width breakpoint:
/// a narrow window on a laptop is still a desktop, and the tray and window
/// chrome are what differ, not the amount of room.
bool get _isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS);
