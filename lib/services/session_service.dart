import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SessionState {
  SessionState({
    required this.openTabs,
    required this.activeTab,
    required this.cursors,
  });

  final List<String> openTabs;
  final String activeTab;
  final Map<String, Map<String, int>> cursors;

  Map<String, dynamic> toJson() => {
        'openTabs': openTabs,
        'activeTab': activeTab,
        'cursors': cursors,
      };

  factory SessionState.fromJson(Map<String, dynamic> json) {
    final tabs = (json['openTabs'] as List?)?.cast<String>() ?? ['editor.tsx'];
    final active = (json['activeTab'] as String?) ?? (tabs.isNotEmpty ? tabs.first : 'editor.tsx');
    final rawCursors = json['cursors'] as Map<String, dynamic>? ?? {};

    final parsedCursors = <String, Map<String, int>>{};
    rawCursors.forEach((key, val) {
      if (val is Map) {
        parsedCursors[key] = {
          'row': (val['row'] as num?)?.toInt() ?? 0,
          'col': (val['col'] as num?)?.toInt() ?? 0,
        };
      }
    });

    return SessionState(
      openTabs: tabs,
      activeTab: active,
      cursors: parsedCursors,
    );
  }
}

class SessionService {
  static const String _sessionFile = '.session_state.json';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_sessionFile');
  }

  Future<void> saveSession(SessionState state) async {
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(state.toJson()));
    } catch (_) {}
  }

  Future<SessionState?> loadSession() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return SessionState.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
