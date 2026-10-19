import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'common.dart';

class BuildResult {
  const BuildResult({required this.errors});
  final List<String> errors;
  bool get ok => errors.isEmpty;
}

/// Bottom panel with Terminal / Problems / Output tabs.
class TerminalPanel extends StatefulWidget {
  const TerminalPanel({super.key, required this.result, required this.onClose});
  final BuildResult result;
  final VoidCallback onClose;

  @override
  State<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<TerminalPanel> {
  int _tab = 0;
  static const _tabs = ['Terminal', 'Problems', 'Output'];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final maxH = MediaQuery.sizeOf(context).height * 0.47;
    final height = maxH < 400 ? maxH : 400.0;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onClose,
            onVerticalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) > 200) widget.onClose();
            },
            child: SizedBox(
              height: 16,
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.key,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: Row(
              children: [
                const SizedBox(width: 8),
                for (var i = 0; i < _tabs.length; i++)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _tab = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                              weight: _tab == i
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: _tab == i ? c.text : c.textMuted,
                            ),
                          ),
                          if (i == 1 && widget.result.errors.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            CountBadge(widget.result.errors.length,
                                color: c.error.withValues(alpha: 0.18)),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
          Expanded(
            child: Container(
              color: c.bg,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: SingleChildScrollView(child: _body(c)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(LatticeColors c) {
    final base = LatticeText.mono(12, color: c.synPlain, height: 1.6);
    final r = widget.result;
    switch (_tab) {
      case 1:
        if (r.ok) {
          return Text('No problems detected.',
              style: LatticeText.ui(13, color: c.textMuted));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final e in r.errors)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(e, style: base.copyWith(color: c.error)),
              ),
          ],
        );
      case 2:
        return Text('[vite] ${r.ok ? "build complete" : "build failed"}',
            style: base.copyWith(color: c.textMuted));
      default:
        return Text.rich(
          TextSpan(style: base, children: [
            _prompt(c),
            const TextSpan(text: 'npm run build\n\n'),
            TextSpan(
                text: '> lattice-app@0.4.2 build\n> tsc && vite build\n\n',
                style: base.copyWith(color: c.textMuted)),
            if (r.ok)
              TextSpan(
                  text: '✓ built in 1.24s\n\n',
                  style: base.copyWith(color: c.success))
            else ...[
              for (final e in r.errors)
                TextSpan(text: '$e\n', style: base.copyWith(color: c.error)),
              TextSpan(
                  text: '\nFound ${r.errors.length} error in 1 file.\n\n',
                  style: base.copyWith(color: c.textMuted)),
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
    final base = LatticeText.mono(12, color: c.synPlain, height: 1.6);
    return TextSpan(children: [
      TextSpan(text: '~/lattice-app ', style: base.copyWith(color: c.synType)),
      TextSpan(text: '(main) ', style: base.copyWith(color: c.textMuted)),
      TextSpan(text: r'$ ', style: base.copyWith(color: c.success)),
    ]);
  }
}
