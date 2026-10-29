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

class LspParameterInfo {
  const LspParameterInfo({
    required this.label,
    this.documentation,
  });

  final String label;
  final String? documentation;
}

class LspSignatureInfo {
  const LspSignatureInfo({
    required this.label,
    this.documentation,
    required this.parameters,
  });

  final String label;
  final String? documentation;
  final List<LspParameterInfo> parameters;
}

class LspSignatureHelp {
  const LspSignatureHelp({
    required this.signatures,
    required this.activeSignature,
    required this.activeParameter,
  });

  final List<LspSignatureInfo> signatures;
  final int activeSignature;
  final int activeParameter;
}

class LspService {
  static const Map<String, List<LspCompletion>> _objectMembers = {
    'react': [
      LspCompletion(label: 'useState', kind: 'function', detail: '(initialState) => [state, setState]', documentation: 'React Hook that lets you add state variable to your component.'),
      LspCompletion(label: 'useEffect', kind: 'function', detail: '(effect, deps) => void', documentation: 'React Hook that lets you synchronize a component with an external system.'),
      LspCompletion(label: 'useContext', kind: 'function', detail: '(context) => value', documentation: 'React Hook that lets you read and subscribe to context from your component.'),
      LspCompletion(label: 'useReducer', kind: 'function', detail: '(reducer, initialArg) => [state, dispatch]', documentation: 'React Hook that lets you add a reducer to your component.'),
      LspCompletion(label: 'useCallback', kind: 'function', detail: '(fn, deps) => callback', documentation: 'React Hook that lets you cache a function definition between re-renders.'),
      LspCompletion(label: 'useMemo', kind: 'function', detail: '(factory, deps) => value', documentation: 'React Hook that lets you cache the result of a calculation between re-renders.'),
      LspCompletion(label: 'useRef', kind: 'function', detail: '(initialValue) => refContainer', documentation: 'React Hook that lets you reference a value that’s not needed for rendering.'),
      LspCompletion(label: 'FC', kind: 'type', detail: 'type React.FC<P>', documentation: 'React Functional Component type.'),
      LspCompletion(label: 'Component', kind: 'class', detail: 'class React.Component<P, S>', documentation: 'Base class for React components.'),
      LspCompletion(label: 'createContext', kind: 'function', detail: '(defaultValue) => Context', documentation: 'Creates a Context object.'),
      LspCompletion(label: 'createElement', kind: 'function', detail: '(type, props, ...children)', documentation: 'Creates a React element.'),
      LspCompletion(label: 'memo', kind: 'function', detail: '(Component) => MemoizedComponent', documentation: 'Skips re-rendering component when props are unchanged.'),
      LspCompletion(label: 'forwardRef', kind: 'function', detail: '(render) => Component', documentation: 'Exposes a DOM node to a parent component with a ref.'),
      LspCompletion(label: 'lazy', kind: 'function', detail: '(load) => LazyComponent', documentation: 'Lets you defer loading component code until it is rendered.'),
      LspCompletion(label: 'Suspense', kind: 'class', detail: 'class Suspense', documentation: 'Displays a fallback until its children finish loading.'),
      LspCompletion(label: 'Fragment', kind: 'class', detail: 'class Fragment', documentation: 'Groups elements without extra DOM node.'),
      LspCompletion(label: 'StrictMode', kind: 'class', detail: 'class StrictMode', documentation: 'Checks for potential problems in an application during development.'),
    ],
    'console': [
      LspCompletion(label: 'log', kind: 'function', detail: '(message?: any, ...optionalParams: any[]) => void', documentation: 'Outputs a message to the web console.'),
      LspCompletion(label: 'error', kind: 'function', detail: '(message?: any, ...optionalParams: any[]) => void', documentation: 'Outputs an error message.'),
      LspCompletion(label: 'warn', kind: 'function', detail: '(message?: any, ...optionalParams: any[]) => void', documentation: 'Outputs a warning message.'),
      LspCompletion(label: 'info', kind: 'function', detail: '(message?: any, ...optionalParams: any[]) => void', documentation: 'Outputs an informational message.'),
      LspCompletion(label: 'debug', kind: 'function', detail: '(message?: any, ...optionalParams: any[]) => void', documentation: 'Outputs a debug message.'),
      LspCompletion(label: 'clear', kind: 'function', detail: '() => void', documentation: 'Clears the console.'),
      LspCompletion(label: 'time', kind: 'function', detail: '(label?: string) => void', documentation: 'Starts a timer.'),
      LspCompletion(label: 'timeEnd', kind: 'function', detail: '(label?: string) => void', documentation: 'Stops a timer.'),
      LspCompletion(label: 'table', kind: 'function', detail: '(tabularData?: any) => void', documentation: 'Displays tabular data as a table.'),
    ],
    'math': [
      LspCompletion(label: 'abs', kind: 'function', detail: '(x: number) => number'),
      LspCompletion(label: 'ceil', kind: 'function', detail: '(x: number) => number'),
      LspCompletion(label: 'floor', kind: 'function', detail: '(x: number) => number'),
      LspCompletion(label: 'max', kind: 'function', detail: '(...values: number[]) => number'),
      LspCompletion(label: 'min', kind: 'function', detail: '(...values: number[]) => number'),
      LspCompletion(label: 'pow', kind: 'function', detail: '(x: number, y: number) => number'),
      LspCompletion(label: 'random', kind: 'function', detail: '() => number'),
      LspCompletion(label: 'round', kind: 'function', detail: '(x: number) => number'),
      LspCompletion(label: 'sqrt', kind: 'function', detail: '(x: number) => number'),
      LspCompletion(label: 'PI', kind: 'constant', detail: 'number = 3.141592653589793'),
    ],
    'json': [
      LspCompletion(label: 'parse', kind: 'function', detail: '(text: string) => any', documentation: 'Parses JSON text into value.'),
      LspCompletion(label: 'stringify', kind: 'function', detail: '(value: any) => string', documentation: 'Converts value to JSON string.'),
    ],
    'array': [
      LspCompletion(label: 'from', kind: 'function', detail: '(arrayLike) => Array'),
      LspCompletion(label: 'isArray', kind: 'function', detail: '(arg: any) => boolean'),
      LspCompletion(label: 'of', kind: 'function', detail: '(...items) => Array'),
    ],
    'document': [
      LspCompletion(label: 'getElementById', kind: 'function', detail: '(elementId: string) => Element | null'),
      LspCompletion(label: 'querySelector', kind: 'function', detail: '(selectors: string) => Element | null'),
      LspCompletion(label: 'querySelectorAll', kind: 'function', detail: '(selectors: string) => NodeList'),
      LspCompletion(label: 'createElement', kind: 'function', detail: '(tagName: string) => HTMLElement'),
      LspCompletion(label: 'addEventListener', kind: 'function', detail: '(type: string, listener: Function) => void'),
    ],
  };
  static const Map<String, List<LspCompletion>> _langKeywords = {
    'php': [
      LspCompletion(label: 'array_filter', kind: 'function', detail: r'array_filter(array $array, ?callable $callback)', documentation: 'Filters elements of an array using a callback function.'),
      LspCompletion(label: 'array_map', kind: 'function', detail: r'array_map(?callable $callback, array $array)', documentation: 'Applies callback to elements of given arrays.'),
      LspCompletion(label: 'array_merge', kind: 'function', detail: r'array_merge(array ...$arrays)', documentation: 'Merges one or more arrays.'),
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword', documentation: 'Declares a class.'),
      LspCompletion(label: 'count', kind: 'function', detail: r'count(Countable|array $value)', documentation: 'Counts all elements in an array or Countable object.'),
      LspCompletion(label: 'echo', kind: 'keyword', detail: 'keyword', documentation: 'Outputs one or more strings.'),
      LspCompletion(label: 'empty', kind: 'function', detail: r'empty(mixed $var)', documentation: 'Determines whether a variable is empty.'),
      LspCompletion(label: 'explode', kind: 'function', detail: r'explode(string $separator, string $string)', documentation: 'Splits a string by a string.'),
      LspCompletion(label: 'function', kind: 'keyword', detail: 'keyword', documentation: 'Declares a function.'),
      LspCompletion(label: 'header', kind: 'function', detail: r'header(string $header)', documentation: 'Sends a raw HTTP header.'),
      LspCompletion(label: 'implode', kind: 'function', detail: r'implode(string $separator, array $array)', documentation: 'Joins array elements with a string.'),
      LspCompletion(label: 'isset', kind: 'function', detail: r'isset(mixed $var)', documentation: 'Determines if a variable is declared and is different than null.'),
      LspCompletion(label: 'json_decode', kind: 'function', detail: r'json_decode(string $json, ?bool $associative)', documentation: 'Decodes a JSON string.'),
      LspCompletion(label: 'json_encode', kind: 'function', detail: r'json_encode(mixed $value)', documentation: 'Returns the JSON representation of a value.'),
      LspCompletion(label: 'namespace', kind: 'keyword', detail: 'keyword', documentation: 'Declares a PHP namespace.'),
      LspCompletion(label: 'PDO', kind: 'class', detail: 'class PDO', documentation: 'Represents a connection between PHP and a database server.'),
      LspCompletion(label: 'private', kind: 'keyword', detail: 'access modifier'),
      LspCompletion(label: 'protected', kind: 'keyword', detail: 'access modifier'),
      LspCompletion(label: 'public', kind: 'keyword', detail: 'access modifier'),
      LspCompletion(label: 'sprintf', kind: 'function', detail: r'sprintf(string $format, mixed ...$values)', documentation: 'Returns a formatted string.'),
      LspCompletion(label: 'strlen', kind: 'function', detail: r'strlen(string $string)', documentation: 'Get string length.'),
      LspCompletion(label: 'str_replace', kind: 'function', detail: r'str_replace(array|string $search, array|string $replace, array|string $subject)', documentation: 'Replace all occurrences of the search string with the replacement string.'),
    ],
    'typescript': [
      LspCompletion(label: 'Array', kind: 'class', detail: 'interface Array<T>', documentation: 'JavaScript Array object.'),
      LspCompletion(label: 'async', kind: 'keyword', detail: 'keyword', documentation: 'Marks a function as asynchronous.'),
      LspCompletion(label: 'await', kind: 'keyword', detail: 'keyword', documentation: 'Pauses execution until a promise resolves.'),
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword', documentation: 'Declares a class.'),
      LspCompletion(label: 'console.log', kind: 'function', detail: '(message?: any, ...optionalParams: any[]) => void', documentation: 'Prints to console.'),
      LspCompletion(label: 'const', kind: 'keyword', detail: 'keyword', documentation: 'Declares a read-only named constant.'),
      LspCompletion(label: 'export', kind: 'keyword', detail: 'keyword', documentation: 'Exports a member from the module.'),
      LspCompletion(label: 'function', kind: 'keyword', detail: 'keyword', documentation: 'Declares a function.'),
      LspCompletion(label: 'import', kind: 'keyword', detail: 'keyword', documentation: 'Imports exports from another module.'),
      LspCompletion(label: 'interface', kind: 'keyword', detail: 'keyword', documentation: 'Declares a TypeScript interface.'),
      LspCompletion(label: 'JSON.parse', kind: 'function', detail: '(text: string) => any', documentation: 'Parses JSON text.'),
      LspCompletion(label: 'JSON.stringify', kind: 'function', detail: '(value: any) => string', documentation: 'Converts JavaScript value to JSON string.'),
      LspCompletion(label: 'let', kind: 'keyword', detail: 'keyword', documentation: 'Declares a reassignable block-scoped variable.'),
      LspCompletion(label: 'Promise', kind: 'class', detail: 'class Promise<T>', documentation: 'Represents asynchronous operations.'),
      LspCompletion(label: 'React.FC', kind: 'type', detail: 'type React.FC<P>', documentation: 'React Functional Component type.'),
      LspCompletion(label: 'return', kind: 'keyword', detail: 'keyword', documentation: 'Returns a value from a function.'),
      LspCompletion(label: 'saveFile', kind: 'function', detail: '(path: string, content: string) => Promise<void>', documentation: 'Saves file to disk.'),
      LspCompletion(label: 'setDirty', kind: 'function', detail: '(value: boolean) => void', documentation: 'Sets the dirty state of the editor.'),
      LspCompletion(label: 'type', kind: 'keyword', detail: 'keyword', documentation: 'Declares a type alias.'),
      LspCompletion(label: 'useCallback', kind: 'function', detail: '(fn, deps) => callback', documentation: 'React hook to memoize callbacks.'),
      LspCompletion(label: 'useContext', kind: 'function', detail: '(context) => value', documentation: 'React hook to consume a Context.'),
      LspCompletion(label: 'useEffect', kind: 'function', detail: '(effect, deps) => void', documentation: 'React hook for side effects.'),
      LspCompletion(label: 'useMemo', kind: 'function', detail: '(factory, deps) => value', documentation: 'React hook to memoize computed values.'),
      LspCompletion(label: 'useReducer', kind: 'function', detail: '(reducer, initialArg) => [state, dispatch]', documentation: 'React hook for state management via reducer.'),
      LspCompletion(label: 'useRef', kind: 'function', detail: '(initialValue) => refContainer', documentation: 'React hook for persistent references.'),
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
      LspCompletion(label: 'useCallback', kind: 'function', detail: '(fn, deps)', documentation: 'React useCallback hook.'),
      LspCompletion(label: 'useEffect', kind: 'function', detail: '(effect, deps)', documentation: 'React useEffect hook.'),
      LspCompletion(label: 'useState', kind: 'function', detail: '(initialState)', documentation: 'React useState hook.'),
      LspCompletion(label: 'var', kind: 'keyword', detail: 'keyword', documentation: 'Declares a function-scoped variable.'),
    ],
    'dart': [
      LspCompletion(label: 'AppBar', kind: 'class', detail: 'class AppBar', documentation: 'Material design app bar widget.'),
      LspCompletion(label: 'async', kind: 'keyword', detail: 'keyword', documentation: 'Asynchronous method modifier.'),
      LspCompletion(label: 'await', kind: 'keyword', detail: 'keyword', documentation: 'Await Future completion.'),
      LspCompletion(label: 'BuildContext', kind: 'class', detail: 'abstract class BuildContext', documentation: 'Handle to the location of a widget in the widget tree.'),
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword', documentation: 'Declares a class.'),
      LspCompletion(label: 'Column', kind: 'class', detail: 'class Column', documentation: 'Displays children in a vertical array.'),
      LspCompletion(label: 'const', kind: 'keyword', detail: 'keyword', documentation: 'Compile-time constant modifier.'),
      LspCompletion(label: 'Container', kind: 'class', detail: 'class Container', documentation: 'Convenience widget combining painting, positioning, and sizing.'),
      LspCompletion(label: 'Expanded', kind: 'class', detail: 'class Expanded', documentation: 'Widget that expands a child of a Row or Column.'),
      LspCompletion(label: 'final', kind: 'keyword', detail: 'keyword', documentation: 'Immutable variable modifier.'),
      LspCompletion(label: 'Future', kind: 'class', detail: 'class Future<T>', documentation: 'Computation producing a value asynchronously.'),
      LspCompletion(label: 'GestureDetector', kind: 'class', detail: 'class GestureDetector', documentation: 'Widget that detects gestures.'),
      LspCompletion(label: 'ListView', kind: 'class', detail: 'class ListView', documentation: 'Scrollable array of widgets.'),
      LspCompletion(label: 'main', kind: 'function', detail: 'void main()', documentation: 'Entry point for Dart applications.'),
      LspCompletion(label: 'Navigator', kind: 'class', detail: 'class Navigator', documentation: 'Widget that manages a set of child widgets with a stack history.'),
      LspCompletion(label: 'Padding', kind: 'class', detail: 'class Padding', documentation: 'Insets its child by given padding.'),
      LspCompletion(label: 'print', kind: 'function', detail: 'void print(Object? object)', documentation: 'Prints string representation to console.'),
      LspCompletion(label: 'Row', kind: 'class', detail: 'class Row', documentation: 'Displays children in a horizontal array.'),
      LspCompletion(label: 'runApp', kind: 'function', detail: 'void runApp(Widget app)', documentation: 'Inflates the given widget and attaches it to the screen.'),
      LspCompletion(label: 'Scaffold', kind: 'class', detail: 'class Scaffold', documentation: 'Implements the basic visual layout structure of Material design.'),
      LspCompletion(label: 'setState', kind: 'function', detail: 'void setState(VoidCallback fn)', documentation: 'Notifies framework that internal state changed.'),
      LspCompletion(label: 'SizedBox', kind: 'class', detail: 'class SizedBox', documentation: 'Box with a specified size.'),
      LspCompletion(label: 'State', kind: 'class', detail: 'abstract class State<T extends StatefulWidget>'),
      LspCompletion(label: 'StatefulWidget', kind: 'class', detail: 'abstract class StatefulWidget', documentation: 'Widget that has mutable state.'),
      LspCompletion(label: 'StatelessWidget', kind: 'class', detail: 'abstract class StatelessWidget', documentation: 'Widget that does not require mutable state.'),
      LspCompletion(label: 'Stream', kind: 'class', detail: 'class Stream<T>', documentation: 'Source of asynchronous data events.'),
      LspCompletion(label: 'Text', kind: 'class', detail: 'class Text', documentation: 'Text widget.'),
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
      LspCompletion(label: 'dict', kind: 'class', detail: 'class dict', documentation: 'Dictionary built-in type.'),
      LspCompletion(label: 'elif', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'else', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'enumerate', kind: 'function', detail: 'enumerate(iterable, start=0)', documentation: 'Returns an enumerate object.'),
      LspCompletion(label: 'except', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'for', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'from', kind: 'keyword', detail: 'keyword', documentation: 'Imports specific attributes from a module.'),
      LspCompletion(label: 'if', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'import', kind: 'keyword', detail: 'keyword', documentation: 'Imports a module.'),
      LspCompletion(label: 'isinstance', kind: 'function', detail: 'isinstance(object, classinfo)', documentation: 'Check if object is an instance of classinfo.'),
      LspCompletion(label: 'len', kind: 'function', detail: 'len(s)', documentation: 'Returns length of an object.'),
      LspCompletion(label: 'list', kind: 'class', detail: 'class list', documentation: 'List built-in type.'),
      LspCompletion(label: 'print', kind: 'function', detail: 'print(*values)', documentation: 'Prints values to output stream.'),
      LspCompletion(label: 'range', kind: 'function', detail: 'range(stop)', documentation: 'Returns sequence of numbers.'),
      LspCompletion(label: 'return', kind: 'keyword', detail: 'keyword', documentation: 'Returns value from function.'),
      LspCompletion(label: 'try', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'while', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'zip', kind: 'function', detail: 'zip(*iterables)', documentation: 'Returns an iterator of tuples.'),
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
      LspCompletion(label: 'std::map', kind: 'type', detail: 'std::map<Key, T>', documentation: 'Associative container.'),
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
      LspCompletion(label: 'listOf', kind: 'function', detail: 'listOf<T>(vararg elements: T)', documentation: 'Returns a new read-only list.'),
      LspCompletion(label: 'package', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'println', kind: 'function', detail: 'println(message: Any?)', documentation: 'Prints message and newline.'),
      LspCompletion(label: 'val', kind: 'keyword', detail: 'keyword', documentation: 'Read-only property declaration.'),
      LspCompletion(label: 'var', kind: 'keyword', detail: 'keyword', documentation: 'Mutable property declaration.'),
    ],
    'java': [
      LspCompletion(label: 'ArrayList', kind: 'class', detail: 'class ArrayList<E>', documentation: 'Resizable-array implementation of the List interface.'),
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
      LspCompletion(label: 'append', kind: 'function', detail: 'append(slice []Type, elems ...Type)', documentation: 'Appends elements to a slice.'),
      LspCompletion(label: 'const', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'fmt.Println', kind: 'function', detail: 'fmt.Println(...)', documentation: 'Formats and prints to stdout.'),
      LspCompletion(label: 'fmt.Printf', kind: 'function', detail: 'fmt.Printf(format string, a ...any)', documentation: 'Formats according to format specifier.'),
      LspCompletion(label: 'func', kind: 'keyword', detail: 'keyword', documentation: 'Declares a function.'),
      LspCompletion(label: 'import', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'interface', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'make', kind: 'function', detail: 'make(t Type, size ...IntegerType)', documentation: 'Allocates and initializes slice, map, or chan.'),
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
      LspCompletion(label: 'match', kind: 'keyword', detail: 'keyword', documentation: 'Pattern matching expression.'),
      LspCompletion(label: 'mut', kind: 'keyword', detail: 'keyword', documentation: 'Makes variable binding mutable.'),
      LspCompletion(label: 'println!', kind: 'macro', detail: 'println!(...)', documentation: 'Prints formatted output with newline.'),
      LspCompletion(label: 'String', kind: 'struct', detail: 'struct String', documentation: 'A UTF-8 encoded, growable string.'),
      LspCompletion(label: 'struct', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'Vec', kind: 'struct', detail: 'struct Vec<T>', documentation: 'Contiguous growable array type.'),
    ],
    'csharp': [
      LspCompletion(label: 'async', kind: 'keyword', detail: 'modifier'),
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'Console.WriteLine', kind: 'function', detail: 'Console.WriteLine(...)', documentation: 'Writes output followed by line terminator.'),
      LspCompletion(label: 'namespace', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'public', kind: 'keyword', detail: 'modifier'),
      LspCompletion(label: 'Task', kind: 'class', detail: 'class Task', documentation: 'Represents an asynchronous operation.'),
      LspCompletion(label: 'using', kind: 'keyword', detail: 'directive'),
    ],
    'swift': [
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'func', kind: 'keyword', detail: 'keyword', documentation: 'Declares a function.'),
      LspCompletion(label: 'guard', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'let', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'print', kind: 'function', detail: 'print(_:separator:terminator:)', documentation: 'Prints items to standard output.'),
      LspCompletion(label: 'struct', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'var', kind: 'keyword', detail: 'keyword'),
    ],
    'ruby': [
      LspCompletion(label: 'attr_accessor', kind: 'function', detail: 'attr_accessor :symbol', documentation: 'Defines reader and writer methods for given attributes.'),
      LspCompletion(label: 'class', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'def', kind: 'keyword', detail: 'keyword', documentation: 'Defines a method.'),
      LspCompletion(label: 'module', kind: 'keyword', detail: 'keyword'),
      LspCompletion(label: 'puts', kind: 'function', detail: 'puts(*args)', documentation: 'Writes given objects to standard output.'),
      LspCompletion(label: 'require', kind: 'function', detail: 'require(name)', documentation: 'Loads given feature.'),
    ],
    'html': [
      LspCompletion(label: '<a>', kind: 'tag', detail: 'HTML anchor element'),
      LspCompletion(label: '<button>', kind: 'tag', detail: 'HTML button element'),
      LspCompletion(label: '<div>', kind: 'tag', detail: 'HTML div element'),
      LspCompletion(label: '<form>', kind: 'tag', detail: 'HTML form element'),
      LspCompletion(label: '<h1>', kind: 'tag', detail: 'HTML heading element'),
      LspCompletion(label: '<img>', kind: 'tag', detail: 'HTML image element'),
      LspCompletion(label: '<input>', kind: 'tag', detail: 'HTML input element'),
      LspCompletion(label: '<p>', kind: 'tag', detail: 'HTML paragraph element'),
      LspCompletion(label: '<script>', kind: 'tag', detail: 'HTML script element'),
      LspCompletion(label: '<span>', kind: 'tag', detail: 'HTML span element'),
      LspCompletion(label: '<style>', kind: 'tag', detail: 'HTML style element'),
    ],
    'css': [
      LspCompletion(label: 'align-items', kind: 'property', detail: 'flex/grid property'),
      LspCompletion(label: 'background-color', kind: 'property', detail: 'property'),
      LspCompletion(label: 'border', kind: 'property', detail: 'property'),
      LspCompletion(label: 'color', kind: 'property', detail: 'property'),
      LspCompletion(label: 'display', kind: 'property', detail: 'property'),
      LspCompletion(label: 'flex', kind: 'property', detail: 'property'),
      LspCompletion(label: 'font-size', kind: 'property', detail: 'property'),
      LspCompletion(label: 'grid', kind: 'property', detail: 'property'),
      LspCompletion(label: 'justify-content', kind: 'property', detail: 'flex/grid property'),
      LspCompletion(label: 'margin', kind: 'property', detail: 'property'),
      LspCompletion(label: 'padding', kind: 'property', detail: 'property'),
      LspCompletion(label: 'position', kind: 'property', detail: 'property'),
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
      LspCompletion(label: 'ALTER TABLE', kind: 'keyword', detail: 'SQL keyword'),
      LspCompletion(label: 'CREATE TABLE', kind: 'keyword', detail: 'SQL keyword'),
      LspCompletion(label: 'DELETE FROM', kind: 'keyword', detail: 'SQL keyword'),
      LspCompletion(label: 'FROM', kind: 'keyword', detail: 'SQL keyword'),
      LspCompletion(label: 'GROUP BY', kind: 'keyword', detail: 'SQL keyword'),
      LspCompletion(label: 'HAVING', kind: 'keyword', detail: 'SQL keyword'),
      LspCompletion(label: 'INSERT INTO', kind: 'keyword', detail: 'SQL keyword'),
      LspCompletion(label: 'ORDER BY', kind: 'keyword', detail: 'SQL keyword'),
      LspCompletion(label: 'SELECT', kind: 'keyword', detail: 'SQL keyword'),
      LspCompletion(label: 'UPDATE', kind: 'keyword', detail: 'SQL keyword'),
      LspCompletion(label: 'WHERE', kind: 'keyword', detail: 'SQL keyword'),
    ],
    'shell': [
      LspCompletion(label: 'cd', kind: 'command', detail: 'shell command'),
      LspCompletion(label: 'chmod', kind: 'command', detail: 'shell command'),
      LspCompletion(label: 'curl', kind: 'command', detail: 'shell command'),
      LspCompletion(label: 'echo', kind: 'command', detail: 'shell command'),
      LspCompletion(label: 'export', kind: 'command', detail: 'shell command'),
      LspCompletion(label: 'find', kind: 'command', detail: 'shell command'),
      LspCompletion(label: 'grep', kind: 'command', detail: 'shell command'),
      LspCompletion(label: 'ls', kind: 'command', detail: 'shell command'),
      LspCompletion(label: 'mkdir', kind: 'command', detail: 'shell command'),
    ],
  };

  String detectLanguage(String fileName) {
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'php':
        return 'php';
      case 'ts':
      case 'tsx':
        return 'typescript';
      case 'js':
      case 'jsx':
      case 'vue':
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
      case 'java':
        return 'java';
      case 'go':
        return 'go';
      case 'rs':
        return 'rust';
      case 'cs':
        return 'csharp';
      case 'swift':
        return 'swift';
      case 'rb':
        return 'ruby';
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
    final lines = content.split('\n');
    final line = (row >= 0 && row < lines.length) ? lines[row] : '';
    final safeCol = col.clamp(0, line.length);
    final beforeCol = line.substring(0, safeCol);

    // Check member access (e.g., react. or React.use or console.log)
    final memberMatch = RegExp(r'([A-Za-z_$][\w$]*)\.\s*([A-Za-z_$][\w$]*)?$').firstMatch(beforeCol);
    if (memberMatch != null) {
      final target = memberMatch.group(1)!;
      final mPrefix = memberMatch.group(2) ?? '';

      final members = _objectMembers[target] ?? _objectMembers[target.toLowerCase()];
      if (members != null) {
        return members.where((m) {
          if (mPrefix.isEmpty) return true;
          return m.label.toLowerCase().startsWith(mPrefix.toLowerCase());
        }).toList();
      }

      // Generic target fallback members from document symbols or standard list
      final lang = detectLanguage(fileName);
      final predefined = _langKeywords[lang] ?? _langKeywords['typescript']!;
      final genericMembers = <LspCompletion>[];
      for (final c in predefined) {
        if (c.kind == 'function' || c.kind == 'property' || c.kind == 'variable') {
          if (mPrefix.isEmpty || c.label.toLowerCase().startsWith(mPrefix.toLowerCase())) {
            genericMembers.add(c);
          }
        }
      }
      return genericMembers;
    }

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

  /// Analyzes code context around row & col and returns signature help for function calls if active.
  LspSignatureHelp? getSignatureHelp(
    String fileName,
    String content,
    int row,
    int col,
  ) {
    final lines = content.split('\n');
    if (row < 0 || row >= lines.length) return null;

    final buffer = StringBuffer();
    for (var i = 0; i <= row; i++) {
      final l = lines[i];
      if (i < row) {
        buffer.writeln(l);
      } else {
        buffer.write(l.substring(0, col.clamp(0, l.length)));
      }
    }
    final textUpToCursor = buffer.toString();

    var depth = 0;
    var commaCount = 0;
    var openParenIndex = -1;

    for (var i = textUpToCursor.length - 1; i >= 0; i--) {
      final ch = textUpToCursor[i];
      if (ch == ')') {
        depth++;
      } else if (ch == '(') {
        if (depth > 0) {
          depth--;
        } else {
          openParenIndex = i;
          break;
        }
      } else if (ch == ',' && depth == 0) {
        commaCount++;
      }
    }

    if (openParenIndex < 0) return null;

    final textBeforeParen = textUpToCursor.substring(0, openParenIndex).trimRight();
    final fnMatch = RegExp(r'([A-Za-z_$][\w$.]*)$').firstMatch(textBeforeParen);
    if (fnMatch == null) return null;

    final rawFnName = fnMatch.group(1)!;
    final fnName = rawFnName.contains('.') ? rawFnName.split('.').last : rawFnName;

    String? detail;
    String? documentation;

    for (final members in _objectMembers.values) {
      for (final item in members) {
        if (item.label == fnName) {
          detail = item.detail;
          documentation = item.documentation;
          break;
        }
      }
      if (detail != null) break;
    }

    if (detail == null) {
      final lang = detectLanguage(fileName);
      final predefined = _langKeywords[lang] ?? _langKeywords['typescript']!;
      for (final item in predefined) {
        if (item.label == fnName || item.label == rawFnName) {
          detail = item.detail;
          documentation = item.documentation;
          break;
        }
      }
    }

    if (detail == null) {
      final docFnMatch = RegExp('\\b(?:def|function|fun|func|fn)\\s+${RegExp.escape(fnName)}\\s*\\(([^)]*)\\)')
          .firstMatch(content);
      if (docFnMatch != null) {
        final paramsStr = docFnMatch.group(1) ?? '';
        detail = '$fnName($paramsStr)';
      }
    }

    detail ??= '$fnName(...)';

    final params = <LspParameterInfo>[];
    final paramMatch = RegExp(r'\(([^)]*)\)').firstMatch(detail);
    if (paramMatch != null) {
      final rawParams = paramMatch.group(1)!;
      if (rawParams.trim().isNotEmpty) {
        for (final p in rawParams.split(',')) {
          final trimmed = p.trim();
          if (trimmed.isNotEmpty) {
            params.add(LspParameterInfo(label: trimmed));
          }
        }
      }
    }

    final sigLabel = detail.startsWith('(') ? '$rawFnName$detail' : detail;

    final sigInfo = LspSignatureInfo(
      label: sigLabel,
      documentation: documentation,
      parameters: params,
    );

    final activeParam = params.isEmpty ? 0 : commaCount.clamp(0, params.length - 1);

    return LspSignatureHelp(
      signatures: [sigInfo],
      activeSignature: 0,
      activeParameter: activeParam,
    );
  }
}
