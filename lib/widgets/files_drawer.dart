import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import '../theme/tokens.dart';
import '../theme/typography.dart';

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

// ───────────────────────── Icon theme ─────────────────────────

class _Glyph {
  const _Glyph(this.label, this.color);
  final String label;
  final Color color;
}

/// Badge-style file icons (label + tint), like Material Icon Theme.
_Glyph? _glyphFor(String name) {
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  switch (ext) {
    case 'ts':
      return const _Glyph('TS', Color(0xFF3B82F6));
    case 'tsx':
      return const _Glyph('TSX', Color(0xFF38BDF8));
    case 'dart':
      return const _Glyph('D', Color(0xFF22B8CF));
    case 'py':
      return const _Glyph('PY', Color(0xFFEAB308));
    case 'cpp':
      return const _Glyph('C++', Color(0xFF8B5CF6));
    case 'kt':
      return const _Glyph('KT', Color(0xFFF97316));
    case 'json':
      return const _Glyph('{}', Color(0xFFF59E0B));
    case 'md':
      return const _Glyph('MD', Color(0xFF94A3B8));
    default:
      return null;
  }
}

Color? _folderTint(String name) {
  switch (name) {
    case 'src':
      return const Color(0xFF3B82F6);
    case 'components':
      return const Color(0xFF8B5CF6);
    case 'assets':
      return const Color(0xFFF59E0B);
    default:
      return null;
  }
}

class _FileGlyph extends StatelessWidget {
  const _FileGlyph(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final g = _glyphFor(name);
    if (g == null) {
      return iconoir.Page(color: c.textMuted, width: 16, height: 16);
    }
    return Container(
      width: 22,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: g.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        g.label,
        style: LatticeText.ui(g.label.length > 2 ? 8 : 9,
            weight: FontWeight.w700, color: g.color),
      ),
    );
  }
}

// ───────────────────────── Drawer ─────────────────────────

/// Left side drawer: VS Code / PyCharm style project explorer.
/// Sections (OPEN EDITORS, project tree), compact rows, indent guides,
/// git decorations, and a status-bar style footer.
class FilesDrawer extends StatefulWidget {
  const FilesDrawer({
    super.key,
    required this.activeFile,
    required this.changeCount,
    required this.onOpenFile,
    required this.onOpenSettings,
    required this.onOpenSourceControl,
    this.openFiles = const [],
    this.customFiles = const [],
    this.customFolders = const [],
    this.projectName = 'lattice-app',
    this.branch = 'main',
    this.onNewFile,
    this.onNewFolder,
    this.onNewProject,
  });

  final String activeFile;
  final int changeCount;
  final List<String> openFiles;
  final List<String> customFiles;
  final List<String> customFolders;
  final String projectName;
  final String branch;
  final ValueChanged<String> onOpenFile;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenSourceControl;
  final VoidCallback? onNewFile;
  final VoidCallback? onNewFolder;
  final VoidCallback? onNewProject;

  @override
  State<FilesDrawer> createState() => _FilesDrawerState();
}

class _FilesDrawerState extends State<FilesDrawer> {
  final _q = TextEditingController();
  bool _editorsOpen = true;
  bool _projectOpen = true;

  List<_Node> get _currentTree {
    final list = List<_Node>.from(_tree);
    for (final folder in widget.customFolders) {
      if (!list.any((n) => n.name == folder)) {
        list.add(_Node(folder, 0, folder: true, open: true));
      }
    }
    for (final file in widget.customFiles) {
      if (!list.any((n) => n.name == file)) {
        list.add(_Node(file, 0));
      }
    }
    return list;
  }

  late final Set<int> _open = {
    for (var i = 0; i < _tree.length; i++)
      if (_tree[i].folder && _tree[i].open) i
  };

  List<int?> _buildParents(List<_Node> tree) {
    final stack = <int>[];
    final out = <int?>[];
    for (var i = 0; i < tree.length; i++) {
      while (stack.isNotEmpty && tree[stack.last].depth >= tree[i].depth) {
        stack.removeLast();
      }
      out.add(stack.isEmpty ? null : stack.last);
      if (tree[i].folder) stack.add(i);
    }
    return out;
  }

  Iterable<int> _ancestors(int i, List<int?> parentList) sync* {
    var p = parentList[i];
    while (p != null) {
      yield p;
      p = parentList[p];
    }
  }

  bool _dirty(int folder, List<_Node> tree) {
    for (var i = folder + 1;
        i < tree.length && tree[i].depth > tree[folder].depth;
        i++) {
      if (tree[i].status != null) return true;
    }
    return false;
  }

  String? _statusOf(String file, List<_Node> tree) {
    for (final n in tree) {
      if (!n.folder && n.name == file) return n.status;
    }
    return null;
  }

  List<int> _visible(String q, List<_Node> tree, List<int?> parentList) {
    if (q.isEmpty) {
      return [
        for (var i = 0; i < tree.length; i++)
          if (_ancestors(i, parentList).every(_open.contains)) i
      ];
    }
    final keep = <int>{};
    for (var i = 0; i < tree.length; i++) {
      if (!tree[i].folder && tree[i].name.toLowerCase().contains(q)) {
        keep.add(i);
        keep.addAll(_ancestors(i, parentList));
      }
    }
    return keep.toList()..sort();
  }

  /// Indent-guide that lights up for the folder containing the active file.
  Set<int> _activePathFolders(List<_Node> tree, List<int?> parentList) {
    final i = tree.indexWhere((n) => !n.folder && n.name == widget.activeFile);
    return i < 0 ? {} : _ancestors(i, parentList).toSet();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final currentTree = _currentTree;
    final parentList = _buildParents(currentTree);
    final q = _q.text.trim().toLowerCase();
    final rows = _visible(q, currentTree, parentList);
    final activeFolders = _activePathFolders(currentTree, parentList);
    final width = min(316.0, MediaQuery.of(context).size.width * 0.86);
    final showEditors = widget.openFiles.isNotEmpty && q.isEmpty;

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
            // ── Title bar: EXPLORER + view actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('EXPLORER',
                        style: LatticeText.ui(11,
                            weight: FontWeight.w600, color: c.textMuted)),
                  ),
                  IconButton(
                    tooltip: 'Collapse all',
                    constraints:
                        const BoxConstraints.tightFor(width: 36, height: 36),
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    color: c.textMuted,
                    onPressed: () => setState(_open.clear),
                    icon: const Icon(Icons.unfold_less),
                  ),
                  IconButton(
                    tooltip: 'More',
                    constraints:
                        const BoxConstraints.tightFor(width: 36, height: 36),
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    color: c.textMuted,
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz),
                  ),
                ],
              ),
            ),
            // ── Filter field
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
              child: Container(
                height: 36,
                padding: const EdgeInsets.only(left: 10, right: 4),
                decoration: BoxDecoration(
                  color: c.raised,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    iconoir.Search(color: c.textMuted, width: 15, height: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _q,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        style: LatticeText.ui(13, color: c.text),
                        cursorColor: c.accent,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Filter files',
                          hintStyle: LatticeText.ui(13, color: c.textFaint),
                        ),
                      ),
                    ),
                    if (q.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear',
                        constraints:
                            const BoxConstraints.tightFor(width: 28, height: 28),
                        padding: EdgeInsets.zero,
                        iconSize: 15,
                        color: c.textMuted,
                        onPressed: () => setState(_q.clear),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ),
            ),
            // ── Sections
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: Text('No matching files',
                          style: LatticeText.ui(13, color: c.textMuted)),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 8),
                      children: [
                        if (showEditors) ...[
                          _SectionHeader(
                            title: 'OPEN EDITORS',
                            expanded: _editorsOpen,
                            badge: '${widget.openFiles.length}',
                            onTap: () =>
                                setState(() => _editorsOpen = !_editorsOpen),
                          ),
                          if (_editorsOpen)
                            for (final f in widget.openFiles)
                              _OpenEditorRow(
                                name: f,
                                active: f == widget.activeFile,
                                status: _statusOf(f, currentTree),
                                onTap: () => widget.onOpenFile(f),
                              ),
                        ],
                        _SectionHeader(
                          title: widget.projectName.toUpperCase(),
                          expanded: _projectOpen || q.isNotEmpty,
                          actions: [
                            _HeaderAction(
                              tooltip: 'New file',
                              icon: iconoir.PagePlus(
                                  color: c.textMuted, width: 16, height: 16),
                              onTap: widget.onNewFile ?? () {},
                            ),
                            _HeaderAction(
                              tooltip: 'New folder',
                              icon: iconoir.FolderPlus(
                                  color: c.textMuted, width: 16, height: 16),
                              onTap: widget.onNewFolder ?? () {},
                            ),
                            if (widget.onNewProject != null)
                              _HeaderAction(
                                tooltip: 'New project',
                                icon: iconoir.PlusCircle(
                                    color: c.textMuted, width: 16, height: 16),
                                onTap: widget.onNewProject!,
                              ),
                          ],
                          onTap: () =>
                              setState(() => _projectOpen = !_projectOpen),
                        ),
                        if (_projectOpen || q.isNotEmpty)
                          for (final i in rows)
                            _TreeRow(
                              node: currentTree[i],
                              active: !currentTree[i].folder &&
                                  currentTree[i].name == widget.activeFile,
                              expanded: q.isNotEmpty || _open.contains(i),
                              dirty: currentTree[i].folder && _dirty(i, currentTree),
                              query: q,
                              guideFolders: activeFolders,
                              ancestors: _ancestors(i, parentList).toList(),
                              onTap: currentTree[i].folder
                                  ? () => setState(() {
                                        if (!_open.remove(i)) _open.add(i);
                                      })
                                  : () => widget.onOpenFile(currentTree[i].name),
                            ),
                      ],
                    ),
            ),
            // ── Status-bar style footer
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: c.raised,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: widget.onOpenSourceControl,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            iconoir.GitBranch(
                                color: c.accent, width: 14, height: 14),
                            const SizedBox(width: 6),
                            Text(widget.branch,
                                style: LatticeText.ui(12,
                                    weight: FontWeight.w600, color: c.text)),
                            const SizedBox(width: 10),
                            if (widget.changeCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c.warning.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text('${widget.changeCount}',
                                    style: LatticeText.ui(11,
                                        weight: FontWeight.w600,
                                        color: c.warning)),
                              )
                            else
                              Text('No changes',
                                  style: LatticeText.ui(12,
                                      color: c.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Settings',
                    constraints:
                        const BoxConstraints.tightFor(width: 44, height: 40),
                    padding: EdgeInsets.zero,
                    onPressed: widget.onOpenSettings,
                    icon: iconoir.Settings(
                        color: c.textMuted, width: 17, height: 17),
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

// ───────────────────────── Pieces ─────────────────────────

class _HeaderAction extends StatelessWidget {
  const _HeaderAction(
      {required this.tooltip, required this.icon, required this.onTap});
  final String tooltip;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 32, height: 28),
      padding: EdgeInsets.zero,
      onPressed: onTap,
      icon: icon,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.expanded,
    required this.onTap,
    this.badge,
    this.actions = const [],
  });
  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final String? badge;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      expanded: expanded,
      label: title,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.only(left: 8, right: 4),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: Row(
            children: [
              expanded
                  ? iconoir.NavArrowDown(
                      color: c.textMuted, width: 16, height: 16)
                  : iconoir.NavArrowRight(
                      color: c.textMuted, width: 16, height: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(title,
                    overflow: TextOverflow.ellipsis,
                    style: LatticeText.ui(11,
                        weight: FontWeight.w700, color: c.text)),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge!,
                      style: LatticeText.ui(10,
                          weight: FontWeight.w600, color: c.accent)),
                ),
              ],
              const Spacer(),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

Color _statusColor(dynamic c, String? s) =>
    s == 'A' ? c.success : (s == 'M' ? c.warning : c.text);

class _OpenEditorRow extends StatelessWidget {
  const _OpenEditorRow({
    required this.name,
    required this.active,
    required this.status,
    required this.onTap,
  });
  final String name;
  final bool active;
  final String? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: active ? c.accentSoft : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 34,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Row(
              children: [
                Icon(Icons.close, size: 14, color: c.textFaint),
                const SizedBox(width: 8),
                _FileGlyph(name),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name,
                      overflow: TextOverflow.ellipsis,
                      style: LatticeText.ui(13.5,
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          color: _statusColor(c, status))),
                ),
                if (status != null)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: _statusColor(c, status), shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TreeRow extends StatelessWidget {
  const _TreeRow({
    required this.node,
    required this.active,
    required this.expanded,
    required this.dirty,
    required this.query,
    required this.guideFolders,
    required this.ancestors,
    this.onTap,
  });
  final _Node node;
  final bool active, expanded, dirty;
  final String query;
  final Set<int> guideFolders;
  final List<int> ancestors;
  final VoidCallback? onTap;

  static const double _indent = 16;
  static const double _base = 10;

  Widget _label(dynamic c) {
    final style = LatticeText.ui(
      13.5,
      weight: active ? FontWeight.w600 : FontWeight.w400,
      color: _statusColor(c, node.status),
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
              color: c.accent,
              backgroundColor: c.accentSoft,
              fontWeight: FontWeight.w700),
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
    final folderTint = _folderTint(node.name) ?? c.textMuted;

    return Semantics(
      button: true,
      selected: active,
      expanded: node.folder ? expanded : null,
      label: node.name,
      child: Material(
        color: active ? c.accentSoft : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 34,
            child: Stack(
              children: [
                // indent guides (one per ancestor level, lit on active path)
                for (var d = 0; d < node.depth; d++)
                  Positioned(
                    left: _base + 8 + d * _indent,
                    top: 0,
                    bottom: 0,
                    width: 1,
                    child: ColoredBox(
                      color: d < ancestors.length &&
                              guideFolders
                                  .contains(ancestors[ancestors.length - 1 - d])
                          ? c.textFaint
                          : c.border,
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(
                      left: _base + node.depth * _indent, right: 12),
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
                      const SizedBox(width: 4),
                      if (node.folder)
                        Icon(
                          expanded
                              ? Icons.folder_open_rounded
                              : Icons.folder_rounded,
                          size: 18,
                          color: folderTint,
                        )
                      else
                        _FileGlyph(node.name),
                      const SizedBox(width: 8),
                      Expanded(child: _label(c)),
                      if (node.status != null)
                        Text(
                          node.status!,
                          style: LatticeText.ui(11.5,
                              weight: FontWeight.w700,
                              color: _statusColor(c, node.status)),
                        )
                      else if (dirty)
                        Container(
                          width: 6,
                          height: 6,
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
    );
  }
}