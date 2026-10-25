import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import 'package:path/path.dart' as p;
import '../models/editor_model.dart';
import '../models/project_search_model.dart';
import '../models/search_model.dart';
import '../services/file_service.dart';
import '../services/session_service.dart';
import '../state/settings.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/code_view.dart';
import '../widgets/command_palette.dart';
import '../widgets/common.dart';
import '../widgets/files_drawer.dart';
import '../widgets/find_replace_widget.dart';
import '../widgets/keyboard.dart';
import '../widgets/project_search_panel.dart';
import '../widgets/terminal_panel.dart';
import 'settings_screen.dart';
import 'source_control_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> with WidgetsBindingObserver {
  final FileService _fileService = FileService();
  final SearchModel _searchModel = SearchModel();
  late final ProjectSearchModel _projectSearchModel;
  final SessionService _sessionService = SessionService();

  final _models = <String, EditorModel>{
    'editor.tsx': EditorModel.editorTsx(),
    'fs.ts': EditorModel.fsTs(),
    'App.tsx': EditorModel.appTsx(),
    'main.dart': EditorModel.mainDart(),
    'app.py': EditorModel.appPy(),
    'native.cpp': EditorModel.nativeCpp(),
    'Helper.kt': EditorModel.helperKt(),
  };
  final _openTabs = <String>['editor.tsx', 'main.dart', 'app.py'];
  String _active = 'editor.tsx';

  List<TreeNode> _dynamicNodes = [];

  bool _drawer = false;
  bool _terminal = false;
  bool _findPanel = false;
  bool _projectSearchPanel = false;
  String? _paletteQuery;
  int _paletteSel = 0;
  BuildResult _build = const BuildResult(errors: []);

  EditorModel get _model => _models[_active] ?? EditorModel(fileName: _active, lines: const ['']);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _projectSearchModel = ProjectSearchModel(fileService: _fileService);
    _initSessionAndStorage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _persistSession();
    }
  }

  Future<void> _refreshFileTree() async {
    final entities = await _fileService.listDirectoryEntities();
    final appDir = await _fileService.getAppDirectory();

    final nodes = <TreeNode>[];
    for (final e in entities) {
      final relPath = p.relative(e.path, from: appDir.path);
      if (relPath.startsWith('.')) continue;

      final isDir = e is Directory;
      final parts = p.split(relPath);
      final depth = parts.length - 1;
      nodes.add(TreeNode(
        parts.last,
        depth,
        folder: isDir,
        fullPath: relPath,
      ));
    }

    if (mounted) {
      setState(() {
        _dynamicNodes = nodes;
      });
    }
  }

  Future<void> _initSessionAndStorage() async {
    await _saveAllToStorage();
    await _refreshFileTree();
    final restored = await _sessionService.loadSession();
    if (restored != null && mounted) {
      setState(() {
        _openTabs.clear();
        _openTabs.addAll(restored.openTabs);
        if (_openTabs.contains(restored.activeTab)) {
          _active = restored.activeTab;
        } else if (_openTabs.isNotEmpty) {
          _active = _openTabs.first;
        }
      });
    }
  }

  Future<void> _persistSession() async {
    final cursors = <String, Map<String, int>>{};
    _models.forEach((key, model) {
      cursors[key] = {'row': model.row, 'col': model.col};
    });

    final state = SessionState(
      openTabs: _openTabs,
      activeTab: _active,
      cursors: cursors,
    );
    await _sessionService.saveSession(state);
  }

  Future<void> _saveAllToStorage() async {
    for (final entry in _models.entries) {
      await _fileService.writeFile(entry.key, entry.value.text);
    }
  }

  void _onKey(String k) {
    switch (k) {
      case Keys.backspace:
        _model.backspace();
      case Keys.enter:
        _model.newline();
      case Keys.left:
        _model.moveHorizontal(-1);
      case Keys.right:
        _model.moveHorizontal(1);
      case Keys.tab:
        _model.insert('  ');
      default:
        _model.insert(k);
    }
    _persistSession();
  }

  void _runCommand(PaletteCommand cmd) {
    setState(() {
      _paletteQuery = null;
      _paletteSel = 0;
    });
    switch (cmd.id) {
      case 'format.doc':
      case 'format.sel':
        _model.format();
      case 'goto.line':
        setState(() => _findPanel = true);
      case 'wrap':
        SettingsScope.of(context)
            .update((s) => s.wordWrap = !s.wordWrap);
      case 'run':
        _run();
    }
  }

  Future<void> _saveCurrentFile() async {
    await _fileService.writeFile(_active, _model.text);
    _model.markSaved();
    await _refreshFileTree();
    await _persistSession();
  }

  void _run() async {
    final src = _model.text;
    final lines = src.split('\n');
    final errors = <String>[];
    for (var i = 0; i < lines.length; i++) {
      final m = RegExp(r'(?<![\w$])setD(?![\w$])').firstMatch(lines[i]);
      if (m != null) {
        errors.add(
            "src/components/editor.tsx:${i + 1}:${m.start + 1} - error TS2304: Cannot find name 'setD'.");
      }
    }
    setState(() {
      _build = BuildResult(errors: errors);
      _terminal = true;
    });

    await _saveCurrentFile();

    if (mounted && SettingsScope.of(context).autoSave) {
      for (final entry in _models.entries) {
        await _fileService.writeFile(entry.key, entry.value.text);
        entry.value.markSaved();
      }
    }
  }

  Future<void> _openFile(String name) async {
    if (!_models.containsKey(name)) {
      if (await _fileService.exists(name)) {
        final content = await _fileService.readFile(name);
        _models[name] = EditorModel(
          fileName: name,
          lines: content.split('\n'),
        );
      } else {
        _models[name] = EditorModel(
          fileName: name,
          lines: const [''],
        );
      }
    }

    setState(() {
      if (!_openTabs.contains(name)) _openTabs.add(name);
      _active = name;
      _drawer = false;
      _projectSearchPanel = false;
    });
    _persistSession();
  }

  void _closeTab(String tab) {
    setState(() {
      _openTabs.remove(tab);
      if (_openTabs.isNotEmpty) {
        if (_active == tab) {
          _active = _openTabs.last;
        }
      } else {
        const newFile = 'untitled.txt';
        _models[newFile] = EditorModel(fileName: newFile, lines: const ['']);
        _openTabs.add(newFile);
        _active = newFile;
      }
    });
    _persistSession();
  }

  void _createNewTab() async {
    final newFile = 'untitled_${_openTabs.length + 1}.txt';
    _models[newFile] = EditorModel(fileName: newFile, lines: const ['']);
    await _fileService.createFile(newFile);
    await _refreshFileTree();
    setState(() {
      _openTabs.add(newFile);
      _active = newFile;
    });
    _persistSession();
  }

  void _createNewFolder() async {
    final folderName = 'new_folder_${_openTabs.length}';
    await _fileService.createFolder(folderName);
    await _refreshFileTree();
  }

  void _push(Widget page) {
    setState(() => _drawer = false);
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final media = MediaQuery.of(context);
    final paletteOpen = _paletteQuery != null;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: media.padding.top),
              _AppBar(
                title: _active,
                onMenu: () => setState(() => _drawer = true),
                onTitle: () => setState(() {
                  _paletteQuery = '';
                  _paletteSel = 0;
                }),
                onUndo: _model.undo,
                onRedo: _model.redo,
                onRun: _run,
                onSave: _saveCurrentFile,
                onFind: () => setState(() => _findPanel = !_findPanel),
                onProjectSearch: () => setState(() => _projectSearchPanel = !_projectSearchPanel),
              ),
              _Tabs(
                tabs: _openTabs,
                active: _active,
                models: _models,
                onSelect: (t) {
                  setState(() => _active = t);
                  _persistSession();
                },
                onClose: _closeTab,
                onNewTab: _createNewTab,
              ),
              _Breadcrumb(file: _active),
              Expanded(
                child: Stack(
                  children: [
                    CodeView(key: ValueKey(_active), model: _model),
                    if (_findPanel)
                      Positioned(
                        top: 10,
                        right: 12,
                        child: FindReplaceWidget(
                          model: _model,
                          searchModel: _searchModel,
                          onClose: () => setState(() => _findPanel = false),
                        ),
                      ),
                    if (_projectSearchPanel)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: ProjectSearchPanel(
                          searchModel: _projectSearchModel,
                          onSelectResult: (filePath, line, col) {
                            final fileName = filePath.split('/').last;
                            _openFile(fileName);
                            _model.moveTo(line, col);
                          },
                          onClose: () => setState(() => _projectSearchPanel = false),
                        ),
                      ),
                  ],
                ),
              ),
              if (_terminal)
                TerminalPanel(
                  result: _build,
                  onClose: () => setState(() => _terminal = false),
                )
              else
                ExtraKeys(onKey: _onKey),
            ],
          ),
          // Scrim + palette
          if (paletteOpen) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _paletteQuery = null),
                child: ColoredBox(color: c.scrim),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: media.padding.top + 12,
              child: CommandPalette(
                query: _paletteQuery!,
                selected: _paletteSel,
                onPick: _runCommand,
                onQueryChanged: (q) => setState(() => _paletteQuery = q),
              ),
            ),
          ],
          // Files drawer
          IgnorePointer(
            ignoring: !_drawer,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _drawer ? 1 : 0,
              child: GestureDetector(
                onTap: () => setState(() => _drawer = false),
                child: ColoredBox(
                  color: c.scrim,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: _drawer ? 0 : -330,
            top: 0,
            bottom: 0,
            child: FilesDrawer(
              activeFile: _active,
              changeCount: 3,
              onOpenFile: _openFile,
              onOpenSettings: () => _push(const SettingsScreen()),
              onOpenSourceControl: () => _push(const SourceControlScreen()),
              onCreateFile: _createNewTab,
              onCreateFolder: _createNewFolder,
              customNodes: _dynamicNodes.isNotEmpty ? _dynamicNodes : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.title,
    required this.onMenu,
    required this.onTitle,
    required this.onUndo,
    required this.onRedo,
    required this.onRun,
    required this.onSave,
    required this.onFind,
    required this.onProjectSearch,
  });

  final String title;
  final VoidCallback onMenu;
  final VoidCallback onTitle;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onRun;
  final VoidCallback onSave;
  final VoidCallback onFind;
  final VoidCallback onProjectSearch;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 12),
        child: Row(
          children: [
            LIconButton(
              icon: iconoir.Menu(color: c.text, width: 22, height: 22),
              iconSize: 22,
              onTap: onMenu,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onTitle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title,
                          style: LatticeText.ui(15,
                              weight: FontWeight.w600, color: c.text)),
                      const SizedBox(height: 1),
                      Text('lattice-app  ·  main',
                          style: LatticeText.ui(11, color: c.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            LIconButton(
              icon: iconoir.Folder(color: c.text, width: 18, height: 18),
              onTap: onProjectSearch,
            ),
            const SizedBox(width: 4),
            LIconButton(
              icon: iconoir.Search(color: c.text, width: 18, height: 18),
              onTap: onFind,
            ),
            const SizedBox(width: 4),
            LIconButton(
              icon: iconoir.FloppyDisk(color: c.text, width: 18, height: 18),
              onTap: onSave,
            ),
            const SizedBox(width: 4),
            LIconButton(
              icon: iconoir.Undo(color: c.text, width: 18, height: 18),
              onTap: onUndo,
            ),
            const SizedBox(width: 4),
            LIconButton(
              icon: iconoir.Redo(color: c.text, width: 18, height: 18),
              onTap: onRedo,
            ),
            const SizedBox(width: 4),
            LIconButton(
              icon: iconoir.Play(color: c.text, width: 18, height: 18),
              onTap: onRun,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.tabs,
    required this.active,
    required this.models,
    required this.onSelect,
    required this.onClose,
    required this.onNewTab,
  });

  final List<String> tabs;
  final String active;
  final Map<String, EditorModel> models;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onClose;
  final VoidCallback onNewTab;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final t in tabs)
            GestureDetector(
              onTap: () => onSelect(t),
              child: Container(
                color: t == active ? c.bg : Colors.transparent,
                child: Column(
                  children: [
                    Container(
                      height: 2,
                      color: t == active ? c.accent : Colors.transparent,
                    ),
                    SizedBox(
                      height: 39,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Text(
                              t,
                              style: LatticeText.ui(
                                13,
                                weight: t == active
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                color: t == active ? c.text : c.textMuted,
                              ),
                            ),
                            if (models[t] != null && models[t]!.dirty) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: c.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => onClose(t),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: iconoir.Xmark(
                                    color: c.textMuted, width: 12, height: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          InkWell(
            onTap: onNewTab,
            child: SizedBox(
              width: 44,
              child: Center(
                child: iconoir.Plus(color: c.textMuted, width: 18, height: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.file});
  final String file;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final style = LatticeText.ui(12, color: c.textMuted);
    final chev = iconoir.NavArrowRight(color: c.textFaint, width: 12, height: 12);
    return SizedBox(
      height: 28,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Text('src', style: style),
            const SizedBox(width: 4),
            chev,
            const SizedBox(width: 4),
            Text('components', style: style),
            const SizedBox(width: 4),
            chev,
            const SizedBox(width: 4),
            Text(file,
                style: LatticeText.ui(12,
                    weight: FontWeight.w500, color: c.text)),
          ],
        ),
      ),
    );
  }
}
