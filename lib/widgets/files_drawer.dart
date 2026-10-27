import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'common.dart';

/// A file or folder, addressed by its full path ('src/components/Tabs.tsx').
class _Node {
  const _Node(this.path, {this.folder = false, this.status});
  final String path;
  final bool folder;
  final String? status; // 'M' | 'A'

  String get name => path.contains('/') ? path.substring(path.lastIndexOf('/') + 1) : path;
  int get depth => '/'.allMatches(path).length;
  String get parent => path.contains('/') ? path.substring(0, path.lastIndexOf('/')) : '';
}

const _initial = <_Node>[
  _Node('src', folder: true),
  _Node('src/components', folder: true),
  _Node('src/components/editor.tsx', status: 'M'),
  _Node('src/components/Tabs.tsx', status: 'A'),
  _Node('src/fs.ts', status: 'M'),
  _Node('src/App.tsx'),
  _Node('src/main.dart'),
  _Node('src/app.py'),
  _Node('src/native.cpp'),
  _Node('src/Helper.kt'),
  _Node('assets', folder: true),
  _Node('package.json'),
  _Node('tsconfig.json'),
  _Node('README.md'),
];

class _Pending {
  const _Pending({required this.folder, required this.dir});
  final bool folder; // header "new folder" button
  final String dir; // target directory ('' = project root)
}

/// Path prefixes of [path], nearest parent first.
List<String> _ancestorsOf(String path) {
  final segs = path.split('/');
  return [for (var i = segs.length - 1; i > 0; i--) segs.sublist(0, i).join('/')];
}

// ───────────────────────── Icon theme ─────────────────────────

class _Glyph {
  const _Glyph(this.label, this.color);
  final String label;
  final Color color;
}

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

/// Header buttons start an INLINE entry row inside the tree (no dialog).
/// Type a name or a path like `apo/ggg.txt`: missing folders are created.
/// A trailing `/` creates a folder. Enter or tapping away confirms; the ✕
/// button (or leaving it empty) cancels.
class FilesDrawer extends StatefulWidget {
  const FilesDrawer({
    super.key,
    required this.activeFile,
    required this.changeCount,
    required this.onOpenFile,
    required this.onOpenSettings,
    required this.onOpenSourceControl,
    this.openFiles = const [],
    this.projectName = 'lattice-app',
    this.branch = 'main',
    this.onCreate,
  });

  /// Matches either a node's full path or its bare name.
  final String activeFile;
  final int changeCount;
  final List<String> openFiles;
  final String projectName;
  final String branch;

  /// Receives the FULL PATH of the file to open (e.g. 'src/fs.ts').
  final ValueChanged<String> onOpenFile;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenSourceControl;

  /// Called after a file / folder is created. Persist it to disk here.
  final void Function(String path, bool isFolder)? onCreate;

  @override
  State<FilesDrawer> createState() => _FilesDrawerState();
}

class _FilesDrawerState extends State<FilesDrawer> {
  final _q = TextEditingController();
  final List<_Node> _items = List.of(_initial);
  final Set<String> _open = {'src', 'src/components'};
  bool _editorsOpen = true;
  bool _projectOpen = true;
  String? _selected; // last tapped path; decides where "new" is created
  _Pending? _pending;

  bool _isActive(_Node n) =>
      n.path == widget.activeFile || (!n.folder && n.name == widget.activeFile);

  _Node? _find(String key) {
    for (final n in _items) {
      if (n.path == key || (!n.folder && n.name == key)) return n;
    }
    return null;
  }

  /// Folders first, then A→Z, depth-first.
  List<_Node> _flat() {
    final byParent = <String, List<_Node>>{};
    for (final n in _items) {
      (byParent[n.parent] ??= []).add(n);
    }
    int cmp(_Node a, _Node b) {
      if (a.folder != b.folder) return a.folder ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }

    final out = <_Node>[];
    void walk(String p) {
      final kids = (byParent[p] ?? [])..sort(cmp);
      for (final k in kids) {
        out.add(k);
        if (k.folder) walk(k.path);
      }
    }

    walk('');
    return out;
  }

  bool _dirty(String folder) =>
      _items.any((n) => n.status != null && n.path.startsWith('$folder/'));

  List<_Node> _visible(List<_Node> flat, String q) {
    if (q.isEmpty) {
      return [
        for (final n in flat)
          if (_ancestorsOf(n.path).every(_open.contains)) n
      ];
    }
    final keep = <String>{};
    for (final n in flat) {
      if (!n.folder && n.name.toLowerCase().contains(q)) {
        keep.add(n.path);
        keep.addAll(_ancestorsOf(n.path));
      }
    }
    return [for (final n in flat) if (keep.contains(n.path)) n];
  }

  Set<String> _activePathFolders() {
    for (final n in _items) {
      if (!n.folder && _isActive(n)) return _ancestorsOf(n.path).toSet();
    }
    return {};
  }

  // ---- inline create ------------------------------------------------------

  String _targetDir() {
    final s = _selected;
    if (s == null) return '';
    final n = _find(s);
    if (n == null) return '';
    return n.folder ? n.path : n.parent;
  }

  void _startCreate({required bool folder}) {
    setState(() {
      _q.clear();
      _projectOpen = true;
      final dir = _targetDir();
      if (dir.isNotEmpty) {
        _open.add(dir);
        _open.addAll(_ancestorsOf(dir));
      }
      _pending = _Pending(folder: folder, dir: dir);
    });
  }

  static final _badChars = RegExp(r'[\\:*?"<>|]');

  /// Returns an error message, or null when [raw] is a valid new path.
  String? _validate(String raw) {
    final p = _pending;
    if (p == null) return null;
    var t = raw.trim();
    if (t.isEmpty) return null;
    if (t.startsWith('/')) return 'A name cannot start with a slash';
    t = t.replaceAll(RegExp(r'/+$'), '');
    if (_badChars.hasMatch(t)) return 'Invalid character in name';
    final segs = t.split('/');
    if (segs.any((s) => s.isEmpty || s == '.' || s == '..' || s.trim() != s)) {
      return 'Invalid name';
    }
    final full = p.dir.isEmpty ? t : '${p.dir}/$t';
    if (_items.any((n) => n.path == full)) {
      return '"${segs.last}" already exists here';
    }
    for (final a in _ancestorsOf(full)) {
      final hit = _items.where((n) => n.path == a);
      if (hit.isNotEmpty && !hit.first.folder) {
        return '"${a.split('/').last}" is a file, not a folder';
      }
    }
    return null;
  }

  void _create(String raw) {
    final p = _pending;
    if (p == null) return;
    var t = raw.trim();
    final trailing = t.endsWith('/');
    t = t.replaceAll(RegExp(r'/+$'), '');
    final isFolder = p.folder || trailing;
    final full = p.dir.isEmpty ? t : '${p.dir}/$t';
    final segs = full.split('/');
    setState(() {
      var acc = '';
      for (var i = 0; i < segs.length; i++) {
        acc = i == 0 ? segs[0] : '$acc/${segs[i]}';
        final last = i == segs.length - 1;
        final asFolder = !last || isFolder;
        if (!_items.any((n) => n.path == acc)) {
          _items.add(_Node(acc, folder: asFolder, status: asFolder ? null : 'A'));
        }
        if (asFolder) _open.add(acc);
      }
      _pending = null;
      _selected = full;
    });
    widget.onCreate?.call(full, isFolder);
    if (!isFolder) widget.onOpenFile(full);
  }

  void _cancelCreate() {
    if (_pending != null && mounted) setState(() => _pending = null);
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
    final flat = _flat();
    final rows = _visible(flat, q);
    final activeFolders = _activePathFolders();
    final width = min(316.0, MediaQuery.of(context).size.width * 0.86);
    final showEditors = widget.openFiles.isNotEmpty && q.isEmpty;
    final pending = q.isEmpty ? _pending : null;

    final tree = <Widget>[];
    Widget entryRow(int depth) => _NewEntryRow(
          key: const ValueKey('new-entry'),
          depth: depth,
          folder: pending!.folder,
          validate: _validate,
          onSubmit: _create,
          onCancel: _cancelCreate,
        );
    if (pending != null && pending.dir.isEmpty) tree.add(entryRow(0));
    for (final n in rows) {
      final expanded = q.isNotEmpty || _open.contains(n.path);
      tree.add(_TreeRow(
        node: n,
        active: _isActive(n),
        selected: n.path == _selected,
        expanded: expanded,
        dirty: n.folder && _dirty(n.path),
        query: q,
        guideFolders: activeFolders,
        ancestors: _ancestorsOf(n.path),
        onTap: () => setState(() {
          _selected = n.path;
          if (n.folder) {
            if (!_open.remove(n.path)) _open.add(n.path);
          }
          if (!n.folder) widget.onOpenFile(n.path);
        }),
      ));
      if (pending != null && n.folder && pending.dir == n.path && expanded) {
        tree.add(entryRow(n.depth + 1));
      }
    }

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
            // ── Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.projectName,
                            overflow: TextOverflow.ellipsis,
                            style: LatticeText.ui(17,
                                weight: FontWeight.w600, color: c.text)),
                        const SizedBox(height: 4),
                        Container(
                          height: 21,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: c.accentSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              iconoir.GitBranch(
                                  color: c.accent, width: 12, height: 12),
                              const SizedBox(width: 5),
                              Text(widget.branch,
                                  style: LatticeText.ui(12,
                                      weight: FontWeight.w500,
                                      color: c.accent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'New file',
                    child: LIconButton(
                        icon: iconoir.PagePlus(
                            color: c.text, width: 18, height: 18),
                        size: 36,
                        onTap: () => _startCreate(folder: false)),
                  ),
                  const SizedBox(width: 10),
                  Tooltip(
                    message: 'New folder',
                    child: LIconButton(
                        icon: iconoir.FolderPlus(
                            color: c.text, width: 18, height: 18),
                        size: 36,
                        onTap: () => _startCreate(folder: true)),
                  ),
                ],
              ),
            ),
            // ── Filter field
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
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
              child: rows.isEmpty && pending == null
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
                                name: f.split('/').last,
                                active: f == widget.activeFile ||
                                    f.split('/').last == widget.activeFile,
                                status: _find(f)?.status,
                                onTap: () => widget.onOpenFile(_find(f)?.path ?? f),
                              ),
                        ],
                        _SectionHeader(
                          title: widget.projectName.toUpperCase(),
                          expanded: _projectOpen || q.isNotEmpty,
                          actions: [
                            _HeaderAction(
                              tooltip: 'Collapse all',
                              icon: Icon(Icons.unfold_less,
                                  size: 16, color: c.textMuted),
                              onTap: () => setState(() {
                                _open.clear();
                                _selected = null;
                              }),
                            ),
                          ],
                          // Tapping the project row also targets the root.
                          onTap: () => setState(() {
                            _projectOpen = !_projectOpen;
                            _selected = null;
                          }),
                        ),
                        if (_projectOpen || q.isNotEmpty) ...tree,
                      ],
                    ),
            ),
            // ── Footer
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
                            Text('Source control',
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

// ───────────────────────── Inline entry row ─────────────────────────

class _NewEntryRow extends StatefulWidget {
  const _NewEntryRow({
    super.key,
    required this.depth,
    required this.folder,
    required this.validate,
    required this.onSubmit,
    required this.onCancel,
  });
  final int depth;
  final bool folder;
  final String? Function(String) validate;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;

  @override
  State<_NewEntryRow> createState() => _NewEntryRowState();
}

class _NewEntryRowState extends State<_NewEntryRow> {
  final _ctl = TextEditingController();
  final _focus = FocusNode();
  String? _error;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Scrollable.ensureVisible(context);
    });
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _ctl.dispose();
    super.dispose();
  }

  /// Like VS Code: leaving the field confirms a valid name, cancels otherwise.
  void _onFocus() {
    if (_focus.hasFocus || _done) return;
    final t = _ctl.text.trim();
    _done = true;
    if (t.isEmpty || widget.validate(t) != null) {
      widget.onCancel();
    } else {
      widget.onSubmit(t);
    }
  }

  void _submit() {
    final t = _ctl.text.trim();
    if (t.isEmpty) {
      _done = true;
      widget.onCancel();
      return;
    }
    final e = widget.validate(t);
    if (e != null) {
      setState(() => _error = e);
      return; // keep editing
    }
    _done = true;
    widget.onSubmit(t);
  }

  void _cancel() {
    _done = true;
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = _ctl.text.trim();
    final isFolder = widget.folder || text.endsWith('/');
    final leaf = text.replaceAll(RegExp(r'/+$'), '').split('/').last;
    final left = _TreeRow._base + widget.depth * _TreeRow._indent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: Padding(
            padding: EdgeInsets.only(left: left, right: 6),
            child: Row(
              children: [
                const SizedBox(width: 20),
                if (isFolder)
                  Icon(Icons.folder_rounded, size: 18, color: c.textMuted)
                else
                  _FileGlyph(leaf),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: c.raised,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: _error != null ? c.error : c.accent),
                    ),
                    child: TextField(
                      controller: _ctl,
                      focusNode: _focus,
                      autofocus: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      // onEditingComplete (not onSubmitted) so the field keeps
                      // focus when the name is invalid.
                      onEditingComplete: _submit,
                      onChanged: (v) => setState(() {
                        _error = widget.validate(v);
                      }),
                      style: LatticeText.ui(13, color: c.text),
                      cursorColor: c.accent,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: widget.folder
                            ? 'folder or path/to/folder'
                            : 'file.ext or folder/file.ext',
                        hintStyle: LatticeText.ui(13, color: c.textFaint),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cancel',
                  constraints:
                      const BoxConstraints.tightFor(width: 32, height: 32),
                  padding: EdgeInsets.zero,
                  iconSize: 15,
                  color: c.textMuted,
                  // Prevent the tap from first causing a focus-loss "confirm".
                  onPressed: _cancel,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ),
        if (_error != null)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(left: left + 44, right: 10, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: c.error.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: c.error),
            ),
            child: Text(_error!,
                style: LatticeText.ui(12, color: c.error)),
          ),
      ],
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
    required this.selected,
    required this.expanded,
    required this.dirty,
    required this.query,
    required this.guideFolders,
    required this.ancestors,
    this.onTap,
  });
  final _Node node;
  final bool active, selected, expanded, dirty;
  final String query;
  final Set<String> guideFolders;
  final List<String> ancestors; // nearest parent first
  final VoidCallback? onTap;

  static const double _indent = 16;
  static const double _base = 10;

  Widget _label(dynamic c) {
    final style = LatticeText.ui(
      13.5,
      weight: active ? FontWeight.w600 : FontWeight.w400,
      color: _statusColor(c, node.status),
    );
    final name = node.name;
    final i = query.isEmpty ? -1 : name.toLowerCase().indexOf(query);
    if (i < 0) {
      return Text(name, overflow: TextOverflow.ellipsis, style: style);
    }
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: name.substring(0, i)),
        TextSpan(
          text: name.substring(i, i + query.length),
          style: style.copyWith(
              color: c.accent,
              backgroundColor: c.accentSoft,
              fontWeight: FontWeight.w700),
        ),
        TextSpan(text: name.substring(i + query.length)),
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
        color: active
            ? c.accentSoft
            : (selected ? c.raised : Colors.transparent),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 34,
            child: Stack(
              children: [
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