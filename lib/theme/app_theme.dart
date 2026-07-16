import 'package:flutter/material.dart';

/// Brand tokens for the Follow-up Tracker.
/// Cool mist + marine ink + mint accent — clear hierarchy for daily
/// call/collections work. Money amounts keep a short mint underline.
class AppColors {
  static const ink = Color(0xFF0B1F33);
  static const paper = Color(0xFFF0F4F8);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFD5DEE8);
  static const muted = Color(0xFF6B7C8F);

  /// Primary accent — money tally underline, tabs, secondary highlights.
  static const amber = Color(0xFF1D9A8A);
  static const amberDeep = Color(0xFF0F6E63);

  static const teal = Color(0xFF1B8A5A);
  static const tealDeep = Color(0xFF146C46);
  static const tealBg = Color(0xFFE3F6EC);

  static const coral = Color(0xFFC73E3E);
  static const coralDeep = Color(0xFF9B2C2C);
  static const coralBg = Color(0xFFFDECEC);

  /// Pending / snooze — clear blue (not purple).
  static const violet = Color(0xFF2B6CB0);
  static const violetBg = Color(0xFFE8F1FB);

  /// Soft fill for avatars / secondary buttons.
  static const softFill = Color(0xFFE4EAF1);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.ink,
        secondary: AppColors.amber,
        surface: AppColors.card,
        error: AppColors.coral,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.amber, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.amber,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.amber.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.ink : AppColors.muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.amberDeep : AppColors.muted,
          );
        }),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
    );
  }
}

/// Status semantics used across badges, chips, and follow-up cards.
enum FollowUpStatus { pending, completed, overdue }

extension FollowUpStatusX on FollowUpStatus {
  Color get bg {
    switch (this) {
      case FollowUpStatus.pending:
        return AppColors.violetBg;
      case FollowUpStatus.completed:
        return AppColors.tealBg;
      case FollowUpStatus.overdue:
        return AppColors.coralBg;
    }
  }

  Color get fg {
    switch (this) {
      case FollowUpStatus.pending:
        return AppColors.violet;
      case FollowUpStatus.completed:
        return AppColors.tealDeep;
      case FollowUpStatus.overdue:
        return AppColors.coralDeep;
    }
  }

  String get label {
    switch (this) {
      case FollowUpStatus.pending:
        return 'Pending';
      case FollowUpStatus.completed:
        return 'Completed';
      case FollowUpStatus.overdue:
        return 'Overdue';
    }
  }
}
