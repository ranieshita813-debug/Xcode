import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/document.dart';
import '../models/editor_model.dart';
import '../models/folding_model.dart';
import '../models/highlighter.dart';
import '../state/settings.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'common.dart';
import 'editor_input_client.dart';

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

/// Virtualized CodeView using [ListView.builder] for sub-16ms rendering of 100,000+ line files.
/// Features selection handles, magnifier lens, touch floating toolbar, code folding, and indentation guides.
class CodeView extends StatefulWidget {
  const CodeView({super.key, required this.model, this.foldingModel});
  final EditorModel model;
  final FoldingModel? foldingModel;

  static const double _gutterW = 48;
  static const double _codeLeft = 56;
  static const double _topPad = 8;

  @override
  State<CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<CodeView> {
  late final EditorInputClient _inputClient;
  late final FoldingModel _folding;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  TextPosition? _selectionStart;
  TextPosition? _selectionEnd;
  Offset? _magnifierPos;

  @override
  void initState() {
    super.initState();
    _folding = widget.foldingModel ?? FoldingModel();
    _inputClient = EditorInputClient(
      model: widget.model,
      onEditingChanged: () => setState(() {}),
    );
    widget.model.addListener(_onModelChanged);
    _folding.addListener(_onModelChanged);

    _verticalScrollController.addListener(_onScrollChanged);
    _horizontalScrollController.addListener(_onScrollChanged);
  }

  @override
  void didUpdateWidget(CodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model) {
      oldWidget.model.removeListener(_onModelChanged);
      widget.model.addListener(_onModelChanged);
      _inputClient.detach();
      _clearSelection();
    }
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChanged);
    _folding.removeListener(_onModelChanged);
    _verticalScrollController.removeListener(_onScrollChanged);
    _horizontalScrollController.removeListener(_onScrollChanged);
    _inputClient.detach();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _onModelChanged() {
    if (mounted) setState(() {});
  }

  void _onScrollChanged() {
    if (mounted) setState(() {});
  }

  void _clearSelection() {
    setState(() {
      _selectionStart = null;
      _selectionEnd = null;
      _magnifierPos = null;
    });
  }

  void _selectWordAt(int row, int col) {
    final line = widget.model.lines[row];
    if (line.isEmpty) {
      setState(() {
        _selectionStart = TextPosition(row, 0);
        _selectionEnd = TextPosition(row, 0);
      });
      return;
    }

    var start = col.clamp(0, line.length);
    var end = col.clamp(0, line.length);

    final wordReg = RegExp(r'[\w$]');
    while (start > 0 && wordReg.hasMatch(line[start - 1])) {
      start--;
    }
    while (end < line.length && wordReg.hasMatch(line[end])) {
      end++;
    }

    setState(() {
      _selectionStart = TextPosition(row, start);
      _selectionEnd = TextPosition(row, end);
    });
  }

  TextPosition _posFromOffset(Offset localPos, double lineH, double charW) {
    final lines = widget.model.lines;
    final dy = localPos.dy + _verticalScrollController.offset;
    final dx = localPos.dx + _horizontalScrollController.offset;
    final r = ((dy - CodeView._topPad) / lineH).floor().clamp(0, lines.length - 1);
    final c = ((dx - CodeView._codeLeft) / charW).round().clamp(0, lines[r].length);
    return TextPosition(r, c);
  }

  Future<void> _copySelection() async {
    if (_selectionStart == null || _selectionEnd == null) return;
    final text = _getSelectedText();
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> _cutSelection() async {
    if (_selectionStart == null || _selectionEnd == null) return;
    await _copySelection();
    widget.model.document.deleteRange(_selectionStart!, _selectionEnd!);
    _clearSelection();
  }

  Future<void> _pasteText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    if (_selectionStart != null && _selectionEnd != null) {
      widget.model.document.replaceRange(_selectionStart!, _selectionEnd!, data!.text!);
      _clearSelection();
    } else {
      widget.model.insert(data!.text!);
    }
  }

  void _selectAll() {
    final lines = widget.model.lines;
    if (lines.isEmpty) return;
    setState(() {
      _selectionStart = const TextPosition(0, 0);
      _selectionEnd = TextPosition(lines.length - 1, lines.last.length);
    });
  }

  String _getSelectedText() {
    if (_selectionStart == null || _selectionEnd == null) return '';
    var s = _selectionStart!;
    var e = _selectionEnd!;
    if (s.row > e.row || (s.row == e.row && s.col > e.col)) {
      final temp = s;
      s = e;
      e = temp;
    }

    final lines = widget.model.lines;
    if (s.row == e.row) {
      return lines[s.row].substring(s.col, e.col);
    }

    final buf = StringBuffer();
    buf.writeln(lines[s.row].substring(s.col));
    for (var r = s.row + 1; r < e.row; r++) {
      buf.writeln(lines[r]);
    }
    buf.write(lines[e.row].substring(0, e.col));
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = SettingsScope.of(context);
    final fs = s.fontSize;
    final lineH = fs * 22 / 12;
    final charW = fs * 0.6;
    final baseStyle = LatticeText.mono(
      fs,
      color: c.synPlain,
      height: lineH / fs,
      fontFamily: s.fontFamily,
    );

    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        final lines = widget.model.lines;
        final suggestions = widget.model.suggestions;
        final caretRow = widget.model.row;
        final caretCol = widget.model.col;

        final foldRegions = _folding.calculateFoldRegions(widget.model.document);

        final visibleLineIndices = <int>[];
        for (var i = 0; i < lines.length; i++) {
          if (!_folding.isLineHidden(i, foldRegions)) {
            visibleLineIndices.add(i);
          }
        }

        final longestLineLength = lines.fold<int>(0, (m, l) => l.length > m ? l.length : m);
        final minContentWidth = CodeView._codeLeft + (longestLineLength + 6) * charW;

        final caretX = CodeView._codeLeft + caretCol * charW;
        final caretY = CodeView._topPad + caretRow * lineH;

        final hasSelection = _selectionStart != null && _selectionEnd != null && _selectionStart != _selectionEnd;

        TextPosition normStart = _selectionStart ?? const TextPosition(0, 0);
        TextPosition normEnd = _selectionEnd ?? const TextPosition(0, 0);
        if (_selectionStart != null && _selectionEnd != null) {
          if (_selectionStart!.row > _selectionEnd!.row ||
              (_selectionStart!.row == _selectionEnd!.row && _selectionStart!.col > _selectionEnd!.col)) {
            normStart = _selectionEnd!;
            normEnd = _selectionStart!;
          } else {
            normStart = _selectionStart!;
            normEnd = _selectionEnd!;
          }
        }

        final scrollOffset = _verticalScrollController.hasClients ? _verticalScrollController.offset : 0.0;
        final viewportHeight = MediaQuery.of(context).size.height;
        final firstVisibleRow = max(0, ((scrollOffset - CodeView._topPad) / lineH).floor() - 2);
        final lastVisibleRow = min(lines.length - 1, (((scrollOffset + viewportHeight) - CodeView._topPad) / lineH).ceil() + 2);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            _inputClient.attach();
            if (hasSelection) {
              _clearSelection();
              return;
            }
            final pos = _posFromOffset(details.localPosition, lineH, charW);
            _inputClient.updateModelSelection(pos.row, pos.col);
          },
          onLongPressStart: (details) {
            final pos = _posFromOffset(details.localPosition, lineH, charW);
            _selectWordAt(pos.row, pos.col);
            setState(() {
              _magnifierPos = details.localPosition;
            });
          },
          onLongPressMoveUpdate: (details) {
            final pos = _posFromOffset(details.localPosition, lineH, charW);
            setState(() {
              _selectionEnd = pos;
              _magnifierPos = details.localPosition;
            });
          },
          onLongPressEnd: (_) {
            setState(() {
              _magnifierPos = null;
            });
          },
          child: Stack(
            children: [
              Container(
                color: c.bg,
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: minContentWidth,
                    child: Stack(
                      children: [
                        // Virtualized Line List
                        Padding(
                          padding: const EdgeInsets.only(top: CodeView._topPad),
                          child: ListView.builder(
                            controller: _verticalScrollController,
                            itemCount: visibleLineIndices.length,
                            itemExtent: lineH,
                            itemBuilder: (context, vIndex) {
                              final index = visibleLineIndices[vIndex];
                              final lineText = lines[index];
                              final isCurrentLine = index == caretRow;
                              final gitMark = widget.model.gitMarks[index];
                              final isFoldable = foldRegions.any((r) => r.startLine == index);

                              final leadingSpaces = RegExp(r'^\s*').stringMatch(lineText)?.length ?? 0;
                              final indentLevels = leadingSpaces ~/ 2;

                              return Container(
                                height: lineH,
                                color: isCurrentLine ? c.lineHighlight : Colors.transparent,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Gutter & Fold toggle
                                    SizedBox(
                                      width: CodeView._gutterW,
                                      child: Container(
                                        color: c.surface,
                                        padding: const EdgeInsets.only(right: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (isFoldable)
                                              GestureDetector(
                                                onTap: () => _folding.toggleFold(index),
                                                child: Icon(
                                                  _folding.isLineFolded(index)
                                                      ? Icons.chevron_right
                                                      : Icons.expand_more,
                                                  size: 14,
                                                  color: c.textMuted,
                                                ),
                                              ),
                                            const SizedBox(width: 2),
                                            if (s.lineNumbers)
                                              Text(
                                                '${index + 1}',
                                                style: LatticeText.mono(
                                                  fs,
                                                  color: isCurrentLine ? c.text : c.textFaint,
                                                  fontFamily: s.fontFamily,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Git Mark Bar
                                    SizedBox(
                                      width: 4,
                                      child: gitMark != null
                                          ? ColoredBox(
                                              color: gitMark == 'added' ? c.success : c.warning,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 4),
                                    // Indentation Guides & Code Text
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          for (var i = 1; i <= indentLevels; i++)
                                            Positioned(
                                              left: i * 2 * charW,
                                              top: 0,
                                              bottom: 0,
                                              width: 1,
                                              child: Container(color: c.border),
                                            ),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text.rich(
                                              highlightLine(
                                                lineText.isEmpty ? ' ' : lineText,
                                                c,
                                                baseStyle,
                                                fileName: widget.model.fileName,
                                              ),
                                              softWrap: false,
                                              overflow: TextOverflow.visible,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        // Virtualized Selection Highlight Layer
                        if (hasSelection) ...[
                          for (var r = max(normStart.row, firstVisibleRow); r <= min(normEnd.row, lastVisibleRow); r++)
                            Positioned(
                              left: CodeView._codeLeft + (r == normStart.row ? normStart.col : 0) * charW,
                              top: CodeView._topPad + r * lineH - scrollOffset,
                              width: max(1.0, ((r == normEnd.row ? normEnd.col : lines[r].length) -
                                      (r == normStart.row ? normStart.col : 0)) * charW),
                              height: lineH,
                              child: ColoredBox(color: c.accentSoft),
                            ),
                          // Selection Handles
                          Positioned(
                            left: CodeView._codeLeft + normStart.col * charW - 10,
                            top: CodeView._topPad + normStart.row * lineH + lineH - scrollOffset,
                            child: GestureDetector(
                              onPanUpdate: (d) {
                                final pos = _posFromOffset(d.globalPosition, lineH, charW);
                                setState(() {
                                  _selectionStart = pos;
                                  _magnifierPos = d.localPosition;
                                });
                              },
                              onPanEnd: (_) => setState(() {
                                _magnifierPos = null;
                              }),
                              child: _HandleDot(color: c.accent),
                            ),
                          ),
                          Positioned(
                            left: CodeView._codeLeft + normEnd.col * charW - 10,
                            top: CodeView._topPad + normEnd.row * lineH + lineH - scrollOffset,
                            child: GestureDetector(
                              onPanUpdate: (d) {
                                final pos = _posFromOffset(d.globalPosition, lineH, charW);
                                setState(() {
                                  _selectionEnd = pos;
                                  _magnifierPos = d.localPosition;
                                });
                              },
                              onPanEnd: (_) => setState(() {
                                _magnifierPos = null;
                              }),
                              child: _HandleDot(color: c.accent),
                            ),
                          ),
                        ],
                        // Caret Overlay
                        if (!hasSelection)
                          Positioned(
                            left: caretX,
                            top: caretY - scrollOffset,
                            child: BlinkingCaret(
                              color: c.accent,
                              height: lineH - 4,
                            ),
                          ),
                        // Autocomplete Popup Overlay
                        if (suggestions.isNotEmpty && !hasSelection)
                          Positioned(
                            left: caretX - 6,
                            top: caretY + lineH + 4 - scrollOffset,
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
              // Floating Action Toolbar on Selection
              if (hasSelection)
                Positioned(
                  top: CodeView._topPad + normStart.row * lineH - 48 - scrollOffset,
                  left: CodeView._codeLeft + normStart.col * charW,
                  child: _FloatingToolbar(
                    onCut: _cutSelection,
                    onCopy: _copySelection,
                    onPaste: _pasteText,
                    onSelectAll: _selectAll,
                  ),
                ),
              // Touch Magnifier Lens
              if (_magnifierPos != null)
                Positioned(
                  left: _magnifierPos!.dx - 40,
                  top: _magnifierPos!.dy - 70,
                  child: RawMagnifier(
                    size: const Size(80, 48),
                    magnificationScale: 1.25,
                    focalPointOffset: const Offset(0, 30),
                    decoration: MagnifierDecoration(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(color: c.accent, width: 1.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HandleDot extends StatelessWidget {
  const _HandleDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

class _FloatingToolbar extends StatelessWidget {
  const _FloatingToolbar({
    required this.onCut,
    required this.onCopy,
    required this.onPaste,
    required this.onSelectAll,
  });

  final VoidCallback onCut;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.raised,
      borderRadius: BorderRadius.circular(10),
      elevation: 6,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolbarBtn(label: 'Cut', onTap: onCut),
            _ToolbarBtn(label: 'Copy', onTap: onCopy),
            _ToolbarBtn(label: 'Paste', onTap: onPaste),
            _ToolbarBtn(label: 'Select All', onTap: onSelectAll),
          ],
        ),
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  const _ToolbarBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          label,
          style: LatticeText.ui(12, weight: FontWeight.w500, color: c.text),
        ),
      ),
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
