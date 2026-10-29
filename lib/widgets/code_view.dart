import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:highlight/highlight.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/kotlin.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/yaml.dart';

import '../models/editor_model.dart';
import '../models/folding_model.dart';
import '../state/settings.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

int rowColToOffset(List<String> lines, int row, int col) {
  var offset = 0;
  final r = row.clamp(0, lines.isEmpty ? 0 : lines.length - 1);
  for (var i = 0; i < r; i++) {
    offset += lines[i].length + 1;
  }
  final c = col.clamp(0, lines.isEmpty ? 0 : lines[r].length);
  return offset + c;
}

(int row, int col) offsetToRowCol(List<String> lines, int offset) {
  if (lines.isEmpty) return (0, 0);
  var current = 0;
  for (var i = 0; i < lines.length; i++) {
    final len = lines[i].length;
    if (offset <= current + len) return (i, offset - current);
    current += len + 1;
  }
  return (lines.length - 1, lines.last.length);
}

Mode? _getLanguageMode(String fileName) {
  final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
  switch (ext) {
    case 'dart':
      return dart;
    case 'py':
      return python;
    case 'ts':
    case 'tsx':
      return typescript;
    case 'js':
    case 'jsx':
      return javascript;
    case 'cpp':
    case 'c':
    case 'h':
    case 'hpp':
      return cpp;
    case 'kt':
    case 'kts':
      return kotlin;
    case 'java':
      return java;
    case 'json':
      return json;
    case 'md':
      return markdown;
    case 'yaml':
    case 'yml':
      return yaml;
    case 'xml':
    case 'html':
      return xml;
    case 'css':
      return css;
    default:
      return null;
  }
}

class CodeView extends StatefulWidget {
  const CodeView({
    super.key,
    required this.model,
    this.foldingModel,
  });

  final EditorModel model;
  final FoldingModel? foldingModel;

  @override
  State<CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<CodeView> {
  late CodeController _codeController;
  bool _updatingFromModel = false;

  @override
  void initState() {
    super.initState();
    _initController();
    widget.model.addListener(_onModelChanged);
  }

  void _initController() {
    final mode = _getLanguageMode(widget.model.fileName);
    _codeController = CodeController(
      text: widget.model.text,
      language: mode,
    );
    _codeController.addListener(_onCodeChanged);
  }

  @override
  void didUpdateWidget(CodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model) {
      oldWidget.model.removeListener(_onModelChanged);
      _codeController.removeListener(_onCodeChanged);
      _codeController.dispose();
      _initController();
      widget.model.addListener(_onModelChanged);
    }
  }

  void _onCodeChanged() {
    if (_updatingFromModel) return;
    if (_codeController.text != widget.model.text) {
      _updatingFromModel = true;
      widget.model.lines = _codeController.text.split('\n');
      widget.model.dirty = true;
      _updatingFromModel = false;
    }
  }

  void _onModelChanged() {
    if (_updatingFromModel) return;
    if (_codeController.text != widget.model.text) {
      _updatingFromModel = true;
      _codeController.text = widget.model.text;
      _updatingFromModel = false;
    }
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChanged);
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = SettingsScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeStyles = isDark ? atomOneDarkTheme : atomOneLightTheme;

    final textStyle = LatticeText.mono(
      s.fontSize,
      fontFamily: s.fontFamily,
      color: c.text,
    );

    return CodeTheme(
      data: CodeThemeData(styles: themeStyles),
      child: Container(
        color: c.bg,
        child: SingleChildScrollView(
          child: CodeField(
            controller: _codeController,
            textStyle: textStyle,
            gutterStyle: GutterStyle(
              showLineNumbers: s.lineNumbers,
              textStyle: LatticeText.mono(
                s.fontSize,
                fontFamily: s.fontFamily,
                color: c.textFaint,
              ),
              width: s.lineNumbers ? 42 : 12,
              margin: 8,
            ),
          ),
        ),
      ),
    );
  }
}
