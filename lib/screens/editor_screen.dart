import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import '../models/editor_model.dart';
import '../services/file_service.dart';
import '../state/settings.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/code_view.dart';
import '../widgets/command_palette.dart';
import '../widgets/common.dart';
import '../widgets/files_drawer.dart';
import '../widgets/keyboard.dart';
import '../widgets/terminal_panel.dart';
import 'settings_screen.dart';
import 'source_control_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final FileService _fileService = FileService();

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

  bool _drawer = false;
  bool _terminal = false;
  bool _autoSave = false;
  String? _paletteQuery; // non-null => palette open
  int _paletteSel = 0;
  BuildResult _build = const BuildResult(errors: []);

  final _saveTimers = <String, Timer>{};
  final _listeners = <String, VoidCallback>{};

  EditorModel? get _model => _models[_active];

  static const double _drawerW = 330;

  @override
  void initState() {
    super.initState();
    _models.forEach(_watch);
    _seedStorage();
  }

  @override
  void dispose() {
    for (final t in _saveTimers.values) {
      t.cancel();
    }
    _listeners.forEach((name, l) => _models[name]?.removeListener(l));
    super.dispose();
  }

  /// Only seeds files that don't exist yet; never overwrites saved work.
  Future<void> _seedStorage() async {
    for (final e in _models.entries) {
      try {
        if (!await _fileService.exists(e.key)) {
          await _fileService.writeFile(e.key, e.value.text);
        }
      } catch (_) {}
    }
  }

  // ---- saving ------------------------------------------------------------

  void _watch(String name, EditorModel m) {
    void l() {
      if (_autoSave && m.dirty) {
        _saveTimers[name]?.cancel();
        _saveTimers[name] =
            Timer(const Duration(milliseconds: 800), () => _saveFile(name));
      }
    }

    _listeners[name] = l;
    m.addListener(l);
  }

  Future<bool> _saveFile(String name, {bool toast = false}) async {
    final m = _models[name];
    if (m == null) return false;
    try {
      await _fileService.writeFile(name, m.text);
      m.markSaved();
      if (toast && mounted) _toast('Saved $name');
      return true;
    } catch (_) {
      if (mounted) _toast("Couldn't save $name");
      return false;
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
  }

  // ---- input routing -----------------------------------------------------

  void _onKey(String k) {
    final m = _model;
    if (m == null) return;
    switch (k) {
      case Keys.backspace:
        m.backspace();
      case Keys.enter:
        m.newline();
      case Keys.left:
        m.moveHorizontal(-1);
      case Keys.right:
        m.moveHorizontal(1);
      case Keys.tab:
        m.insert('  ');
      default:
        m.insert(k);
    }
  }

  void _openPalette() => setState(() {
        _paletteQuery = '';
        _paletteSel = 0;
      });

  void _runCommand(PaletteCommand cmd) {
    setState(() {
      _paletteQuery = null;
      _paletteSel = 0;
    });
    switch (cmd.id) {
      case 'format.doc':
      case 'format.sel':
        _model?.format();
      case 'goto.line':
        _model?.moveTo(0, 0);
      case 'wrap':
        SettingsScope.of(context).update((s) => s.wordWrap = !s.wordWrap);
      case 'run':
        _run();
    }
  }

  // ---- actions -----------------------------------------------------------

  Future<void> _run() async {
    final m = _model;
    if (m == null) return;
    final errors = <String>[];

    for (final diag in m.diagnostics) {
      errors.add(diag.format());
    }

    if (errors.isEmpty) {
      final lines = m.text.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final hit = RegExp(r'(?<![\w$])setD(?![\w$])').firstMatch(lines[i]);
        if (hit != null) {
          errors.add(
              "$_active:${i + 1}:${hit.start + 1} - error TS2304: Cannot find name 'setD'.");
        }
      }
    }

    setState(() {
      _build = BuildResult(errors: errors);
      _terminal = true;
    });
    await _saveFile(_active);
    if (_autoSave) {
      for (final name in _models.keys.toList()) {
        if (_models[name]!.dirty) await _saveFile(name);
      }
    }
  }

  Future<void> _openFile(String name) async {
    if (!_models.containsKey(name)) {
      var lines = <String>[''];
      try {
        if (await _fileService.exists(name)) {
          lines = (await _fileService.readFile(name)).split('\n');
        }
      } catch (_) {
        if (mounted) _toast("Couldn't open $name");
        return;
      }
      final m = EditorModel(fileName: name, lines: lines);
      _models[name] = m;
      _watch(name, m);
    }
    if (!mounted) return;
    setState(() {
      if (!_openTabs.contains(name)) _openTabs.add(name);
      _active = name;
      _drawer = false;
    });
  }

  Future<void> _closeTab(String name) async {
    final m = _models[name];
    var discard = false;
    if (m != null && m.dirty) {
      final r = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Save changes to $name?'),
          content: const Text("Your changes will be lost if you don't save them."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'discard'), child: const Text("Don't save")),
            FilledButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('Save')),
          ],
        ),
      );
      if (r == null || r == 'cancel') return;
      if (r == 'save') {
        if (!await _saveFile(name)) return;
      } else {
        discard = true;
      }
    }
    if (!mounted) return;
    setState(() {
      final i = _openTabs.indexOf(name);
      _openTabs.remove(name);
      if (discard) {
        _saveTimers.remove(name)?.cancel();
        final l = _listeners.remove(name);
        if (l != null) m?.removeListener(l);
        _models.remove(name); // reopening reloads from disk
      }
      if (_active == name) {
        _active = _openTabs.isEmpty ? '' : _openTabs[min(i, _openTabs.length - 1)];
      }
    });
  }

  void _push(Widget page) {
    setState(() => _drawer = false);
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Map<ShortcutActivator, VoidCallback> _shortcuts() {
    final actions = <LogicalKeyboardKey, VoidCallback>{
      LogicalKeyboardKey.keyS: () => _saveFile(_active, toast: true),
      LogicalKeyboardKey.keyP: _openPalette,
      LogicalKeyboardKey.keyB: () => setState(() => _drawer = !_drawer),
      LogicalKeyboardKey.backquote: () => setState(() => _terminal = !_terminal),
      LogicalKeyboardKey.keyZ: () => _model?.undo(),
      LogicalKeyboardKey.keyY: () => _model?.redo(),
    };
    return {
      for (final e in actions.entries) ...{
        SingleActivator(e.key, control: true): e.value,
        SingleActivator(e.key, meta: true): e.value,
      }
    };
  }

  // ---- build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final media = MediaQuery.of(context);
    final paletteOpen = _paletteQuery != null;
    _autoSave = SettingsScope.of(context).autoSave;
    final drawerW = min(_drawerW, media.size.width * 0.86 + 14);
    final m = _model;

    return PopScope(
      canPop: !(_drawer || paletteOpen || _terminal),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() {
          if (paletteOpen) {
            _paletteQuery = null;
          } else if (_drawer) {
            _drawer = false;
          } else {
            _terminal = false;
          }
        });
      },
      child: Focus(
        autofocus: true,
        child: CallbackShortcuts(
          bindings: _shortcuts(),
          child: Scaffold(
            backgroundColor: c.bg,
            body: Stack(
              children: [
                Column(
                  children: [
                    SizedBox(height: media.padding.top),
                    _AppBar(
                      title: m == null ? 'Lattice' : _active,
                      onMenu: () => setState(() => _drawer = true),
                      onTitle: _openPalette,
                      onUndo: () => m?.undo(),
                      onRedo: () => m?.redo(),
                      onRun: _run,
                      onSave: () => _saveFile(_active, toast: true),
                    ),
                    _Tabs(
                      tabs: _openTabs,
                      active: _active,
                      models: _models,
                      onSelect: (t) => setState(() => _active = t),
                      onClose: _closeTab,
                      onNew: () => setState(() => _drawer = true),
                    ),
                    Expanded(
                      child: m == null
                          ? _EmptyState(onOpen: () => setState(() => _drawer = true))
                          : CodeView(key: ValueKey(_active), model: m),
                    ),
                    if (_terminal)
                      TerminalPanel(
                        result: _build,
                        onClose: () => setState(() => _terminal = false),
                      ),
                    SafeArea(top: false, child: ExtraKeys(onKey: _onKey)),
                  ],
                ),
                // Left-edge swipe opens the drawer.
                if (!_drawer)
                  Positioned(
                    left: 0,
                    top: media.padding.top + 100,
                    bottom: 80,
                    width: 18,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragUpdate: (d) {
                        if (d.delta.dx > 6) setState(() => _drawer = true);
                      },
                    ),
                  ),
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
                IgnorePointer(
                  ignoring: !_drawer,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _drawer ? 1 : 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _drawer = false),
                      child: ColoredBox(color: c.scrim, child: const SizedBox.expand()),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: _drawer ? 0 : -drawerW - 16,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onHorizontalDragEnd: (d) {
                      if ((d.primaryVelocity ?? 0) < -300) setState(() => _drawer = false);
                    },
                    child: FilesDrawer(
                      activeFile: _active,
                      changeCount: 3,
                      onOpenFile: _openFile,
                      onOpenSettings: () => _push(const SettingsScreen()),
                      onOpenSourceControl: () => _push(const SourceControlScreen()),
                    ),
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

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.title,
    required this.onMenu,
    required this.onTitle,
    required this.onUndo,
    required this.onRedo,
    required this.onRun,
    required this.onSave,
  });

  final String title;
  final VoidCallback onMenu, onTitle, onUndo, onRedo, onRun, onSave;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget tip(String msg, Widget child) => Tooltip(message: msg, child: child);
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 12),
        child: Row(
          children: [
            tip('Explorer',
                LIconButton(icon: iconoir.Menu(color: c.text, width: 22, height: 22), iconSize: 22, onTap: onMenu)),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LatticeText.ui(15, weight: FontWeight.w600, color: c.text)),
                      const SizedBox(height: 1),
                      Text('lattice-app  ·  main  ·  tap for commands',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LatticeText.ui(11, color: c.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            tip('Save', LIconButton(icon: iconoir.FloppyDisk(color: c.text, width: 18, height: 18), onTap: onSave)),
            const SizedBox(width: 4),
            tip('Undo', LIconButton(icon: iconoir.Undo(color: c.text, width: 18, height: 18), onTap: onUndo)),
            const SizedBox(width: 4),
            tip('Redo', LIconButton(icon: iconoir.Redo(color: c.text, width: 18, height: 18), onTap: onRedo)),
            const SizedBox(width: 4),
            tip('Run', LIconButton(icon: iconoir.Play(color: c.text, width: 18, height: 18), onTap: onRun)),
          ],
        ),
      ),
    );
  }
}

class _Tabs extends StatefulWidget {
  const _Tabs({
    required this.tabs,
    required this.active,
    required this.models,
    required this.onSelect,
    required this.onClose,
    required this.onNew,
  });

  final List<String> tabs;
  final String active;
  final Map<String, EditorModel> models;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onClose;
  final VoidCallback onNew;

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  final _keys = <String, GlobalKey>{};

  @override
  void didUpdateWidget(_Tabs old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[widget.active]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 200), alignment: 0.5);
        }
      });
    }
  }

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
          for (final t in widget.tabs)
            _TabItem(
              key: _keys.putIfAbsent(t, GlobalKey.new),
              name: t,
              active: t == widget.active,
              model: widget.models[t],
              onTap: () => widget.onSelect(t),
              onClose: () => widget.onClose(t),
            ),
          SizedBox(
            width: 44,
            child: IconButton(
              tooltip: 'Open file',
              onPressed: widget.onNew,
              icon: iconoir.Plus(color: c.textMuted, width: 18, height: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    super.key,
    required this.name,
    required this.active,
    required this.model,
    required this.onTap,
    required this.onClose,
  });
  final String name;
  final bool active;
  final EditorModel? model;
  final VoidCallback onTap, onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      selected: active,
      label: name,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 96, maxWidth: 200),
          decoration: BoxDecoration(
            color: active ? c.bg : Colors.transparent,
            border: Border(right: BorderSide(color: c.border)),
          ),
          child: Column(
            children: [
              Container(height: 2, color: active ? c.accent : Colors.transparent),
              SizedBox(
                height: 39,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: LatticeText.ui(13,
                              weight: active ? FontWeight.w500 : FontWeight.w400,
                              color: active ? c.text : c.textMuted),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Dirty dot swaps to a close button, like VS Code.
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: model == null
                            ? const SizedBox.shrink()
                            : ListenableBuilder(
                                listenable: model!,
                                builder: (_, __) => InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: onClose,
                                  child: Center(
                                    child: model!.dirty
                                        ? Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                                color: c.warning, shape: BoxShape.circle),
                                          )
                                        : Icon(Icons.close,
                                            size: 15,
                                            color: active ? c.textMuted : c.textFaint),
                                  ),
                                ),
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconoir.Page(color: c.textFaint, width: 40, height: 40),
          const SizedBox(height: 12),
          Text('No file open', style: LatticeText.ui(15, weight: FontWeight.w500, color: c.text)),
          const SizedBox(height: 4),
          Text('Open a file from the explorer to start editing.',
              style: LatticeText.ui(13, color: c.textMuted)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onOpen, child: const Text('Open explorer')),
        ],
      ),
    );
  }
}