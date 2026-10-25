import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Handles file operations within app document storage.
class FileService {
  FileService({Directory? rootDir}) : _rootDir = rootDir;

  Directory? _rootDir;

  Future<Directory> getAppDirectory() async {
    if (_rootDir != null) return _rootDir!;
    _rootDir = await getApplicationDocumentsDirectory();
    return _rootDir!;
  }

  Future<List<File>> listFiles() async {
    final dir = await getAppDirectory();
    if (!await dir.exists()) return [];

    final entities = await dir.list().toList();
    final files = <File>[];
    for (final entity in entities) {
      if (entity is File) {
        files.add(entity);
      }
    }
    files.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    return files;
  }

  Future<String> readFile(String fileNameOrPath) async {
    final file = await _resolveFile(fileNameOrPath);
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', file.path);
    }
    return await file.readAsString();
  }

  Future<File> writeFile(String fileNameOrPath, String content) async {
    final file = await _resolveFile(fileNameOrPath);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    return await file.writeAsString(content);
  }

  Future<void> deleteFile(String fileNameOrPath) async {
    final file = await _resolveFile(fileNameOrPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> exists(String fileNameOrPath) async {
    final file = await _resolveFile(fileNameOrPath);
    return await file.exists();
  }

  Future<File> _resolveFile(String fileNameOrPath) async {
    if (p.isAbsolute(fileNameOrPath)) {
      return File(fileNameOrPath);
    }
    final dir = await getAppDirectory();
    return File(p.join(dir.path, fileNameOrPath));
  }
}
