import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/common.dart';

class _Change {
  _Change(this.name, this.dir, this.status, this.staged);
  final String name;
  final String dir;
  final String status; // M | A
  bool staged;
}

class SourceControlScreen extends StatefulWidget {
  const SourceControlScreen({super.key});

  @override
  State<SourceControlScreen> createState() => _SourceControlScreenState();
}

class _SourceControlScreenState extends State<SourceControlScreen> {
  final _changes = [
    _Change('editor.tsx', 'src/components', 'M', true),
    _Change('fs.ts', 'src', 'M', true),
    _Change('Tabs.tsx', 'src/components', 'A', false),
  ];
  final _message =
      TextEditingController(text: 'Fix: wait for save before clearing dirty flag');

  int get _stagedCount => _changes.where((c) => c.staged).length;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _commit() {
    if (_stagedCount == 0) return;
    final n = _stagedCount;
    setState(() => _changes.removeWhere((c) => c.staged));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Committed $n file${n == 1 ? '' : 's'} (local demo)'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 12),
                child: Row(
                  children: [
                    LIconButton(
                        icon: Icons.menu,
                        iconSize: 22,
                        onTap: () => Navigator.of(context).maybePop()),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('Source Control',
                          style: LatticeText.ui(17,
                              weight: FontWeight.w600, color: c.text)),
                    ),
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: c.raised,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.call_split, size: 14, color: c.accent),
                          const SizedBox(width: 6),
                          Text('main',
                              style: LatticeText.ui(13,
                                  weight: FontWeight.w500, color: c.text)),
                          const SizedBox(width: 6),
                          Text('↓2 ↑1',
                              style: LatticeText.ui(11, color: c.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    LIconButton(icon: Icons.sync, onTap: () {}),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Commit message
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Container(
                      height: 84,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: c.raised,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      child: TextField(
                        controller: _message,
                        maxLines: null,
                        expands: true,
                        cursorColor: c.accent,
                        style: LatticeText.ui(14, color: c.text, height: 1.4),
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  // CHANGES header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Text('CHANGES',
                            style: LatticeText.ui(11,
                                weight: FontWeight.w600,
                                color: c.textMuted,
                                letterSpacing: 0.9)),
                        const SizedBox(width: 8),
                        CountBadge(_changes.length),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() {
                            for (final ch in _changes) {
                              ch.staged = true;
                            }
                          }),
                          child: Text('Stage all',
                              style: LatticeText.ui(13,
                                  weight: FontWeight.w500, color: c.accent)),
                        ),
                      ],
                    ),
                  ),
                  for (final ch in _changes) _ChangeRow(change: ch, onToggle: () {
                    setState(() => ch.staged = !ch.staged);
                  }),
                  // Diff header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Row(
                      children: [
                        Text('editor.tsx',
                            style: LatticeText.mono(12,
                                weight: FontWeight.w500, color: c.text)),
                        const Spacer(),
                        Text('+4',
                            style: LatticeText.mono(12, color: c.success)),
                        const SizedBox(width: 8),
                        Text('−1',
                            style: LatticeText.mono(12, color: c.error)),
                      ],
                    ),
                  ),
                  const _Diff(),
                ],
              ),
            ),
            // Commit button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 16),
              child: Material(
                color: _stagedCount == 0 ? c.key : c.accent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _commit,
                  child: SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check,
                            size: 18,
                            color: _stagedCount == 0
                                ? c.textMuted
                                : c.onAccent),
                        const SizedBox(width: 8),
                        Text(
                          'Commit $_stagedCount staged file${_stagedCount == 1 ? '' : 's'}',
                          style: LatticeText.ui(15,
                              weight: FontWeight.w600,
                              color: _stagedCount == 0
                                  ? c.textMuted
                                  : c.onAccent),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.change, required this.onToggle});
  final _Change change;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = change.status == 'A' ? c.success : c.warning;
    return SizedBox(
      height: 54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(change.status,
                  style: LatticeText.ui(12,
                      weight: FontWeight.w600, color: color)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(change.name,
                      style: LatticeText.ui(14,
                          weight: FontWeight.w500, color: c.text)),
                  Text(change.dir,
                      style: LatticeText.ui(12, color: c.textMuted)),
                ],
              ),
            ),
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: change.staged ? c.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: change.staged ? c.accent : c.border, width: 1.5),
                ),
                child: change.staged
                    ? Icon(Icons.check, size: 14, color: c.onAccent)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Diff extends StatelessWidget {
  const _Diff();

  static const _lines = <(String, String)>[
    ('hunk', '@@ -8,6 +8,9 @@'),
    (' ', '  async function onSave(text: string) {'),
    ('-', '-   saveFile(path, text);'),
    ('+', '+   await saveFile(path, text);'),
    ('+', '+   setDirty(false);'),
    ('+', "+   track('save');"),
    (' ', '  }'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      color: c.surface,
      child: Column(
        children: [
          for (final (kind, text) in _lines)
            Container(
              height: 24,
              width: double.infinity,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: kind == '+'
                  ? c.success.withValues(alpha: 0.10)
                  : kind == '-'
                      ? c.error.withValues(alpha: 0.10)
                      : Colors.transparent,
              child: Text(
                text,
                style: LatticeText.mono(
                  12,
                  color: kind == '+'
                      ? c.success
                      : kind == '-'
                          ? c.error
                          : kind == 'hunk'
                              ? c.accent
                              : c.synPlain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
