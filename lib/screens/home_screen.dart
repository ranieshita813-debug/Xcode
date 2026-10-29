import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import '../state/settings.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/clone_dialog.dart';
import '../widgets/common.dart';
import 'editor_screen.dart';

/// JetBrains "New UI" inspired: flat panels, 1px hairlines, 6px radii,
/// a single blue accent, colored file-type badges, and a status bar.
const double _kRadius = 6;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: const [_ProjectTab(), SettingsScreenContent()],
        ),
      ),
      // Tool-window style bar: flat, labelled, accent underline on selection.
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                _NavItem(
                  label: 'Projects',
                  selected: _currentIndex == 0,
                  iconBuilder: (col) =>
                      iconoir.Folder(color: col, width: 20, height: 20),
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  label: 'Settings',
                  selected: _currentIndex == 1,
                  iconBuilder: (col) =>
                      iconoir.Settings(color: col, width: 20, height: 20),
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.selected,
    required this.iconBuilder,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Widget Function(Color) iconBuilder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final col = selected ? c.accent : c.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (selected)
              Positioned(
                top: 0,
                left: 24,
                right: 24,
                child: Container(height: 2, color: c.accent),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconBuilder(col),
                const SizedBox(height: 3),
                Text(label,
                    style: LatticeText.ui(11,
                        weight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: col)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentFile {
  const _RecentFile(this.name, this.lang, this.path, this.badge, this.color);
  final String name, lang, path, badge;
  final Color color;
}

class _ProjectTab extends StatelessWidget {
  const _ProjectTab();

  // JetBrains-like file-type colors.
  static const _files = [
    _RecentFile('editor.tsx', 'TypeScript React', 'lib/', 'TSX', Color(0xFF3178C6)),
    _RecentFile('main.dart', 'Dart', 'lib/', 'DART', Color(0xFF2DB7F5)),
    _RecentFile('app.py', 'Python', 'scripts/', 'PY', Color(0xFFF2C94C)),
    _RecentFile('fs.ts', 'TypeScript', 'src/', 'TS', Color(0xFF3178C6)),
    _RecentFile('native.cpp', 'C++', 'native/', 'C++', Color(0xFF9B7BE0)),
    _RecentFile('Helper.kt', 'Kotlin', 'android/', 'KT', Color(0xFFE5764A)),
  ];

  void _openEditor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const EditorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CustomScrollView(
      slivers: [
        // Title bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(_kRadius + 2),
                  ),
                  child: const Center(
                    child: iconoir.CodeBracketsSquare(
                        color: Colors.white, width: 20, height: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lattice Studio',
                          style: LatticeText.ui(17,
                              weight: FontWeight.w600, color: c.text)),
                      Text('Mobile code workspace',
                          style: LatticeText.ui(12, color: c.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // "Search everywhere" bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(_kRadius),
              onTap: () => _openEditor(context),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(_kRadius),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    iconoir.Search(color: c.textMuted, width: 18, height: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Search files, symbols, actions',
                          style: LatticeText.ui(13, color: c.textMuted)),
                    ),
                    Text('Aa',
                        style: LatticeText.mono(11, color: c.textFaint)),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Welcome-screen actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Open',
                    primary: true,
                    icon: const iconoir.OpenInWindow(
                        color: Colors.white, width: 18, height: 18),
                    onTap: () => _openEditor(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: 'New file',
                    icon: iconoir.Plus(color: c.text, width: 18, height: 18),
                    onTap: () => _openEditor(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: 'Clone',
                    icon: iconoir.GitBranch(
                        color: c.text, width: 18, height: 18),
                    onTap: () async {
                      await CloneDialog.show(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
            child: Row(
              children: [
                Text('Recent',
                    style: LatticeText.ui(12,
                        weight: FontWeight.w600, color: c.textMuted)),
                const Spacer(),
                Text('${_files.length}',
                    style: LatticeText.ui(11, color: c.textFaint)),
              ],
            ),
          ),
        ),
        // Dense project-tree style list inside one bordered panel
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(_kRadius + 2),
                border: Border.all(color: c.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < _files.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: c.border),
                    _FileRow(file: _files[i], onTap: () => _openEditor(context)),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });
  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: primary ? c.accent : c.surface,
      borderRadius: BorderRadius.circular(_kRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_kRadius),
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kRadius),
            border: primary ? null : Border.all(color: c.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 6),
              Text(label,
                  style: LatticeText.ui(13,
                      weight: FontWeight.w500,
                      color: primary ? Colors.white : c.text)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onTap});
  final _RecentFile file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: file.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(file.badge,
                  style: LatticeText.mono(10,
                      weight: FontWeight.w700, color: file.color)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(file.name,
                      style: LatticeText.ui(14,
                          weight: FontWeight.w500, color: c.text)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(file.path,
                        overflow: TextOverflow.ellipsis,
                        style: LatticeText.ui(12, color: c.textFaint)),
                  ),
                ],
              ),
            ),
            Text(file.lang, style: LatticeText.ui(11, color: c.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// Settings, grouped in bordered panels like the IDE Settings dialog.
class SettingsScreenContent extends StatelessWidget {
  const SettingsScreenContent({super.key});

  void _showFontPicker(BuildContext context, AppSettings s) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        final c = ctx.c;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Editor font',
                    style: LatticeText.ui(15,
                        weight: FontWeight.w600, color: c.text)),
              ),
              Divider(height: 1, color: c.border),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final font in AppSettings.availableFonts)
                      ListTile(
                        dense: true,
                        title: Text(font,
                            style: LatticeText.mono(14,
                                color: c.text, fontFamily: font)),
                        trailing: s.fontFamily == font
                            ? iconoir.Check(
                                color: c.accent, width: 18, height: 18)
                            : null,
                        onTap: () {
                          s.update((x) => x.fontFamily = font);
                          Navigator.of(ctx).pop();
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = SettingsScope.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Settings',
            style: LatticeText.ui(20, weight: FontWeight.w600, color: c.text)),
        const SizedBox(height: 16),
        _Group(title: 'Appearance', children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _ThemeSegments(settings: s),
          ),
          _Row(
            title: 'Font',
            onTap: () => _showFontPicker(context, s),
            trailing: Row(children: [
              Text(s.fontFamily,
                  style: LatticeText.ui(13, color: c.textMuted)),
              const SizedBox(width: 8),
              iconoir.NavArrowRight(color: c.textFaint, width: 16, height: 16),
            ]),
          ),
          _FontSize(settings: s),
        ]),
        const SizedBox(height: 16),
        _Group(title: 'Editor', children: [
          _ToggleRow(
              title: 'Word wrap',
              value: s.wordWrap,
              onChanged: (v) => s.update((x) => x.wordWrap = v)),
          _ToggleRow(
              title: 'Line numbers',
              value: s.lineNumbers,
              onChanged: (v) => s.update((x) => x.lineNumbers = v)),
          _ToggleRow(
              title: 'Auto-save',
              subtitle: 'After 1 second of inactivity',
              value: s.autoSave,
              onChanged: (v) => s.update((x) => x.autoSave = v)),
          _ToggleRow(
              title: 'Minimap',
              value: s.minimap,
              onChanged: (v) => s.update((x) => x.minimap = v)),
          _ToggleRow(
              title: 'Format on save',
              subtitle: 'Uses Prettier or the language formatter',
              value: s.formatOnSave,
              onChanged: (v) => s.update((x) => x.formatOnSave = v)),
        ]),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(title,
              style: LatticeText.ui(12,
                  weight: FontWeight.w600, color: c.textMuted)),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(_kRadius + 2),
            border: Border.all(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, color: c.border),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeSegments extends StatelessWidget {
  const _ThemeSegments({required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    const items = [
      ('Dark', ThemeMode.dark),
      ('Light', ThemeMode.light),
      ('System', ThemeMode.system),
    ];
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          for (final it in items)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => settings.update((s) => s.themeMode = it.$2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: settings.themeMode == it.$2
                        ? c.accent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(_kRadius - 2),
                  ),
                  child: Text(it.$1,
                      style: LatticeText.ui(13,
                          weight: FontWeight.w500,
                          color: settings.themeMode == it.$2
                              ? Colors.white
                              : c.textMuted)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(
      {required this.title, this.subtitle, required this.trailing, this.onTap});
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: subtitle == null ? 48 : 58),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: LatticeText.ui(14,
                          weight: FontWeight.w500, color: c.text)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: LatticeText.ui(12, color: c.textMuted)),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => _Row(
        title: title,
        subtitle: subtitle,
        onTap: () => onChanged(!value),
        trailing: LToggle(value: value, onChanged: onChanged),
      );
}

class _FontSize extends StatelessWidget {
  const _FontSize({required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Font size',
                style: LatticeText.ui(14,
                    weight: FontWeight.w500, color: c.text)),
            const Spacer(),
            Text('${settings.fontSize.round()} pt',
                style: LatticeText.mono(12,
                    color: c.textMuted, fontFamily: settings.fontFamily)),
          ]),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: c.accent,
              inactiveTrackColor: c.key,
              thumbColor: c.accent,
              overlayColor: c.accentSoft,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              min: 8,
              max: 28,
              divisions: 20,
              value: settings.fontSize.clamp(8, 28),
              onChanged: (v) => settings.update((s) => s.fontSize = v),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(color: c.border),
            ),
            child: Text(
              r'const greet = (name: string) => `Hello, ${name}`;',
              style: LatticeText.mono(settings.fontSize,
                  color: c.synPlain,
                  height: 1.6,
                  fontFamily: settings.fontFamily),
            ),
          ),
        ],
      ),
    );
  }
}