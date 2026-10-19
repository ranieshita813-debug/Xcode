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
    this.color,
    this.textColor,
    this.height = 42,
    this.radius = 7,
    this.fontSize = 17,
  });

  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;
  final double height;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: color ?? c.key,
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
                  weight: FontWeight.w500, color: textColor ?? c.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// Row of code-friendly keys above the keyboard: Tab { } ( ) ; " ← →
class ExtraKeys extends StatelessWidget {
  const ExtraKeys({super.key, required this.onKey});
  final KeyHandler onKey;

  static const _keys = ['{', '}', '(', ')', ';', '"', '←', '→'];

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
            width: 50,
            child: _KeyCap(
              label: 'Tab',
              height: 32,
              radius: 8,
              fontSize: 13,
              onTap: () => onKey(Keys.tab),
            ),
          ),
          for (final k in _keys) ...[
            const SizedBox(width: 6),
            Expanded(
              child: _KeyCap(
                label: k,
                height: 32,
                radius: 8,
                fontSize: 15,
                onTap: () => onKey(k == '←'
                    ? Keys.left
                    : k == '→'
                        ? Keys.right
                        : k),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// On-screen QWERTY keyboard drawn from the design (with shift and 123 layers).
class LatticeKeyboard extends StatefulWidget {
  const LatticeKeyboard({super.key, required this.onKey});
  final KeyHandler onKey;

  @override
  State<LatticeKeyboard> createState() => _LatticeKeyboardState();
}

class _LatticeKeyboardState extends State<LatticeKeyboard> {
  bool _shift = false;
  bool _symbols = false;

  static const _alpha = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
  static const _sym = ['1234567890', r'-/:;()&@"', r".,?!'_="];

  void _type(String ch) {
    widget.onKey(_shift && !_symbols ? ch.toUpperCase() : ch);
    if (_shift) setState(() => _shift = false);
  }

  Widget _row(String chars, {double hPad = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Row(
        children: [
          for (var i = 0; i < chars.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: _KeyCap(
                label: _shift && !_symbols
                    ? chars[i].toUpperCase()
                    : chars[i],
                onTap: () => _type(chars[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final rows = _symbols ? _sym : _alpha;
    return Container(
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(rows[0]),
          const SizedBox(height: 11),
          _row(rows[1], hPad: _symbols ? 0 : 18),
          const SizedBox(height: 11),
          Row(
            children: [
              SizedBox(
                width: 46,
                child: _KeyCap(
                  label: _symbols ? '#+=' : 'shift',
                  color: _shift ? c.accentSoft : c.raised,
                  textColor: _shift ? c.accent : c.text,
                  fontSize: 12,
                  onTap: () {
                    if (!_symbols) setState(() => _shift = !_shift);
                  },
                ),
              ),
              const SizedBox(width: 5),
              Expanded(child: _row(rows[2])),
              const SizedBox(width: 5),
              SizedBox(
                width: 46,
                child: _KeyCap(
                  label: 'del',
                  color: c.raised,
                  fontSize: 12,
                  onTap: () => widget.onKey(Keys.backspace),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              SizedBox(
                width: 46,
                child: _KeyCap(
                  label: _symbols ? 'abc' : '123',
                  color: c.raised,
                  fontSize: 13,
                  onTap: () => setState(() => _symbols = !_symbols),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _KeyCap(
                  label: 'space',
                  fontSize: 13,
                  onTap: () => widget.onKey(' '),
                ),
              ),
              const SizedBox(width: 5),
              SizedBox(
                width: 76,
                child: _KeyCap(
                  label: 'return',
                  color: c.accent,
                  textColor: c.onAccent,
                  fontSize: 13,
                  onTap: () => widget.onKey(Keys.enter),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
