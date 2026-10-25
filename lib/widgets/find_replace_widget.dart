import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import '../models/editor_model.dart';
import '../models/search_model.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'common.dart';

class FindReplaceWidget extends StatefulWidget {
  const FindReplaceWidget({
    super.key,
    required this.model,
    required this.searchModel,
    required this.onClose,
  });

  final EditorModel model;
  final SearchModel searchModel;
  final VoidCallback onClose;

  @override
  State<FindReplaceWidget> createState() => _FindReplaceWidgetState();
}

class _FindReplaceWidgetState extends State<FindReplaceWidget> {
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final TextEditingController _gotoController = TextEditingController();

  bool _showReplace = false;

  @override
  void initState() {
    super.initState();
    _findController.text = widget.searchModel.query;
    _replaceController.text = widget.searchModel.replaceQuery;
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    _gotoController.dispose();
    super.dispose();
  }

  void _jumpToMatch() {
    final cur = widget.searchModel.currentMatch;
    if (cur != null) {
      widget.model.moveTo(cur.start.row, cur.start.col);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListenableBuilder(
      listenable: widget.searchModel,
      builder: (context, _) {
        final matches = widget.searchModel.matches;
        final index = widget.searchModel.currentIndex;

        return Material(
          color: c.raised,
          borderRadius: BorderRadius.circular(12),
          elevation: 8,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Find Row
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _showReplace ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        size: 18,
                        color: c.textMuted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _showReplace = !_showReplace),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          controller: _findController,
                          style: LatticeText.ui(13, color: c.text),
                          cursorColor: c.accent,
                          decoration: InputDecoration(
                            hintText: 'Find',
                            hintStyle: LatticeText.ui(13, color: c.textFaint),
                            isCollapsed: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            fillColor: c.bg,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: c.border),
                            ),
                          ),
                          onChanged: (val) {
                            widget.searchModel.updateQuery(val, widget.model.document);
                            _jumpToMatch();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      matches.isEmpty ? 'No results' : '${index + 1}/${matches.length}',
                      style: LatticeText.ui(11, color: c.textMuted),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 16),
                      color: c.text,
                      onPressed: () {
                        widget.searchModel.previousMatch();
                        _jumpToMatch();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 16),
                      color: c.text,
                      onPressed: () {
                        widget.searchModel.nextMatch();
                        _jumpToMatch();
                      },
                    ),
                    LIconButton(
                      icon: iconoir.Xmark(color: c.text, width: 16, height: 16),
                      onTap: widget.onClose,
                    ),
                  ],
                ),
                // Replace Row
                if (_showReplace) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 24),
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            controller: _replaceController,
                            style: LatticeText.ui(13, color: c.text),
                            cursorColor: c.accent,
                            decoration: InputDecoration(
                              hintText: 'Replace',
                              hintStyle: LatticeText.ui(13, color: c.textFaint),
                              isCollapsed: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              fillColor: c.bg,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: c.border),
                              ),
                            ),
                            onChanged: (val) => widget.searchModel.updateReplaceQuery(val),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.find_replace, size: 18),
                        color: c.accent,
                        onPressed: () => widget.searchModel.replaceCurrent(widget.model),
                      ),
                      IconButton(
                        icon: const Icon(Icons.published_with_changes, size: 18),
                        color: c.accent,
                        onPressed: () => widget.searchModel.replaceAll(widget.model),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                // Toggles & Go To Line Row
                Row(
                  children: [
                    FilterChip(
                      label: Text('.*', style: LatticeText.mono(11, color: widget.searchModel.isRegex ? c.onAccent : c.text)),
                      selected: widget.searchModel.isRegex,
                      selectedColor: c.accent,
                      onSelected: (_) => widget.searchModel.toggleRegex(widget.model.document),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: Text('Aa', style: LatticeText.ui(11, color: widget.searchModel.isMatchCase ? c.onAccent : c.text)),
                      selected: widget.searchModel.isMatchCase,
                      selectedColor: c.accent,
                      onSelected: (_) => widget.searchModel.toggleMatchCase(widget.model.document),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 90,
                      height: 32,
                      child: TextField(
                        controller: _gotoController,
                        keyboardType: TextInputType.number,
                        style: LatticeText.ui(12, color: c.text),
                        decoration: InputDecoration(
                          hintText: 'Go line…',
                          hintStyle: LatticeText.ui(11, color: c.textFaint),
                          isCollapsed: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          fillColor: c.bg,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: c.border),
                          ),
                        ),
                        onSubmitted: (val) {
                          final line = int.tryParse(val);
                          if (line != null && line > 0) {
                            widget.model.moveTo(line - 1, 0);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
