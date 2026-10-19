import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'common.dart';

class PaletteCommand {
  const PaletteCommand(this.id, this.title, this.iconBuilder, this.category);
  final String id;
  final String title;
  final Widget Function(Color color, double size) iconBuilder;
  final String category;
}

final kCommands = <PaletteCommand>[
  PaletteCommand(
      'format.doc',
      'Format Document',
      (color, size) => iconoir.AlignLeft(color: color, width: size, height: size),
      'Editor'),
  PaletteCommand(
      'format.sel',
      'Format Selection',
      (color, size) => iconoir.AlignLeft(color: color, width: size, height: size),
      'Editor'),
  PaletteCommand(
      'goto.line',
      'Go to Line…',
      (color, size) => iconoir.Hashtag(color: color, width: size, height: size),
      'Navigate'),
  PaletteCommand(
      'wrap',
      'Toggle Word Wrap',
      (color, size) => iconoir.WrapText(color: color, width: size, height: size),
      'View'),
  PaletteCommand(
      'run',
      'Run Current File',
      (color, size) => iconoir.Play(color: color, width: size, height: size),
      'Run'),
];

const kTotalCommands = 38;

List<PaletteCommand> filterCommands(String q) {
  final query = q.trim().toLowerCase();
  if (query.isEmpty) return kCommands;
  return kCommands.where((c) => c.title.toLowerCase().contains(query)).toList();
}

/// Floating card from the "03 Command palette" frame.
class CommandPalette extends StatefulWidget {
  const CommandPalette({
    super.key,
    required this.query,
    required this.selected,
    required this.onPick,
    this.onQueryChanged,
  });

  final String query;
  final int selected;
  final ValueChanged<PaletteCommand> onPick;
  final ValueChanged<String>? onQueryChanged;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(CommandPalette oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.value = TextEditingController.fromValue(
        TextEditingValue(
          text: widget.query,
          selection: TextSelection.collapsed(offset: widget.query.length),
        ),
      ).value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final results = filterCommands(widget.query);
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
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: LatticeText.ui(15,
                          weight: FontWeight.w500, color: c.text),
                      cursorColor: c.accent,
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        widget.onQueryChanged?.call(val);
                      },
                      onSubmitted: (_) {
                        if (results.isNotEmpty) {
                          widget.onPick(results[widget.selected
                              .clamp(0, results.length - 1)]);
                        }
                      },
                    ),
                  ),
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
                    color: i == widget.selected ? c.accentSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => widget.onPick(results[i]),
                      child: SizedBox(
                        height: 46,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              results[i].iconBuilder(
                                  i == widget.selected ? c.accent : c.textMuted,
                                  18),
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
