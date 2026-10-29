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
      LspCompletion(label: 'async', kind: 'keyword', detail: 'keyword', documentation: 'Marks a function as asynchronous.'),
      LspCompletion(label: 'await', kind: 'keyword', detail: 'keyword', documentation: 'Pauses execution until a promise resolves.'),
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword', documentation: 'Declares a class.'),
      LspCompletion(label: 'console.log', kind: 'function', detail: '(message?: any, ...optionalParams: any[]) => void', documentation: 'Prints to console.'),
      LspCompletion(label: 'const', kind: 'keyword', detail: 'keyword', documentation: 'Declares a read-only named constant.'),
      LspCompletion(label: 'export', kind: 'keyword', detail: 'keyword', documentation: 'Exports a member from the module.'),
      LspCompletion(label: 'function', kind: 'keyword', detail: 'keyword', documentation: 'Declares a function.'),
      LspCompletion(label: 'import', kind: 'keyword', detail: 'keyword', documentation: 'Imports exports from another module.'),
      LspCompletion(label: 'interface', kind: 'keyword', detail: 'keyword', documentation: 'Declares a TypeScript interface.'),
      LspCompletion(label: 'let', kind: 'keyword', detail: 'keyword', documentation: 'Declares a reassignable block-scoped variable.'),
      LspCompletion(label: 'Promise', kind: 'class', detail: 'class Promise<T>', documentation: 'Represents asynchronous operations.'),
      LspCompletion(label: 'return', kind: 'keyword', detail: 'keyword', documentation: 'Returns a value from a function.'),
      LspCompletion(label: 'saveFile', kind: 'function', detail: '(path: string, content: string) => Promise<void>', documentation: 'Saves file to disk.'),
      LspCompletion(label: 'setDirty', kind: 'function', detail: '(value: boolean) => void', documentation: 'Sets the dirty state of the editor.'),
      LspCompletion(label: 'type', kind: 'keyword', detail: 'keyword', documentation: 'Declares a type alias.'),
      LspCompletion(label: 'useCallback', kind: 'function', detail: '(fn, deps) => callback', documentation: 'React hook to memoize callbacks.'),
      LspCompletion(label: 'useEffect', kind: 'function', detail: '(effect, deps) => void', documentation: 'React hook for side effects.'),
      LspCompletion(label: 'useMemo', kind: 'function', detail: '(factory, deps) => value', documentation: 'React hook to memoize computed values.'),
      LspCompletion(label: 'useRef', kind: 'function', detail: '(initialValue) => refObject', documentation: 'React hook for persistent ref.'),
      LspCompletion(label: 'useState', kind: 'function', detail: '(initialState) => [state, setState]', documentation: 'React hook for local state management.'),
      LspCompletion(label: 'var', kind: 'keyword', detail: 'keyword', documentation: 'Declares a variable.'),
    ],
    'javascript': [
      LspCompletion(label: 'async', kind: 'keyword', detail: 'keyword', documentation: 'Asynchronous function specifier.'),
      LspCompletion(label: 'await', kind: 'keyword', detail: 'keyword', documentation: 'Await promise resolution.'),
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'console.log', kind: 'function', detail: 'console.log(...)', documentation: 'Outputs message to console.'),
      LspCompletion(label: 'const', kind: 'keyword', detail: 'keyword', documentation: 'Declares a constant variable.'),
      LspCompletion(label: 'export', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'function', kind: 'keyword', detail: 'keyword', documentation: 'Declares a function.'),
      LspCompletion(label: 'import', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'let', kind: 'keyword', detail: 'keyword', documentation: 'Declares a block variable.'),
      LspCompletion(label: 'return', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'setInterval', kind: 'function', detail: '(handler, timeout) => number', documentation: 'Schedules repeated timer execution.'),
      LspCompletion(label: 'setTimeout', kind: 'function', detail: '(handler, timeout) => number', documentation: 'Schedules timer execution.'),
      LspCompletion(label: 'var', kind: 'keyword', detail: 'keyword', documentation: 'Declares a function-scoped variable.'),
    ],
    'php': [
      LspCompletion(label: 'abstract', kind: 'keyword', detail: 'keyword', documentation: 'Abstract class or method specifier.'),
      LspCompletion(label: 'array', kind: 'type', detail: 'built-in type', documentation: 'Array data structure in PHP.'),
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword', documentation: 'Declares a class in PHP.'),
      LspCompletion(label: 'echo', kind: 'function', detail: 'echo string ...', documentation: 'Outputs one or more strings.'),
      LspCompletion(label: 'extends', kind: 'keyword', detail: 'keyword', documentation: 'Extends a class.'),
      LspCompletion(label: 'function', kind: 'keyword', detail: 'keyword', documentation: 'Declares a function or method.'),
      LspCompletion(label: 'implements', kind: 'keyword', detail: 'keyword', documentation: 'Implements an interface.'),
      LspCompletion(label: 'namespace', kind: 'keyword', detail: 'keyword', documentation: 'Declares a PHP namespace.'),
      LspCompletion(label: 'private', kind: 'keyword', detail: 'modifier', documentation: 'Private visibility.'),
      LspCompletion(label: 'protected', kind: 'keyword', detail: 'modifier', documentation: 'Protected visibility.'),
      LspCompletion(label: 'public', kind: 'keyword', detail: 'modifier', documentation: 'Public visibility.'),
      LspCompletion(label: 'return', kind: 'keyword', detail: 'keyword', documentation: 'Returns from function.'),
      LspCompletion(label: 'static', kind: 'keyword', detail: 'modifier', documentation: 'Static member specifier.'),
      LspCompletion(label: 'trait', kind: 'keyword', detail: 'keyword', documentation: 'Declares a PHP trait.'),
      LspCompletion(label: 'use', kind: 'keyword', detail: 'keyword', documentation: 'Imports a namespace or uses a trait.'),
    ],
    'dart': [
      LspCompletion(label: 'async', kind: 'keyword', detail: 'keyword', documentation: 'Asynchronous method modifier.'),
      LspCompletion(label: 'await', kind: 'keyword', detail: 'keyword', documentation: 'Await Future completion.'),
      LspCompletion(label: 'BuildContext', kind: 'class', detail: 'abstract class BuildContext'),
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword', documentation: 'Declares a class.'),
      LspCompletion(label: 'const', kind: 'keyword', detail: 'keyword', documentation: 'Compile-time constant modifier.'),
      LspCompletion(label: 'final', kind: 'keyword', detail: 'keyword', documentation: 'Immutable variable modifier.'),
      LspCompletion(label: 'Future', kind: 'class', detail: 'class Future<T>', documentation: 'Computation producing a value asynchronously.'),
      LspCompletion(label: 'main', kind: 'function', detail: 'void main()', documentation: 'Entry point for Dart applications.'),
      LspCompletion(label: 'print', kind: 'function', detail: 'void print(Object? object)', documentation: 'Prints string representation to console.'),
      LspCompletion(label: 'runApp', kind: 'function', detail: 'void runApp(Widget app)', documentation: 'Inflates the given widget and attaches it to the screen.'),
      LspCompletion(label: 'setState', kind: 'function', detail: 'void setState(VoidCallback fn)', documentation: 'Notifies framework that internal state changed.'),
      LspCompletion(label: 'State', kind: 'class', detail: 'abstract class State<T extends StatefulWidget>'),
      LspCompletion(label: 'StatefulWidget', kind: 'class', detail: 'abstract class StatefulWidget', documentation: 'Widget that has mutable state.'),
      LspCompletion(label: 'StatelessWidget', kind: 'class', detail: 'abstract class StatelessWidget', documentation: 'Widget that does not require mutable state.'),
      LspCompletion(label: 'Stream', kind: 'class', detail: 'class Stream<T>', documentation: 'Source of asynchronous data events.'),
      LspCompletion(label: 'var', kind: 'keyword', detail: 'keyword', documentation: 'Type-inferred variable.'),
      LspCompletion(label: 'void', kind: 'keyword', detail: 'type', documentation: 'Return type indicating no value.'),
      LspCompletion(label: 'Widget', kind: 'class', detail: 'class Widget', documentation: 'Describes part of the UI.'),
    ],
    'python': [
      LspCompletion(label: 'async', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'await', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'calculate_sum', kind: 'function', detail: '(a: int, b: int) -> int'),
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword', documentation: 'Defines a class.'),
      LspCompletion(label: 'def', kind: 'keyword', detail: 'keyword', documentation: 'Defines a function.'),
      LspCompletion(label: 'elif', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'else', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'except', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'for', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'from', kind: 'keyword', detail: 'keyword', documentation: 'Imports specific attributes from a module.'),
      LspCompletion(label: 'if', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'import', kind: 'keyword', detail: 'keyword', documentation: 'Imports a module.'),
      LspCompletion(label: 'len', kind: 'function', detail: 'len(s)', documentation: 'Returns length of an object.'),
      LspCompletion(label: 'print', kind: 'function', detail: 'print(*values)', documentation: 'Prints values to output stream.'),
      LspCompletion(label: 'range', kind: 'function', detail: 'range(stop)', documentation: 'Returns sequence of numbers.'),
      LspCompletion(label: 'return', kind: 'keyword', detail: 'keyword', documentation: 'Returns value from function.'),
      LspCompletion(label: 'try', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'while', kind: 'keyword', detail: 'keyword'),
    ],
    'cpp': [
      LspCompletion(label: '#define', kind: 'keyword', detail: 'preprocessor directive'),
      LspCompletion(label: '#include', kind: 'keyword', detail: 'preprocessor directive', documentation: 'Includes standard or header file.'),
      LspCompletion(label: 'bool', kind: 'type', detail: 'built-in type'),
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'double', kind: 'type', detail: 'built-in type'),
      LspCompletion(label: 'float', kind: 'type', detail: 'built-in type'),
      LspCompletion(label: 'int', kind: 'type', detail: 'built-in type'),
      LspCompletion(label: 'main', kind: 'function', detail: 'int main()', documentation: 'Application entry point.'),
      LspCompletion(label: 'std::cin', kind: 'variable', detail: 'std::istream', documentation: 'Standard input stream.'),
      LspCompletion(label: 'std::cout', kind: 'variable', detail: 'std::ostream', documentation: 'Standard output stream.'),
      LspCompletion(label: 'std::endl', kind: 'constant', detail: 'manipulator', documentation: 'Inserts newline and flushes stream.'),
      LspCompletion(label: 'std::string', kind: 'type', detail: 'std::string', documentation: 'String class.'),
      LspCompletion(label: 'std::vector', kind: 'type', detail: 'std::vector<T>', documentation: 'Dynamic array container.'),
      LspCompletion(label: 'struct', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'template', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'void', kind: 'type', detail: 'built-in type'),
    ],
    'kotlin': [
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'data class', kind: 'keyword', detail: 'keyword', documentation: 'Data holder class.'),
      LspCompletion(label: 'fun', kind: 'keyword', detail: 'keyword', documentation: 'Declares a function.'),
      LspCompletion(label: 'greetUser', kind: 'function', detail: '(name: String): String'),
      LspCompletion(label: 'import', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'package', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'println', kind: 'function', detail: 'println(message: Any?)', documentation: 'Prints message and newline.'),
      LspCompletion(label: 'val', kind: 'keyword', detail: 'keyword', documentation: 'Read-only property declaration.'),
      LspCompletion(label: 'var', kind: 'keyword', detail: 'keyword', documentation: 'Mutable property declaration.'),
    ],
    'java': [
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'final', kind: 'keyword', detail: 'modifier'),
      LspCompletion(label: 'interface', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'private', kind: 'keyword', detail: 'access modifier'),
      LspCompletion(label: 'protected', kind: 'keyword', detail: 'access modifier'),
      LspCompletion(label: 'public', kind: 'keyword', detail: 'access modifier'),
      LspCompletion(label: 'static', kind: 'keyword', detail: 'modifier'),
      LspCompletion(label: 'System.out.println', kind: 'function', detail: 'System.out.println(...)', documentation: 'Prints to stdout.'),
      LspCompletion(label: 'void', kind: 'type', detail: 'type'),
    ],
    'go': [
      LspCompletion(label: 'const', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'fmt.Println', kind: 'function', detail: 'fmt.Println(...)', documentation: 'Formats and prints to stdout.'),
      LspCompletion(label: 'func', kind: 'keyword', detail: 'keyword', documentation: 'Declares a function.'),
      LspCompletion(label: 'import', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'interface', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'package', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'struct', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'type', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'var', kind: 'keyword', detail: 'keyword'),
    ],
    'rust': [
      LspCompletion(label: 'enum', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'fn', kind: 'keyword', detail: 'keyword', documentation: 'Declares a function.'),
      LspCompletion(label: 'impl', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'let', kind: 'keyword', detail: 'keyword', documentation: 'Binds a variable.'),
      LspCompletion(label: 'mut', kind: 'keyword', detail: 'keyword', documentation: 'Makes variable binding mutable.'),
      LspCompletion(label: 'println!', kind: 'macro', detail: 'println!(...)', documentation: 'Prints formatted output with newline.'),
      LspCompletion(label: 'struct', kind: 'keyword', detail: 'keyword'),
    ],
    'html': [
      LspCompletion(label: '<a>', kind: 'tag', detail: 'HTML element'),
      LspCompletion(label: '<div>', kind: 'tag', detail: 'HTML element'),
      LspCompletion(label: '<p>', kind: 'tag', detail: 'HTML element'),
      LspCompletion(label: 'script', kind: 'tag', detail: 'HTML element'),
      LspCompletion(label: '<span>', kind: 'tag', detail: 'HTML element'),
      LspCompletion(label: '<style>', kind: 'tag', detail: 'HTML element'),
    ],
    'css': [
      LspCompletion(label: 'background-color', kind: 'property', detail: 'property'),
      LspCompletion(label: 'color', kind: 'property', detail: 'property'),
      LspCompletion(label: 'display', kind: 'property', detail: 'property'),
      LspCompletion(label: 'flex', kind: 'property', detail: 'property'),
      LspCompletion(label: 'margin', kind: 'property', detail: 'property'),
      LspCompletion(label: 'padding', kind: 'property', detail: 'property'),
    ],
    'json': [
      LspCompletion(label: '"dependencies"', kind: 'property', detail: 'object key'),
      LspCompletion(label: '"description"', kind: 'property', detail: 'string key'),
      LspCompletion(label: '"name"', kind: 'property', detail: 'string key'),
      LspCompletion(label: '"version"', kind: 'property', detail: 'string key'),
    ],
    'yaml': [
      LspCompletion(label: 'dependencies:', kind: 'property', detail: 'YAML key'),
      LspCompletion(label: 'name:', kind: 'property', detail: 'YAML key'),
      LspCompletion(label: 'version:', kind: 'property', detail: 'YAML key'),
    ],
    'sql': [
      LspCompletion(label: 'DELETE FROM', kind: 'keyword', detail: 'SQL keyword'),
      LspCompletion(label: 'FROM', kind: 'keyword', detail: 'SQL keyword'),
      LspCompletion(label: 'INSERT INTO', kind: 'keyword', detail: 'SQL keyword'),
      LspCompletion(label: 'SELECT', kind: 'keyword', detail: 'SQL keyword'),
      LspCompletion(label: 'UPDATE', kind: 'keyword', detail: 'SQL keyword'),
      LspCompletion(label: 'WHERE', kind: 'keyword', detail: 'SQL keyword'),
    ],
    'shell': [
      LspCompletion(label: 'cd', kind: 'command', detail: 'shell command'),
      LspCompletion(label: 'echo', kind: 'command', detail: 'shell command'),
      LspCompletion(label: 'export', kind: 'command', detail: 'shell command'),
      LspCompletion(label: 'ls', kind: 'command', detail: 'shell command'),
    ],
    'ruby': [
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'def', kind: 'keyword', detail: 'keyword', documentation: 'Defines a method.'),
      LspCompletion(label: 'end', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'puts', kind: 'function', detail: 'puts obj', documentation: 'Prints string representation with newline.'),
      LspCompletion(label: 'require', kind: 'function', detail: 'require file'),
    ],
    'csharp': [
      LspCompletion(label: 'async', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'await', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'Console.WriteLine', kind: 'function', detail: 'Console.WriteLine(...)', documentation: 'Writes output to standard output stream.'),
      LspCompletion(label: 'namespace', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'public', kind: 'keyword', detail: 'access modifier'),
      LspCompletion(label: 'using', kind: 'keyword', detail: 'directive'),
    ],
    'swift': [
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'func', kind: 'keyword', detail: 'keyword', documentation: 'Declares a function.'),
      LspCompletion(label: 'import', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'let', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'print', kind: 'function', detail: 'print(...)', documentation: 'Prints output to standard output.'),
      LspCompletion(label: 'struct', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'var', kind: 'keyword', detail: 'keyword'),
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
      case 'php':
        return 'php';
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
      case 'java':
        return 'java';
      case 'go':
        return 'go';
      case 'rs':
        return 'rust';
      case 'html':
      case 'htm':
        return 'html';
      case 'css':
      case 'scss':
        return 'css';
      case 'json':
        return 'json';
      case 'yaml':
      case 'yml':
        return 'yaml';
      case 'sql':
        return 'sql';
      case 'sh':
      case 'bash':
      case 'zsh':
        return 'shell';
      case 'rb':
        return 'ruby';
      case 'cs':
        return 'csharp';
      case 'swift':
        return 'swift';
      default:
        return 'plaintext';
    }
  }

  /// Analyzes document text and returns a list of LSP diagnostics.
  List<LspDiagnostic> analyze(String fileName, String content) {
    final diagnostics = <LspDiagnostic>[];
    final lines = content.split('\n');
    final lang = detectLanguage(fileName);

    // Document-level bracket & brace tracking across lines
    var globalParen = 0, globalBrace = 0, globalBracket = 0;

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

      // Python missing colon check for def/if/elif/else/for/while/class/try/except
      if (lang == 'python') {
        final pyBlockMatch = RegExp(r'^\s*(def|class|if|elif|else|for|while|try|except)\b.*$').firstMatch(line);
        if (pyBlockMatch != null) {
          final trimmed = line.trimRight();
          if (!trimmed.endsWith(':') && !trimmed.endsWith('\\') && !trimmed.startsWith('#')) {
            diagnostics.add(LspDiagnostic(
              fileName: fileName,
              line: i,
              col: line.length,
              message: "Expected ':' at end of ${pyBlockMatch.group(1)} block declaration",
              severity: DiagnosticSeverity.error,
              source: 'PyLinter',
            ));
          }
        }
      }

      // Track open/close parens, braces, brackets across lines
      for (var col = 0; col < line.length; col++) {
        final ch = line[col];
        if (ch == '(') globalParen++;
        if (ch == ')') {
          globalParen--;
          if (globalParen < 0) {
            diagnostics.add(LspDiagnostic(
              fileName: fileName,
              line: i,
              col: col,
              message: "Unmatched closing parenthesis ')'",
              severity: DiagnosticSeverity.error,
              source: 'LSP Parser',
            ));
            globalParen = 0;
          }
        }
        if (ch == '{') globalBrace++;
        if (ch == '}') {
          globalBrace--;
          if (globalBrace < 0 && lang != 'html') {
            diagnostics.add(LspDiagnostic(
              fileName: fileName,
              line: i,
              col: col,
              message: "Unmatched closing brace '}'",
              severity: DiagnosticSeverity.error,
              source: 'LSP Parser',
            ));
            globalBrace = 0;
          }
        }
        if (ch == '[') globalBracket++;
        if (ch == ']') {
          globalBracket--;
          if (globalBracket < 0) {
            diagnostics.add(LspDiagnostic(
              fileName: fileName,
              line: i,
              col: col,
              message: "Unmatched closing bracket ']'",
              severity: DiagnosticSeverity.error,
              source: 'LSP Parser',
            ));
            globalBracket = 0;
          }
        }
      }
    }

    // JSON unclosed bracket or brace check
    if (lang == 'json' && content.trim().isNotEmpty) {
      if (globalBrace > 0 || globalBracket > 0) {
        diagnostics.add(LspDiagnostic(
          fileName: fileName,
          line: lines.length - 1,
          col: lines.last.length,
          message: "Unclosed bracket or brace in JSON",
          severity: DiagnosticSeverity.error,
          source: 'JSON Parser',
        ));
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

    // 2. Dynamic symbols from content (functions, classes, variables)
    final funcRegex = RegExp(r'\b(?:def|function|fun|func|fn)\s+([A-Za-z_$][\w$]*)');
    final classRegex = RegExp(r'\b(?:class|struct|interface|enum|type)\s+([A-Za-z_$][\w$]*)');

    for (final match in funcRegex.allMatches(content)) {
      final fnName = match.group(1)!;
      if (fnName.length >= prefix.length &&
          fnName.toLowerCase().startsWith(prefix.toLowerCase()) &&
          fnName != prefix &&
          !seen.contains(fnName)) {
        results.add(LspCompletion(
          label: fnName,
          kind: 'function',
          detail: 'function in document',
          documentation: 'Function declared in $fileName.',
        ));
        seen.add(fnName);
      }
    }

    for (final match in classRegex.allMatches(content)) {
      final clsName = match.group(1)!;
      if (clsName.length >= prefix.length &&
          clsName.toLowerCase().startsWith(prefix.toLowerCase()) &&
          clsName != prefix &&
          !seen.contains(clsName)) {
        results.add(LspCompletion(
          label: clsName,
          kind: 'class',
          detail: 'type in document',
          documentation: 'Type declared in $fileName.',
        ));
        seen.add(clsName);
      }
    }

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

    // Sort: exact prefix case matches first, followed by functions/classes, then variables
    results.sort((a, b) {
      final aExact = a.label.startsWith(prefix) ? 0 : 1;
      final bExact = b.label.startsWith(prefix) ? 0 : 1;
      if (aExact != bExact) return aExact.compareTo(bExact);
      return a.label.compareTo(b.label);
    });

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

        // Check if token matches a function or class definition in document
        if (RegExp('\\b(?:def|function|fun|func|fn)\\s+$token\\b').hasMatch(content)) {
          return LspHover(
            contents: '($lang) function `$token` defined in $fileName',
            line: row,
            col: m.start,
          );
        }
        if (RegExp('\\b(?:class|struct|interface|enum|type)\\s+$token\\b').hasMatch(content)) {
          return LspHover(
            contents: '($lang) type `$token` defined in $fileName',
            line: row,
            col: m.start,
          );
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
