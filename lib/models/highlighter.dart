import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' show highlight, Node;
import 'package:highlight/languages/bash.dart';
import 'package:highlight/languages/clojure.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/cs.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/dockerfile.dart';
import 'package:highlight/languages/go.dart';
import 'package:highlight/languages/graphql.dart';
import 'package:highlight/languages/ini.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/kotlin.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:highlight/languages/objectivec.dart';
import 'package:highlight/languages/php.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/r.dart';
import 'package:highlight/languages/ruby.dart';
import 'package:highlight/languages/rust.dart';
import 'package:highlight/languages/scss.dart';
import 'package:highlight/languages/sql.dart';
import 'package:highlight/languages/swift.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/yaml.dart';

import '../theme/tokens.dart';

bool _initialized = false;

void _ensureInitialized() {
  if (_initialized) return;
  _initialized = true;

  highlight.registerLanguage('javascript', javascript);
  highlight.registerLanguage('typescript', typescript);
  highlight.registerLanguage('dart', dart);
  highlight.registerLanguage('kotlin', kotlin);
  highlight.registerLanguage('cpp', cpp);
  highlight.registerLanguage('python', python);
  highlight.registerLanguage('json', json);
  highlight.registerLanguage('xml', xml);
  highlight.registerLanguage('css', css);
  highlight.registerLanguage('scss', scss);
  highlight.registerLanguage('java', java);
  highlight.registerLanguage('rust', rust);
  highlight.registerLanguage('go', go);
  highlight.registerLanguage('yaml', yaml);
  highlight.registerLanguage('bash', bash);
  highlight.registerLanguage('cs', cs);
  highlight.registerLanguage('php', php);
  highlight.registerLanguage('swift', swift);
  highlight.registerLanguage('ruby', ruby);
  highlight.registerLanguage('sql', sql);
  highlight.registerLanguage('markdown', markdown);
  highlight.registerLanguage('dockerfile', dockerfile);
  highlight.registerLanguage('graphql', graphql);
  highlight.registerLanguage('ini', ini);
  highlight.registerLanguage('objectivec', objectivec);
  highlight.registerLanguage('clojure', clojure);
  highlight.registerLanguage('r', r);
}

/// Detects syntax language from file extension.
String detectLanguage(String? fileName) {
  if (fileName == null || fileName.isEmpty) return 'javascript';
  final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : fileName;

  switch (ext) {
    case 'dart':
      return 'dart';
    case 'kt':
    case 'kts':
      return 'kotlin';
    case 'cpp':
    case 'cxx':
    case 'cc':
    case 'c':
    case 'h':
    case 'hpp':
      return 'cpp';
    case 'py':
      return 'python';
    case 'js':
    case 'jsx':
      return 'javascript';
    case 'ts':
    case 'tsx':
      return 'typescript';
    case 'json':
      return 'json';
    case 'html':
    case 'htm':
    case 'xml':
    case 'svg':
      return 'xml';
    case 'css':
      return 'css';
    case 'scss':
    case 'sass':
    case 'less':
      return 'scss';
    case 'java':
      return 'java';
    case 'rs':
      return 'rust';
    case 'go':
      return 'go';
    case 'yaml':
    case 'yml':
      return 'yaml';
    case 'sh':
    case 'bash':
    case 'zsh':
      return 'bash';
    case 'cs':
      return 'cs';
    case 'php':
      return 'php';
    case 'swift':
      return 'swift';
    case 'rb':
      return 'ruby';
    case 'sql':
      return 'sql';
    case 'md':
    case 'markdown':
      return 'markdown';
    case 'dockerfile':
      return 'dockerfile';
    case 'gql':
    case 'graphql':
      return 'graphql';
    case 'ini':
    case 'conf':
    case 'env':
      return 'ini';
    case 'm':
    case 'mm':
      return 'objectivec';
    case 'clj':
      return 'clojure';
    case 'r':
      return 'r';
    default:
      return 'javascript';
  }
}

Color _resolveColor(String? className, LatticeColors c) {
  if (className == null) return c.synPlain;

  if (className.contains('keyword') || className.contains('built_in')) {
    return c.synKeyword;
  }
  if (className.contains('string') || className.contains('quote') || className.contains('subst')) {
    return c.synString;
  }
  if (className.contains('type') || className.contains('class')) {
    return c.synType;
  }
  if (className.contains('title') || className.contains('function')) {
    return c.synFunction;
  }
  if (className.contains('comment') || className.contains('doctag')) {
    return c.textFaint;
  }
  if (className.contains('number') || className.contains('symbol') || className.contains('literal')) {
    return c.accent;
  }
  if (className.contains('punctuation') ||
      className.contains('operator') ||
      className.contains('attr') ||
      className.contains('params')) {
    return c.synPunct;
  }

  return c.synPlain;
}

TextSpan _convertNode(Node node, LatticeColors c, TextStyle base, {String? parentClass}) {
  final currentClass = node.className ?? parentClass;
  final color = _resolveColor(currentClass, c);
  final style = base.copyWith(color: color);

  if (node.value != null) {
    return TextSpan(text: node.value, style: style);
  }

  if (node.children != null && node.children!.isNotEmpty) {
    return TextSpan(
      style: style,
      children: node.children!
          .map((child) => _convertNode(child, c, base, parentClass: currentClass))
          .toList(),
    );
  }

  return TextSpan(text: '', style: style);
}

/// Tokenizer that highlights code for Dart, C, C++, Java, JS, JSX, TS, TSX, Python, HTML, CSS, SCSS, Rust, Go, Swift, Kotlin, Bash, C#, PHP, SQL, Markdown, Dockerfile, YAML, etc.
TextSpan highlightLine(
  String line,
  LatticeColors c,
  TextStyle base, {
  String? fileName,
  String? language,
}) {
  _ensureInitialized();
  final lang = language ?? detectLanguage(fileName);

  try {
    final result = highlight.parse(line, language: lang);
    if (result.nodes != null && result.nodes!.isNotEmpty) {
      return TextSpan(
        style: base,
        children: result.nodes!
            .map((node) => _convertNode(node, c, base))
            .toList(),
      );
    }
  } catch (_) {}

  return TextSpan(text: line, style: base.copyWith(color: c.synPlain));
}
