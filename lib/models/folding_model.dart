import 'package:flutter/foundation.dart';
import '../models/document.dart';

class FoldRegion {
  const FoldRegion({
    required this.startLine,
    required this.endLine,
  });

  final int startLine;
  final int endLine;
}

class FoldingModel extends ChangeNotifier {
  final Set<int> _foldedStartLines = {};

  Set<int> get foldedStartLines => Set.unmodifiable(_foldedStartLines);

  bool isLineFolded(int line) => _foldedStartLines.contains(line);

  void toggleFold(int startLine) {
    if (_foldedStartLines.contains(startLine)) {
      _foldedStartLines.remove(startLine);
    } else {
      _foldedStartLines.add(startLine);
    }
    notifyListeners();
  }

  List<FoldRegion> calculateFoldRegions(TextDocument doc) {
    final lines = doc.lines;
    final regions = <FoldRegion>[];
    final stack = <int>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('{')) {
        stack.add(i);
      }
      if (line.contains('}') && stack.isNotEmpty) {
        final start = stack.removeLast();
        if (i > start) {
          regions.add(FoldRegion(startLine: start, endLine: i));
        }
      }
    }
    return regions;
  }

  bool isLineHidden(int lineIndex, List<FoldRegion> regions) {
    for (final startLine in _foldedStartLines) {
      final match = regions.where((r) => r.startLine == startLine);
      if (match.isNotEmpty) {
        final region = match.first;
        if (lineIndex > region.startLine && lineIndex <= region.endLine) {
          return true;
        }
      }
    }
    return false;
  }
}
