/// Compile-time feature flags.
///
/// These are `const` deliberately. Apple's guidelines 5.4 and 4.2 make an app
/// that itself crawls search engines and lists unknown third-party servers
/// unshippable, so on those builds the discovery code must not be *present*, not
/// merely hidden — a runtime toggle still ships the crawler in the binary.
///
/// Because they are const, the Dart compiler removes the branches they guard
/// from the tree, so `flutter build ipa --dart-define=ENABLE_DISCOVERY=false`
/// produces a binary with no engine list, no scraper and no keyword generator
/// reachable from any screen.
///
/// Build with:
/// ```
/// flutter build apk                                    # everything
/// flutter build ipa --dart-define=ENABLE_DISCOVERY=false \
///                   --dart-define=ENABLE_SHARING=false
/// ```
abstract final class Features {
  /// Search-engine discovery: screens 01, 02 and 07.
  ///
  /// Off on Apple builds. Those users import their own subscription links
  /// instead, which is what screen 09 is for.
  static const enableDiscovery = bool.fromEnvironment(
    'ENABLE_DISCOVERY',
    defaultValue: true,
  );

  /// Connection sharing: screens 12, 13 and 14.
  ///
  /// Off on Apple builds — not for policy reasons but because iOS cannot keep a
  /// background listener alive, so the feature could not work even if it shipped.
  static const enableSharing = bool.fromEnvironment(
    'ENABLE_SHARING',
    defaultValue: true,
  );

  /// Per-app routing: screen 15. Android only; no other platform has the API.
  static const enableSplitTunnel = bool.fromEnvironment(
    'ENABLE_SPLIT_TUNNEL',
    defaultValue: true,
  );

  /// True when the build has no way to find servers on its own, so the UI should
  /// lead with import rather than with search.
  static const importIsPrimaryEntry = !enableDiscovery;
}
