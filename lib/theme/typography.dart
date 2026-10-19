import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// UI text uses IBM Plex Sans, code uses JetBrains Mono (both from the design).
class LatticeText {
  LatticeText._();

  static TextStyle ui(
    double size, {
    FontWeight weight = FontWeight.w400,
    required Color color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.ibmPlexSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w400,
    required Color color,
    double? height,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );
}
