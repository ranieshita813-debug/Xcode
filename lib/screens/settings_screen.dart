import 'package:flutter/material.dart';
import '../state/settings.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = SettingsScope.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 12),
                child: Row(
                  children: [
                    LIconButton(
                      icon: Icons.chevron_left,
                      iconSize: 24,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 4),
                    Text('Settings',
                        style: LatticeText.ui(17,
                            weight: FontWeight.w600, color: c.text)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SectionLabel('APPEARANCE'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ThemeSegments(settings: s),
                  ),
                  const SizedBox(height: 6),
                  _Row(
                    title: 'Font',
                    trailing: Row(
                      children: [
                        Text(s.fontFamily,
                            style: LatticeText.ui(14, color: c.textMuted)),
                        const SizedBox(width: 12),
                        Icon(Icons.chevron_right,
                            size: 16, color: c.textFaint),
                      ],
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
                    subtitle: 'Uses Prettier',
                    value: s.formatOnSave,
                    onChanged: (v) => s.update((x) => x.formatOnSave = v),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
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
                  style: LatticeText.mono(13, color: c.textMuted)),
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
                  color: c.synPlain, height: 1.8),
            ),
          ),
        ],
      ),
    );
  }
}
