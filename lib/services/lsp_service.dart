enum DiagnosticSeverity {
  error,
  warning,
  info,
  hint,
}

class LspDiagnostic {
  const LspDiagnostic({
    required this.fileName,
    required this.line,
    required this.col,
    required this.message,
    this.severity = DiagnosticSeverity.error,
    this.source = 'LSP',
    this.code,
  });

  final String fileName;
  final int line; // 0-indexed
  final int col; // 0-indexed
  final String message;
  final DiagnosticSeverity severity;
  final String source;
  final String? code;

  String format() {
    final lineNum = line + 1;
    final colNum = col + 1;
    final codeStr = code != null ? ' $code:' : '';
    return '$fileName:$lineNum:$colNum - ${severity.name}$codeStr $message';
  }
}

class LspCompletion {
  const LspCompletion({
    required this.label,
    required this.kind,
    this.detail,
    this.documentation,
    this.insertText,
  });

  final String label;
  final String kind;
  final String? detail;
  final String? documentation;
  final String? insertText;
}

class LspHover {
  const LspHover({
    required this.contents,
    required this.line,
    required this.col,
  });

  final String contents;
  final int line;
  final int col;
}

class LspService {
  static const Map<String, List<LspCompletion>> _langKeywords = {
    'typescript': [
      LspCompletion(label: 'const', kind: 'keyword', detail: 'keyword', documentation: 'Declares a read-only named constant.'),
      LspCompletion(label: 'let', kind: 'keyword', detail: 'keyword', documentation: 'Declares a reassignable block-scoped variable.'),
      LspCompletion(label: 'function', kind: 'keyword', detail: 'keyword', documentation: 'Declares a function.'),
      LspCompletion(label: 'import', kind: 'keyword', detail: 'keyword', documentation: 'Imports exports from another module.'),
      LspCompletion(label: 'export', kind: 'keyword', detail: 'keyword', documentation: 'Exports a member from the module.'),
      LspCompletion(label: 'return', kind: 'keyword', detail: 'keyword', documentation: 'Returns a value from a function.'),
      LspCompletion(label: 'async', kind: 'keyword', detail: 'keyword', documentation: 'Defines an asynchronous function.'),
      LspCompletion(label: 'await', kind: 'keyword', detail: 'keyword', documentation: 'Awaits completion of a Promise.'),
      LspCompletion(label: 'useState', kind: 'function', detail: '(initialState) => [state, setState]', documentation: 'React hook for local state management.'),
      LspCompletion(label: 'useEffect', kind: 'function', detail: '(effect, deps) => void', documentation: 'React hook for side effects.'),
      LspCompletion(label: 'setDirty', kind: 'function', detail: '(value: boolean) => void', documentation: 'Sets the dirty state of the editor.'),
      LspCompletion(label: 'saveFile', kind: 'function', detail: '(path: string, content: string) => Promise<void>', documentation: 'Saves file to disk.'),
      LspCompletion(label: 'log', kind: 'method', detail: 'console.log(...data)', documentation: 'Logs to output stream.'),
      LspCompletion(label: 'map', kind: 'method', detail: 'Array.map(callback)', documentation: 'Transforms array elements.'),
      LspCompletion(label: 'filter', kind: 'method', detail: 'Array.filter(predicate)', documentation: 'Filters array elements.'),
      LspCompletion(label: 'forEach', kind: 'method', detail: 'Array.forEach(callback)', documentation: 'Iterates over array elements.'),
      LspCompletion(label: 'includes', kind: 'method', detail: 'Array/String.includes(element)', documentation: 'Checks presence.'),
      LspCompletion(label: 'length', kind: 'property', detail: 'number', documentation: 'Gets string/array length.'),
    ],
    'javascript': [
      LspCompletion(label: 'const', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'let', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'function', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'async', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'await', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'log', kind: 'method', detail: 'console.log(...)'),
      LspCompletion(label: 'map', kind: 'method', detail: 'Array.map(...)'),
      LspCompletion(label: 'filter', kind: 'method', detail: 'Array.filter(...)'),
      LspCompletion(label: 'length', kind: 'property', detail: 'number'),
    ],
    'dart': [
      LspCompletion(label: 'void', kind: 'keyword', detail: 'type'),
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'final', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'const', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'main', kind: 'function', detail: 'void main()', documentation: 'Entry point for Dart applications.'),
      LspCompletion(label: 'runApp', kind: 'function', detail: 'void runApp(Widget app)', documentation: 'Inflates the given widget and attaches it to the screen.'),
      LspCompletion(label: 'Widget', kind: 'class', detail: 'class Widget'),
      LspCompletion(label: 'StatelessWidget', kind: 'class', detail: 'abstract class StatelessWidget'),
      LspCompletion(label: 'StatefulWidget', kind: 'class', detail: 'abstract class StatefulWidget'),
      LspCompletion(label: 'setState', kind: 'function', detail: 'void setState(VoidCallback fn)'),
      LspCompletion(label: 'print', kind: 'function', detail: 'void print(Object? object)'),
      LspCompletion(label: 'toString', kind: 'method', detail: 'String toString()'),
      LspCompletion(label: 'add', kind: 'method', detail: 'void add(element)'),
      LspCompletion(label: 'length', kind: 'property', detail: 'int'),
    ],
    'python': [
      LspCompletion(label: 'def', kind: 'keyword', detail: 'keyword', documentation: 'Defines a function.'),
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword', documentation: 'Defines a class.'),
      LspCompletion(label: 'import', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'return', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'print', kind: 'function', detail: 'print(*values)', documentation: 'Prints values to stream.'),
      LspCompletion(label: 'calculate_sum', kind: 'function', detail: '(a: int, b: int) -> int'),
      LspCompletion(label: 'append', kind: 'method', detail: 'list.append(x)'),
      LspCompletion(label: 'split', kind: 'method', detail: 'str.split(sep=None)'),
      LspCompletion(label: 'join', kind: 'method', detail: 'str.join(iterable)'),
    ],
    'cpp': [
      LspCompletion(label: '#include', kind: 'keyword', detail: 'preprocessor directive'),
      LspCompletion(label: 'int', kind: 'type', detail: 'type'),
      LspCompletion(label: 'main', kind: 'function', detail: 'int main()'),
      LspCompletion(label: 'std::cout', kind: 'variable', detail: 'std::ostream', documentation: 'Standard output stream.'),
      LspCompletion(label: 'std::endl', kind: 'constant', detail: 'manipulator'),
      LspCompletion(label: 'std::string', kind: 'type', detail: 'type'),
      LspCompletion(label: 'cout', kind: 'variable', detail: 'std::ostream'),
      LspCompletion(label: 'endl', kind: 'constant', detail: 'manipulator'),
      LspCompletion(label: 'push_back', kind: 'method', detail: 'vector.push_back(val)'),
    ],
    'kotlin': [
      LspCompletion(label: 'fun', kind: 'keyword', detail: 'keyword', documentation: 'Declares a function.'),
      LspCompletion(label: 'val', kind: 'keyword', detail: 'keyword', documentation: 'Read-only property declaration.'),
      LspCompletion(label: 'var', kind: 'keyword', detail: 'keyword', documentation: 'Mutable property declaration.'),
      LspCompletion(label: 'package', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'println', kind: 'function', detail: 'println(message: Any?)'),
      LspCompletion(label: 'greetUser', kind: 'function', detail: '(name: String): String'),
      LspCompletion(label: 'forEach', kind: 'method', detail: 'Iterable.forEach(action)'),
    ],
  };

  String detectLanguage(String fileName) {
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'ts':
      case 'tsx':
        return 'typescript';
      case 'js':
      case 'jsx':
        return 'javascript';
      case 'dart':
        return 'dart';
      case 'py':
        return 'python';
      case 'cpp':
      case 'hpp':
      case 'c':
      case 'h':
        return 'cpp';
      case 'kt':
      case 'kts':
        return 'kotlin';
      case 'json':
        return 'json';
      default:
        return 'plaintext';
    }
  }

  /// Analyzes document text and returns a list of LSP diagnostics.
  List<LspDiagnostic> analyze(String fileName, String content) {
    final diagnostics = <LspDiagnostic>[];
    final lines = content.split('\n');
    final lang = detectLanguage(fileName);

    var openParen = 0;
    var openBrace = 0;
    var openBracket = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // TS/JS unresolved 'setD' identifier check
      if (lang == 'typescript' || lang == 'javascript') {
        final hit = RegExp(r'(?<![\w$])setD(?![\w$])').firstMatch(line);
        if (hit != null) {
          diagnostics.add(LspDiagnostic(
            fileName: fileName,
            line: i,
            col: hit.start,
            message: "Cannot find name 'setD'. Did you mean 'setDirty'?",
            severity: DiagnosticSeverity.error,
            source: 'LSP (tsc)',
            code: 'TS2304',
          ));
        }
      }

      for (var col = 0; col < line.length; col++) {
        final ch = line[col];
        if (ch == '(') openParen++;
        if (ch == ')') openParen--;
        if (ch == '{') openBrace++;
        if (ch == '}') openBrace--;
        if (ch == '[') openBracket++;
        if (ch == ']') openBracket--;

        if (openParen < 0) {
          diagnostics.add(LspDiagnostic(
            fileName: fileName,
            line: i,
            col: col,
            message: "Unmatched closing parenthesis ')'",
            severity: DiagnosticSeverity.error,
            source: 'LSP Parser',
          ));
          openParen = 0;
        }
        if (openBrace < 0) {
          diagnostics.add(LspDiagnostic(
            fileName: fileName,
            line: i,
            col: col,
            message: "Unmatched closing brace '}'",
            severity: DiagnosticSeverity.error,
            source: 'LSP Parser',
          ));
          openBrace = 0;
        }
        if (openBracket < 0) {
          diagnostics.add(LspDiagnostic(
            fileName: fileName,
            line: i,
            col: col,
            message: "Unmatched closing bracket ']'",
            severity: DiagnosticSeverity.error,
            source: 'LSP Parser',
          ));
          openBracket = 0;
        }
      }
    }

    return diagnostics;
  }

  /// Returns completions based on language standards + symbols extracted from document content.
  List<LspCompletion> getCompletions(
    String fileName,
    String content,
    int row,
    int col,
    String prefix,
  ) {
    if (prefix.isEmpty) return const [];
    final lang = detectLanguage(fileName);
    final results = <LspCompletion>[];
    final seen = <String>{};

    // 1. Language built-ins and keywords
    final predefined = _langKeywords[lang] ?? _langKeywords['typescript']!;
    for (final c in predefined) {
      if (c.label.toLowerCase().startsWith(prefix.toLowerCase()) && c.label != prefix) {
        results.add(c);
        seen.add(c.label);
      }
    }

    // 2. Dynamic symbols from content (identifiers)
    final wordRegex = RegExp(r'\b[A-Za-z_$][\w$]*\b');
    for (final match in wordRegex.allMatches(content)) {
      final w = match.group(0)!;
      if (w.length >= prefix.length &&
          w.toLowerCase().startsWith(prefix.toLowerCase()) &&
          w != prefix &&
          !seen.contains(w)) {
        results.add(LspCompletion(
          label: w,
          kind: 'variable',
          detail: 'local symbol',
          documentation: 'Symbol defined in current file.',
        ));
        seen.add(w);
      }
    }

    return results;
  }

  /// Returns hover info for symbol at line and col.
  LspHover? getHover(String fileName, String content, int row, int col) {
    final lines = content.split('\n');
    if (row < 0 || row >= lines.length) return null;
    final line = lines[row];
    if (col < 0 || col > line.length) return null;

    final wordMatch = RegExp(r'\b[A-Za-z_$][\w$]*\b');
    for (final m in wordMatch.allMatches(line)) {
      if (col >= m.start && col <= m.end) {
        final token = m.group(0)!;
        final lang = detectLanguage(fileName);
        final list = _langKeywords[lang] ?? [];
        for (final item in list) {
          if (item.label == token) {
            final docs = item.documentation != null ? '\n${item.documentation}' : '';
            final detail = item.detail != null ? '`${item.detail}`' : '`$token`';
            return LspHover(
              contents: '($lang) $detail$docs',
              line: row,
              col: m.start,
            );
          }
        }
        return LspHover(
          contents: '($lang) symbol `$token`',
          line: row,
          col: m.start,
        );
      }
    }

    return null;
  }
}
