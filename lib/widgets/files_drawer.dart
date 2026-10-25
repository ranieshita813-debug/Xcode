import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'common.dart';

class _Node {
  const _Node(this.name, this.depth,
      {this.folder = false, this.open = false, this.status});
  final String name;
  final int depth;
  final bool folder;
  final bool open;
  final String? status; // 'M' | 'A'
}

const _tree = <_Node>[
  _Node('src', 0, folder: true, open: true),
  _Node('components', 1, folder: true, open: true),
  _Node('editor.tsx', 2, status: 'M'),
  _Node('Tabs.tsx', 2, status: 'A'),
  _Node('fs.ts', 1, status: 'M'),
  _Node('App.tsx', 1),
  _Node('main.dart', 1),
  _Node('app.py', 1),
  _Node('native.cpp', 1),
  _Node('Helper.kt', 1),
  _Node('assets', 0, folder: true),
  _Node('package.json', 0),
  _Node('tsconfig.json', 0),
  _Node('README.md', 0),
];

/// File-type tint, like VS Code's icon themes.
Color? _extColor(String name) {
  switch (name.contains('.') ? name.split('.').last.toLowerCase() : '') {
    case 'ts':
    case 'tsx':
      return const Color(0xFF3B82F6);
    case 'dart':
      return const Color(0xFF22B8CF);
    case 'py':
      return const Color(0xFFEAB308);
    case 'cpp':
      return const Color(0xFF8B5CF6);
    case 'kt':
      return const Color(0xFFF97316);
    case 'json':
      return const Color(0xFFF59E0B);
    default:
      return null;
  }
}

/// Left side drawer: explorer with collapsible tree, live filter, git status.
class FilesDrawer extends StatefulWidget {
  const FilesDrawer({
    super.key,
    required this.activeFile,
    required this.changeCount,
    required this.onOpenFile,
    required this.onOpenSettings,
    required this.onOpenSourceControl,
    this.onNewFile,
    this.onNewFolder,
  });

  final String activeFile;
  final int changeCount;
  final ValueChanged<String> onOpenFile;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenSourceControl;
  final VoidCallback? onNewFile;
  final VoidCallback? onNewFolder;

  @override
  State<FilesDrawer> createState() => _FilesDrawerState();
}

class _FilesDrawerState extends State<FilesDrawer> {
  final _q = TextEditingController();
  late final Set<int> _open = {
    for (var i = 0; i < _tree.length; i++)
      if (_tree[i].folder && _tree[i].open) i
  };
  late final List<int?> _parent = _buildParents();

  List<int?> _buildParents() {
    final stack = <int>[];
    final out = <int?>[];
    for (var i = 0; i < _tree.length; i++) {
      while (stack.isNotEmpty && _tree[stack.last].depth >= _tree[i].depth) {
        stack.removeLast();
      }
      out.add(stack.isEmpty ? null : stack.last);
      if (_tree[i].folder) stack.add(i);
    }
    return out;
  }

  Iterable<int> _ancestors(int i) sync* {
    var p = _parent[i];
    while (p != null) {
      yield p;
      p = _parent[p];
    }
  }

  bool _dirty(int folder) {
    for (var i = folder + 1;
        i < _tree.length && _tree[i].depth > _tree[folder].depth;
        i++) {
      if (_tree[i].status != null) return true;
    }
    return false;
  }

  List<int> _visible(String q) {
    if (q.isEmpty) {
      return [
        for (var i = 0; i < _tree.length; i++)
          if (_ancestors(i).every(_open.contains)) i
      ];
    }
    final keep = <int>{};
    for (var i = 0; i < _tree.length; i++) {
      if (!_tree[i].folder && _tree[i].name.toLowerCase().contains(q)) {
        keep.add(i);
        keep.addAll(_ancestors(i));
      }
    }
    return keep.toList()..sort();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final q = _q.text.trim().toLowerCase();
    final rows = _visible(q);
    final width = min(316.0, MediaQuery.of(context).size.width * 0.86);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EXPLORER',
                            style: LatticeText.ui(11,
                                weight: FontWeight.w600, color: c.textFaint)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text('lattice-app',
                                  overflow: TextOverflow.ellipsis,
                                  style: LatticeText.ui(17,
                                      weight: FontWeight.w600, color: c.text)),
                            ),
                            const SizedBox(width: 8),
                            _BranchChip(label: 'main'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  LIconButton(
                      icon: iconoir.PagePlus(color: c.text, width: 18, height: 18),
                      size: 40,
                      onTap: widget.onNewFile ?? () {}),
                  LIconButton(
                      icon: iconoir.FolderPlus(color: c.text, width: 18, height: 18),
                      size: 40,
                      onTap: widget.onNewFolder ?? () {}),
                  IconButton(
                    tooltip: 'Collapse all',
                    constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    color: c.text,
                    onPressed: () => setState(_open.clear),
                    icon: const Icon(Icons.unfold_less),
                  ),
                ],
              ),
            ),
            // Search (live filter)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Container(
                height: 40,
                padding: const EdgeInsets.only(left: 12, right: 4),
                decoration: BoxDecoration(
                  color: c.raised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    iconoir.Search(color: c.textMuted, width: 16, height: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _q,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        style: LatticeText.ui(14, color: c.text),
                        cursorColor: c.accent,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Search files',
                          hintStyle: LatticeText.ui(14, color: c.textFaint),
                        ),
                      ),
                    ),
                    if (q.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear',
                        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                        padding: EdgeInsets.zero,
                        iconSize: 16,
                        color: c.textMuted,
                        onPressed: () => setState(_q.clear),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ),
            ),
            // Tree
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: Text('No matching files',
                          style: LatticeText.ui(13, color: c.textMuted)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      itemCount: rows.length,
                      itemBuilder: (_, k) {
                        final i = rows[k];
                        final n = _tree[i];
                        return _Row(
                          node: n,
                          active: !n.folder && n.name == widget.activeFile,
                          expanded: q.isNotEmpty || _open.contains(i),
                          dirty: n.folder && _dirty(i),
                          query: q,
                          onTap: n.folder
                              ? () => setState(() {
                                    if (!_open.remove(i)) _open.add(i);
                                  })
                              : () => widget.onOpenFile(n.name),
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: c.border),
            // Footer
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: widget.onOpenSettings,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            iconoir.Settings(color: c.textMuted, width: 18, height: 18),
                            const SizedBox(width: 10),
                            Text('Settings',
                                style: LatticeText.ui(14,
                                    weight: FontWeight.w500, color: c.text)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: widget.onOpenSourceControl,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: widget.changeCount > 0
                              ? c.warning.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.changeCount == 0
                              ? 'No changes'
                              : '${widget.changeCount} change${widget.changeCount == 1 ? '' : 's'}',
                          style: LatticeText.ui(12,
                              weight: FontWeight.w500,
                              color: widget.changeCount > 0 ? c.warning : c.textMuted),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchChip extends StatelessWidget {
  const _BranchChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 21,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconoir.GitBranch(color: c.accent, width: 12, height: 12),
          const SizedBox(width: 5),
          Text(label,
              style: LatticeText.ui(12, weight: FontWeight.w500, color: c.accent)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.node,
    required this.active,
    required this.expanded,
    required this.dirty,
    required this.query,
    this.onTap,
  });
  final _Node node;
  final bool active, expanded, dirty;
  final String query;
  final VoidCallback? onTap;

  Color _nameColor(dynamic c) {
    if (node.status == 'A') return c.success;
    if (node.status == 'M') return c.warning;
    return c.text;
  }

  Widget _label(dynamic c) {
    final style = LatticeText.ui(
      14,
      weight: active || node.folder ? FontWeight.w500 : FontWeight.w400,
      color: _nameColor(c),
    );
    final i = query.isEmpty ? -1 : node.name.toLowerCase().indexOf(query);
    if (i < 0) {
      return Text(node.name, overflow: TextOverflow.ellipsis, style: style);
    }
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: node.name.substring(0, i)),
        TextSpan(
          text: node.name.substring(i, i + query.length),
          style: style.copyWith(
              color: c.accent, backgroundColor: c.accentSoft, fontWeight: FontWeight.w600),
        ),
        TextSpan(text: node.name.substring(i + query.length)),
      ]),
      style: style,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final tint = _extColor(node.name);
    return Semantics(
      button: true,
      selected: active,
      expanded: node.folder ? expanded : null,
      label: node.name,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 1),
        child: Material(
          color: active ? c.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 40,
              child: Stack(
                children: [
                  // indent guides
                  for (var d = 0; d < node.depth; d++)
                    Positioned(
                      left: 14 + d * 18.0,
                      top: 0,
                      bottom: 0,
                      width: 1,
                      child: ColoredBox(color: c.border),
                    ),
                  if (active)
                    Positioned(
                      left: 0,
                      top: 8,
                      bottom: 8,
                      width: 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(left: 6 + node.depth * 18.0, right: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          child: node.folder
                              ? (expanded
                                  ? iconoir.NavArrowDown(
                                      color: c.textMuted, width: 16, height: 16)
                                  : iconoir.NavArrowRight(
                                      color: c.textMuted, width: 16, height: 16))
                              : null,
                        ),
                        const SizedBox(width: 8),
                        node.folder
                            ? iconoir.Folder(color: c.accent, width: 18, height: 18)
                            : iconoir.Page(
                                color: tint ?? c.textMuted, width: 18, height: 18),
                        const SizedBox(width: 8),
                        Expanded(child: _label(c)),
                        if (node.status != null)
                          Text(
                            node.status!,
                            style: LatticeText.ui(12,
                                weight: FontWeight.w600, color: _nameColor(c)),
                          )
                        else if (dirty)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                                color: c.warning, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}