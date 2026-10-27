import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import '../state/settings.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/common.dart';
import 'editor_screen.dart';

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
          children: const [
            _ProjectTab(),
            _SettingsTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: c.surface,
          indicatorColor: c.accentSoft,
          elevation: 0,
          destinations: [
            NavigationDestination(
              icon: iconoir.Folder(color: c.textMuted, width: 22, height: 22),
              selectedIcon:
                  iconoir.Folder(color: c.accent, width: 22, height: 22),
              label: 'Projects',
            ),
            NavigationDestination(
              icon:
                  iconoir.Settings(color: c.textMuted, width: 22, height: 22),
              selectedIcon:
                  iconoir.Settings(color: c.accent, width: 22, height: 22),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectTab extends StatelessWidget {
  const _ProjectTab();

  static const _recentFiles = [
    {
      'name': 'editor.tsx',
      'lang': 'TypeScript React',
      'path': 'lib/editor.tsx',
      'icon': 'tsx'
    },
    {
      'name': 'main.dart',
      'lang': 'Dart',
      'path': 'lib/main.dart',
      'icon': 'dart'
    },
    {
      'name': 'app.py',
      'lang': 'Python',
      'path': 'scripts/app.py',
      'icon': 'py'
    },
    {
      'name': 'fs.ts',
      'lang': 'TypeScript',
      'path': 'src/fs.ts',
      'icon': 'ts'
    },
    {
      'name': 'native.cpp',
      'lang': 'C++',
      'path': 'native/native.cpp',
      'icon': 'cpp'
    },
    {
      'name': 'Helper.kt',
      'lang': 'Kotlin',
      'path': 'android/Helper.kt',
      'icon': 'kt'
    },
  ];

  void _openEditor(BuildContext context, [String? fileName]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const EditorScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Center(
                    child: iconoir.CodeBracketsSquare(
                      color: c.accent,
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lattice Studio',
                      style: LatticeText.ui(
                        20,
                        weight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                    Text(
                      'Mobile Code Workspace',
                      style: LatticeText.ui(
                        12,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    c.accent.withValues(alpha: 0.12),
                    c.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      iconoir.Code(color: c.accent, width: 22, height: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Launch Editor Workspace',
                        style: LatticeText.ui(
                          15,
                          weight: FontWeight.w600,
                          color: c.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Full-featured code editor with syntax highlighting, auto-complete, multi-tabs & terminal.',
                    style: LatticeText.ui(12, color: c.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _openEditor(context),
                      icon: const iconoir.OpenInWindow(
                          color: Colors.white, width: 18, height: 18),
                      label: Text(
                        'Open Editor',
                        style: LatticeText.ui(14, weight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT FILES & PROJECTS',
                  style: LatticeText.ui(
                    11,
                    weight: FontWeight.w700,
                    color: c.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '${_recentFiles.length} files',
                  style: LatticeText.ui(11, color: c.textFaint),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final file = _recentFiles[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openEditor(context, file['name']),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: c.bg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  file['icon']!.toUpperCase(),
                                  style: LatticeText.mono(
                                    11,
                                    weight: FontWeight.w700,
                                    color: c.accent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    file['name']!,
                                    style: LatticeText.ui(
                                      14,
                                      weight: FontWeight.w600,
                                      color: c.text,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${file['lang']}  ·  ${file['path']}',
                                    style: LatticeText.ui(
                                      11,
                                      color: c.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            iconoir.NavArrowRight(
                              color: c.textFaint,
                              width: 18,
                              height: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: _recentFiles.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return const SettingsScreenContent();
  }
}

/// Standalone content widget for Settings to be embedded inside HomeScreen Tab or SettingsScreen
class SettingsScreenContent extends StatelessWidget {
  const SettingsScreenContent({super.key});

  void _showFontPicker(BuildContext context, AppSettings s) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final c = ctx.c;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Select Coding Font',
                  style: LatticeText.ui(16,
                      weight: FontWeight.w600, color: c.text),
                ),
              ),
              Divider(color: c.border),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final font in AppSettings.availableFonts)
                      ListTile(
                        title: Text(
                          font,
                          style: LatticeText.mono(15,
                              color: c.text, fontFamily: font),
                        ),
                        trailing: s.fontFamily == font
                            ? iconoir.Check(
                                color: c.accent, width: 20, height: 20)
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Settings',
            style: LatticeText.ui(22, weight: FontWeight.w700, color: c.text),
          ),
        ),
        const SectionLabel('APPEARANCE'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ThemeSegments(settings: s),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _showFontPicker(context, s),
          child: _Row(
            title: 'Font',
            trailing: Row(
              children: [
                Text(s.fontFamily,
                    style: LatticeText.ui(14, color: c.textMuted)),
                const SizedBox(width: 12),
                iconoir.NavArrowRight(
                    color: c.textFaint, width: 16, height: 16),
              ],
            ),
          ),
        ),
        _FontSize(settings: s),
        const SectionLabel('EDITOR'),
        _ToggleRow(
          title: 'Word wrap',
          value: s.wordWrap,
          onChanged: (v) => s.update((x) => x.wordWrap = v),
        ),
        _ToggleRow(
          title: 'Line numbers',
          value: s.lineNumbers,
          onChanged: (v) => s.update((x) => x.lineNumbers = v),
        ),
        _ToggleRow(
          title: 'Auto-save',
          subtitle: 'After 1 second of inactivity',
          value: s.autoSave,
          onChanged: (v) => s.update((x) => x.autoSave = v),
        ),
        _ToggleRow(
          title: 'Minimap',
          value: s.minimap,
          onChanged: (v) => s.update((x) => x.minimap = v),
        ),
        _ToggleRow(
          title: 'Format on save',
          subtitle: 'Uses Prettier / Language formatter',
          value: s.formatOnSave,
          onChanged: (v) => s.update((x) => x.formatOnSave = v),
        ),
        const SizedBox(height: 24),
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
      ('Auto', ThemeMode.system),
    ];
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: () => settings.update((s) => s.themeMode = items[i].$2),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: settings.themeMode == items[i].$2
                        ? c.key
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    items[i].$1,
                    style: LatticeText.ui(
                      14,
                      weight: settings.themeMode == items[i].$2
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: settings.themeMode == items[i].$2
                          ? c.text
                          : c.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, this.subtitle, required this.trailing});
  final String title;
  final String? subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      constraints: BoxConstraints(minHeight: subtitle == null ? 54 : 62),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Font size',
                  style: LatticeText.ui(14,
                      weight: FontWeight.w500, color: c.text)),
              const Spacer(),
              Text('${settings.fontSize.round()} pt',
                  style: LatticeText.mono(13,
                      color: c.textMuted, fontFamily: settings.fontFamily)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: c.accent,
              inactiveTrackColor: c.key,
              thumbColor: c.accent,
              overlayColor: c.accentSoft,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              min: 8,
              max: 28,
              divisions: 20,
              value: settings.fontSize.clamp(8, 28),
              onChanged: (v) => settings.update((s) => s.fontSize = v),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Text(
              r'const greet = (name: string) => `Hello, ${name}`;',
              style: LatticeText.mono(settings.fontSize,
                  color: c.synPlain,
                  height: 1.8,
                  fontFamily: settings.fontFamily),
            ),
          ),
        ],
      ),
    );
  }
}
