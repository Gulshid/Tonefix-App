import 'package:flutter/material.dart';

/// ToneFix Design Tokens
/// All colours used across the app defined in one place.
abstract class AppColors {
  // ─── Brand ───────────────────────────────────────────────────────
  static const primary = Color(0xFF6C5CE7);       // Violet
  static const primaryLight = Color(0xFF8F7FF0);
  static const primaryDark = Color(0xFF4B3DC8);
  static const accent = Color(0xFF00CEC9);         // Teal accent

  // ─── Tone Badge Colours ──────────────────────────────────────────
  static const toneProfessional = Color(0xFF2D3436);
  static const toneFriendly = Color(0xFFFDAA3B);
  static const toneAssertive = Color(0xFFE17055);
  static const toneEmpathetic = Color(0xFFE84393);
  static const toneDiplomatic = Color(0xFF00B894);
  static const toneCustom = Color(0xFF6C5CE7);

  // ─── Neutrals ────────────────────────────────────────────────────
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF0D0D0D);

  // ─── Light surface ───────────────────────────────────────────────
  static const surfaceLight = Color(0xFFF8F7FF);
  static const cardLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE8E4FF);
  static const textPrimaryLight = Color(0xFF1A1A2E);
  static const textSecondaryLight = Color(0xFF6B6B8A);

  // ─── Dark surface ────────────────────────────────────────────────
  static const surfaceDark = Color(0xFF0F0F1A);
  static const cardDark = Color(0xFF1A1A2E);
  static const borderDark = Color(0xFF2D2D4A);
  static const textPrimaryDark = Color(0xFFF0EEFF);
  static const textSecondaryDark = Color(0xFF9090B0);

  // ─── Status ──────────────────────────────────────────────────────
  static const success = Color(0xFF00B894);
  static const error = Color(0xFFE17055);
  static const warning = Color(0xFFFDAA3B);
}
