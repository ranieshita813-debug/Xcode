import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'common.dart';

class PaletteCommand {
  const PaletteCommand(this.id, this.title, this.icon, this.category);
  final String id;
  final String title;
  final IconData icon;
  final String category;
}

const kCommands = <PaletteCommand>[
  PaletteCommand('format.doc', 'Format Document', Icons.format_align_left, 'Editor'),
  PaletteCommand('format.sel', 'Format Selection', Icons.format_align_left, 'Editor'),
  PaletteCommand('goto.line', 'Go to Line…', Icons.tag, 'Navigate'),
  PaletteCommand('wrap', 'Toggle Word Wrap', Icons.wrap_text, 'View'),
  PaletteCommand('run', 'Run Current File', Icons.play_arrow_outlined, 'Run'),
];

const kTotalCommands = 38;

List<PaletteCommand> filterCommands(String q) {
  final query = q.trim().toLowerCase();
  if (query.isEmpty) return kCommands;
  return kCommands.where((c) => c.title.toLowerCase().contains(query)).toList();
}

/// Floating card from the "03 Command palette" frame. Text input arrives from
/// the in-app keyboard, so this widget is purely presentational.
class CommandPalette extends StatelessWidget {
  const CommandPalette({
    super.key,
    required this.query,
    required this.selected,
    required this.onPick,
  });

  final String query;
  final int selected;
  final ValueChanged<PaletteCommand> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final results = filterCommands(query);
    return Container(
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x80000000), blurRadius: 32, offset: Offset(0, 12)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 54,
              child: Row(
                children: [
                  Text('>',
                      style: LatticeText.mono(16,
                          weight: FontWeight.w500, color: c.accent)),
                  const SizedBox(width: 8),
                  Text(query,
                      style: LatticeText.ui(15,
                          weight: FontWeight.w500, color: c.text)),
                  const SizedBox(width: 2),
                  BlinkingCaret(color: c.accent, height: 20),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: c.border),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                if (results.isEmpty)
                  SizedBox(
                    height: 46,
                    child: Center(
                      child: Text('No matching commands',
                          style: LatticeText.ui(13, color: c.textMuted)),
                    ),
                  ),
                for (var i = 0; i < results.length; i++)
                  Material(
                    color: i == selected ? c.accentSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onPick(results[i]),
                      child: SizedBox(
                        height: 46,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Icon(results[i].icon,
                                  size: 18,
                                  color: i == selected ? c.accent : c.textMuted),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(results[i].title,
                                    style: LatticeText.ui(14,
                                        weight: FontWeight.w500,
                                        color: c.text)),
                              ),
                              Text(results[i].category,
                                  style: LatticeText.ui(12,
                                      color: c.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
          SizedBox(
            height: 39,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('${results.length} of $kTotalCommands commands',
                      style: LatticeText.ui(12, color: c.textMuted)),
                  const Spacer(),
                  Text('Files · Symbols · Commands',
                      style: LatticeText.ui(12, color: c.textFaint)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
