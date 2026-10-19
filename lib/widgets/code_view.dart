import 'package:flutter/material.dart';
import '../models/editor_model.dart';
import '../models/highlighter.dart';
import '../state/settings.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'common.dart';

int rowColToOffset(List<String> lines, int row, int col) {
  var offset = 0;
  final r = row.clamp(0, lines.isEmpty ? 0 : lines.length - 1);
  for (var i = 0; i < r; i++) {
    offset += lines[i].length + 1;
  }
  final c = col.clamp(0, lines.isEmpty ? 0 : lines[r].length);
  return offset + c;
}

(int row, int col) offsetToRowCol(List<String> lines, int offset) {
  if (lines.isEmpty) return (0, 0);
  var current = 0;
  for (var i = 0; i < lines.length; i++) {
    final len = lines[i].length;
    if (offset <= current + len) {
      return (i, offset - current);
    }
    current += len + 1;
  }
  return (lines.length - 1, lines.last.length);
}

/// Editor body: gutter, git marks, current-line highlight, highlighted code,
/// caret and the autocomplete popup. Integrates with the mobile system keyboard.
class CodeView extends StatefulWidget {
  const CodeView({super.key, required this.model});
  final EditorModel model;

  static const double _gutterW = 44;
  static const double _codeLeft = 56;
  static const double _topPad = 8;

  @override
  State<CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<CodeView> {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.model.text);
    _syncControllerSelection();

    widget.model.addListener(_onModelChanged);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model) {
      oldWidget.model.removeListener(_onModelChanged);
      widget.model.addListener(_onModelChanged);
      _onModelChanged();
    }
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChanged);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncControllerSelection() {
    final offset =
        rowColToOffset(widget.model.lines, widget.model.row, widget.model.col);
    _controller.value = TextEditingValue(
      text: widget.model.text,
      selection: TextSelection.collapsed(
        offset: offset.clamp(0, widget.model.text.length),
      ),
    );
  }

  void _onModelChanged() {
    if (_isUpdating) return;
    _isUpdating = true;
    _syncControllerSelection();
    _isUpdating = false;
    setState(() {});
  }

  void _onControllerChanged() {
    if (_isUpdating) return;
    _isUpdating = true;
    final newText = _controller.text;
    final selection = _controller.selection;

    if (newText != widget.model.text) {
      widget.model.lines = newText.split('\n');
      widget.model.dirty = true;
    }

    if (selection.isValid && selection.isCollapsed) {
      final (r, c) =
          offsetToRowCol(widget.model.lines, selection.baseOffset);
      widget.model.row = r;
      widget.model.col = c;
    }

    widget.model.notifyListeners();
    _isUpdating = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = SettingsScope.of(context);
    final fs = s.fontSize;
    final lineH = fs * 22 / 12;
    final charW = fs * 0.6;
    final base = LatticeText.mono(
      fs,
      color: c.synPlain,
      height: lineH / fs,
      fontFamily: s.fontFamily,
    );

    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        final longest = widget.model.lines
            .fold<int>(0, (m, l) => l.length > m ? l.length : m);
        final contentW = CodeView._codeLeft + longest * charW + 48;
        final contentH = CodeView._topPad * 2 + widget.model.lines.length * lineH + 120;
        final suggestions = widget.model.suggestions;

        return LayoutBuilder(builder: (context, box) {
          final w = contentW < box.maxWidth ? box.maxWidth : contentW;
          final h = contentH < box.maxHeight ? box.maxHeight : contentH;
          final caretX = CodeView._codeLeft + widget.model.col * charW;
          final caretTop = CodeView._topPad + widget.model.row * lineH + 2;

          return ClipRect(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    final r = ((d.localPosition.dy - CodeView._topPad) / lineH).floor();
                    final col =
                        ((d.localPosition.dx - CodeView._codeLeft) / charW).round();
                    widget.model.moveTo(r, col);
                    _focusNode.requestFocus();
                  },
                  child: SizedBox(
                    width: w,
                    height: h,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Hidden TextField for mobile keyboard input
                        Positioned(
                          left: 0,
                          top: 0,
                          width: 1,
                          height: 1,
                          child: Opacity(
                            opacity: 0,
                            child: TextField(
                              focusNode: _focusNode,
                              controller: _controller,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              autocorrect: false,
                              enableSuggestions: false,
                            ),
                          ),
                        ),
                        // Gutter
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: CodeView._gutterW,
                          child: ColoredBox(color: c.surface),
                        ),
                        // Current line highlight
                        Positioned(
                          left: 0,
                          right: 0,
                          top: CodeView._topPad + widget.model.row * lineH,
                          height: lineH,
                          child: ColoredBox(color: c.lineHighlight),
                        ),
                        // Git marks
                        for (final e in widget.model.gitMarks.entries)
                          if (e.key < widget.model.lines.length)
                            Positioned(
                              left: CodeView._gutterW - 3,
                              top: CodeView._topPad + e.key * lineH,
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
                            top: CodeView._topPad,
                            width: CodeView._gutterW - 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (var i = 0; i < widget.model.lines.length; i++)
                                  SizedBox(
                                    height: lineH,
                                    child: Text(
                                      '${i + 1}',
                                      style: LatticeText.mono(
                                        fs,
                                        color: i == widget.model.row
                                            ? c.text
                                            : c.textFaint,
                                        height: lineH / fs,
                                        fontFamily: s.fontFamily,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        // Code
                        Positioned(
                          left: CodeView._codeLeft,
                          top: CodeView._topPad,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final line in widget.model.lines)
                                SizedBox(
                                  height: lineH,
                                  child: Text.rich(
                                    highlightLine(
                                      line.isEmpty ? ' ' : line,
                                      c,
                                      base,
                                      fileName: widget.model.fileName,
                                    ),
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
                            top: CodeView._topPad + (widget.model.row + 1) * lineH + 6,
                            child: _Autocomplete(
                              suggestions: suggestions,
                              prefix: widget.model.prefix,
                              onPick: widget.model.applySuggestion,
                              fontFamily: s.fontFamily,
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
    required this.fontFamily,
  });

  final List<Suggestion> suggestions;
  final String prefix;
  final ValueChanged<Suggestion> onPick;
  final String fontFamily;

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
                                  weight: FontWeight.w500,
                                  color: c.accent,
                                  fontFamily: fontFamily),
                            ),
                            TextSpan(
                              text: suggestions[i].label.substring(prefix.length),
                              style: LatticeText.mono(13,
                                  color: c.text, fontFamily: fontFamily),
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
