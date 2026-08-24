import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Every icon in the app goes through here.
///
/// The design ships geometric placeholders and asks for a real outline set
/// (Lucide or Phosphor). Material's bundled outlined set is the stand-in: it is
/// uniform, stroke-based, and costs no dependency. Swapping to Lucide later is a
/// change to [AppIcons] alone, not to the 22 screens that use it.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size = 20,
    this.color = C.primaryMuted,
  });

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Icon(icon, size: size, color: color);
}

abstract final class AppIcons {
  static const search = Icons.search_rounded;
  static const settings = Icons.settings_outlined;
  static const bookmark = Icons.bookmark_border_rounded;
  static const results = Icons.list_alt_outlined;
  static const refresh = Icons.refresh_rounded;
  static const copy = Icons.copy_rounded;
  static const share = Icons.wifi_tethering_rounded;
  static const history = Icons.history_rounded;
  static const dashboard = Icons.dashboard_outlined;
  static const simple = Icons.bolt_outlined;
  static const shield = Icons.shield_outlined;
  static const globe = Icons.public_rounded;
  static const server = Icons.dns_outlined;
  static const device = Icons.devices_outlined;
  static const laptop = Icons.laptop_mac_rounded;
  static const phone = Icons.smartphone_rounded;
  static const tv = Icons.tv_rounded;
  static const qr = Icons.qr_code_2_rounded;
  static const close = Icons.close_rounded;
  static const check = Icons.check_rounded;
  static const browser = Icons.language_rounded;
  static const chat = Icons.chat_bubble_outline_rounded;
  static const bank = Icons.account_balance_outlined;
  static const video = Icons.play_circle_outline_rounded;
  static const power = Icons.power_settings_new_rounded;
  static const swap = Icons.swap_horiz_rounded;
  static const exit = Icons.logout_rounded;
}

/// The rounded-square app mark. Radius 26 at 88px in simple mode, 10 at 30px in
/// the advanced header — the design scales the corner with the mark.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 30, this.radius = 10});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: C.primaryGradient,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
    );
  }
}

/// A round outline icon button — the trailing action in several headers.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton(
    this.icon, {
    super.key,
    this.onTap,
    this.size = 34,
    this.square = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  /// 04 and 06 use a rounded square instead of a circle for the trailing action.
  final bool square;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: C.surfaceElevated,
          borderRadius: square
              ? const BorderRadius.all(Radius.circular(8))
              : R.pill,
          border: hairlineBorder(),
        ),
        child: Center(child: AppIcon(icon, size: size * 0.5)),
      ),
    );
  }
}
