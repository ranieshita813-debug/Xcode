import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import 'package:path/path.dart' as p;
import '../models/project_search_model.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'common.dart';

class ProjectSearchPanel extends StatefulWidget {
  const ProjectSearchPanel({
    super.key,
    required this.searchModel,
    required this.onSelectResult,
    required this.onClose,
  });

  final ProjectSearchModel searchModel;
  final Function(String path, int line, int col) onSelectResult;
  final VoidCallback onClose;

  @override
  State<ProjectSearchPanel> createState() => _ProjectSearchPanelState();
}

class _ProjectSearchPanelState extends State<ProjectSearchPanel> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.searchModel.query;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return ListenableBuilder(
      listenable: widget.searchModel,
      builder: (context, _) {
        final results = widget.searchModel.results;

        return Material(
          color: c.surface,
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(right: BorderSide(color: c.border)),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Text('SEARCH',
                          style: LatticeText.ui(12,
                              weight: FontWeight.w600, color: c.textMuted)),
                      const Spacer(),
                      LIconButton(
                        icon: iconoir.Xmark(color: c.text, width: 16, height: 16),
                        onTap: widget.onClose,
                      ),
                    ],
                  ),
                ),
                // Search Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: c.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      children: [
                        iconoir.Search(color: c.textMuted, width: 16, height: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: LatticeText.ui(13, color: c.text),
                            cursorColor: c.accent,
                            decoration: InputDecoration(
                              hintText: 'Search across files',
                              hintStyle: LatticeText.ui(13, color: c.textFaint),
                              isCollapsed: true,
                              border: InputBorder.none,
                            ),
                            onChanged: (val) => widget.searchModel.updateQuery(val),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Options Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text('.*', style: LatticeText.mono(11, color: widget.searchModel.isRegex ? c.onAccent : c.text)),
                        selected: widget.searchModel.isRegex,
                        selectedColor: c.accent,
                        onSelected: (_) => widget.searchModel.toggleRegex(),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: Text('Aa', style: LatticeText.ui(11, color: widget.searchModel.isMatchCase ? c.onAccent : c.text)),
                        selected: widget.searchModel.isMatchCase,
                        selectedColor: c.accent,
                        onSelected: (_) => widget.searchModel.toggleMatchCase(),
                      ),
                      const Spacer(),
                      Text('${results.length} results',
                          style: LatticeText.ui(11, color: c.textMuted)),
                    ],
                  ),
                ),
                const Divider(height: 16),
                // Results List
                Expanded(
                  child: ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index];
                      final fileName = p.basename(item.filePath);

                      return InkWell(
                        onTap: () => widget.onSelectResult(item.filePath, item.line, item.col),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  iconoir.Page(color: c.accent, width: 14, height: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$fileName:${item.line + 1}',
                                    style: LatticeText.ui(12, weight: FontWeight.w600, color: c.text),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.lineText.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: LatticeText.mono(11, color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
