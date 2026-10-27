import 'package:flutter/foundation.dart';
import 'package:lattice/models/document.dart';
import 'package:lattice/services/lsp_service.dart';

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
  Suggestion('print', 'function'),
  Suggestion('println', 'function'),
  Suggestion('std::cout', 'stream'),
];

final LspService _sharedLsp = LspService();

/// Editor model wrapping [TextDocument] (defaults to [LineListDocument])
/// while maintaining backward compatibility with the existing prototype API.
class EditorModel extends ChangeNotifier {
  EditorModel({
    required List<String> lines,
    int row = 0,
    int? col,
    this.dirty = false,
    this.gitMarks = const {},
    this.fileName = 'editor.tsx',
    TextDocument? document,
    LspService? lspService,
  })  : lspService = lspService ?? _sharedLsp,
        _doc = document ??
            LineListDocument(
              initialLines: lines,
              initialRow: row,
              initialCol: col ?? 0,
            ) {
    _doc.addListener(_handleDocChanged);
    _analyzeLsp();
  }

  final TextDocument _doc;
  final LspService lspService;
  List<LspDiagnostic> diagnostics = [];
  bool dirty;
  String fileName;
  final Map<int, String> gitMarks;

  static const _autoPairs = {
    '(': ')',
    '[': ']',
    '{': '}',
    '"': '"',
    "'": "'",
  };

  void _handleDocChanged() {
    _analyzeLsp();
    notifyListeners();
  }

  void _analyzeLsp() {
    diagnostics = lspService.analyze(fileName, text);
  }

  TextDocument get document => _doc;

  List<String> get lines => _doc.lines;
  set lines(List<String> val) {
    _doc.setLinesDirectly(val);
  }

  int get row => _doc.row;
  set row(int r) {
    _doc.cursorPosition = TextPosition(r, col);
  }

  int get col => _doc.col;
  set col(int c) {
    _doc.cursorPosition = TextPosition(row, c);
  }

  String get text => _doc.text;
  String get currentLine => _doc.lineAt(row);

  bool get canUndo => _doc.canUndo;
  bool get canRedo => _doc.canRedo;

  void undo() {
    _doc.undo();
    dirty = true;
  }

  void redo() {
    _doc.redo();
    dirty = true;
  }

  void insert(String s) {
    if (_autoPairs.containsKey(s)) {
      final closing = _autoPairs[s]!;
      _doc.insertText(row, col, '$s$closing');
      _doc.cursorPosition = TextPosition(row, col - 1);
      dirty = true;
      return;
    }
    _doc.insertText(row, col, s);
    dirty = true;
  }

  void deleteSelection(TextPosition start, TextPosition end) {
    _doc.deleteRange(start, end);
    dirty = true;
  }

  void replaceSelection(TextPosition start, TextPosition end, String replacement) {
    _doc.replaceRange(start, end, replacement);
    dirty = true;
  }

  void backspace({TextPosition? selStart, TextPosition? selEnd}) {
    if (selStart != null && selEnd != null && selStart != selEnd) {
      deleteSelection(selStart, selEnd);
      return;
    }

    if (col == 0 && row == 0) return;

    final line = currentLine;

    // Auto-pair deletion: e.g. (|), [|], {|}, "|", '|'
    if (col > 0 && col < line.length) {
      final left = line[col - 1];
      final right = line[col];
      if (_autoPairs[left] == right) {
        _doc.deleteRange(TextPosition(row, col - 1), TextPosition(row, col + 1));
        dirty = true;
        return;
      }
    }

    // Soft tab indentation deletion
    if (col > 0) {
      final prefix = line.substring(0, col);
      if (prefix.trim().isEmpty) {
        final deleteCount = (col % 2 == 0 && col >= 2) ? 2 : 1;
        _doc.deleteRange(TextPosition(row, col - deleteCount), TextPosition(row, col));
        dirty = true;
        return;
      }
      _doc.deleteRange(TextPosition(row, col - 1), TextPosition(row, col));
    } else if (row > 0) {
      final prevLen = lines[row - 1].length;
      _doc.deleteRange(TextPosition(row - 1, prevLen), TextPosition(row, 0));
    }
    dirty = true;
  }

  void newline() {
    final l = currentLine;
    final indent = RegExp(r'^\s*').stringMatch(l) ?? '';
    final extra = l.substring(0, col).trimRight().endsWith('{') ? '  ' : '';
    final insertText = '\n$indent$extra';
    _doc.insertText(row, col, insertText);
    dirty = true;
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
  }

  void moveTo(int r, int c) {
    final targetRow = r.clamp(0, lines.length - 1);
    final targetCol = c.clamp(0, lines[targetRow].length);
    _doc.cursorPosition = TextPosition(targetRow, targetCol);
  }

  void updateState({List<String>? newLines, int? newRow, int? newCol, bool? isDirty}) {
    if (newLines != null) {
      _doc.setLinesDirectly(newLines);
    }
    if (newRow != null || newCol != null) {
      final r = newRow ?? row;
      final c = newCol ?? col;
      _doc.cursorPosition = TextPosition(r, c);
    }
    if (isDirty != null) {
      dirty = isDirty;
      notifyListeners();
    }
  }

  String get prefix {
    final cur = currentLine;
    final safeCol = col.clamp(0, cur.length);
    final before = cur.substring(0, safeCol);
    return RegExp(r'(?:[\.\:\>\-])?[A-Za-z_$][\w$]*$').stringMatch(before) ?? '';
  }

  List<Suggestion> get suggestions {
    final rawPrefix = prefix;
    if (rawPrefix.isEmpty) return const [];
    final cleanPrefix = rawPrefix.replaceAll(RegExp(r'^[\.\:\>\-]+'), '');
    if (cleanPrefix.isEmpty && !rawPrefix.contains('.')) return const [];

    final completions = lspService.getCompletions(fileName, text, row, col, cleanPrefix);
    final results = completions.map((c) => Suggestion(c.label, c.kind)).toList();

    for (final s in kAllSuggestions) {
      if (s.label.toLowerCase().startsWith(cleanPrefix.toLowerCase()) &&
          s.label != cleanPrefix &&
          !results.any((r) => r.label == s.label)) {
        results.add(s);
      }
    }
    return results;
  }

  void applySuggestion(Suggestion s) {
    final rawPrefix = prefix;
    final cleanPrefix = rawPrefix.replaceAll(RegExp(r'^[\.\:\>\-]+'), '');
    _doc.replaceRange(
      TextPosition(row, col - cleanPrefix.length),
      TextPosition(row, col),
      s.label,
    );
    dirty = true;
  }

  void format() {
    _doc.pushSnapshot();
    final formatted = lines.map((l) => l.replaceFirst(RegExp(r'\s+$'), '')).toList();
    lines = formatted;
    col = col.clamp(0, lines[row].length);
    dirty = true;
  }

  void markSaved() {
    dirty = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _doc.removeListener(_handleDocChanged);
    super.dispose();
  }

  static EditorModel editorTsx() => EditorModel(
        fileName: 'editor.tsx',
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
        fileName: 'fs.ts',
        lines: const [
          "export async function saveFile(path: string, text: string) {",
          r"  await fetch(`/api/files/${path}`, { method: 'PUT', body: text });",
          '}',
          '',
        ],
      );

  static EditorModel appTsx() => EditorModel(
        fileName: 'App.tsx',
        lines: const [
          "import { Editor } from './components/editor';",
          '',
          'export default function App() {',
          "  return <Editor path=\"src/App.tsx\" />;",
          '}',
          '',
        ],
      );

  static EditorModel mainDart() => EditorModel(
        fileName: 'main.dart',
        lines: const [
          "import 'package:flutter/material.dart';",
          '',
          'void main() {',
          "  runApp(const MaterialApp(home: Text('Hello Lattice!')));",
          '}',
          '',
        ],
      );

  static EditorModel appPy() => EditorModel(
        fileName: 'app.py',
        lines: const [
          'def calculate_sum(a: int, b: int) -> int:',
          '    """Returns the sum of two integers."""',
          '    return a + b',
          '',
          'if __name__ == "__main__":',
          '    print("Sum:", calculate_sum(10, 20))',
          '',
        ],
      );

  static EditorModel nativeCpp() => EditorModel(
        fileName: 'native.cpp',
        lines: const [
          '#include <iostream>',
          '#include <string>',
          '',
          'int main() {',
          '    std::string greeting = "Hello C++";',
          '    std::cout << greeting << std::endl;',
          '    return 0;',
          '}',
          '',
        ],
      );

  static EditorModel helperKt() => EditorModel(
        fileName: 'Helper.kt',
        lines: const [
          'package com.example.lattice',
          '',
          'fun greetUser(name: String): String {',
          '    return "Hello, \$name!"',
          '}',
          '',
          'fun main() {',
          '    println(greetUser("Developer"))',
          '}',
          '',
        ],
      );
}
