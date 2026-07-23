import 'package:flutter/material.dart';

/// BRAC brand palette (from BRAC colour palette reference).
class AppColors {
  AppColors._();

  // Primary
  static const Color magenta = Color(0xFFD10074); // Pantone Magenta

  // Secondary
  static const Color skyBlue = Color(0xFF3DB7E4); // Pantone 298 C
  static const Color orange = Color(0xFFFFA100); // Pantone 137 C
  static const Color lime = Color(0xFFC9D600); // Pantone 381 C
  static const Color coolGray = Color(0xFF4D4F53); // Pantone Cool Gray 11 C
  static const Color teal = Color(0xFF007161); // Pantone 3298 C
  static const Color purple = Color(0xFF80379B); // Pantone 2593 C
  static const Color neutralBlack = Color(0xFF27281C); // Pantone Neutral Black C
  static const Color tan = Color(0xFFD0AA8A); // Pantone 7590 C
  static const Color red = Color(0xFFA41E22); // Pantone 7621 C
  static const Color olive = Color(0xFF4D5732); // Pantone 7498 C
  static const Color periwinkle = Color(0xFF7B8FB9); // Pantone 652 C

  // Semantic roles (learner verify status)
  static const Color statusPending = orange;
  static const Color statusVerified = teal;
  static const Color statusDuplicate = red;
}
