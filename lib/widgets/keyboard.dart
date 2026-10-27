import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

typedef KeyHandler = void Function(String key);

/// Special key codes sent through [KeyHandler].
class Keys {
  static const tab = '\t';
  static const enter = '\n';
  static const backspace = '<backspace>';
  static const left = '<left>';
  static const right = '<right>';
}

class _KeyCap extends StatelessWidget {
  const _KeyCap({
    required this.label,
    required this.onTap,
    this.height = 36,
    this.radius = 8,
    this.fontSize = 15,
  });

  final String label;
  final VoidCallback onTap;
  final double height;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.key,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Center(
            child: Text(
              label,
              style: LatticeText.ui(fontSize,
                  weight: FontWeight.w500, color: c.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// Row of code-friendly keys above the mobile keyboard: Tab { } ( ) ; " ← → ⌫
class ExtraKeys extends StatelessWidget {
  const ExtraKeys({super.key, required this.onKey});
  final KeyHandler onKey;

  static const _keys = ['{', '}', '(', ')', ';', '"', '←', '→', '⌫'];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: _KeyCap(
              label: 'Tab',
              height: 32,
              radius: 8,
              fontSize: 12,
              onTap: () => onKey(Keys.tab),
            ),
          ),
          for (final k in _keys) ...[
            const SizedBox(width: 4),
            Expanded(
              child: _KeyCap(
                label: k,
                height: 32,
                radius: 8,
                fontSize: 14,
                onTap: () => onKey(k == '←'
                    ? Keys.left
                    : k == '→'
                        ? Keys.right
                        : k == '⌫'
                            ? Keys.backspace
                            : k),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
