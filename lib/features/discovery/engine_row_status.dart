import 'package:flutter/widgets.dart';

import '../../core/discovery/models.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'discovery_controller.dart';

/// How one engine's state reads on the scanning screen.
///
/// Kept out of the screen because the mapping is the product decision — a
/// blocked engine and a captcha are different things to a user, and neither is
/// an error the run should surface as a failure.
/// The message for a run-level failure.
String runErrorMessage(L l, RunError error) => switch (error) {
  RunError.noEnginesEnabled => l.runErrorNoEngines,
  RunError.runFailed => l.runErrorFailed,
};

({String label, Color color}) engineRowStatus(L l, EngineState state) =>
    switch (state.status) {
      EngineStatus.done when state.hits > 0 => (
        label: l.engineResults(state.hits),
        color: C.success,
      ),
      EngineStatus.done => (label: l.engineNoResults, color: C.muted),
      EngineStatus.running => (label: l.engineSearching, color: C.primary),
      EngineStatus.queued => (label: l.engineQueued, color: C.muted),
      EngineStatus.blocked => (label: l.engineBlocked, color: C.danger),
      EngineStatus.captcha => (label: l.engineCaptcha, color: C.warning),
      EngineStatus.failed => (label: l.engineUnavailable, color: C.danger),
      EngineStatus.idle => (label: l.engineStopped, color: C.muted),
    };
