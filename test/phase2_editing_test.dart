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
    test('auto-closes opening brackets and quotes, and backspace removes pairs', () {
      final model = EditorModel(lines: ['']);
      model.insert('(');
      expect(model.text, equals('()'));
      expect(model.col, equals(1));

      model.insert('[');
      expect(model.text, equals('([])'));
      expect(model.col, equals(2));

      model.backspace();
      expect(model.text, equals('()'));
      expect(model.col, equals(1));

      model.backspace();
      expect(model.text, equals(''));
      expect(model.col, equals(0));
    });

    test('EditorInputClient delta deletion handles ranges correctly', () {
      final model = EditorModel(lines: ['hello world']);
      final client = EditorInputClient(
        model: model,
        onEditingChanged: () {},
      );

      client.updateEditingValueWithDeltas([
        const TextEditingDeltaDeletion(
          oldText: 'hello world',
          deletedRange: TextRange(start: 5, end: 11),
          selection: TextSelection.collapsed(offset: 5),
          composing: TextRange.empty,
        ),
      ]);

      expect(model.text, equals('hello'));
      expect(model.col, equals(5));
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
  });
}
