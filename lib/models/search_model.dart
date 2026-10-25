import 'package:flutter/foundation.dart';
import '../models/document.dart';
import '../models/editor_model.dart';

class SearchMatch {
  const SearchMatch({
    required this.start,
    required this.end,
  });

  final TextPosition start;
  final TextPosition end;
}

class SearchModel extends ChangeNotifier {
  String _query = '';
  String _replaceQuery = '';
  bool _isRegex = false;
  bool _isMatchCase = false;

  List<SearchMatch> _matches = [];
  int _currentIndex = -1;

  String get query => _query;
  String get replaceQuery => _replaceQuery;
  bool get isRegex => _isRegex;
  bool get isMatchCase => _isMatchCase;
  List<SearchMatch> get matches => List.unmodifiable(_matches);
  int get currentIndex => _currentIndex;
  SearchMatch? get currentMatch =>
      (_currentIndex >= 0 && _currentIndex < _matches.length)
          ? _matches[_currentIndex]
          : null;

  void updateQuery(String newQuery, TextDocument doc) {
    _query = newQuery;
    _performSearch(doc);
  }

  void updateReplaceQuery(String newReplace) {
    _replaceQuery = newReplace;
    notifyListeners();
  }

  void toggleRegex(TextDocument doc) {
    _isRegex = !_isRegex;
    _performSearch(doc);
  }

  void toggleMatchCase(TextDocument doc) {
    _isMatchCase = !_isMatchCase;
    _performSearch(doc);
  }

  void nextMatch() {
    if (_matches.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _matches.length;
    notifyListeners();
  }

  void previousMatch() {
    if (_matches.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _matches.length) % _matches.length;
    notifyListeners();
  }

  void replaceCurrent(EditorModel model) {
    if (currentMatch == null) return;
    final m = currentMatch!;
    model.document.replaceRange(m.start, m.end, _replaceQuery);
    _performSearch(model.document);
  }

  void replaceAll(EditorModel model) {
    if (_matches.isEmpty) return;
    model.document.pushSnapshot();
    for (var i = _matches.length - 1; i >= 0; i--) {
      final m = _matches[i];
      model.document.replaceRangeWithoutSnapshot(m.start, m.end, _replaceQuery);
    }
    _performSearch(model.document);
  }

  void _performSearch(TextDocument doc) {
    _matches = [];
    _currentIndex = -1;

    if (_query.isEmpty) {
      notifyListeners();
      return;
    }

    RegExp? regExp;
    try {
      if (_isRegex) {
        regExp = RegExp(_query, caseSensitive: _isMatchCase);
      } else {
        regExp = RegExp(RegExp.escape(_query), caseSensitive: _isMatchCase);
      }
    } catch (_) {
      notifyListeners();
      return;
    }

    final lines = doc.lines;
    for (var r = 0; r < lines.length; r++) {
      final line = lines[r];
      final regMatches = regExp.allMatches(line);
      for (final m in regMatches) {
        _matches.add(SearchMatch(
          start: TextPosition(r, m.start),
          end: TextPosition(r, m.end),
        ));
      }
    }

    if (_matches.isNotEmpty) {
      _currentIndex = 0;
    }
    notifyListeners();
  }
}
