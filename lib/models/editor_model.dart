import 'package:flutter/foundation.dart';

class Suggestion {
  const Suggestion(this.label, this.kind);
  final String label;
  final String kind;
}

const kAllSuggestions = <Suggestion>[
  Suggestion('setDirty', 'const'),
  Suggestion('setTimeout', 'function'),
  Suggestion('setInterval', 'function'),
  Suggestion('saveFile', 'function'),
  Suggestion('useState', 'function'),
];

class _Snapshot {
  _Snapshot(this.lines, this.row, this.col);
  final List<String> lines;
  final int row;
  final int col;
}

/// A tiny text buffer: lines + a single cursor, with undo/redo.
class EditorModel extends ChangeNotifier {
  EditorModel({
    required List<String> lines,
    this.row = 0,
    int? col,
    this.dirty = false,
    this.gitMarks = const {},
  })  : lines = List<String>.of(lines),
        col = col ?? 0;

  List<String> lines;
  int row;
  int col;
  bool dirty;

  /// line index -> 'added' | 'modified'
  final Map<int, String> gitMarks;

  final List<_Snapshot> _undo = [];
  final List<_Snapshot> _redo = [];

  String get text => lines.join('\n');
  String get currentLine => lines[row];

  void _push() {
    _undo.add(_Snapshot(List<String>.of(lines), row, col));
    if (_undo.length > 200) _undo.removeAt(0);
    _redo.clear();
  }

  void _restore(_Snapshot s) {
    lines = List<String>.of(s.lines);
    row = s.row;
    col = s.col;
  }

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_Snapshot(List<String>.of(lines), row, col));
    _restore(_undo.removeLast());
    dirty = true;
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_Snapshot(List<String>.of(lines), row, col));
    _restore(_redo.removeLast());
    dirty = true;
    notifyListeners();
  }

  void insert(String s) {
    _push();
    final l = lines[row];
    lines[row] = l.substring(0, col) + s + l.substring(col);
    col += s.length;
    dirty = true;
    notifyListeners();
  }

  void backspace() {
    if (col == 0 && row == 0) return;
    _push();
    if (col > 0) {
      final l = lines[row];
      lines[row] = l.substring(0, col - 1) + l.substring(col);
      col -= 1;
    } else {
      final prevLen = lines[row - 1].length;
      lines[row - 1] = lines[row - 1] + lines[row];
      lines.removeAt(row);
      row -= 1;
      col = prevLen;
    }
    dirty = true;
    notifyListeners();
  }

  void newline() {
    _push();
    final l = lines[row];
    final indent = RegExp(r'^\s*').stringMatch(l) ?? '';
    final extra = l.substring(0, col).trimRight().endsWith('{') ? '  ' : '';
    final tail = l.substring(col);
    lines[row] = l.substring(0, col);
    lines.insert(row + 1, indent + extra + tail);
    row += 1;
    col = indent.length + extra.length;
    dirty = true;
    notifyListeners();
  }

  void moveHorizontal(int d) {
    if (d < 0) {
      if (col > 0) {
        col -= 1;
      } else if (row > 0) {
        row -= 1;
        col = lines[row].length;
      }
    } else {
      if (col < lines[row].length) {
        col += 1;
      } else if (row < lines.length - 1) {
        row += 1;
        col = 0;
      }
    }
    notifyListeners();
  }

  void moveTo(int r, int c) {
    row = r.clamp(0, lines.length - 1);
    col = c.clamp(0, lines[row].length);
    notifyListeners();
  }

  /// Word prefix directly before the cursor, e.g. `setD`.
  String get prefix {
    final before = lines[row].substring(0, col);
    return RegExp(r'[A-Za-z_$][\w$]*$').stringMatch(before) ?? '';
  }

  List<Suggestion> get suggestions {
    final p = prefix;
    if (p.length < 2) return const [];
    return kAllSuggestions
        .where((s) => s.label.startsWith(p) && s.label != p)
        .toList();
  }

  void applySuggestion(Suggestion s) {
    final p = prefix;
    _push();
    final l = lines[row];
    lines[row] = l.substring(0, col - p.length) + s.label + l.substring(col);
    col = col - p.length + s.label.length;
    dirty = true;
    notifyListeners();
  }

  /// Trim trailing whitespace (stand-in for a real formatter).
  void format() {
    _push();
    lines = lines.map((l) => l.replaceFirst(RegExp(r'\s+$'), '')).toList();
    col = col.clamp(0, lines[row].length);
    dirty = true;
    notifyListeners();
  }

  void markSaved() {
    dirty = false;
    notifyListeners();
  }

  static EditorModel editorTsx() => EditorModel(
        lines: const [
          "import { useState } from 'react';",
          "import { saveFile } from './fs';",
          '',
          'type Props = { path: string };',
          '',
          'export function Editor({ path }: Props) {',
          '  const [dirty, setDirty] = useState(false);',
          '',
          '  async function onSave(text: string) {',
          '    await saveFile(path, text);',
          '    setD',
          '  }',
          '',
          '  return null;',
          '}',
          '',
        ],
        row: 10,
        col: 8,
        dirty: true,
        gitMarks: const {1: 'added', 6: 'modified', 10: 'added'},
      );

  static EditorModel fsTs() => EditorModel(
        lines: const [
          "export async function saveFile(path: string, text: string) {",
          r"  await fetch(`/api/files/${path}`, { method: 'PUT', body: text });",
          '}',
          '',
        ],
      );

  static EditorModel appTsx() => EditorModel(
        lines: const [
          "import { Editor } from './components/editor';",
          '',
          'export default function App() {',
          "  return <Editor path=\"src/App.tsx\" />;",
          '}',
          '',
        ],
      );
}
