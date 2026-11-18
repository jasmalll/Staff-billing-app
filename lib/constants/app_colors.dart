import 'package:flutter/material.dart';

/// Shared CaterPro design tokens. Screen widgets should prefer ColorScheme
/// for foreground/background colours so every surface adapts to dark mode.
class AppColors {
  static const Color background = Color(0xFFF3F8F6);
  static const Color primary = Color(0xFF103B43);
  static const Color primarySurface = Color(0xFF174D55);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF122D31);
  static const Color textSecondary = Color(0xFF667B7B);
  static const Color textMuted = Color(0xFF91A3A1);
  static const Color border = Color(0xFFDCE8E4);
  static const Color borderSubtle = Color(0xFFEAF1EE);
  static const Color success = Color(0xFF159B70);
  static const Color successLight = Color(0xFFDDF5EA);
  static const Color danger = Color(0xFFDC5656);
  static const Color dangerLight = Color(0xFFFCE8E8);
  static const Color warning = Color(0xFFC58A32);
  static const Color warningLight = Color(0xFFFBF1DE);
  static const Color teal = Color(0xFF159B88);
  static const Color roleSp = Color(0xFF4779C7);
  static const Color roleSpLight = Color(0xFFEAF1FC);
  static const Color roleCp = Color(0xFFC58A32);
  static const Color roleCpLight = Color(0xFFFBF1DE);

  // High-contrast foregrounds for dark surfaces. Keep the original light palette.
  static Color primaryText(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF72DCEB)
      : primary;
  static Color successText(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF55E6B5)
      : success;
  static Color dangerText(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFF737D)
      : danger;
}
