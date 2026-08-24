import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'mono.dart';

/// The standard list card: elevated surface, hairline, radius 18.
class ListCard extends StatelessWidget {
  const ListCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(S.x14),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: C.surfaceElevated,
      borderRadius: R.mdAll,
      border: hairlineBorder(),
    ),
    child: child,
  );
}

/// A settings row: label + caption on one side, a trailing control on the other,
/// separated from the next row by a hairline.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.label,
    this.caption,
    this.trailing,
    this.showDivider = true,
  });

  final String label;
  final String? caption;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(border: showDivider ? hairlineBottom : null),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: T.settingLabel),
                if (caption != null) ...[
                  const SizedBox(height: 3),
                  Text(caption!, style: T.small),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: S.x12), trailing!],
        ],
      ),
    );
  }
}

/// A label/value meta row. The label reads in Persian on the leading side, the
/// value is mono and LTR on the trailing side.
class MetaRow extends StatelessWidget {
  const MetaRow(
    this.label,
    this.value, {
    super.key,
    this.valueColor,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: S.x10),
      decoration: BoxDecoration(border: showDivider ? hairlineBottom : null),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: T.caption),
          const SizedBox(width: S.x12),
          Flexible(
            child: MonoText(
              value,
              style: T.monoValue.copyWith(
                fontSize: 13,
                color: valueColor ?? C.heading,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

/// The sunken block used for raw config links and the connection log.
class SunkenBlock extends StatelessWidget {
  const SunkenBlock({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(S.x12),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: C.sunken,
      borderRadius: R.smAll,
      border: hairlineBorder(),
    ),
    child: child,
  );
}

/// A section heading, optionally with a counter on the trailing side.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: S.x10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: T.listTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: S.x8), trailing!],
        ],
      ),
    );
  }
}

/// Header row: app mark + wordmark on the leading side, an action on the trailing.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.leading, this.trailing});

  final Widget leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Flexible(child: leading),
      if (trailing != null) ...[const SizedBox(width: S.x12), trailing!],
    ],
  );
}
