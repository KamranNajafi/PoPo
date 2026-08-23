import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';

/// 44×26 pill, 3px padding, 20px knob.
///
/// The layout is RTL, so `MainAxisAlignment.start` puts the knob on the visual
/// right — which is where "on" belongs in a right-to-left UI.
class AppToggle extends StatelessWidget {
  const AppToggle(this.value, {super.key, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Container(
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? C.toggleTrackOn : C.toggleTrackOff,
          borderRadius: R.pill,
          border: value ? null : hairlineBorder(),
        ),
        child: Row(
          mainAxisAlignment:
              value ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? C.primary : C.toggleKnobOff,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 20×20, radius 6. Checked is a filled primary square.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox(this.value, {super.key, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: value ? C.primary : null,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          border: Border.all(color: value ? C.primary : C.offRing, width: 2),
        ),
        child: value
            ? const Center(
                child: Icon(_check, size: 12, color: C.onPrimary),
              )
            : null,
      ),
    );
  }
}

/// 22×22 circle with a 10px primary dot when selected.
class AppRadio extends StatelessWidget {
  const AppRadio(this.selected, {super.key, this.onTap});

  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: C.primaryMuted, width: 2),
        ),
        child: selected
            ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: C.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

/// Pill chip. Selected is accent tint + accent border + muted-primary label.
class AppChip extends StatelessWidget {
  const AppChip(
    this.label, {
    super.key,
    this.selected = false,
    this.onTap,
    this.leading,
    this.trailing,
    this.mono = false,
    this.filled = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;

  /// Engine names are mono; keyword and filter chips are not.
  final bool mono;

  /// The "کپی همه" action chip on 06, which is a solid primary fill.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final BoxDecoration decoration;

    if (filled) {
      fg = C.onPrimary;
      decoration = const BoxDecoration(gradient: C.primaryGradient, borderRadius: R.pill);
    } else if (selected) {
      fg = C.primaryMuted;
      decoration = BoxDecoration(
        color: C.accentTint,
        borderRadius: R.pill,
        border: Border.all(color: C.accentBorder),
      );
    } else {
      fg = C.body;
      decoration = BoxDecoration(
        color: C.surfaceElevated,
        borderRadius: R.pill,
        border: hairlineBorder(),
      );
    }

    final style = mono
        ? T.monoName.copyWith(color: fg)
        : T.chip.copyWith(color: fg, fontWeight: FontWeight.w500);

    // Chips carry user-supplied and generated search phrases, which can be far
    // longer than the design's samples. A pill that cannot shrink overflows the
    // row, so the label is flexible and truncates rather than the chip growing
    // past the screen.
    final labelText = Text(
      label,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final text = Flexible(
      child: mono
          ? Directionality(textDirection: TextDirection.ltr, child: labelText)
          : labelText,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: S.x12),
        decoration: decoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            text,
            if (trailing != null) ...[const SizedBox(width: 6), trailing!],
          ],
        ),
      ),
    );
  }
}

/// A disabled engine chip: surface fill, muted label, dead dot.
class DisabledChip extends StatelessWidget {
  const DisabledChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => AppChip(
        label,
        mono: true,
        leading: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: C.offRing, shape: BoxShape.circle),
        ),
      );
}

const _check = IconData(0xe156, fontFamily: 'MaterialIcons');
