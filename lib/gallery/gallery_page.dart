import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../core/theme/typography.dart';
import '../l10n/app_localizations.dart';
import '../core/widgets/buttons.dart';
import '../core/widgets/phone_frame.dart';
import '../features/discovery/discovery_flow.dart';
import 'screen_catalog.dart';

/// The design canvas: every screen laid out side by side, the way the prototype
/// presents them. Tapping one opens it full-size so it can be judged at the size
/// it will actually ship at.
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      backgroundColor: C.page,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(S.x24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CanvasHeader(),
              const SizedBox(height: S.x16),
              // The canvas is static by design; this is the one way into a real
              // run, so the screens can be judged against live data too.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: GhostButton(
                  l.runRealSearch,
                  large: true,
                  color: C.primaryMuted,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DiscoveryFlowPage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: S.x24),
              Wrap(
                spacing: S.x24,
                runSpacing: S.x26,
                children: [
                  for (final spec in kScreens)
                    GalleryTile(
                      number: spec.number,
                      title: spec.title(l),
                      width: spec.wide ? 690 : 330,
                      child: _Openable(spec: spec),
                    ),
                ],
              ),
              const SizedBox(height: S.x24),
              const _Legend(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Openable extends StatelessWidget {
  const _Openable({required this.spec});

  final ScreenSpec spec;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ScreenPage(spec: spec),
        ),
      ),
      child: spec.builder(context),
    );
  }
}

/// One screen on its own, centred on the page background.
class ScreenPage extends StatelessWidget {
  const ScreenPage({super.key, required this.spec});

  final ScreenSpec spec;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.page,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: S.x16, vertical: S.x10),
              child: Row(
                children: [
                  // BackButton rather than a hardcoded arrow: the direction it
                  // points has to follow the locale, and pinning it to RTL made
                  // it point the wrong way in English.
                  const BackButton(color: C.body),
                  Expanded(
                    child: Text(
                      '${spec.number} · ${spec.title(L.of(context))}',
                      style: T.listTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: spec.wide ? 900 : 390,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(S.x16),
                    child: spec.builder(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CanvasHeader extends StatelessWidget {
  const _CanvasHeader();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.galleryTitle, style: T.simpleHero),
        const SizedBox(height: 6),
        Text(l.gallerySubtitle(kScreens.length), style: T.caption),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  static List<(Availability, String, Color)> _entries(L l) => [
        (Availability.noApple, l.availAndroidDesktop, C.warning),
        (Availability.androidOnly, l.availAndroidOnly, C.primary),
        (Availability.desktopOnly, l.availDesktopOnly, C.primaryMuted),
      ];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Wrap(
      spacing: S.x18,
      runSpacing: S.x10,
      children: [
        for (final (availability, label, color) in _entries(l))
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '$label · ${kScreens.where((s) => s.availability == availability).map((s) => s.number).join(l.listSeparator)}',
                style: T.small,
              ),
            ],
          ),
      ],
    );
  }
}
