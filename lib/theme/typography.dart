import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// UI text and code typography throughout Lattice.
/// Uses IBM Plex Mono font everywhere by default.
class LatticeText {
  LatticeText._();

  static TextStyle ui(
    double size, {
    FontWeight weight = FontWeight.w400,
    required Color color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.ibmPlexMono(
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
    String fontFamily = 'IBM Plex Mono',
  }) {
    try {
      return GoogleFonts.getFont(
        fontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );
    } catch (_) {
      return GoogleFonts.ibmPlexMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );
    }
  }
}
