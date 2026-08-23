import 'package:flutter/widgets.dart';

import '../../core/theme/tokens.dart';
import '../../core/discovery/models.dart';
import '../../core/util/fa.dart';

/// How one engine's state reads on the scanning screen.
///
/// Kept out of the screen because the mapping is the product decision — a
/// blocked engine and a captcha are different things to a user, and neither is
/// an error the run should surface as a failure.
({String label, Color color}) engineRowStatus(EngineState state) =>
    switch (state.status) {
      EngineStatus.done when state.hits > 0 =>
        (label: '${fa(state.hits)} نتیجه', color: C.success),
      EngineStatus.done => (label: 'نتیجه‌ای نداشت', color: C.muted),
      EngineStatus.running => (label: 'در حال جست‌وجو', color: C.primary),
      EngineStatus.queued => (label: 'در صف', color: C.muted),
      EngineStatus.blocked => (label: 'بلاک شد', color: C.danger),
      EngineStatus.captcha => (label: 'کپچا خواست', color: C.warning),
      EngineStatus.failed => (label: 'در دسترس نبود', color: C.danger),
      EngineStatus.idle => (label: 'متوقف شد', color: C.muted),
    };
