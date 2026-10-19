import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// 40x40 rounded icon button used in app bars.
class LIconButton extends StatelessWidget {
  const LIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.iconSize = 20,
    this.color,
  });

  final Widget icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: SizedBox(
              width: iconSize,
              height: iconSize,
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}

/// 46x26 pill toggle from the Settings screen.
class LToggle extends StatelessWidget {
  const LToggle({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 46,
        height: 26,
        padding: const EdgeInsets.all(3),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? c.accent : c.key,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: value ? c.onAccent : c.textMuted,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Small rounded count badge (Problems "1", CHANGES "3").
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key, this.color});
  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      constraints: const BoxConstraints(minWidth: 19),
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? c.accentSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: LatticeText.ui(11,
            weight: FontWeight.w600, color: c.accent, height: 1.2),
      ),
    );
  }
}

/// Blinking caret used by the editor, palette and terminal.
class BlinkingCaret extends StatefulWidget {
  const BlinkingCaret({
    super.key,
    required this.color,
    this.width = 2,
    this.height = 18,
  });
  final Color color;
  final double width;
  final double height;

  @override
  State<BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<BlinkingCaret> {
  bool _on = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) setState(() => _on = !_on);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: _on ? widget.color : Colors.transparent,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

/// Section label such as APPEARANCE / EDITOR / CHANGES.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(
        text,
        style: LatticeText.ui(11,
            weight: FontWeight.w600, color: c.textMuted, letterSpacing: 0.9),
      ),
    );
  }
}
