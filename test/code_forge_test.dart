import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/screens/editor_screen.dart';
import 'package:lattice/services/code_forge_service.dart';
import 'package:lattice/state/settings.dart';
import 'package:lattice/theme/app_theme.dart';
import 'package:lattice/theme/tokens.dart';
import 'package:lattice/widgets/code_forge_panel.dart';

Widget buildTestableWidget(Widget child) {
  final settings = AppSettings();
  return SettingsScope(
    settings: settings,
    child: MaterialApp(
      theme: buildTheme(LatticeColors.light, Brightness.light),
      darkTheme: buildTheme(LatticeColors.dark, Brightness.dark),
      home: child,
    ),
  );
}

void main() {
  group('CodeForgeService unit tests', () {
    late CodeForgeService service;

    setUp(() {
      service = CodeForgeService();
    });

    test('generate code for fetch request', () {
      final res = service.processPrompt(
        prompt: 'fetch api data',
        fileName: 'main.dart',
        currentCode: 'void main() {}',
        action: CodeForgeAction.generate,
      );

      expect(res.generatedCode, contains('http.get'));
      expect(res.action, equals(CodeForgeAction.generate));
    });

    test('fix errors resolves setD to setDirty in typescript', () {
      final res = service.processPrompt(
        prompt: '',
        fileName: 'editor.tsx',
        currentCode: 'function test() { setD }',
        action: CodeForgeAction.fixErrors,
      );

      expect(res.generatedCode, contains('setDirty(false);'));
      expect(res.explanation, contains('setD'));
    });

    test('fix errors adds colons to python statements', () {
      final res = service.processPrompt(
        prompt: '',
        fileName: 'app.py',
        currentCode: 'def main()\n    print("hello")',
        action: CodeForgeAction.fixErrors,
      );

      expect(res.generatedCode, contains('def main():'));
    });

    test('add tests generates test boilerplate for Dart', () {
      final res = service.processPrompt(
        prompt: '',
        fileName: 'helper.dart',
        currentCode: '',
        action: CodeForgeAction.addTests,
      );

      expect(res.generatedCode, contains('import \'package:flutter_test/flutter_test.dart\';'));
      expect(res.generatedCode, contains('group(\'helper tests\''));
    });

    test('explain provides file line and structure breakdown', () {
      final res = service.processPrompt(
        prompt: '',
        fileName: 'app.py',
        currentCode: 'def foo(): pass\nclass Bar: pass',
        action: CodeForgeAction.explain,
      );

      expect(res.explanation, contains('lines of code'));
      expect(res.explanation, contains('Contains 1 function declarations'));
      expect(res.explanation, contains('Defines 1 type/class structures'));
    });
  });

  group('CodeForgePanel widget tests', () {
    Widget createWidgetUnderTest({
      required ValueChanged<String> onInsert,
      required ValueChanged<String> onReplace,
      required VoidCallback onClose,
    }) {
      return buildTestableWidget(
        Scaffold(
          body: CodeForgePanel(
            fileName: 'editor.tsx',
            currentCode: 'const x = 1;',
            onInsertCode: onInsert,
            onReplaceCode: onReplace,
            onClose: onClose,
          ),
        ),
      );
    }

    testWidgets('CodeForgePanel renders title and chips', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        onInsert: (_) {},
        onReplace: (_) {},
        onClose: () {},
      ));

      expect(find.text('CodeForge AI Assistant'), findsOneWidget);
      expect(find.text('Target: editor.tsx'), findsOneWidget);
      expect(find.text('Generate'), findsOneWidget);
      expect(find.text('Fix Errors'), findsOneWidget);
      expect(find.text('Refactor'), findsOneWidget);
    });

    testWidgets('Tapping Fix Errors produces code and allows insert', (tester) async {
      String? inserted;

      await tester.pumpWidget(createWidgetUnderTest(
        onInsert: (code) => inserted = code,
        onReplace: (_) {},
        onClose: () {},
      ));

      await tester.tap(find.text('Fix Errors'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Insert at Cursor'), findsOneWidget);

      await tester.tap(find.text('Insert at Cursor'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(inserted, isNotNull);
    });
  });

  group('EditorScreen with CodeForge integration', () {
    testWidgets('CodeForge button opens CodeForgePanel', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const EditorScreen()));

      final codeForgeButton = find.byTooltip('CodeForge AI');
      expect(codeForgeButton, findsOneWidget);

      await tester.tap(codeForgeButton);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CodeForge AI Assistant'), findsOneWidget);
    });
  });
}
