import 'package:flutter/material.dart';
import '../models/editor_model.dart';
import '../models/highlighter.dart';
import '../state/settings.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'common.dart';

/// Editor body: gutter, git marks, current-line highlight, highlighted code,
/// caret and the autocomplete popup. Scrolls vertically and horizontally.
class CodeView extends StatelessWidget {
  const CodeView({super.key, required this.model});
  final EditorModel model;

  static const double _gutterW = 44;
  static const double _codeLeft = 56;
  static const double _topPad = 8;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = SettingsScope.of(context);
    final fs = s.fontSize;
    final lineH = fs * 22 / 12;
    final charW = fs * 0.6;
    final base = LatticeText.mono(fs, color: c.synPlain, height: lineH / fs);

    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final longest =
            model.lines.fold<int>(0, (m, l) => l.length > m ? l.length : m);
        final contentW = _codeLeft + longest * charW + 48;
        final contentH = _topPad * 2 + model.lines.length * lineH + 120;
        final suggestions = model.suggestions;

        return LayoutBuilder(builder: (context, box) {
          final w = contentW < box.maxWidth ? box.maxWidth : contentW;
          final h = contentH < box.maxHeight ? box.maxHeight : contentH;
          final caretX = _codeLeft + model.col * charW;
          final caretTop = _topPad + model.row * lineH + 2;

          return ClipRect(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    final r = ((d.localPosition.dy - _topPad) / lineH).floor();
                    final col =
                        ((d.localPosition.dx - _codeLeft) / charW).round();
                    model.moveTo(r, col);
                  },
                  child: SizedBox(
                    width: w,
                    height: h,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Gutter
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: _gutterW,
                          child: ColoredBox(color: c.surface),
                        ),
                        // Current line highlight
                        Positioned(
                          left: 0,
                          right: 0,
                          top: _topPad + model.row * lineH,
                          height: lineH,
                          child: ColoredBox(color: c.lineHighlight),
                        ),
                        // Git marks
                        for (final e in model.gitMarks.entries)
                          if (e.key < model.lines.length)
                            Positioned(
                              left: _gutterW - 3,
                              top: _topPad + e.key * lineH,
                              width: 3,
                              height: lineH,
                              child: ColoredBox(
                                color: e.value == 'added'
                                    ? c.success
                                    : c.warning,
                              ),
                            ),
                        // Line numbers
                        if (s.lineNumbers)
                          Positioned(
                            left: 0,
                            top: _topPad,
                            width: _gutterW - 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (var i = 0; i < model.lines.length; i++)
                                  SizedBox(
                                    height: lineH,
                                    child: Text(
                                      '${i + 1}',
                                      style: LatticeText.mono(
                                        fs,
                                        color: i == model.row
                                            ? c.text
                                            : c.textFaint,
                                        height: lineH / fs,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        // Code
                        Positioned(
                          left: _codeLeft,
                          top: _topPad,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final line in model.lines)
                                SizedBox(
                                  height: lineH,
                                  child: Text.rich(
                                    highlightLine(
                                        line.isEmpty ? ' ' : line, c, base),
                                    softWrap: false,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Caret
                        Positioned(
                          left: caretX,
                          top: caretTop,
                          child: BlinkingCaret(
                              color: c.accent, height: lineH - 4),
                        ),
                        // Autocomplete
                        if (suggestions.isNotEmpty)
                          Positioned(
                            left: caretX - 6,
                            top: _topPad + (model.row + 1) * lineH + 6,
                            child: _Autocomplete(
                              suggestions: suggestions,
                              prefix: model.prefix,
                              onPick: model.applySuggestion,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }
}

class _Autocomplete extends StatelessWidget {
  const _Autocomplete({
    required this.suggestions,
    required this.prefix,
    required this.onPick,
  });

  final List<Suggestion> suggestions;
  final String prefix;
  final ValueChanged<Suggestion> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < suggestions.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
              child: Material(
                color: i == 0 ? c.accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onPick(suggestions[i]),
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: prefix,
                              style: LatticeText.mono(13,
                                  weight: FontWeight.w500, color: c.accent),
                            ),
                            TextSpan(
                              text: suggestions[i].label.substring(prefix.length),
                              style: LatticeText.mono(13, color: c.text),
                            ),
                          ]),
                        ),
                        const Spacer(),
                        Text(
                          suggestions[i].kind,
                          style: LatticeText.ui(11, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
