import 'package:flutter/material.dart';
import 'tokens.dart';

ThemeData buildTheme(LatticeColors c, Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    splashFactory: InkRipple.splashFactory,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      secondary: c.accent,
      onSecondary: c.onAccent,
      error: c.error,
      onError: c.onAccent,
      surface: c.surface,
      onSurface: c.text,
    ),
    dividerColor: c.border,
    extensions: <ThemeExtension<dynamic>>[c],
  );
}
