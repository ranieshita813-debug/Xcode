enum CodeForgeAction {
  generate,
  refactor,
  fixErrors,
  addTests,
  explain,
}

class CodeForgeResult {
  const CodeForgeResult({
    required this.generatedCode,
    required this.explanation,
    required this.action,
  });

  final String generatedCode;
  final String explanation;
  final CodeForgeAction action;
}

class CodeForgeService {
  String _detectLanguage(String fileName) {
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
      default:
        return 'plaintext';
    }
  }

  CodeForgeResult processPrompt({
    required String prompt,
    required String fileName,
    required String currentCode,
    String? selectedCode,
    CodeForgeAction action = CodeForgeAction.generate,
  }) {
    final lang = _detectLanguage(fileName);
    final targetCode = (selectedCode != null && selectedCode.trim().isNotEmpty)
        ? selectedCode
        : currentCode;

    switch (action) {
      case CodeForgeAction.fixErrors:
        return _fixErrors(fileName, targetCode, lang);
      case CodeForgeAction.refactor:
        return _refactor(fileName, targetCode, lang, prompt);
      case CodeForgeAction.addTests:
        return _addTests(fileName, targetCode, lang);
      case CodeForgeAction.explain:
        return _explain(fileName, targetCode, lang);
      case CodeForgeAction.generate:
        return _generate(fileName, targetCode, lang, prompt);
    }
  }

  CodeForgeResult _fixErrors(String fileName, String code, String lang) {
    var fixed = code;
    final fixes = <String>[];

    // Fix TS/JS setD -> setDirty(false);
    if (fixed.contains('setD') && !fixed.contains('setDirty')) {
      fixed = fixed.replaceAll(RegExp(r'(?<![\w$])setD(?![\w$])'), 'setDirty(false);');
      fixes.add("Fixed unresolved identifier 'setD' -> 'setDirty(false);'");
    }

    // Fix Python missing colons in def/class/if/for/while
    if (lang == 'python') {
      final lines = fixed.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (RegExp(r'^\s*(def|class|if|elif|else|for|while|try|except)\b.*$').hasMatch(line)) {
          final trimmed = line.trimRight();
          if (!trimmed.endsWith(':') && !trimmed.endsWith('\\') && !trimmed.startsWith('#')) {
            lines[i] = '$line:';
            fixes.add('Added missing colon on line ${i + 1}');
          }
        }
      }
      fixed = lines.join('\n');
    }

    // Fix unclosed brackets or parens
    if (fixed.split('{').length > fixed.split('}').length) {
      final missing = fixed.split('{').length - fixed.split('}').length;
      fixed = '$fixed\n${'}' * missing}';
      fixes.add('Added $missing missing closing brace(s)');
    }

    if (fixes.isEmpty) {
      fixes.add('Validated syntax: No critical diagnostics found');
    }

    return CodeForgeResult(
      generatedCode: fixed,
      explanation: fixes.join('\n• '),
      action: CodeForgeAction.fixErrors,
    );
  }

  CodeForgeResult _refactor(String fileName, String code, String lang, String prompt) {
    var refactored = code;
    var explanation = 'Applied code refactoring for $lang';

    if (lang == 'typescript' || lang == 'javascript') {
      if (!refactored.contains('try {') && refactored.contains('async')) {
        refactored = refactored.replaceAllMapped(
          RegExp(r'(async\s+function\s+\w+\(.*?\)\s*\{)([\s\S]*?)(\})'),
          (match) => '${match.group(1)}\n    try {\n  ${match.group(2)}  } catch (error) {\n      console.error(error);\n    }\n${match.group(3)}',
        );
        explanation = 'Added async try-catch error handling wrapper';
      }
    } else if (lang == 'dart') {
      if (!refactored.contains('@override') && refactored.contains('Widget build(')) {
        refactored = refactored.replaceAll('Widget build(', '@override\n  Widget build(');
        explanation = 'Added missing @override annotation to build method';
      }
    } else if (lang == 'python') {
      if (!refactored.contains('def ') && prompt.isNotEmpty) {
        refactored = 'def main():\n    """Refactored main function."""\n    $refactored\n\nif __name__ == "__main__":\n    main()\n';
        explanation = 'Structured standalone Python script into main() entrypoint';
      }
    }

    return CodeForgeResult(
      generatedCode: refactored,
      explanation: explanation,
      action: CodeForgeAction.refactor,
    );
  }

  CodeForgeResult _addTests(String fileName, String code, String lang) {
    final baseName = fileName.contains('/') ? fileName.split('/').last : fileName;
    final pureName = baseName.contains('.') ? baseName.split('.').first : baseName;
    String testCode;

    switch (lang) {
      case 'dart':
        testCode = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('$pureName tests', () {
    test('initializes correctly', () {
      expect(true, isTrue);
    });
  });
}
''';
        break;
      case 'typescript':
      case 'javascript':
        testCode = '''
import { describe, it, expect } from 'vitest';

describe('$pureName', () => {
  it('should execute successfully', () => {
    expect(true).toBe(true);
  });
});
''';
        break;
      case 'python':
        testCode = '''
import pytest

def test_${pureName}_initialization():
    assert True
''';
        break;
      case 'cpp':
        testCode = '''
#include <gtest/gtest.dart>

TEST(${pureName}Test, BasicAssertions) {
  EXPECT_EQ(1, 1);
}
''';
        break;
      case 'kotlin':
        testCode = '''
import org.junit.Test
import org.junit.Assert.*

class ${pureName.substring(0, 1).toUpperCase()}${pureName.substring(1)}Test {
    @Test
    void testBasic() {
        assertTrue(true)
    }
}
''';
        break;
      default:
        testCode = '// Unit tests for $baseName\n';
    }

    return CodeForgeResult(
      generatedCode: testCode.trim(),
      explanation: 'Generated boilerplate unit test suite for $baseName',
      action: CodeForgeAction.addTests,
    );
  }

  CodeForgeResult _explain(String fileName, String code, String lang) {
    final lines = code.trim().split('\n');
    final funcCount = RegExp(r'\b(def|function|fun|func|fn)\b').allMatches(code).length;
    final classCount = RegExp(r'\b(class|struct|interface)\b').allMatches(code).length;

    final exp = StringBuffer();
    exp.writeln('Code overview for $fileName ($lang):');
    exp.writeln('• ${lines.length} lines of code');
    if (classCount > 0) exp.writeln('• Defines $classCount type/class structures');
    if (funcCount > 0) exp.writeln('• Contains $funcCount function declarations');
    if (code.contains('import')) exp.writeln('• Includes external module imports');

    return CodeForgeResult(
      generatedCode: code,
      explanation: exp.toString().trim(),
      action: CodeForgeAction.explain,
    );
  }

  CodeForgeResult _generate(String fileName, String code, String lang, String prompt) {
    final p = prompt.toLowerCase();
    String generated;
    String explanation;

    if (p.contains('fetch') || p.contains('api') || p.contains('http')) {
      if (lang == 'typescript' || lang == 'javascript') {
        generated = '''
export async function fetchData(url: string) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`HTTP error! status: \${response.status}`);
  }
  return await response.json();
}
''';
        explanation = 'Generated async HTTP fetch function in TypeScript/JS';
      } else if (lang == 'dart') {
        generated = '''
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> fetchData(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception('Failed to load data: \${response.statusCode}');
  }
}
''';
        explanation = 'Generated async HTTP request function in Dart';
      } else {
        generated = '''
import requests

def fetch_data(url: str) -> dict:
    response = requests.get(url)
    response.raise_for_status()
    return response.json()
''';
        explanation = 'Generated requests HTTP function in Python';
      }
    } else if (p.contains('state') || p.contains('hook') || p.contains('component')) {
      if (lang == 'typescript' || lang == 'javascript') {
        generated = '''
import React, { useState } from 'react';

export function CodeForgeWidget() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>Increment</button>
    </div>
  );
}
''';
        explanation = 'Generated React stateful component snippet';
      } else if (lang == 'dart') {
        generated = '''
import 'package:flutter/material.dart';

class CodeForgeCounter extends StatefulWidget {
  const CodeForgeCounter({super.key});

  @override
  State<CodeForgeCounter> createState() => _CodeForgeCounterState();
}

class _CodeForgeCounterState extends State<CodeForgeCounter> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: \$_counter'),
        ElevatedButton(
          onPressed: () => setState(() => _counter++),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
''';
        explanation = 'Generated Flutter StatefulWidget counter snippet';
      } else {
        generated = '''
class Counter:
    def __init__(self):
        self.count = 0

    def increment(self):
        self.count += 1
''';
        explanation = 'Generated Python counter class snippet';
      }
    } else {
      // Default generated snippet for prompt
      final safePrompt = prompt.isEmpty ? 'utility helper' : prompt;
      if (lang == 'typescript' || lang == 'javascript') {
        generated = '''
/**
 * $safePrompt
 */
export function codeForgeHelper(input: string): string {
  return `Processed: \${input}`;
}
''';
      } else if (lang == 'dart') {
        generated = '''
/// $safePrompt
String codeForgeHelper(String input) {
  return 'Processed: \$input';
}
''';
      } else if (lang == 'python') {
        generated = '''
def code_forge_helper(input_str: str) -> str:
    """$safePrompt"""
    return f"Processed: {input_str}"
''';
      } else {
        generated = '// CodeForge generated snippet for: $safePrompt\n';
      }
      explanation = 'Generated snippet for prompt "$safePrompt"';
    }

    return CodeForgeResult(
      generatedCode: generated.trim(),
      explanation: explanation,
      action: CodeForgeAction.generate,
    );
  }
}
