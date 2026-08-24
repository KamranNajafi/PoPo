import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/icons.dart';
import '../../core/widgets/phone_frame.dart';
import '../../core/widgets/surfaces.dart';
import '../../l10n/app_localizations.dart';
import '../../core/util/prefs.dart';
import 'keyword_store.dart';

/// 07 · Search phrases — viewable and editable.
///
/// The user gets two levers, matching how the two halves behave. Their own
/// phrases are a plain editable list. The generated ones are switched by
/// category rather than one by one, because the generator re-runs whenever the
/// month changes and per-phrase edits to it would silently disappear.
class KeywordsScreen extends StatefulWidget {
  const KeywordsScreen({super.key, this.store});

  /// Null on the design canvas, which shows the screen without a live store.
  final KeywordStore? store;

  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen> {
  final _controller = TextEditingController();
  bool _duplicate = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final store = widget.store;
    if (store == null) return;

    final added = await store.add(_controller.text);
    if (!mounted) return;
    setState(() {
      _duplicate = !added && _controller.text.trim().isNotEmpty;
      if (added) _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    if (store == null) return _build(context, null);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _build(context, store),
    );
  }

  Widget _build(BuildContext context, KeywordStore? store) {
    final l = L.of(context);

    // On the canvas there is no store, so show the generator's own output.
    final effective = store ?? _demoStore;
    final generated = effective.activeGenerated;
    // Search phrases, not UI copy — shown as written, not translated.
    final custom = store?.custom ?? const ['کانفیگ رایگان', 'vless reality'];

    return PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.keywordsTitle, style: T.screenTitle),
          const SizedBox(height: 6),
          Text(l.keywordsIntro, style: T.small),
          const SizedBox(height: S.x16),

          _AddField(
            controller: _controller,
            hint: l.addKeywordHint,
            onSubmit: store == null ? null : _add,
          ),
          if (_duplicate) ...[
            const SizedBox(height: S.x8),
            Text(
              l.keywordAlreadyExists,
              style: T.small.copyWith(color: C.warning),
            ),
          ],
          const SizedBox(height: S.x18),

          SectionTitle(
            l.customPhrases,
            trailing: Text(l.phrasesCount(custom.length), style: T.small),
          ),
          if (custom.isEmpty)
            Text(l.noCustomKeywords, style: T.small)
          else
            Wrap(
              spacing: S.x8,
              runSpacing: S.x8,
              children: [
                for (final phrase in custom)
                  AppChip(
                    phrase,
                    selected: true,
                    onTap: store == null
                        ? null
                        : () => store.removeCustom(phrase),
                    trailing: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: C.primaryMuted),
                      ),
                      child: const Center(
                        child: AppIcon(
                          AppIcons.close,
                          size: 8,
                          color: C.primaryMuted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: S.x24),
          SectionTitle(l.presetSets),
          for (final set in KeywordSet.values)
            SettingRow(
              label: _setLabel(l, set),
              caption: l.phrasesCount(effective.countIn(set)),
              trailing: AppToggle(
                effective.isSetEnabled(set),
                onChanged: store == null
                    ? null
                    : (value) => store.setSetEnabled(set, value),
              ),
            ),

          const SizedBox(height: S.x20),
          SectionTitle(
            l.generatedPhrases,
            trailing: Text(l.phrasesCount(generated.length), style: T.small),
          ),
          Wrap(
            spacing: S.x8,
            runSpacing: S.x8,
            children: [
              for (final keyword in generated.take(24))
                AppChip(keyword.text, mono: true),
            ],
          ),

          const SizedBox(height: S.x24),
          SecondaryButton(l.restoreDefaults, onTap: store?.restoreDefaults),
        ],
      ),
    );
  }

  String _setLabel(L l, KeywordSet set) => switch (set) {
    KeywordSet.protocol => l.setProtocolNames,
    KeywordSet.freshness => l.setFreshness,
    KeywordSet.persian => l.setPersian,
    KeywordSet.siteScoped => l.setSiteScoped,
    KeywordSet.rawLinks => l.setRawLinks,
  };
}

class _AddField extends StatelessWidget {
  const _AddField({
    required this.controller,
    required this.hint,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.only(start: S.x16, end: 6),
      decoration: BoxDecoration(
        color: C.surfaceElevated,
        borderRadius: R.pill,
        border: hairlineBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: onSubmit != null,
              onSubmitted: (_) => onSubmit?.call(),
              style: T.caption.copyWith(color: C.heading),
              cursorColor: C.primary,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: T.caption,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          GhostButton(L.of(context).addKeyword, onTap: onSubmit),
        ],
      ),
    );
  }
}

/// A store backed by memory, so the design canvas can show the screen with real
/// generator output and no persistence.
final _demoStore = KeywordStore(prefs: MemoryPrefs());
