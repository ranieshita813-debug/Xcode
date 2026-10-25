import 'package:flutter/foundation.dart';
import '../services/file_service.dart';

class ProjectSearchResult {
  const ProjectSearchResult({
    required this.filePath,
    required this.line,
    required this.col,
    required this.lineText,
  });

  final String filePath;
  final int line;
  final int col;
  final String lineText;
}

class ProjectSearchModel extends ChangeNotifier {
  ProjectSearchModel({FileService? fileService})
      : _fileService = fileService ?? FileService();

  final FileService _fileService;

  String _query = '';
  bool _isRegex = false;
  bool _isMatchCase = false;
  List<ProjectSearchResult> _results = [];
  bool _isSearching = false;

  String get query => _query;
  bool get isRegex => _isRegex;
  bool get isMatchCase => _isMatchCase;
  List<ProjectSearchResult> get results => List.unmodifiable(_results);
  bool get isSearching => _isSearching;

  void updateQuery(String newQuery) {
    _query = newQuery;
    performSearch();
  }

  void toggleRegex() {
    _isRegex = !_isRegex;
    performSearch();
  }

  void toggleMatchCase() {
    _isMatchCase = !_isMatchCase;
    performSearch();
  }

  Future<void> performSearch() async {
    if (_query.trim().isEmpty) {
      _results = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final newResults = <ProjectSearchResult>[];
    final files = await _fileService.listFiles();

    RegExp? regExp;
    try {
      if (_isRegex) {
        regExp = RegExp(_query, caseSensitive: _isMatchCase);
      } else {
        regExp = RegExp(RegExp.escape(_query), caseSensitive: _isMatchCase);
      }
    } catch (_) {
      _isSearching = false;
      _results = [];
      notifyListeners();
      return;
    }

    for (final file in files) {
      try {
        final content = await file.readAsString();
        final lines = content.split('\n');
        for (var r = 0; r < lines.length; r++) {
          final line = lines[r];
          final matches = regExp.allMatches(line);
          for (final m in matches) {
            newResults.add(ProjectSearchResult(
              filePath: file.path,
              line: r,
              col: m.start,
              lineText: line,
            ));
          }
        }
      } catch (_) {}
    }

    _results = newResults;
    _isSearching = false;
    notifyListeners();
  }
}
