import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/util/locale_controller.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/phone_frame.dart';
import '../../l10n/app_localizations.dart';

/// Language picker.
///
/// "Follow the device" is offered first and is the default: an app that pins one
/// language is wrong for every user whose device says otherwise.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key, required this.controller});

  final LocaleController controller;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => PhoneFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.settingLanguage, style: T.screenTitle),
            const SizedBox(height: S.x16),
            _Row(
              label: l.languageSystem,
              selected: controller.locale == null,
              onTap: () => controller.setLocale(null),
            ),
            for (final locale in LocaleController.supported)
              _Row(
                // Endonym: listed in its own language so a user who cannot read
                // the current one can still find theirs.
                label: kLanguageNames[locale.languageCode] ?? locale.languageCode,
                selected: controller.locale?.languageCode == locale.languageCode,
                onTap: () => controller.setLocale(locale),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: S.x14),
        decoration: const BoxDecoration(border: hairlineBottom),
        child: Row(
          children: [
            AppRadio(selected, onTap: onTap),
            const SizedBox(width: S.x12),
            Expanded(child: Text(label, style: T.settingLabel)),
          ],
        ),
      ),
    );
  }
}
