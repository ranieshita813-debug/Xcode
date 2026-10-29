import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/common.dart';
import '../widgets/terminal_panel.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key, required this.result});

  final BuildResult result;

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  int _tab = 0;
  static const _tabs = ['Terminal', 'Problems', 'Output'];

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Terminal & Output',
          style: LatticeText.ui(16, weight: FontWeight.w600, color: c.text),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                for (var i = 0; i < _tabs.length; i++)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _tab = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _tab == i ? c.accent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _tabs[i],
                            style: LatticeText.ui(
                              13,
                              weight: _tab == i ? FontWeight.w600 : FontWeight.w400,
                              color: _tab == i ? c.text : c.textMuted,
                            ).copyWith(
                              decoration: _tab == i ? TextDecoration.underline : TextDecoration.none,
                              decorationColor: c.accent,
                            ),
                          ),
                          if (i == 1 && widget.result.errors.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            CountBadge(
                              widget.result.errors.length,
                              color: c.error.withValues(alpha: 0.18),
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
      ),
      body: Container(
        color: c.bg,
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: _body(c),
        ),
      ),
    );
  }

  Widget _body(LatticeColors c) {
    final base = LatticeText.mono(13, color: c.synPlain, height: 1.6);
    final r = widget.result;

    switch (_tab) {
      case 1:
        if (r.ok) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  iconoir.Check(color: c.success, width: 36, height: 36),
                  const SizedBox(height: 12),
                  Text(
                    'No problems detected in workspace.',
                    style: LatticeText.ui(14, color: c.textMuted),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final e in r.errors)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: c.error.withValues(alpha: 0.4)),
                  ),
                  child: Text(e, style: base.copyWith(color: c.error)),
                ),
              ),
          ],
        );
      case 2:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: c.border),
          ),
          child: Text(
            '[vite] ${r.ok ? "build complete successfully" : "build failed with errors"}',
            style: base.copyWith(color: r.ok ? c.success : c.error),
          ),
        );
      default:
        return Text.rich(
          TextSpan(style: base, children: [
            _prompt(c),
            const TextSpan(text: 'npm run build\n\n'),
            TextSpan(
              text: '> lattice-app@0.4.2 build\n> tsc && vite build\n\n',
              style: base.copyWith(color: c.textMuted),
            ),
            if (r.ok)
              TextSpan(
                text: '✓ built in 1.24s\n\n',
                style: base.copyWith(color: c.success),
              )
            else ...[
              for (final e in r.errors)
                TextSpan(text: '$e\n', style: base.copyWith(color: c.error)),
              TextSpan(
                text: '\nFound ${r.errors.length} error in workspace.\n\n',
                style: base.copyWith(color: c.textMuted),
              ),
            ],
            _prompt(c),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: BlinkingCaret(color: c.text, width: 7, height: 15),
            ),
          ]),
        );
    }
  }

  TextSpan _prompt(LatticeColors c) {
    final base = LatticeText.mono(13, color: c.synPlain, height: 1.6);
    return TextSpan(children: [
      TextSpan(text: '~/lattice-app ', style: base.copyWith(color: c.synType)),
      TextSpan(text: '(main) ', style: base.copyWith(color: c.textMuted)),
      TextSpan(text: r'$ ', style: base.copyWith(color: c.success)),
    ]);
  }
}
