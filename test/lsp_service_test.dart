import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/models/editor_model.dart';
import 'package:lattice/services/lsp_service.dart';

void main() {
  group('LspService', () {
    late LspService lspService;

    setUp(() {
      lspService = LspService();
    });

    test('detectLanguage correctly identifies file types', () {
      expect(lspService.detectLanguage('file.ts'), 'typescript');
      expect(lspService.detectLanguage('file.tsx'), 'typescript');
      expect(lspService.detectLanguage('main.dart'), 'dart');
      expect(lspService.detectLanguage('app.py'), 'python');
      expect(lspService.detectLanguage('native.cpp'), 'cpp');
      expect(lspService.detectLanguage('Helper.kt'), 'kotlin');
      expect(lspService.detectLanguage('App.java'), 'java');
      expect(lspService.detectLanguage('main.go'), 'go');
      expect(lspService.detectLanguage('lib.rs'), 'rust');
      expect(lspService.detectLanguage('config.json'), 'json');
      expect(lspService.detectLanguage('deploy.yaml'), 'yaml');
      expect(lspService.detectLanguage('script.sh'), 'shell');
    });

    test('analyze detects missing python colon', () {
      const code = 'def test()\n    return 1';
      final diagnostics = lspService.analyze('app.py', code);

      expect(diagnostics.any((d) => d.message.contains("Expected ':'")), isTrue);
    });

    test('analyze detects json syntax errors', () {
      const code = '{\n  "name": "lattice"\n}}';
      final diagnostics = lspService.analyze('config.json', code);

      expect(diagnostics.any((d) => d.message.contains('Unmatched') || d.message.contains('closing')), isTrue);
    });

    test('analyze detects TS2304 error for setD in TypeScript', () {
      const code = 'function test() {\n  setD\n}';
      final diagnostics = lspService.analyze('editor.tsx', code);

      expect(diagnostics.length, equals(1));
      final diag = diagnostics.first;
      expect(diag.code, equals('TS2304'));
      expect(diag.line, equals(1));
      expect(diag.severity, equals(DiagnosticSeverity.error));
      expect(diag.format(), contains('TS2304: Cannot find name \'setD\''));
    });

    test('analyze detects unmatched parentheses', () {
      const code = 'function test() {\n  foo())\n}';
      final diagnostics = lspService.analyze('test.js', code);

      expect(diagnostics.where((d) => d.message.contains('Unmatched')).length, equals(1));
    });

    test('getCompletions returns keywords and document symbols', () {
      const code = 'const customVariable = 123;\nuseS';
      final completions = lspService.getCompletions('editor.tsx', code, 1, 4, 'useS');

      expect(completions.any((c) => c.label == 'useState'), isTrue);
    });

    test('getHover returns hover details for keywords', () {
      const code = 'const x = 10;';
      final hover = lspService.getHover('editor.tsx', code, 0, 1);

      expect(hover, isNotNull);
      expect(hover!.contents, contains('typescript'));
      expect(hover.contents, contains('const'));
    });

    test('getCompletions returns member suggestions after dot for react / React', () {
      const code1 = 'import React from "react";\nReact.';
      final completions1 = lspService.getCompletions('App.tsx', code1, 1, 6, '');
      expect(completions1.any((c) => c.label == 'useState'), isTrue);
      expect(completions1.any((c) => c.label == 'useEffect'), isTrue);

      const code2 = 'import react from "react";\nreact.use';
      final completions2 = lspService.getCompletions('App.tsx', code2, 1, 9, 'use');
      expect(completions2.every((c) => c.label.startsWith('use')), isTrue);
      expect(completions2.any((c) => c.label == 'useState'), isTrue);
    });

    test('getCompletions returns member suggestions for console and Math', () {
      const code = 'console.\nMath.p';
      final consoleCompletions = lspService.getCompletions('app.js', code, 0, 8, '');
      expect(consoleCompletions.any((c) => c.label == 'log'), isTrue);

      final mathCompletions = lspService.getCompletions('app.js', code, 1, 6, 'p');
      expect(mathCompletions.any((c) => c.label == 'pow'), isTrue);
      expect(mathCompletions.any((c) => c.label == 'PI'), isTrue);
    });

    test('getSignatureHelp calculates active parameter correctly', () {
      const code = 'saveFile("test.txt", ';
      final help = lspService.getSignatureHelp('editor.tsx', code, 0, code.length);

      expect(help, isNotNull);
      expect(help!.signatures.length, equals(1));
      final sig = help.signatures.first;
      expect(sig.label, contains('saveFile'));
      expect(help.activeParameter, equals(1)); // Second parameter after comma
      expect(sig.parameters[1].label, contains('content'));
    });

    test('getSignatureHelp returns first parameter when function opened', () {
      const code = 'calculate_sum(';
      final help = lspService.getSignatureHelp('app.py', code, 0, code.length);

      expect(help, isNotNull);
      expect(help!.activeParameter, equals(0)); // First parameter
      expect(help.signatures.first.label, contains('calculate_sum'));
    });
  });

  group('EditorModel LSP Integration', () {
    test('EditorModel automatically updates diagnostics and suggestions', () {
      final model = EditorModel.editorTsx();

      // editor.tsx has line 'setD'
      expect(model.diagnostics.length, greaterThanOrEqualTo(1));
      expect(model.diagnostics.first.code, equals('TS2304'));

      // suggestions should include 'setDirty' via LSP
      expect(model.prefix, equals('setD'));
      expect(model.suggestions.any((s) => s.label == 'setDirty'), isTrue);

      // Fix error and verify diagnostics update
      model.applySuggestion(model.suggestions.firstWhere((s) => s.label == 'setDirty'));
      expect(model.diagnostics.isEmpty, isTrue);
    });

    test('EditorModel provides dot member suggestions and signature help', () {
      final model = EditorModel(
        fileName: 'App.tsx',
        lines: ['import React from "react";', 'React.'],
        row: 1,
        col: 6,
      );

      expect(model.suggestions.isNotEmpty, isTrue);
      expect(model.suggestions.any((s) => s.label == 'useState'), isTrue);

      final useStateSuggestion = model.suggestions.firstWhere((s) => s.label == 'useState');
      model.applySuggestion(useStateSuggestion);

      expect(model.lines[1], equals('React.useState'));

      model.lines = ['saveFile('];
      model.moveTo(0, 9);
      expect(model.signatureHelp, isNotNull);
      expect(model.signatureHelp!.signatures.first.label, contains('saveFile'));
    });
  });
}
