import 'dart:math';
import 'package:flutter/material.dart' hide TextPosition;
import 'package:flutter/services.dart';
import '../models/document.dart';
import '../models/editor_model.dart';
import '../models/folding_model.dart';
import '../services/lsp_service.dart';
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
    if (offset <= current + len) return (i, offset - current);
    current += len + 1;
  }
  return (lines.length - 1, lines.last.length);
}

/// Virtualized code view.
///
/// Changes in this version (on top of the previous one):
///  - IME sync: selection and caret are pushed to the keyboard (syncToIme), so
///    Backspace / Cut / Replace-selection work with the phone keyboard
///  - delta based input client (see editor_input_client.dart)
///  - hardware shortcuts: Ctrl/Cmd + C X V A F G, Escape
///  - Unicode-aware word selection (Bengali etc.)
///  - Find bar close gives the keyboard back to the editor
///  - replace-all is batched (one recompute instead of thousands)
///  - settings respected: lineNumbers, minimap
///  - indent guides follow the file's real indent (2 / 4 / 8)
///  - lines list, diagnostics and hashes are computed once per build
///  - leaks fixed (go-to-line controller, own FoldingModel, focus node)
///  - larger autocomplete touch targets, Semantics label
///
/// Known limitation: caret math assumes one cell per UTF-16 unit. Bengali
/// conjuncts, emoji and tabs can drift; fixing that needs per-line text
/// measurement with TextPainter.
class CodeView extends StatefulWidget {
  const CodeView({super.key, required this.model, this.foldingModel});
  final EditorModel model;
  final FoldingModel? foldingModel;

  static const double _topPad = 8;
  static const double _toolbarW = 270;

  @override
  State<CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<CodeView> {
  late EditorInputClient _inputClient;
  late FoldingModel _folding;
  bool _ownFolding = false;
  final _v = ScrollController();
  final _h = ScrollController();
  final _stackKey = GlobalKey();
  final _focus = FocusNode(debugLabel: 'code-view');

  static final _wsRe = RegExp(r'^\s*');
  static final _wordRe = RegExp(r'[\p{L}\p{M}\p{N}_$]', unicode: true);

  TextPosition? _selectionStart;
  TextPosition? _selectionEnd;
  TextPosition? _dragAnchor;
  TextPosition _wordStart = const TextPosition(0, 0);
  TextPosition _wordEnd = const TextPosition(0, 0);
  Offset? _magnifierPos;

  DateTime _lastTapAt = DateTime.fromMillisecondsSinceEpoch(0);
  Offset _lastTapPos = Offset.zero;

  late var _regions = _folding.calculateFoldRegions(widget.model.document);
  Set<int> _foldStarts = {};
  List<int>? _visible;
  int _longest = 0;
  int _docSig = 0;
  int _indent = 2;
  bool _batching = false;
  final Map<int, List<int>> _scopeCache = {};

  (TextPosition, TextPosition)? _bracket;

  bool _findOpen = false, _caseSens = false, _replaceOpen = false;
  final _findCtl = TextEditingController();
  final _replCtl = TextEditingController();
  List<(int, int)> _matches = [];
  Map<int, List<int>> _matchByRow = {};
  int _matchIdx = -1;

  double _lineH = 20, _charW = 8, _codeLeft = 56;
  Size _viewport = Size.zero;
  double? _lastViewportH;

  // ADAPTER: the only place that needs your EditorModel's caret setter.
  void _setCaretRaw(int row, int col) => widget.model.moveCaret(row, col);

  EditorInputClient _makeClient() => EditorInputClient(
        model: widget.model,
        setCaret: _setCaretRaw,
        onEditingChanged: () {
          if (mounted) setState(() {});
        },
      );

  @override
  void initState() {
    super.initState();
    _ownFolding = widget.foldingModel == null;
    _folding = widget.foldingModel ?? FoldingModel();
    _inputClient = _makeClient();
    widget.model.addListener(_onModelChanged);
    _folding.addListener(_onFoldChanged);
    _recompute();
  }

  @override
  void didUpdateWidget(CodeView old) {
    super.didUpdateWidget(old);
    var changed = false;
    if (old.foldingModel != widget.foldingModel) {
      _folding.removeListener(_onFoldChanged);
      if (_ownFolding) _folding.dispose();
      _ownFolding = widget.foldingModel == null;
      _folding = widget.foldingModel ?? FoldingModel();
      _folding.addListener(_onFoldChanged);
      changed = true;
    }
    if (old.model != widget.model) {
      old.model.removeListener(_onModelChanged);
      widget.model.addListener(_onModelChanged);
      _inputClient.detach();
      _inputClient = _makeClient();
      _selectionStart = _selectionEnd = _magnifierPos = _dragAnchor = null;
      _matches = [];
      _matchByRow = {};
      _matchIdx = -1;
      if (_v.hasClients) _v.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_h.hasClients) _h.jumpTo(0);
        _ensureCaretVisible();
      });
      changed = true;
    }
    if (changed) _recompute();
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChanged);
    _folding.removeListener(_onFoldChanged);
    if (_ownFolding) _folding.dispose();
    _inputClient.detach();
    _v.dispose();
    _h.dispose();
    _focus.dispose();
    _findCtl.dispose();
    _replCtl.dispose();
    super.dispose();
  }

  // ---- IME helpers --------------------------------------------------------

  /// Push caret / selection to the keyboard. Without this the keyboard keeps a
  /// stale caret and Backspace / Cut act on the wrong (often empty) range.
  void _syncIme() {
    if (_hasSelection) {
      final (s, e) = _norm();
      _inputClient.syncToIme(s, e);
    } else {
      _inputClient.syncToIme();
    }
  }

  void _setCaret(TextPosition p) => _inputClient.updateModelSelection(p.row, p.col);

  // ---- cached layout ------------------------------------------------------

  int _detectIndent(List<String> lines) {
    var best = 0;
    final n = min(lines.length, 400);
    for (var i = 0; i < n; i++) {
      final l = lines[i];
      if (l.trim().isEmpty) continue;
      final lead = l.length - l.trimLeft().length;
      if (lead > 0 && (best == 0 || lead < best)) best = lead;
    }
    return best == 0 ? 2 : best.clamp(2, 8);
  }

  void _recompute([int? sig]) {
    final lines = widget.model.lines;
    _regions = _folding.calculateFoldRegions(widget.model.document);
    _foldStarts = {for (final r in _regions) r.startLine};
    final anyFolded = _foldStarts.any(_folding.isLineFolded);
    _visible = anyFolded
        ? [
            for (var i = 0; i < lines.length; i++)
              if (!_folding.isLineHidden(i, _regions)) i
          ]
        : null;
    _longest = lines.fold<int>(0, (m, l) => l.length > m ? l.length : m);
    _indent = _detectIndent(lines);
    _scopeCache.clear();
    _docSig = sig ?? Object.hashAll(lines);
    if (_findOpen) _computeMatches();
  }

  int get _count => _visible?.length ?? widget.model.lines.length;
  int _rowAt(int v) => _visible?[v] ?? v;
  int _vIndexOf(int row) {
    final vis = _visible;
    if (vis == null) return row;
    if (vis.isEmpty) return 0;
    var lo = 0, hi = vis.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (vis[mid] < row) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  void _onModelChanged() {
    if (!mounted || _batching) return;
    final sig = Object.hashAll(widget.model.lines);
    final textChanged = sig != _docSig;
    setState(() {
      _recompute(sig);
      if (textChanged) {
        _selectionStart = _selectionEnd = _magnifierPos = _dragAnchor = null;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCaretVisible());
  }

  void _onFoldChanged() {
    if (mounted) setState(_recompute);
  }

  // ---- find & replace -----------------------------------------------------

  void _computeMatches() {
    final q = _findCtl.text;
    _matches = [];
    _matchByRow = {};
    if (q.isEmpty) {
      _matchIdx = -1;
      return;
    }
    final lines = widget.model.lines;
    final needle = _caseSens ? q : q.toLowerCase();
    for (var r = 0; r < lines.length && _matches.length < 5000; r++) {
      final hay = _caseSens ? lines[r] : lines[r].toLowerCase();
      var i = hay.indexOf(needle);
      while (i >= 0 && _matches.length < 5000) {
        _matches.add((r, i));
        (_matchByRow[r] ??= []).add(i);
        i = hay.indexOf(needle, i + needle.length);
      }
    }
    _matchIdx = _matches.isEmpty ? -1 : _matchIdx.clamp(0, _matches.length - 1);
  }

  void _onFindChanged() {
    setState(() {
      _matchIdx = 0;
      _computeMatches();
      final m = widget.model;
      final i = _matches.indexWhere(
          (e) => e.$1 > m.row || (e.$1 == m.row && e.$2 >= m.col));
      if (_matches.isNotEmpty) _matchIdx = i < 0 ? 0 : i;
    });
    _goToMatch();
  }

  void _stepMatch(int d) {
    if (_matches.isEmpty) return;
    setState(() => _matchIdx = (_matchIdx + d) % _matches.length);
    _goToMatch();
  }

  void _goToMatch() {
    if (_matchIdx < 0 || _matchIdx >= _matches.length) return;
    final (r, col) = _matches[_matchIdx];
    if (_hasSelection) {
      setState(() => _selectionStart = _selectionEnd = null);
    }
    _inputClient.updateModelSelection(r, col);
    _centerRow(r);
  }

  void _replaceCurrent() {
    if (_matchIdx < 0 || _matchIdx >= _matches.length) return;
    final (r, col) = _matches[_matchIdx];
    final len = _findCtl.text.length;
    widget.model.document.replaceRange(
        TextPosition(r, col), TextPosition(r, col + len), _replCtl.text);
    setState(_computeMatches);
    _goToMatch();
    HapticFeedback.selectionClick();
  }

  void _replaceAll() {
    if (_matches.isEmpty) return;
    final len = _findCtl.text.length;
    final doc = widget.model.document;
    final todo = List<(int, int)>.of(_matches);
    // One recompute at the end instead of one per replacement.
    _batching = true;
    try {
      for (final (r, col) in todo.reversed) {
        doc.replaceRange(
            TextPosition(r, col), TextPosition(r, col + len), _replCtl.text);
      }
    } finally {
      _batching = false;
    }
    setState(() {
      _selectionStart = _selectionEnd = null;
      _recompute();
    });
    _inputClient.syncToIme();
    HapticFeedback.mediumImpact();
  }

  void _toggleFind() {
    final closing = _findOpen;
    setState(() {
      _findOpen = !_findOpen;
      if (_findOpen) {
        if (_hasSelection) {
          final t = _getSelectedText();
          if (!t.contains('\n')) _findCtl.text = t;
        }
        _computeMatches();
      } else {
        _matches = [];
        _matchByRow = {};
        _replaceOpen = false;
      }
    });
    if (closing) {
      // The find TextField owned the keyboard; hand it back to the editor.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _inputClient.attach();
      });
    }
  }

  // ---- go to line ---------------------------------------------------------

  Future<void> _goToLine() async {
    final c = context.c;
    final total = widget.model.lines.length;
    final ctl = TextEditingController(text: '${widget.model.row + 1}');
    ctl.selection = TextSelection(baseOffset: 0, extentOffset: ctl.text.length);
    final res = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.raised,
        title: Text('Go to line',
            style: LatticeText.ui(16, weight: FontWeight.w600, color: c.text)),
        content: TextField(
          controller: ctl,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: LatticeText.mono(15, color: c.text),
          cursorColor: c.accent,
          decoration: InputDecoration(
            hintText: '1 – $total',
            hintStyle: LatticeText.mono(15, color: c.textFaint),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, int.tryParse(v)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: LatticeText.ui(14, color: c.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, int.tryParse(ctl.text)),
              child: Text('Go',
                  style: LatticeText.ui(14, weight: FontWeight.w600, color: c.accent))),
        ],
      ),
    );
    // Dispose after the dialog's exit animation has finished.
    Future<void>.delayed(const Duration(milliseconds: 400), ctl.dispose);
    if (res == null || !mounted || total == 0) return;
    final r = (res - 1).clamp(0, total - 1);
    setState(() => _selectionStart = _selectionEnd = null);
    _inputClient.updateModelSelection(r, 0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerRow(r, force: true));
  }

  // ---- scopes / brackets --------------------------------------------------

  List<int> _scopes(int row) {
    final cached = _scopeCache[row];
    if (cached != null) return cached;
    final lines = widget.model.lines;
    if (row < 0 || row >= lines.length) return const [];
    int ind(String l) => l.length - l.trimLeft().length;
    var cur = lines[row].trim().isEmpty ? 1 << 30 : ind(lines[row]);
    final out = <int>[];
    for (var r = row - 1; r >= 0 && row - r < 3000 && out.length < 3; r--) {
      final l = lines[r];
      if (l.trim().isEmpty) continue;
      final i = ind(l);
      if (i < cur) {
        out.add(r);
        cur = i;
        if (i == 0) break;
      }
    }
    return _scopeCache[row] = out.reversed.toList();
  }

  String _scopeLabel(int row) {
    var t = widget.model.lines[row].trim();
    if (t.endsWith('{')) t = t.substring(0, t.length - 1).trim();
    return t.length > 28 ? '${t.substring(0, 28)}…' : t;
  }

  (TextPosition, TextPosition)? _findBracketPair(List<String> lines) {
    const open = '([{', close = ')]}';
    final m = widget.model;
    if (m.row >= lines.length) return null;
    final line = lines[m.row];
    for (final k in [m.col - 1, m.col]) {
      if (k < 0 || k >= line.length) continue;
      final ch = line[k];
      final oi = open.indexOf(ch), ci = close.indexOf(ch);
      if (oi < 0 && ci < 0) continue;
      final fwd = oi >= 0;
      final target = fwd ? close[oi] : open[ci];
      var depth = 0, r = m.row, col = k, steps = 0;
      while (r >= 0 && r < lines.length) {
        final l = lines[r];
        while (col >= 0 && col < l.length) {
          final x = l[col];
          if (x == ch) {
            depth++;
          } else if (x == target && --depth == 0) {
            return (TextPosition(m.row, k), TextPosition(r, col));
          }
          col += fwd ? 1 : -1;
          if (++steps > 20000) return null;
        }
        r += fwd ? 1 : -1;
        if (r < 0 || r >= lines.length) break;
        col = fwd ? 0 : lines[r].length - 1;
      }
      return null;
    }
    return null;
  }

  // ---- geometry -----------------------------------------------------------

  double get _vOff => _v.hasClients ? _v.offset : 0;
  double get _hOff => _h.hasClients ? _h.offset : 0;

  double _xOfCol(int col) => _codeLeft + col * _charW - _hOff;
  double _yOfRow(int row) => CodeView._topPad + _vIndexOf(row) * _lineH - _vOff;

  TextPosition _posFromLocal(Offset p) {
    final lines = widget.model.lines;
    final count = _count;
    if (count == 0) return const TextPosition(0, 0);
    final v = ((p.dy - CodeView._topPad + _vOff) / _lineH).floor().clamp(0, count - 1);
    final row = _rowAt(v);
    final col = ((p.dx + _hOff - _codeLeft) / _charW).round().clamp(0, lines[row].length);
    return TextPosition(row, col);
  }

  Offset _globalToLocal(Offset g) =>
      (_stackKey.currentContext!.findRenderObject() as RenderBox).globalToLocal(g);

  double _measureCharW(TextStyle style, double fs) {
    final tp = TextPainter(
      text: TextSpan(text: 'M' * 16, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout();
    final w = tp.width / 16;
    tp.dispose();
    return w > 0 ? w : fs * 0.6;
  }

  void _centerRow(int row, {bool force = false}) {
    if (!_v.hasClients) return;
    final p = _v.position;
    final top = _vIndexOf(row) * _lineH;
    if (force ||
        top < p.pixels + _lineH * 3 ||
        top > p.pixels + p.viewportDimension - _lineH * 3) {
      _v.jumpTo((top - p.viewportDimension / 2).clamp(0.0, p.maxScrollExtent));
    }
  }

  void _ensureCaretVisible() {
    if (!mounted || !_v.hasClients || !_h.hasClients) return;
    final m = widget.model;
    final top = _vIndexOf(m.row) * _lineH;
    final vp = _v.position;
    final stickyH = _scopes(m.row).length * _lineH;
    if (top - stickyH < vp.pixels) {
      _v.jumpTo((top - stickyH).clamp(0.0, vp.maxScrollExtent));
    } else if (top + _lineH > vp.pixels + vp.viewportDimension) {
      _v.jumpTo((top + _lineH - vp.viewportDimension).clamp(0.0, vp.maxScrollExtent));
    }
    final cx = _codeLeft + m.col * _charW;
    final hp = _h.position;
    if (cx < hp.pixels + _codeLeft) {
      _h.jumpTo((cx - _codeLeft - _charW * 2).clamp(0.0, hp.maxScrollExtent));
    } else if (cx + _charW * 2 > hp.pixels + hp.viewportDimension) {
      _h.jumpTo((cx + _charW * 2 - hp.viewportDimension).clamp(0.0, hp.maxScrollExtent));
    }
  }

  // ---- selection & clipboard ---------------------------------------------

  TextPosition _clampPos(TextPosition p) {
    final lines = widget.model.lines;
    if (lines.isEmpty) return const TextPosition(0, 0);
    final r = p.row.clamp(0, lines.length - 1);
    return TextPosition(r, p.col.clamp(0, lines[r].length));
  }

  bool get _hasSelection =>
      _selectionStart != null && _selectionEnd != null && _selectionStart != _selectionEnd;

  (TextPosition, TextPosition) _norm() {
    final a = _clampPos(_selectionStart ?? const TextPosition(0, 0));
    final b = _clampPos(_selectionEnd ?? const TextPosition(0, 0));
    final swap = a.row > b.row || (a.row == b.row && a.col > b.col);
    return swap ? (b, a) : (a, b);
  }

  void _clearSelection() {
    setState(() {
      _selectionStart = _selectionEnd = _magnifierPos = _dragAnchor = null;
    });
    _inputClient.syncToIme();
  }

  void _selectWordAt(int row, int col) {
    final line = widget.model.lines[row];
    var start = col.clamp(0, line.length);
    var end = start;
    while (start > 0 && _wordRe.hasMatch(line[start - 1])) {
      start--;
    }
    while (end < line.length && _wordRe.hasMatch(line[end])) {
      end++;
    }
    setState(() {
      _selectionStart = TextPosition(row, start);
      _selectionEnd = TextPosition(row, end);
    });
    _syncIme();
  }

  void _selectLine(int row) {
    final len = widget.model.lines[row].length;
    setState(() {
      _selectionStart = TextPosition(row, 0);
      _selectionEnd = TextPosition(row, len);
    });
    _syncIme();
  }

  String _getSelectedText() {
    if (!_hasSelection) return '';
    final (s, e) = _norm();
    final lines = widget.model.lines;
    if (s.row == e.row) return lines[s.row].substring(s.col, e.col);
    final buf = StringBuffer()..writeln(lines[s.row].substring(s.col));
    for (var r = s.row + 1; r < e.row; r++) {
      buf.writeln(lines[r]);
    }
    buf.write(lines[e.row].substring(0, e.col));
    return buf.toString();
  }

  Future<void> _copySelection() async {
    await Clipboard.setData(ClipboardData(text: _getSelectedText()));
    HapticFeedback.selectionClick();
  }

  Future<void> _cutSelection() async {
    if (!_hasSelection) return;
    final (s, e) = _norm();
    await _copySelection();
    widget.model.document.deleteRange(s, e);
    _clearSelection();
    _setCaret(s);
  }

  Future<void> _pasteText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    if (_hasSelection) {
      final (s, e) = _norm();
      widget.model.document.replaceRange(s, e, text);
      _clearSelection();
    } else {
      widget.model.insert(text);
    }
    _inputClient.syncToIme();
  }

  void _selectAll() {
    final lines = widget.model.lines;
    if (lines.isEmpty) return;
    setState(() {
      _selectionStart = const TextPosition(0, 0);
      _selectionEnd = TextPosition(lines.length - 1, lines.last.length);
    });
    _syncIme();
  }

  // ---- hardware keyboard --------------------------------------------------
  // Only shortcuts here. Backspace / Delete / arrows / Enter come through the
  // IME as deltas; handling them here too would apply them twice.

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final hw = HardwareKeyboard.instance;
    final ctrl = hw.isControlPressed || hw.isMetaPressed;
    if (k == LogicalKeyboardKey.escape) {
      if (_findOpen) {
        _toggleFind();
        return KeyEventResult.handled;
      }
      if (_hasSelection) {
        _clearSelection();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (!ctrl) return KeyEventResult.ignored;
    if (k == LogicalKeyboardKey.keyC) {
      _copySelection();
    } else if (k == LogicalKeyboardKey.keyX) {
      _cutSelection();
    } else if (k == LogicalKeyboardKey.keyV) {
      _pasteText();
    } else if (k == LogicalKeyboardKey.keyA) {
      _selectAll();
    } else if (k == LogicalKeyboardKey.keyF) {
      if (!_findOpen) _toggleFind();
    } else if (k == LogicalKeyboardKey.keyG) {
      _goToLine();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // ---- gestures -----------------------------------------------------------

  void _onTapUp(TapUpDetails d) {
    _focus.requestFocus();
    _inputClient.attach();
    final now = DateTime.now();
    final isDouble = now.difference(_lastTapAt) < const Duration(milliseconds: 300) &&
        (d.localPosition - _lastTapPos).distance < 24;
    _lastTapAt = isDouble ? DateTime.fromMillisecondsSinceEpoch(0) : now;
    _lastTapPos = d.localPosition;

    if (_count == 0) return;
    final p = _posFromLocal(d.localPosition);

    if (d.localPosition.dx < _codeLeft - 8) {
      _selectLine(p.row);
      HapticFeedback.selectionClick();
      return;
    }
    if (isDouble) {
      _selectWordAt(p.row, p.col);
      HapticFeedback.selectionClick();
      return;
    }
    if (_hasSelection) {
      _clearSelection();
      return;
    }
    _inputClient.updateModelSelection(p.row, p.col);
  }

  void _onLongPressStart(LongPressStartDetails d) {
    if (_count == 0) return;
    final p = _posFromLocal(d.localPosition);
    _selectWordAt(p.row, p.col);
    final (s, e) = _norm();
    _wordStart = s;
    _wordEnd = e;
    HapticFeedback.mediumImpact();
    setState(() => _magnifierPos = d.localPosition);
  }

  void _onLongPressMove(LongPressMoveUpdateDetails d) {
    if (_count == 0) return;
    final pos = _posFromLocal(d.localPosition);
    final before = pos.row < _wordStart.row ||
        (pos.row == _wordStart.row && pos.col < _wordStart.col);
    setState(() {
      if (before) {
        _selectionStart = pos;
        _selectionEnd = _wordEnd;
      } else {
        _selectionStart = _wordStart;
        _selectionEnd = pos;
      }
      _magnifierPos = d.localPosition;
    });
  }

  // ---- build --------------------------------------------------------------

  static const _langs = {
    'dart': 'Dart', 'js': 'JavaScript', 'ts': 'TypeScript', 'tsx': 'TypeScript React',
    'py': 'Python', 'json': 'JSON', 'md': 'Markdown', 'html': 'HTML', 'css': 'CSS',
    'kt': 'Kotlin', 'java': 'Java', 'go': 'Go', 'rs': 'Rust', 'yaml': 'YAML',
    'cpp': 'C++',
  };

  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    final sel = !_hasSelection
        ? ''
        : () {
            final (ns, ne) = _norm();
            return ns.row == ne.row
                ? ' (${ne.col - ns.col} selected)'
                : ' (${ne.row - ns.row + 1} lines selected)';
          }();
    final name = m.fileName;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      child: Semantics(
        label: 'Code editor, ${name.isEmpty ? 'untitled' : name}',
        textField: true,
        multiline: true,
        child: Column(
          children: [
            _Breadcrumb(
              file: name.isEmpty ? 'untitled' : name,
              scopes: [for (final r in _scopes(m.row)) _scopeLabel(r)],
              findOpen: _findOpen,
              onFind: _toggleFind,
            ),
            Expanded(child: _buildEditor(context)),
            _StatusBar(
              left: 'Ln ${m.row + 1}, Col ${m.col + 1}$sel',
              right: 'Spaces: $_indent   UTF-8   LF   ${_langs[ext] ?? 'Plain Text'}',
              onTapLeft: _goToLine,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    final c = context.c;
    final s = SettingsScope.of(context);
    final fs = s.fontSize;
    final lineH = fs * 22 / 12;
    final baseStyle = LatticeText.mono(
      fs,
      color: c.synPlain,
      height: lineH / fs,
      fontFamily: s.fontFamily,
    );
    final charW = _measureCharW(baseStyle, fs);
    final lines = widget.model.lines; // read once, reused by every row
    final digits = max(3, lines.length.toString().length);
    final gutterW = s.lineNumbers ? max(48.0, digits * charW + 36) : 28.0;
    _lineH = lineH;
    _charW = charW;
    _codeLeft = gutterW + 8;
    _bracket = _hasSelection ? null : _findBracketPair(lines);

    final diagByLine = <int, List<dynamic>>{};
    for (final d in widget.model.diagnostics) {
      (diagByLine[d.line as int] ??= []).add(d);
    }

    final selection = _hasSelection ? _norm() : null;
    final caretRow = widget.model.row;
    final caretLeading =
        caretRow < lines.length ? (_wsRe.stringMatch(lines[caretRow])?.length ?? 0) : 0;
    final activeGuide = max(0, caretLeading ~/ _indent - 1);

    return LayoutBuilder(builder: (context, box) {
      _viewport = box.biggest;
      if (_lastViewportH != null && box.maxHeight < _lastViewportH! - 40) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCaretVisible());
      }
      _lastViewportH = box.maxHeight;
      final contentW = max(_viewport.width, _codeLeft + (_longest + 6) * charW);
      final showMinimap = s.minimap && _viewport.width >= 360;

      final editor = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: _onTapUp,
        onLongPressStart: _onLongPressStart,
        onLongPressMoveUpdate: _onLongPressMove,
        onLongPressEnd: (_) {
          setState(() => _magnifierPos = null);
          _syncIme();
        },
        child: MediaQuery.withNoTextScaling(
          child: ColoredBox(
            color: c.bg,
            child: Scrollbar(
              controller: _h,
              notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
              scrollbarOrientation: ScrollbarOrientation.bottom,
              child: Scrollbar(
                controller: _v,
                notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
                child: SingleChildScrollView(
                  controller: _h,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: contentW,
                    height: box.maxHeight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: CodeView._topPad),
                      child: ListView.builder(
                        controller: _v,
                        itemCount: _count,
                        itemExtent: lineH,
                        padding: EdgeInsets.only(bottom: box.maxHeight * 0.4),
                        itemBuilder: (context, vIndex) => _buildRow(
                          context,
                          lines,
                          _rowAt(vIndex),
                          c,
                          s,
                          baseStyle,
                          gutterW,
                          lineH,
                          charW,
                          selection,
                          activeGuide,
                          diagByLine,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      return Stack(
        key: _stackKey,
        children: [
          Positioned.fill(child: editor),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_v, _h]),
              builder: (context, _) => _buildOverlays(c, s, lineH, charW),
            ),
          ),
          if (showMinimap)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: 64,
              child: _Minimap(
                lines: lines,
                count: _count,
                rowAt: _rowAt,
                scroll: _v,
                lineH: lineH,
                bg: c.bg,
                ink: c.textFaint,
                slider: c.accent,
                border: c.border,
              ),
            ),
          if (_findOpen)
            Positioned(
              top: 8,
              right: showMinimap ? 72 : 8,
              child: _FindBar(
                width: min(380.0, _viewport.width - 16),
                controller: _findCtl,
                replaceController: _replCtl,
                caseSens: _caseSens,
                replaceOpen: _replaceOpen,
                count: _findCtl.text.isEmpty
                    ? ''
                    : _matches.isEmpty
                        ? 'No results'
                        : '${_matchIdx + 1} of ${_matches.length}${_matches.length >= 5000 ? '+' : ''}',
                onChanged: _onFindChanged,
                onToggleCase: () {
                  _caseSens = !_caseSens;
                  _onFindChanged();
                },
                onToggleReplace: () => setState(() => _replaceOpen = !_replaceOpen),
                onNext: () => _stepMatch(1),
                onPrev: () => _stepMatch(-1),
                onReplace: _replaceCurrent,
                onReplaceAll: _replaceAll,
                onClose: _toggleFind,
              ),
            ),
        ],
      );
    });
  }

  Widget _buildRow(
    BuildContext context,
    List<String> lines,
    int index,
    dynamic c,
    AppSettings s,
    TextStyle baseStyle,
    double gutterW,
    double lineH,
    double charW,
    (TextPosition, TextPosition)? selection,
    int activeGuide,
    Map<int, List<dynamic>> diagByLine,
  ) {
    final text = lines[index];
    final model = widget.model;
    final isCurrent = index == model.row;
    final gitMark = model.gitMarks[index];
    final foldable = _foldStarts.contains(index);
    final folded = foldable && _folding.isLineFolded(index);
    final leading = _wsRe.stringMatch(text)?.length ?? 0;
    final guides = leading ~/ _indent;
    final bracketCols = <int>[
      if (_bracket != null && _bracket!.$1.row == index) _bracket!.$1.col,
      if (_bracket != null && _bracket!.$2.row == index) _bracket!.$2.col,
    ];
    final lineDiagnostics = diagByLine[index] ?? const <dynamic>[];

    double? selLeft, selWidth;
    if (selection != null && index >= selection.$1.row && index <= selection.$2.row) {
      final ns = selection.$1, ne = selection.$2;
      final from = index == ns.row ? ns.col : 0;
      final to = index == ne.row ? ne.col : text.length;
      final span = to - from + (index < ne.row ? 1 : 0);
      if (span > 0) {
        selLeft = from * charW;
        selWidth = max(charW * 0.6, span * charW);
      }
    }

    return SizedBox(
      height: lineH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isCurrent && !_hasSelection)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.lineHighlight,
                  border: Border.symmetric(horizontal: BorderSide(color: c.border)),
                ),
              ),
            ),
          Positioned(
            left: _codeLeft,
            top: 0,
            bottom: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < guides; i++)
                  Positioned(
                    left: i * _indent * charW,
                    top: 0,
                    bottom: 0,
                    width: 1,
                    child: ColoredBox(color: i == activeGuide ? c.textFaint : c.border),
                  ),
                if (selLeft != null)
                  Positioned(
                    left: selLeft,
                    top: 0,
                    bottom: 0,
                    width: selWidth,
                    child: ColoredBox(color: c.accentSoft),
                  ),
                for (final mc in _matchByRow[index] ?? const <int>[])
                  Positioned(
                    left: mc * charW,
                    top: 1,
                    bottom: 1,
                    width: _findCtl.text.length * charW,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.warning.withValues(
                            alpha: _matchIdx >= 0 && _matches[_matchIdx] == (index, mc)
                                ? 0.55
                                : 0.25),
                        border: _matchIdx >= 0 && _matches[_matchIdx] == (index, mc)
                            ? Border.all(color: c.warning)
                            : null,
                      ),
                    ),
                  ),
                for (final diag in lineDiagnostics)
                  Positioned(
                    left: (diag.col as int) * charW,
                    bottom: 0,
                    width: max(charW * 3, 20.0),
                    height: 2,
                    child: Container(
                      color: diag.severity == DiagnosticSeverity.error ? c.error : c.warning,
                    ),
                  ),
                for (final bc in bracketCols)
                  Positioned(
                    left: bc * charW,
                    top: 1,
                    bottom: 1,
                    width: charW,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.accentSoft,
                        border: Border.all(color: c.textFaint, width: 0.5),
                      ),
                    ),
                  ),
                if (isCurrent && !_hasSelection)
                  Positioned(
                    left: model.col * charW,
                    top: 2,
                    child: BlinkingCaret(color: c.accent, height: lineH - 4),
                  ),
                SizedBox(
                  height: lineH,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        highlightLine(text.isEmpty ? ' ' : text, c, baseStyle,
                            fileName: model.fileName),
                        softWrap: false,
                        overflow: TextOverflow.visible,
                      ),
                      if (folded)
                        GestureDetector(
                          onTap: () => _folding.toggleFold(index),
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: c.accentSoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('⋯',
                                style: LatticeText.ui(12, color: c.textMuted)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _h,
              builder: (_, child) =>
                  Transform.translate(offset: Offset(_hOff, 0), child: child),
              child: Row(
                children: [
                  SizedBox(
                    width: 4,
                    child: ColoredBox(
                      color: gitMark == null
                          ? c.bg
                          : (gitMark == 'added' ? c.success : c.warning),
                    ),
                  ),
                  Container(
                    width: gutterW,
                    color: c.bg,
                    padding: const EdgeInsets.only(right: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (foldable)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _folding.toggleFold(index),
                            child: SizedBox(
                              width: 24,
                              height: lineH,
                              child: Icon(
                                folded ? Icons.chevron_right : Icons.expand_more,
                                size: 16,
                                color: c.textMuted,
                              ),
                            ),
                          ),
                        if (s.lineNumbers)
                          Text(
                            '${index + 1}',
                            style: LatticeText.mono(
                              s.fontSize,
                              color: lineDiagnostics.isNotEmpty
                                  ? c.error
                                  : (isCurrent ? c.text : c.textFaint),
                              fontFamily: s.fontFamily,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 4, child: ColoredBox(color: c.bg)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlays(dynamic c, AppSettings s, double lineH, double charW) {
    final suggestions = widget.model.suggestions;
    final m = widget.model;
    final lines = m.lines;
    final children = <Widget>[];

    if (_vOff > 0 && _count > 0) {
      final first = _rowAt(min(_count - 1, (_vOff / lineH).floor()));
      final stuck = _scopes(first);
      final base = LatticeText.mono(s.fontSize,
          color: c.synPlain, height: lineH / s.fontSize, fontFamily: s.fontFamily);
      if (stuck.isNotEmpty) {
        children.add(Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Container(
            decoration: BoxDecoration(
              color: c.bg,
              border: Border(bottom: BorderSide(color: c.border)),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                for (final r in stuck)
                  GestureDetector(
                    onTap: () => _v.jumpTo(
                        (_vIndexOf(r) * lineH).clamp(0.0, _v.position.maxScrollExtent)),
                    child: SizedBox(
                      height: lineH,
                      child: ClipRect(
                        child: Stack(children: [
                          Positioned(
                            left: _codeLeft - _hOff,
                            top: 0,
                            child: Text.rich(
                              highlightLine(lines[r], c, base, fileName: m.fileName),
                              softWrap: false,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: _codeLeft - 8,
                            child: Container(
                              color: c.bg,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 8),
                              child: Text('${r + 1}',
                                  style: LatticeText.mono(s.fontSize,
                                      color: c.textFaint, fontFamily: s.fontFamily)),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ));
      }
    }

    if (_hasSelection) {
      final (ns, ne) = _norm();
      Widget? handle(TextPosition p, bool isStart) {
        final cx = _xOfCol(p.col);
        final y = _yOfRow(p.row) + lineH - 4;
        if (y < 0 || y > _viewport.height || cx < _codeLeft - 6 || cx > _viewport.width + 6) {
          return null;
        }
        return Positioned(
          left: cx - 22,
          top: y,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) => _dragAnchor = isStart ? ne : ns,
            onPanUpdate: (d) {
              final local = _globalToLocal(d.globalPosition);
              final pos = _posFromLocal(local.translate(0, -lineH * 0.9));
              setState(() {
                _selectionStart = _dragAnchor ?? (isStart ? ne : ns);
                _selectionEnd = pos;
                _magnifierPos = local;
              });
            },
            onPanEnd: (_) {
              setState(() {
                _magnifierPos = null;
                _dragAnchor = null;
              });
              _syncIme();
            },
            onPanCancel: () {
              setState(() {
                _magnifierPos = null;
                _dragAnchor = null;
              });
              _syncIme();
            },
            child: SizedBox(
              width: 44,
              height: 44,
              child: Align(
                alignment: Alignment.topCenter,
                child: _HandleDot(color: c.accent),
              ),
            ),
          ),
        );
      }

      final hs = handle(ns, true);
      final he = handle(ne, false);
      if (hs != null) children.add(hs);
      if (he != null) children.add(he);

      var ty = _yOfRow(ns.row) - 46;
      if (ty < 4) ty = _yOfRow(ne.row) + lineH + 36;
      final tx = _xOfCol(ns.col)
          .clamp(8.0, max(8.0, _viewport.width - CodeView._toolbarW - 8.0))
          .toDouble();
      children.add(Positioned(
        top: ty.clamp(4.0, max(4.0, _viewport.height - 48.0)).toDouble(),
        left: tx,
        child: _FloatingToolbar(
          onCut: _cutSelection,
          onCopy: _copySelection,
          onPaste: _pasteText,
          onSelectAll: _selectAll,
        ),
      ));
    } else if (suggestions.isNotEmpty) {
      final popH = suggestions.length * 42.0 + 10;
      final cy = _yOfRow(m.row);
      final below = cy + lineH + 4;
      final top = below + popH > _viewport.height ? cy - popH - 4 : below;
      children.add(Positioned(
        left: _xOfCol(m.col).clamp(4.0, max(4.0, _viewport.width - 244.0)).toDouble(),
        top: max(4.0, top).toDouble(),
        child: _Autocomplete(
          suggestions: suggestions,
          prefix: m.prefix,
          onPick: (sg) {
            m.applySuggestion(sg);
            _inputClient.syncToIme();
          },
          fontFamily: s.fontFamily,
        ),
      ));
    }

    if (_magnifierPos != null) {
      children.add(Positioned(
        left: (_magnifierPos!.dx - 40).clamp(0.0, max(0.0, _viewport.width - 80)),
        top: max(0.0, _magnifierPos!.dy - 90),
        child: IgnorePointer(
          child: RawMagnifier(
            size: const Size(80, 48),
            magnificationScale: 1.25,
            focalPointOffset: const Offset(0, 50),
            decoration: MagnifierDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: c.accent, width: 1.5),
              ),
            ),
          ),
        ),
      ));
    }
    return Stack(children: children);
  }
}

class _HandleDot extends StatelessWidget {
  const _HandleDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
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

class _FloatingToolbar extends StatelessWidget {
  const _FloatingToolbar({
    required this.onCut,
    required this.onCopy,
    required this.onPaste,
    required this.onSelectAll,
  });
  final VoidCallback onCut, onCopy, onPaste, onSelectAll;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.raised,
      borderRadius: BorderRadius.circular(10),
      elevation: 6,
      child: Container(
        height: 40,
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
            _ToolbarBtn(label: 'Select all', onTap: onSelectAll),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40, minWidth: 44),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label,
                style: LatticeText.ui(12, weight: FontWeight.w500, color: c.text)),
          ),
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
          BoxShadow(color: Color(0x73000000), blurRadius: 20, offset: Offset(0, 8)),
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
                    height: 40, // bigger touch target
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(child: _label(c, suggestions[i].label)),
                        const SizedBox(width: 8),
                        Text(suggestions[i].kind,
                            style: LatticeText.ui(11, color: c.textMuted)),
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

  Widget _label(dynamic c, String label) {
    final plain = LatticeText.mono(13, color: c.text, fontFamily: fontFamily);
    final matches = prefix.isNotEmpty &&
        label.length >= prefix.length &&
        label.toLowerCase().startsWith(prefix.toLowerCase());
    if (!matches) {
      return Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: plain);
    }
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: label.substring(0, prefix.length),
          style: LatticeText.mono(13,
              weight: FontWeight.w600, color: c.accent, fontFamily: fontFamily),
        ),
        TextSpan(text: label.substring(prefix.length), style: plain),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _Minimap extends StatelessWidget {
  const _Minimap({
    required this.lines,
    required this.count,
    required this.rowAt,
    required this.scroll,
    required this.lineH,
    required this.bg,
    required this.ink,
    required this.slider,
    required this.border,
  });
  final List<String> lines;
  final int count;
  final int Function(int) rowAt;
  final ScrollController scroll;
  final double lineH;
  final Color bg, ink, slider, border;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final scale = min(2.0, box.maxHeight / max(1, count));
      void jump(double y) {
        if (!scroll.hasClients) return;
        final p = scroll.position;
        final target = y / scale * lineH - p.viewportDimension / 2;
        scroll.jumpTo(target.clamp(0.0, p.maxScrollExtent));
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => jump(d.localPosition.dy),
        onVerticalDragUpdate: (d) => jump(d.localPosition.dy),
        child: AnimatedBuilder(
          animation: scroll,
          builder: (_, __) => CustomPaint(
            painter: _MinimapPainter(this, scale),
            size: box.biggest,
          ),
        ),
      );
    });
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter(this.m, this.scale);
  final _Minimap m;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = m.bg);
    canvas.drawLine(Offset.zero, Offset(0, size.height), Paint()..color = m.border);
    final ink = Paint()..color = m.ink.withValues(alpha: 0.45);
    final step = max(1, (1 / scale).ceil());
    for (var i = 0; i < m.count; i += step) {
      final l = m.lines[m.rowAt(i)];
      if (l.trim().isEmpty) continue;
      final lead = l.length - l.trimLeft().length;
      canvas.drawRect(
        Rect.fromLTWH(6 + min(lead * 0.8, 20), i * scale,
            min((l.length - lead) * 0.8, 52.0), max(1.0, scale * 0.7)),
        ink,
      );
    }
    if (m.scroll.hasClients) {
      final p = m.scroll.position;
      final top = p.pixels / m.lineH * scale;
      final h = p.viewportDimension / m.lineH * scale;
      canvas.drawRect(Rect.fromLTWH(0, top, size.width, h),
          Paint()..color = m.slider.withValues(alpha: 0.12));
    }
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter old) => true;
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({
    required this.file,
    required this.scopes,
    required this.findOpen,
    required this.onFind,
  });
  final String file;
  final List<String> scopes;
  final bool findOpen;
  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final style = LatticeText.ui(12, color: c.textMuted);
    return Container(
      height: 32,
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: [
                  Text(file, style: style.copyWith(color: c.text)),
                  for (final s in scopes) ...[
                    Icon(Icons.chevron_right, size: 14, color: c.textFaint),
                    Text(s, style: style),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Find',
            iconSize: 18,
            constraints: const BoxConstraints.tightFor(width: 44, height: 32),
            padding: EdgeInsets.zero,
            color: findOpen ? c.accent : c.textMuted,
            onPressed: onFind,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.left, required this.right, this.onTapLeft});
  final String left, right;
  final VoidCallback? onTapLeft;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = ThemeData.estimateBrightnessForColor(c.accent) == Brightness.dark
        ? Colors.white
        : const Color(0xFF0B0D10);
    final st = LatticeText.ui(11.5, color: fg);
    return Container(
      height: 28,
      color: c.accent,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTapLeft,
              child: Container(
                height: 28,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(left, style: st, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(right, style: st, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}

class _FindBar extends StatelessWidget {
  const _FindBar({
    required this.width,
    required this.controller,
    required this.replaceController,
    required this.caseSens,
    required this.replaceOpen,
    required this.count,
    required this.onChanged,
    required this.onToggleCase,
    required this.onToggleReplace,
    required this.onNext,
    required this.onPrev,
    required this.onReplace,
    required this.onReplaceAll,
    required this.onClose,
  });
  final double width;
  final TextEditingController controller, replaceController;
  final bool caseSens, replaceOpen;
  final String count;
  final VoidCallback onChanged,
      onToggleCase,
      onToggleReplace,
      onNext,
      onPrev,
      onReplace,
      onReplaceAll,
      onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget btn(IconData i, String tip, VoidCallback f, {double w = 36}) => IconButton(
          tooltip: tip,
          iconSize: 18,
          constraints: BoxConstraints.tightFor(width: w, height: 36),
          padding: EdgeInsets.zero,
          color: c.textMuted,
          onPressed: f,
          icon: Icon(i),
        );
    Widget textBtn(String label, String tip, VoidCallback f) => Tooltip(
          message: tip,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: f,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36, minWidth: 40),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(label,
                      style: LatticeText.ui(12, weight: FontWeight.w600, color: c.accent)),
                ),
              ),
            ),
          ),
        );
    InputDecoration deco(String hint) => InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: LatticeText.mono(13, color: c.textFaint),
        );

    return Material(
      color: c.raised,
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        padding: const EdgeInsets.only(left: 2, right: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                btn(replaceOpen ? Icons.expand_more : Icons.chevron_right,
                    replaceOpen ? 'Hide replace' : 'Show replace', onToggleReplace,
                    w: 32),
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: (_) => onChanged(),
                    onSubmitted: (_) => onNext(),
                    style: LatticeText.mono(13, color: c.text),
                    cursorColor: c.accent,
                    decoration: deco('Find'),
                  ),
                ),
                Tooltip(
                  message: 'Match case',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: onToggleCase,
                    child: Container(
                      width: 36,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: caseSens ? c.accentSoft : null,
                        border: Border.all(color: caseSens ? c.accent : Colors.transparent),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Aa', style: LatticeText.ui(12, color: c.text)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(count,
                    style: LatticeText.ui(11,
                        color: count == 'No results' ? c.warning : c.textMuted)),
                btn(Icons.keyboard_arrow_up, 'Previous match', onPrev),
                btn(Icons.keyboard_arrow_down, 'Next match', onNext),
                btn(Icons.close, 'Close', onClose),
              ],
            ),
            if (replaceOpen)
              Row(
                children: [
                  const SizedBox(width: 32),
                  Expanded(
                    child: TextField(
                      controller: replaceController,
                      onSubmitted: (_) => onReplace(),
                      style: LatticeText.mono(13, color: c.text),
                      cursorColor: c.accent,
                      decoration: deco('Replace'),
                    ),
                  ),
                  textBtn('Replace', 'Replace this match', onReplace),
                  textBtn('All', 'Replace all matches', onReplaceAll),
                ],
              ),
          ],
        ),
      ),
    );
  }
}