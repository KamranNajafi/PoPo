import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../core/theme/typography.dart';
import '../core/util/fa.dart';
import '../core/widgets/phone_frame.dart';
import 'screen_catalog.dart';

/// The design canvas: every screen laid out side by side, the way the prototype
/// presents them. Tapping one opens it full-size so it can be judged at the size
/// it will actually ship at.
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.page,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(S.x24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CanvasHeader(),
              const SizedBox(height: S.x24),
              Wrap(
                spacing: S.x24,
                runSpacing: S.x26,
                children: [
                  for (final spec in kScreens)
                    GalleryTile(
                      number: spec.number,
                      title: spec.title,
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
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_forward_rounded,
                        color: C.body, size: 20),
                  ),
                  Text('${spec.number} · ${spec.title}', style: T.listTitle),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PoPo — فاز ۰', style: T.simpleHero),
        const SizedBox(height: 6),
        Text(
          '${fa(kScreens.length)} صفحه، ساخته‌شده از توکن‌های دیزاین‌سیستم. '
          'بدون شبکه، بدون سرور — فقط رابط کاربری.',
          style: T.caption,
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  static const _entries = [
    (Availability.noApple, 'اندروید و دسکتاپ', C.warning),
    (Availability.androidOnly, 'فقط اندروید', C.primary),
    (Availability.desktopOnly, 'فقط دسکتاپ', C.primaryMuted),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: S.x18,
      runSpacing: S.x10,
      children: [
        for (final (availability, label, color) in _entries)
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
                '$label · ${kScreens.where((s) => s.availability == availability).map((s) => s.number).join('، ')}',
                style: T.small,
              ),
            ],
          ),
      ],
    );
  }
}
