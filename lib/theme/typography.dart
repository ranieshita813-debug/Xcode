import 'package:flutter/material.dart';

/// UI text and code typography throughout Lattice.
/// Uses Space Grotesk for non-code UI text.
/// Uses Iosevka for code with full OpenType ligatures enabled (`calt`, `liga`, `dlig`, `clig`).
class LatticeText {
  LatticeText._();

  static TextStyle ui(
    double size, {
    FontWeight weight = FontWeight.w400,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Space Grotesk',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w400,
    required Color color,
    double? height,
    String fontFamily = 'Iosevka',
    bool enableLigatures = true,
  }) {
    final fontFeatures = enableLigatures
        ? const [
            FontFeature.enable('calt'),
            FontFeature.enable('liga'),
            FontFeature.enable('dlig'),
            FontFeature.enable('clig'),
          ]
        : <FontFeature>[];

    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      fontFeatures: fontFeatures,
    );
  }
}
