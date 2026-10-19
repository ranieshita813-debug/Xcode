import 'package:flutter/material.dart';

/// Design tokens extracted from the Figma file (dark values come straight from
/// the design variables; light values are derived, since the file only draws
/// the dark theme).
@immutable
class LatticeColors extends ThemeExtension<LatticeColors> {
  const LatticeColors({
    required this.bg,
    required this.surface,
    required this.raised,
    required this.border,
    required this.key,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.success,
    required this.warning,
    required this.error,
    required this.lineHighlight,
    required this.scrim,
    required this.synKeyword,
    required this.synType,
    required this.synString,
    required this.synFunction,
    required this.synPunct,
    required this.synPlain,
  });

  final Color bg;
  final Color surface;
  final Color raised;
  final Color border;
  final Color key;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color success;
  final Color warning;
  final Color error;
  final Color lineHighlight;
  final Color scrim;
  final Color synKeyword;
  final Color synType;
  final Color synString;
  final Color synFunction;
  final Color synPunct;
  final Color synPlain;

  static const dark = LatticeColors(
    bg: Color(0xFF0E1116),
    surface: Color(0xFF151A21),
    raised: Color(0xFF1C222B),
    border: Color(0xFF262D38),
    key: Color(0xFF2B323E),
    text: Color(0xFFE6E9EF),
    textMuted: Color(0xFF8B94A5),
    textFaint: Color(0xFF5B6575),
    accent: Color(0xFF7AA2F7),
    onAccent: Color(0xFF0E1116),
    accentSoft: Color(0x297AA2F7), // 16%
    success: Color(0xFF9EE06A),
    warning: Color(0xFFE0AF68),
    error: Color(0xFFF7768E),
    lineHighlight: Color(0x0DFFFFFF), // 5%
    scrim: Color(0x8C000000),
    synKeyword: Color(0xFFF2916B),
    synType: Color(0xFF4FD1C5),
    synString: Color(0xFF9EE06A),
    synFunction: Color(0xFF7AA2F7),
    synPunct: Color(0xFF8B94A5),
    synPlain: Color(0xFFC9D1E0),
  );

  static const light = LatticeColors(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF4F6F9),
    raised: Color(0xFFFFFFFF),
    border: Color(0xFFDDE2EA),
    key: Color(0xFFE6EAF0),
    text: Color(0xFF1B2230),
    textMuted: Color(0xFF5F6B7E),
    textFaint: Color(0xFF9AA4B4),
    accent: Color(0xFF3B6FE0),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0x293B6FE0),
    success: Color(0xFF3F9B2B),
    warning: Color(0xFFB7791F),
    error: Color(0xFFD6455D),
    lineHighlight: Color(0x0D000000),
    scrim: Color(0x66000000),
    synKeyword: Color(0xFFC8501F),
    synType: Color(0xFF0E8F84),
    synString: Color(0xFF3F9B2B),
    synFunction: Color(0xFF3B6FE0),
    synPunct: Color(0xFF5F6B7E),
    synPlain: Color(0xFF2B3446),
  );

  @override
  ThemeExtension<LatticeColors> copyWith() => this;

  @override
  ThemeExtension<LatticeColors> lerp(
      covariant ThemeExtension<LatticeColors>? other, double t) {
    if (other is! LatticeColors) return this;
    return t < 0.5 ? this : other;
  }
}

extension LatticeContext on BuildContext {
  LatticeColors get c => Theme.of(this).extension<LatticeColors>()!;
}
