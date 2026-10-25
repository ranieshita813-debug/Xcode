import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/models/editor_model.dart';
import 'package:lattice/models/highlighter.dart';
import 'package:lattice/screens/settings_screen.dart';
import 'package:lattice/state/settings.dart';
import 'package:lattice/theme/app_theme.dart';
import 'package:lattice/theme/tokens.dart';

void main() {
  test('autocomplete suggests setDirty for "setD"', () {
    final m = EditorModel.editorTsx();
    expect(m.prefix, 'setD');
    expect(m.suggestions.first.label, 'setDirty');
  });

  test('applySuggestion completes the word and supports undo', () {
    final m = EditorModel.editorTsx();
    m.applySuggestion(m.suggestions.first);
    expect(m.currentLine, '    setDirty');
    m.undo();
    expect(m.currentLine, '    setD');
  });

  test('newline keeps indentation', () {
    final m = EditorModel(lines: const ['  foo'], col: 5);
    m.newline();
    expect(m.lines, ['  foo', '  ']);
    expect(m.row, 1);
  });

  test('detectLanguage identifies extensions correctly', () {
    expect(detectLanguage('main.dart'), 'dart');
    expect(detectLanguage('app.py'), 'python');
    expect(detectLanguage('native.cpp'), 'cpp');
    expect(detectLanguage('Helper.kt'), 'kotlin');
    expect(detectLanguage('editor.tsx'), 'typescript');
    expect(detectLanguage('index.js'), 'javascript');
    expect(detectLanguage('config.json'), 'json');
  });

  test('highlightLine generates text spans for various languages', () {
    const c = LatticeColors.dark;
    const style = TextStyle(fontSize: 12);

    final dartSpan = highlightLine('void main() {}', c, style, fileName: 'main.dart');
    expect(dartSpan.children, isNotEmpty);

    final pySpan = highlightLine('def hello():', c, style, fileName: 'app.py');
    expect(pySpan.children, isNotEmpty);

    final cppSpan = highlightLine('int main() {}', c, style, fileName: 'native.cpp');
    expect(cppSpan.children, isNotEmpty);

    final ktSpan = highlightLine('fun main() {}', c, style, fileName: 'Helper.kt');
    expect(ktSpan.children, isNotEmpty);
  });

  testWidgets('SettingsScreen opens font picker sheet and selects font', (tester) async {
    final settings = AppSettings();
    await tester.pumpWidget(
      SettingsScope(
        settings: settings,
        child: MaterialApp(
          theme: buildTheme(LatticeColors.dark, Brightness.dark),
          home: const SettingsScreen(),
        ),
      ),
    );

    expect(find.text('Select Coding Font'), findsNothing);

    // Tap Font row
    await tester.tap(find.text('Font'));
    await tester.pumpAndSettle();

    // Verify modal bottom sheet is shown
    expect(find.text('Select Coding Font'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    final divider = tester.widget<Divider>(find.byType(Divider));
    expect(divider.height, equals(1));

    // Tap Fira Code font
    await tester.tap(find.text('Fira Code'));
    await tester.pumpAndSettle();

    // Verify sheet closed and settings updated
    expect(find.text('Select Coding Font'), findsNothing);
    expect(settings.fontFamily, equals('Fira Code'));
  });
}
