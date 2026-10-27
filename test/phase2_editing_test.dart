import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/models/document.dart';
import 'package:lattice/models/editor_model.dart';
import 'package:lattice/models/folding_model.dart';
import 'package:lattice/models/search_model.dart';
import 'package:lattice/widgets/editor_input_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2 Editing Quality', () {
    test('auto-closes opening brackets and quotes', () {
      final model = EditorModel(lines: ['']);
      model.insert('(');
      expect(model.text, equals('()'));
      expect(model.col, equals(1));

      model.insert('[');
      expect(model.text, equals('([])'));
      expect(model.col, equals(2));
    });

    test('SearchModel finds matches with regex and performs replace', () {
      final model = EditorModel(lines: ['foo123', 'bar456', 'foo789']);
      final search = SearchModel();

      search.toggleRegex(model.document);
      search.updateQuery(r'foo\d+', model.document);
      expect(search.matches.length, equals(2));
      expect(search.matches.first.start, equals(const TextPosition(0, 0)));
      expect(search.matches.first.end, equals(const TextPosition(0, 6)));

      search.updateReplaceQuery('BAZ');
      search.replaceAll(model);

      expect(model.lines, equals(['BAZ', 'bar456', 'BAZ']));
      expect(model.canUndo, isTrue);

      model.undo();
      expect(model.lines, equals(['foo123', 'bar456', 'foo789']));
    });

    test('FoldingModel calculates brace fold regions', () {
      final doc = LineListDocument(initialLines: [
        'function test() {',
        '  print("inside");',
        '}',
      ]);
      final folding = FoldingModel();
      final regions = folding.calculateFoldRegions(doc);

      expect(regions.length, equals(1));
      expect(regions.first.startLine, equals(0));
      expect(regions.first.endLine, equals(2));

      folding.toggleFold(0);
      expect(folding.isLineHidden(1, regions), isTrue);
      expect(folding.isLineHidden(2, regions), isTrue);
      expect(folding.isLineHidden(0, regions), isFalse);
    });

    test('EditorInputClient IME typing records into undo stack', () {
      final model = EditorModel(lines: ['hello']);
      final client = EditorInputClient(
        model: model,
        onEditingChanged: () {},
      );

      client.updateEditingValue(const TextEditingValue(
        text: 'hello world',
        selection: TextSelection.collapsed(offset: 11),
      ));

      expect(model.text, equals('hello world'));
      expect(model.canUndo, isTrue);

      model.undo();
      expect(model.text, equals('hello'));
    });

    test('backspace handles auto-pairs, selection, and soft tabs', () {
      // Auto-pair backspace
      final model = EditorModel(lines: ['']);
      model.insert('(');
      expect(model.text, equals('()'));
      expect(model.col, equals(1));
      model.backspace();
      expect(model.text, equals(''));

      // Selection deletion
      final model2 = EditorModel(lines: ['hello world']);
      model2.backspace(selStart: const TextPosition(0, 5), selEnd: const TextPosition(0, 11));
      expect(model2.text, equals('hello'));

      // Soft tab backspace (2 spaces)
      final model3 = EditorModel(lines: ['  code']);
      model3.moveTo(0, 2);
      model3.backspace();
      expect(model3.text, equals('code'));
    });
  });
}
