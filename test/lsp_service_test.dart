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
  });
}
