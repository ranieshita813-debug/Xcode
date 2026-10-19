import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/models/editor_model.dart';

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
}
