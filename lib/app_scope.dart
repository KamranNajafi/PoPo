import 'package:flutter/widgets.dart';

import 'core/util/locale_controller.dart';
import 'core/util/prefs.dart';
import 'features/keywords/keyword_store.dart';
import 'features/results/app_settings.dart';
import 'features/results/results_store.dart';

/// The app's long-lived controllers, handed down the tree.
///
/// An InheritedWidget rather than a service locator: the dependencies are few
/// and explicit, and this keeps them visible in the widget tree where they are
/// used instead of hiding them behind a global.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.prefs,
    required this.localeController,
    required this.keywordStore,
    required this.resultsStore,
    required this.settings,
    required super.child,
  });

  final Prefs prefs;
  final LocaleController localeController;
  final KeywordStore keywordStore;
  final ResultsStore resultsStore;
  final AppSettings settings;

  static AppScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No AppScope above this widget');
    return scope!;
  }

  /// Null when there is no scope above — the design canvas renders screens in
  /// tests without one, and those screens fall back to static values.
  static AppScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>();

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      prefs != oldWidget.prefs ||
      localeController != oldWidget.localeController ||
      keywordStore != oldWidget.keywordStore ||
      resultsStore != oldWidget.resultsStore ||
      settings != oldWidget.settings;
}
