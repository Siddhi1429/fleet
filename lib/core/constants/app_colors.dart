import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6C3BFF);
  static const Color primaryMid = Color(0xFF8B5CFF);
  static const Color primaryDark = Color(0xFF5B2EFF);
  static const Color primaryLight = Color(0xFFB08AFF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5B2EFF), Color(0xFF8B5CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1340), Color(0xFF2A1B5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0D0A1E), Color(0xFF160F38)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Color darkBg = Color(0xFF0D0A1E);
  static const Color darkSurface = Color(0xFF160F38);
  static const Color darkCard = Color(0xFF1E1340);
  static const Color darkCardElevated = Color(0xFF241750);
  static const Color glassBorder = Color(0x33FFFFFF);

  static const Color lightBg = Color(0xFFF4F0FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFAF7FF);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B0D4);
  static const Color textMuted = Color(0xFF7B6EA8);
  static const Color textDark = Color(0xFF1A1033);

  static const Color online = Color(0xFF00E5A0);
  static const Color offline = Color(0xFFFF4E6A);
  static const Color warning = Color(0xFFFFB547);
  static const Color info = Color(0xFF47C5FF);

  static const Color fuelHigh = Color(0xFF00E5A0);
  static const Color fuelMid = Color(0xFFFFB547);
  static const Color fuelLow = Color(0xFFFF4E6A);

  static const Color accent = Color(0xFFFF6BDF);
  static const Color accentBlue = Color(0xFF47C5FF);
}
