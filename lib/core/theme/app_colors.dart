import 'package:flutter/material.dart';

class AppColors {

  static const Color primary = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF2FA0DE);
  static const Color primaryDark = Color(0xFF0B2A4A);
  static const Color accent = Color(0xFF1878B0);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2FA0DE), Color(0xFF0B2A4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient instagramGradient = LinearGradient(
    colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF), Color(0xFF515BD4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient facebookGradient = LinearGradient(
    colors: [Color(0xFF1877F2), Color(0xFF0052CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF123452), Color(0xFF0C2740)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color authHeading = Color(0xFF1D4ED8);
  static const LinearGradient authBgGradient = LinearGradient(
    colors: [Color(0xFF071B2E), Color(0xFF1878B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient authButtonGradient = LinearGradient(
    colors: [Color(0xFF2FA0DE), Color(0xFF0B2A4A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Color facebook = Color(0xFF1877F2);
  static const Color instagram = Color(0xFFE1306C);
  static const Color whatsapp = Color(0xFF25D366);

  static const Color statusOpen = Color(0xFF3B82F6);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusResolved = Color(0xFF10B981);
  static const Color statusSnoozed = Color(0xFF8B5CF6);
  static const Color statusClosed = Color(0xFF6B7280);

  static const Color darkBg = Color(0xFF071B2E);
  static const Color darkSurface = Color(0xFF0C2740);
  static const Color darkCard = Color(0xFF123452);
  static const Color darkCardBorder = Color(0xFF1F4A6E);
  static const Color darkInputBg = Color(0xFF0C2740);

  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE2E8F0);
  static const Color lightInputBg = Color(0xFFF1F5F9);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  static const Color internalNoteBg = Color(0xFFFEF3C7);
  static const Color internalNoteText = Color(0xFF92400E);
  static const Color internalNoteBorder = Color(0xFFFDE68A);

  static const Color internalNoteBgDark = Color(0xFF2A2312);
  static const Color internalNoteTextDark = Color(0xFFFCD34D);
  static const Color internalNoteBorderDark = Color(0xFF5C470E);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}
