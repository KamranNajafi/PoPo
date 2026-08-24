import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Pill, gradient fill, white 700 label.
///
/// [oversized] is simple mode's variant: the same button one step larger, which
/// is the whole visual difference between the two modes' calls to action.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
    this.label, {
    super.key,
    this.onTap,
    this.oversized = false,
    this.showConnectedDot = false,
    this.leading,
  });

  final String label;
  final VoidCallback? onTap;
  final bool oversized;

  /// A 10px success dot before the label, shown when the button represents a
  /// live connection ("قطع اتصال" while connected).
  final bool showConnectedDot;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final style = oversized
        ? T.buttonPrimary.copyWith(fontSize: 20)
        : T.buttonPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: oversized ? S.x22 : 15,
          horizontal: S.x20,
        ),
        decoration: const BoxDecoration(
          gradient: C.primaryGradient,
          borderRadius: R.pill,
          boxShadow: Shadows.primaryButton,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showConnectedDot) ...[
              const _Dot(color: C.success, size: 10),
              const SizedBox(width: S.x8),
            ],
            if (leading != null) ...[leading!, const SizedBox(width: S.x8)],
            Flexible(
              child: Text(label, style: style, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill, elevated-surface fill, hairline border, white 600 label.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton(
    this.label, {
    super.key,
    this.onTap,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: S.x14, horizontal: S.x16),
        decoration: BoxDecoration(
          color: C.surfaceElevated,
          borderRadius: R.pill,
          border: hairlineBorder(),
        ),
        // Persian labels run long ("بازکردن در V2rayNG" in a 50/50 row). The
        // copy is final, so shrink it to fit rather than clipping it away.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: T.buttonSecondary,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

/// Transparent with an accent border — inline actions like "کپی" or "اجرای دوباره".
class GhostButton extends StatelessWidget {
  const GhostButton(
    this.label, {
    super.key,
    this.onTap,
    this.color = C.primary,
    this.borderColor = C.accentBorder,
    this.expand = false,
    this.leading,
    this.large = false,
  });

  const GhostButton.destructive(String label, {Key? key, VoidCallback? onTap})
    : this(
        label,
        key: key,
        onTap: onTap,
        color: C.danger,
        borderColor: C.dangerBorder,
      );

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;
  final bool expand;
  final Widget? leading;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          vertical: large ? S.x14 : 6,
          horizontal: large ? S.x16 : S.x12,
        ),
        decoration: BoxDecoration(
          borderRadius: R.pill,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: S.x8)],
            Flexible(
              child: Text(
                label,
                style: (large ? T.buttonSecondary : T.chip).copyWith(
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width destructive action ("پاک‌کردن همهٔ نتایج").
class DestructiveButton extends StatelessWidget {
  const DestructiveButton(this.label, {super.key, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: S.x14),
        decoration: BoxDecoration(
          borderRadius: R.pill,
          border: Border.all(color: C.dangerBorder),
        ),
        child: Text(
          label,
          style: T.buttonSecondary.copyWith(color: C.danger),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// A bare text link — "حالت پیشرفته", "رد کردن".
class TextLink extends StatelessWidget {
  const TextLink(
    this.label, {
    super.key,
    this.onTap,
    this.color = C.muted,
    this.size = 13,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: T.caption.copyWith(color: color, fontSize: size),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// The 50/50 secondary row the design uses repeatedly under a primary action.
class SplitRow extends StatelessWidget {
  const SplitRow({
    super.key,
    required this.start,
    required this.end,
    this.gap = S.x10,
  });

  final Widget start;
  final Widget end;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: start),
        SizedBox(width: gap),
        Expanded(child: end),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Status dot used in engine rows, chips and error cards.
class StatusDot extends StatelessWidget {
  const StatusDot(this.color, {super.key, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => _Dot(color: color, size: size);
}
