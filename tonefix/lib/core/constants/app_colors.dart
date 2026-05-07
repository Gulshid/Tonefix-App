import 'package:flutter/material.dart';

/// ToneFix Design Tokens — Theme: Fintech / Banking
/// Deep navy authority meets crisp cyan precision.
/// Trusted, secure, institutional — yet modern.
abstract class AppColors {
  // ─── Brand ───────────────────────────────────────────────────────
  static const primary        = Color(0xFF0A2540); // Deep navy
  static const primaryLight   = Color(0xFF1A4A7A);
  static const primaryDark    = Color(0xFF061628);
  static const accent         = Color(0xFF00D4FF); // Electric cyan

  // ─── Tone Badge Colours ──────────────────────────────────────────
  static const toneProfessional = Color(0xFF0A2540);
  static const toneFriendly     = Color(0xFF00D4FF);
  static const toneAssertive    = Color(0xFF1652F0); // Coinbase-style blue
  static const toneEmpathetic   = Color(0xFF05C3A0);
  static const toneDiplomatic   = Color(0xFF635BFF); // Stripe-style violet
  static const toneCustom       = Color(0xFF1A4A7A);

  // ─── Neutrals ────────────────────────────────────────────────────
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF03090F);

  // ─── Light surface ───────────────────────────────────────────────
  static const surfaceLight       = Color(0xFFF4F7FB);
  static const cardLight          = Color(0xFFFFFFFF);
  static const borderLight        = Color(0xFFD6E4F0);
  static const textPrimaryLight   = Color(0xFF0A2540);
  static const textSecondaryLight = Color(0xFF546E8A);

  // ─── Dark surface ────────────────────────────────────────────────
  static const surfaceDark       = Color(0xFF03090F);
  static const cardDark          = Color(0xFF0A1628);
  static const borderDark        = Color(0xFF112240);
  static const textPrimaryDark   = Color(0xFFE8F1FB);
  static const textSecondaryDark = Color(0xFF6B90B0);

  // ─── Status ──────────────────────────────────────────────────────
  static const success = Color(0xFF05C3A0);
  static const error   = Color(0xFFE53935);
  static const warning = Color(0xFFFFA726);
}