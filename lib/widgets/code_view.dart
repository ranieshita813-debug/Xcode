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
import '../services/lsp_service.dart';
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
    final initialOffset = rowColToOffset(widget.model.lines, widget.model.row, widget.model.col);
    _codeController.selection = TextSelection.collapsed(offset: initialOffset);
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

    if (_codeController.selection.isValid) {
      final extentOffset = _codeController.selection.extentOffset;
      final (r, c) = offsetToRowCol(widget.model.lines, extentOffset);
      if (r != widget.model.row || c != widget.model.col) {
        _updatingFromModel = true;
        widget.model.moveTo(r, c);
        _updatingFromModel = false;
      }
    }
  }

  void _onModelChanged() {
    if (_updatingFromModel) return;

    _updatingFromModel = true;
    if (_codeController.text != widget.model.text) {
      _codeController.text = widget.model.text;
    }

    final modelOffset = rowColToOffset(widget.model.lines, widget.model.row, widget.model.col);
    if (_codeController.selection.extentOffset != modelOffset) {
      _codeController.selection = TextSelection.collapsed(offset: modelOffset);
    }
    _updatingFromModel = false;
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
    final baseStyles = isDark ? atomOneDarkTheme : atomOneLightTheme;
    final themeStyles = Map<String, TextStyle>.from(baseStyles);
    themeStyles['root'] = (themeStyles['root'] ?? const TextStyle()).copyWith(
      backgroundColor: c.bg,
    );

    final textStyle = LatticeText.mono(
      s.fontSize,
      fontFamily: s.fontFamily,
      color: c.text,
    );

    return CodeTheme(
      data: CodeThemeData(styles: themeStyles),
      child: Container(
        color: c.bg,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: CodeField(
                controller: _codeController,
                textStyle: textStyle,
                background: c.bg,
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
            if (widget.model.suggestions.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _AutocompleteOverlay(
                  model: widget.model,
                  onSelect: (s) {
                    widget.model.applySuggestion(s);
                  },
                ),
              )
            else if (widget.model.signatureHelp != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _SignatureHelpOverlay(
                  help: widget.model.signatureHelp!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SignatureHelpOverlay extends StatelessWidget {
  const _SignatureHelpOverlay({
    required this.help,
  });

  final LspSignatureHelp help;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (help.signatures.isEmpty) return const SizedBox.shrink();

    final sig = help.signatures[help.activeSignature.clamp(0, help.signatures.length - 1)];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Signature',
                style: LatticeText.ui(10, weight: FontWeight.w600, color: c.accent),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildSignatureText(sig, help.activeParameter, c),
          if (sig.documentation != null && sig.documentation!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              sig.documentation!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: LatticeText.ui(11, color: c.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignatureText(LspSignatureInfo sig, int activeParamIndex, LatticeColors c) {
    if (sig.parameters.isEmpty) {
      return Text(
        sig.label,
        style: LatticeText.mono(12, color: c.text),
      );
    }

    final spans = <InlineSpan>[];
    final activeIndex = activeParamIndex.clamp(0, sig.parameters.length - 1);

    for (var i = 0; i < sig.parameters.length; i++) {
      final param = sig.parameters[i];
      final isCurrent = i == activeIndex;

      if (i > 0) {
        spans.add(TextSpan(
          text: ', ',
          style: LatticeText.mono(12, color: c.textMuted),
        ));
      }

      spans.add(TextSpan(
        text: param.label,
        style: LatticeText.mono(
          12,
          color: isCurrent ? c.accent : c.text,
          weight: isCurrent ? FontWeight.bold : FontWeight.normal,
        ),
      ));
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${sig.label.split('(').first}(',
            style: LatticeText.mono(12, color: c.text),
          ),
          ...spans,
          TextSpan(
            text: ')',
            style: LatticeText.mono(12, color: c.text),
          ),
        ],
      ),
    );
  }
}

class _AutocompleteOverlay extends StatefulWidget {
  const _AutocompleteOverlay({
    required this.model,
    required this.onSelect,
  });

  final EditorModel model;
  final ValueChanged<Suggestion> onSelect;

  @override
  State<_AutocompleteOverlay> createState() => _AutocompleteOverlayState();
}

class _AutocompleteOverlayState extends State<_AutocompleteOverlay> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final suggestions = widget.model.suggestions;
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final safeIndex = _selectedIndex.clamp(0, suggestions.length - 1);
    final selectedItem = suggestions[safeIndex];

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: c.raised,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Row(
              children: [
                Text(
                  'IntelliSense',
                  style: LatticeText.ui(10, weight: FontWeight.w600, color: c.accent),
                ),
                const Spacer(),
                Text(
                  '${safeIndex + 1}/${suggestions.length}',
                  style: LatticeText.ui(10, color: c.textFaint),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: c.border),
              itemBuilder: (context, index) {
                final s = suggestions[index];
                final isSelected = index == safeIndex;
                return InkWell(
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    widget.onSelect(s);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    color: isSelected ? c.accentSoft : Colors.transparent,
                    child: Row(
                      children: [
                        _KindBadge(kind: s.kind),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            _highlightMatch(s.label, widget.model.prefix, c),
                            overflow: TextOverflow.ellipsis,
                            style: LatticeText.mono(12, color: c.text),
                          ),
                        ),
                        if (s.detail != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              s.detail!,
                              overflow: TextOverflow.ellipsis,
                              style: LatticeText.mono(11, color: c.textMuted),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (selectedItem.documentation != null && selectedItem.documentation!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.raised,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Text(
                selectedItem.documentation!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: LatticeText.ui(11, color: c.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  TextSpan _highlightMatch(String text, String prefix, LatticeColors c) {
    if (prefix.isEmpty) return TextSpan(text: text);
    final i = text.toLowerCase().indexOf(prefix.toLowerCase());
    if (i < 0) return TextSpan(text: text);

    return TextSpan(
      children: [
        if (i > 0) TextSpan(text: text.substring(0, i)),
        TextSpan(
          text: text.substring(i, i + prefix.length),
          style: TextStyle(
            color: c.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (i + prefix.length < text.length)
          TextSpan(text: text.substring(i + prefix.length)),
      ],
    );
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (kind.toLowerCase()) {
      'function' => ('fn', const Color(0xFF3B82F6)),
      'keyword' => ('kw', const Color(0xFFF97316)),
      'class' || 'type' => ('cl', const Color(0xFF10B981)),
      'variable' => ('var', const Color(0xFF8B5CF6)),
      'property' => ('prop', const Color(0xFFEC4899)),
      'tag' => ('tag', const Color(0xFF06B6D4)),
      _ => ('sym', const Color(0xFF6B7280)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
