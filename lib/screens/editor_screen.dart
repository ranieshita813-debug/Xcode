import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import '../models/editor_model.dart';
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
  String? _paletteQuery; // non-null => palette open
  int _paletteSel = 0;
  BuildResult _build = const BuildResult(errors: []);

  EditorModel get _model => _models[_active]!;

  // ---- input routing -----------------------------------------------------

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
        _model.moveTo(0, 0);
      case 'wrap':
        SettingsScope.of(context)
            .update((s) => s.wordWrap = !s.wordWrap);
      case 'run':
        _run();
    }
  }

  // ---- actions -----------------------------------------------------------

  void _run() {
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
    if (SettingsScope.of(context).autoSave) {
      _models.values.forEach((m) => m.markSaved());
    }
  }

  void _openFile(String name) {
    setState(() {
      if (_models.containsKey(name)) {
        if (!_openTabs.contains(name)) _openTabs.add(name);
        _active = name;
      }
      _drawer = false;
    });
  }

  void _push(Widget page) {
    setState(() => _drawer = false);
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  // ---- build -------------------------------------------------------------

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
              ),
              _Tabs(
                tabs: _openTabs,
                active: _active,
                models: _models,
                onSelect: (t) => setState(() => _active = t),
              ),
              _Breadcrumb(file: _active),
              Expanded(child: CodeView(key: ValueKey(_active), model: _model)),
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
  });

  final String title;
  final VoidCallback onMenu;
  final VoidCallback onTitle;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onRun;

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
                onTap: onTitle, // opens the command palette
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
  });

  final List<String> tabs;
  final String active;
  final Map<String, EditorModel> models;
  final ValueChanged<String> onSelect;

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
                        padding: const EdgeInsets.symmetric(horizontal: 14),
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
                            if (models[t]!.dirty) ...[
                              const SizedBox(width: 8),
                              ListenableBuilder(
                                listenable: models[t]!,
                                builder: (_, __) => Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: models[t]!.dirty
                                        ? c.warning
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(
            width: 44,
            child: Center(
              child: iconoir.Plus(color: c.textMuted, width: 18, height: 18),
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
