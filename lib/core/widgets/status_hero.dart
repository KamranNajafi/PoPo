import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'icons.dart';

enum HeroState {
  /// Connected or working: primary radial gradient with a spinner ring.
  working,

  /// Idle: flat elevated surface with a muted ring.
  idle,

  /// Ready/OK: success tint with a check.
  ready,
}

/// The 96–112px circle that carries connection state on nearly every screen.
///
/// The design's transitions are a color/fade change, not motion, so the
/// "spinner" is drawn as a ring with a transparent top border rather than
/// animated — matching the static prototype and leaving the animation decision
/// to whoever wires up real state.
class StatusHero extends StatelessWidget {
  const StatusHero({
    super.key,
    required this.state,
    this.size = 104,
    this.child,
  });

  final HeroState state;
  final double size;

  /// 04 puts the ping value inside the hero instead of an icon.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ringSize = size * 0.38;

    late final BoxDecoration decoration;
    late final Widget inner;

    switch (state) {
      case HeroState.working:
        decoration = const BoxDecoration(
          gradient: C.heroGradient,
          shape: BoxShape.circle,
          boxShadow: Shadows.connectedHero,
        );
        inner = _SpinnerRing(size: ringSize);
      case HeroState.idle:
        decoration = BoxDecoration(
          color: C.surfaceElevated,
          shape: BoxShape.circle,
          border: hairlineBorder(),
        );
        inner = Container(
          width: ringSize,
          height: ringSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: C.muted, width: 2),
          ),
        );
      case HeroState.ready:
        decoration = BoxDecoration(
          color: const Color(0x1AA3E635), // rgba(163,230,53,0.10)
          shape: BoxShape.circle,
          border: Border.all(color: C.success, width: 2),
        );
        inner = AppIcon(AppIcons.check, size: size * 0.34, color: C.success);
    }

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      child: Center(child: child ?? inner),
    );
  }
}

class _SpinnerRing extends StatelessWidget {
  const _SpinnerRing({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: const _RingPainter(color: C.onPrimary, width: 3),
  );
}

/// A ring with its top quarter left open — the design's static "working" mark.
///
/// This is a painter rather than a [Border] because Flutter only draws circular
/// borders when every side shares one color, and the open top is the whole point.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    final rect =
        Offset(width / 2, width / 2) &
        Size(size.width - width, size.height - width);

    // Start just past 12 o'clock and sweep three quarters of the way round.
    canvas.drawArc(rect, -_quarterTurn / 2, _quarterTurn * 3, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.width != width;
}

const _quarterTurn = 3.1415926535897932 / 2;

/// The small step circle on S2: filled when done, ringed while running, dim
/// while waiting.
class StepCircle extends StatelessWidget {
  const StepCircle(this.state, {super.key});

  final StepState state;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case StepState.done:
        return Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: C.success,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: AppIcon(AppIcons.check, size: 15, color: C.gradientBottom),
          ),
        );
      case StepState.running:
        return Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: C.primary, width: 2),
          ),
        );
      case StepState.waiting:
        return Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: C.offRing, width: 2),
          ),
        );
    }
  }
}

enum StepState { done, running, waiting }

/// The pager dots on onboarding — the active one stretches to 22×6.
class PagerDots extends StatelessWidget {
  const PagerDots({super.key, required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < count; i++)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == active ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: i == active ? C.primary : C.offRing,
            borderRadius: R.pill,
          ),
        ),
    ],
  );
}

/// Text under a hero: a title and an optional mono line.
class HeroCaption extends StatelessWidget {
  const HeroCaption({
    super.key,
    required this.title,
    this.titleStyle,
    this.body,
  });

  final String title;
  final TextStyle? titleStyle;
  final String? body;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(title, style: titleStyle ?? T.hero, textAlign: TextAlign.center),
      if (body != null) ...[
        const SizedBox(height: 6),
        Text(body!, style: T.caption, textAlign: TextAlign.center),
      ],
    ],
  );
}
