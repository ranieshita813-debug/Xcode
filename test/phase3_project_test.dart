import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/models/project_search_model.dart';
import 'package:lattice/services/file_service.dart';
import 'package:lattice/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late FileService fileService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('lattice_phase3_test_');
    fileService = FileService(rootDir: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Phase 3 Project Experience', () {
    test('FileService creates and lists files and folders', () async {
      await fileService.createFile('src/main.dart', content: 'void main() {}');
      await fileService.createFile('src/utils.dart', content: 'int add(int a, int b) => a + b;');

      final files = await fileService.listFiles();
      expect(files.length, equals(2));
      expect(files.any((f) => f.path.contains('main.dart')), isTrue);
      expect(files.any((f) => f.path.contains('utils.dart')), isTrue);
    });

    test('ProjectSearchModel searches across all storage files', () async {
      await fileService.createFile('file1.txt', content: 'hello world\nLattice editor');
      await fileService.createFile('file2.txt', content: 'hello flutter\ncode editor');

      final search = ProjectSearchModel(fileService: fileService);
      search.updateQuery('hello');
      await search.performSearch();

      expect(search.results.length, equals(2));
    });

    test('SessionState serializes and deserializes cleanly', () {
      final state = SessionState(
        openTabs: ['main.dart', 'app.py'],
        activeTab: 'app.py',
        cursors: {
          'main.dart': {'row': 5, 'col': 12},
          'app.py': {'row': 2, 'col': 4},
        },
      );

      final json = state.toJson();
      final restored = SessionState.fromJson(json);

      expect(restored.openTabs, equals(['main.dart', 'app.py']));
      expect(restored.activeTab, equals('app.py'));
      expect(restored.cursors['main.dart']?['row'], equals(5));
      expect(restored.cursors['app.py']?['col'], equals(4));
    });
  });
}
