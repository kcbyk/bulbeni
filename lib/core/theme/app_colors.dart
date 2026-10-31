import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Colors (Primary UI)
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF141416);
  static const Color darkCard = Color(0xFF1A1A1E);
  static const Color darkCardBorder = Color(0xFF26262C);
  
  // Chip & Button Colors
  static const Color darkChipBackground = Color(0xFF1C1C1E);
  static const Color darkChipSelected = Color(0xFFFFFFFF);
  static const Color darkChipTextUnselected = Color(0xFF8E8E93);
  static const Color darkChipTextSelected = Color(0xFF000000);

  // Accent Colors
  static const Color electricBlue = Color(0xFF2F80ED);
  static const Color accentCyan = Color(0xFF00D2FF);
  
  // Text Colors
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF8E8E93);
  static const Color textTertiaryDark = Color(0xFF55555C);
  
  // Light Theme Colors (Clean Minimalist Alternative)
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE5E7EB);
  static const Color lightChipBackground = Color(0xFFF0F0F2);
  static const Color lightChipSelected = Color(0xFF000000);
  static const Color lightChipTextUnselected = Color(0xFF4B5563);
  static const Color lightChipTextSelected = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // Thumbnail Palette for Media / Documents
  static const List<Color> thumbnailGradients = [
    Color(0xFFA7444A), // Muted Wine/Red
    Color(0xFF485461), // Steel Slate
    Color(0xFF746755), // Warm Taupe
    Color(0xFF3B4A5A), // Navy Slate
    Color(0xFF5C5248), // Dark Khaki
    Color(0xFF4E3D52), // Dusty Purple
  ];

  static Color getThumbnailColor(int index) {
    return thumbnailGradients[index % thumbnailGradients.length];
  }
}
