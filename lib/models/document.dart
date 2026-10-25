import 'package:flutter/foundation.dart';

/// Position in the text document (zero-indexed row and column).
class TextPosition {
  const TextPosition(this.row, this.col);
  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextPosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'TextPosition($row, $col)';
}

/// Abstract document buffer contract allowing different underlying implementations
/// (LineList, PieceTable, Rope) while keeping the editor core decoupled from storage.
abstract class TextDocument extends ChangeNotifier {
  List<String> get lines;
  int get lineCount;
  int get length;
  String get text;

  int get row;
  int get col;
  set cursorPosition(TextPosition pos);

  String lineAt(int index);
  TextPosition offsetToPosition(int offset);
  int positionToOffset(TextPosition position);

  void insertText(int row, int col, String text);
  void deleteRange(TextPosition start, TextPosition end);
  void replaceRange(TextPosition start, TextPosition end, String text);
  void replaceRangeWithoutSnapshot(TextPosition start, TextPosition end, String text);
  void setLinesDirectly(List<String> newLines);

  bool get canUndo;
  bool get canRedo;
  void undo();
  void redo();
  void pushSnapshot();
}

class DocumentSnapshot {
  DocumentSnapshot(this.lines, this.row, this.col);
  final List<String> lines;
  final int row;
  final int col;
}

/// Line-list implementation of [TextDocument] with typing burst undo grouping.
class LineListDocument extends TextDocument {
  LineListDocument({
    List<String>? initialLines,
    int initialRow = 0,
    int initialCol = 0,
  })  : _lines = List<String>.of(initialLines == null || initialLines.isEmpty ? const [''] : initialLines),
        _row = initialRow,
        _col = initialCol;

  List<String> _lines;
  int _row;
  int _col;

  DateTime? _lastEditTime;
  int? _lastEditRow;

  final List<DocumentSnapshot> _undoStack = [];
  final List<DocumentSnapshot> _redoStack = [];

  @override
  int get row => _row;

  @override
  int get col => _col;

  @override
  set cursorPosition(TextPosition pos) {
    if (_lines.isEmpty) _lines.add('');
    final maxRow = _lines.length - 1;
    _row = pos.row.clamp(0, maxRow);
    _col = pos.col.clamp(0, _lines[_row].length);
    notifyListeners();
  }

  @override
  List<String> get lines => List.unmodifiable(_lines);

  @override
  int get lineCount => _lines.length;

  @override
  int get length {
    var total = 0;
    for (var i = 0; i < _lines.length; i++) {
      total += _lines[i].length + (i < _lines.length - 1 ? 1 : 0);
    }
    return total;
  }

  @override
  String get text => _lines.join('\n');

  @override
  String lineAt(int index) {
    if (index < 0 || index >= _lines.length) return '';
    return _lines[index];
  }

  @override
  TextPosition offsetToPosition(int offset) {
    if (_lines.isEmpty) return const TextPosition(0, 0);
    var current = 0;
    for (var i = 0; i < _lines.length; i++) {
      final len = _lines[i].length;
      if (offset <= current + len) {
        return TextPosition(i, offset - current);
      }
      current += len + 1;
    }
    return TextPosition(_lines.length - 1, _lines.last.length);
  }

  @override
  int positionToOffset(TextPosition position) {
    if (_lines.isEmpty) return 0;
    var offset = 0;
    final maxRow = _lines.length - 1;
    final r = position.row.clamp(0, maxRow);
    for (var i = 0; i < r; i++) {
      offset += _lines[i].length + 1;
    }
    final c = position.col.clamp(0, _lines[r].length);
    return offset + c;
  }

  @override
  void pushSnapshot() {
    _undoStack.add(DocumentSnapshot(List<String>.of(_lines), _row, _col));
    if (_undoStack.length > 200) _undoStack.removeAt(0);
    _redoStack.clear();
    _lastEditTime = null;
    _lastEditRow = null;
  }

  @override
  bool get canUndo => _undoStack.isNotEmpty;

  @override
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(DocumentSnapshot(List<String>.of(_lines), _row, _col));
    final snap = _undoStack.removeLast();
    _lines = List<String>.of(snap.lines);
    if (_lines.isEmpty) _lines.add('');
    _row = snap.row.clamp(0, _lines.length - 1);
    _col = snap.col.clamp(0, _lines[_row].length);
    _lastEditTime = null;
    _lastEditRow = null;
    notifyListeners();
  }

  @override
  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(DocumentSnapshot(List<String>.of(_lines), _row, _col));
    final snap = _redoStack.removeLast();
    _lines = List<String>.of(snap.lines);
    if (_lines.isEmpty) _lines.add('');
    _row = snap.row.clamp(0, _lines.length - 1);
    _col = snap.col.clamp(0, _lines[_row].length);
    _lastEditTime = null;
    _lastEditRow = null;
    notifyListeners();
  }

  void _insertWithoutSnapshot(int r, int c, String insert) {
    if (_lines.isEmpty) _lines.add('');
    final maxRow = _lines.length - 1;
    _row = r.clamp(0, maxRow);
    _col = c.clamp(0, _lines[_row].length);

    if (!insert.contains('\n')) {
      final l = _lines[_row];
      _lines[_row] = l.substring(0, _col) + insert + l.substring(_col);
      _col += insert.length;
    } else {
      final l = _lines[_row];
      final head = l.substring(0, _col);
      final tail = l.substring(_col);
      final parts = insert.split('\n');

      _lines[_row] = head + parts.first;
      for (var i = 1; i < parts.length - 1; i++) {
        _lines.insert(_row + i, parts[i]);
      }
      _lines.insert(_row + parts.length - 1, parts.last + tail);
      _row = _row + parts.length - 1;
      _col = parts.last.length;
    }
  }

  @override
  void insertText(int r, int c, String insert) {
    final now = DateTime.now();
    final isBurst = _lastEditTime != null &&
        _lastEditRow == r &&
        insert.length == 1 &&
        insert != ' ' &&
        insert != '\n' &&
        now.difference(_lastEditTime!).inMilliseconds < 1200;

    if (!isBurst) {
      pushSnapshot();
    }

    _lastEditTime = now;
    _lastEditRow = r;
    _insertWithoutSnapshot(r, c, insert);
    notifyListeners();
  }

  void _deleteWithoutSnapshot(TextPosition start, TextPosition end) {
    if (_lines.isEmpty) _lines.add('');
    var s = start;
    var e = end;
    if (s.row > e.row || (s.row == e.row && s.col > e.col)) {
      final temp = s;
      s = e;
      e = temp;
    }

    if (s.row == e.row) {
      final line = _lines[s.row];
      _lines[s.row] = line.substring(0, s.col) + line.substring(e.col);
    } else {
      final head = _lines[s.row].substring(0, s.col);
      final tail = _lines[e.row].substring(e.col);
      _lines[s.row] = head + tail;
      _lines.removeRange(s.row + 1, e.row + 1);
    }
    _row = s.row;
    _col = s.col;
  }

  @override
  void deleteRange(TextPosition start, TextPosition end) {
    pushSnapshot();
    _deleteWithoutSnapshot(start, end);
    notifyListeners();
  }

  @override
  void replaceRange(TextPosition start, TextPosition end, String text) {
    pushSnapshot();
    _deleteWithoutSnapshot(start, end);
    _insertWithoutSnapshot(_row, _col, text);
    notifyListeners();
  }

  @override
  void replaceRangeWithoutSnapshot(TextPosition start, TextPosition end, String text) {
    _deleteWithoutSnapshot(start, end);
    _insertWithoutSnapshot(_row, _col, text);
    notifyListeners();
  }

  @override
  void setLinesDirectly(List<String> newLines) {
    _lines = List<String>.of(newLines.isEmpty ? const [''] : newLines);
    final maxRow = _lines.length - 1;
    _row = _row.clamp(0, maxRow);
    _col = _col.clamp(0, _lines[_row].length);
    notifyListeners();
  }
}
