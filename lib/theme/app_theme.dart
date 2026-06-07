// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

// ─── Theme mode notifier (app-wide state) ────────────────────────────────────

class ThemeModeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark; // default: dark for field use

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}

// ─── Inherited widget so any descendant can read/write theme mode ─────────────

class AppThemeScope extends InheritedNotifier<ThemeModeNotifier> {
  const AppThemeScope({
    super.key,
    required ThemeModeNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ThemeModeNotifier of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'AppThemeScope not found in widget tree');
    return scope!.notifier!;
  }
}

// ─── Colour tokens ───────────────────────────────────────────────────────────

class AppColors {
  // Shared accent (same in both modes)
  static const Color accent      = Color(0xFFFF4D1C);
  static const Color accentSoft  = Color(0x33FF4D1C);
  static const Color accentGlow  = Color(0x1AFF4D1C);
  static const Color success     = Color(0xFF27AE60);
  static const Color warning     = Color(0xFFF39C12);
  static const Color danger      = Color(0xFFE74C3C);

  // ── Dark palette ───────────────────────────────────────────────────────────
  static const Color darkBackground  = Color(0xFF0D0F14);
  static const Color darkSurface     = Color(0xFF161A22);
  static const Color darkSurfaceAlt  = Color(0xFF1E2330);
  static const Color darkBorder      = Color(0xFF2A2F3D);
  static const Color darkText        = Color(0xFFF0F2F8);
  static const Color darkTextSec     = Color(0xFF8A91A8);
  static const Color darkTextMuted   = Color(0xFF4A5068);

  // ── Light palette ──────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF4F5F7);
  static const Color lightSurface    = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEEF0F4);
  static const Color lightBorder     = Color(0xFFD8DCE8);
  static const Color lightText       = Color(0xFF111318);
  static const Color lightTextSec    = Color(0xFF555E78);
  static const Color lightTextMuted  = Color(0xFFA0A8BF);
}

// ─── Helper: resolve colour based on current brightness ──────────────────────

extension ThemeColors on BuildContext {
  bool get isDark {
    final scope = dependOnInheritedWidgetOfExactType<AppThemeScope>();
    final mode = scope?.notifier?.mode ?? ThemeMode.dark;
    if (mode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(this) == Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }

  Color get appBackground  => isDark ? AppColors.darkBackground  : AppColors.lightBackground;
  Color get appSurface     => isDark ? AppColors.darkSurface     : AppColors.lightSurface;
  Color get appSurfaceAlt  => isDark ? AppColors.darkSurfaceAlt  : AppColors.lightSurfaceAlt;
  Color get appBorder      => isDark ? AppColors.darkBorder      : AppColors.lightBorder;
  Color get appText        => isDark ? AppColors.darkText        : AppColors.lightText;
  Color get appTextSec     => isDark ? AppColors.darkTextSec     : AppColors.lightTextSec;
  Color get appTextMuted   => isDark ? AppColors.darkTextMuted   : AppColors.lightTextMuted;
  Color get appAccent      => AppColors.accent;
}

// ─── ThemeData builders ───────────────────────────────────────────────────────

class AppTheme {
  // Keep these as static shortcuts for widgets that still need them
  static const Color accent       = AppColors.accent;
  static const Color accentSoft   = AppColors.accentSoft;
  static const Color accentGlow   = AppColors.accentGlow;
  static const Color success      = AppColors.success;
  static const Color warning      = AppColors.warning;
  static const Color danger       = AppColors.danger;

  // Dark static aliases (used in const contexts / painters that can't use context)
  static const Color background   = AppColors.darkBackground;
  static const Color surface      = AppColors.darkSurface;
  static const Color surfaceAlt   = AppColors.darkSurfaceAlt;
  static const Color border       = AppColors.darkBorder;
  static const Color textPrimary  = AppColors.darkText;
  static const Color textSecondary= AppColors.darkTextSec;
  static const Color textMuted    = AppColors.darkTextMuted;

  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg         = isDark ? AppColors.darkBackground  : AppColors.lightBackground;
    final surf       = isDark ? AppColors.darkSurface     : AppColors.lightSurface;
    final surfAlt    = isDark ? AppColors.darkSurfaceAlt  : AppColors.lightSurfaceAlt;
    final bord       = isDark ? AppColors.darkBorder      : AppColors.lightBorder;
    final txtPrimary = isDark ? AppColors.darkText        : AppColors.lightText;
    final txtSec     = isDark ? AppColors.darkTextSec     : AppColors.lightTextSec;
    final txtMuted   = isDark ? AppColors.darkTextMuted   : AppColors.lightTextMuted;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary:          AppColors.accent,
        onPrimary:        Colors.white,
        secondary:        AppColors.accent,
        onSecondary:      Colors.white,
        error:            AppColors.danger,
        onError:          Colors.white,
        surface:          surf,
        onSurface:        txtPrimary,
        outline:          bord,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: txtPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: txtPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: txtPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surf,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: txtMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surf,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: bord, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfAlt,
        labelStyle: TextStyle(color: txtSec),
        hintStyle: TextStyle(color: txtMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: bord, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: bord, thickness: 1),
      textTheme: TextTheme(
        displayLarge  : TextStyle(color: txtPrimary, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: txtPrimary, fontWeight: FontWeight.w700),
        titleLarge    : TextStyle(color: txtPrimary, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium   : TextStyle(color: txtPrimary, fontWeight: FontWeight.w600, fontSize: 15),
        bodyLarge     : TextStyle(color: txtPrimary, fontSize: 15),
        bodyMedium    : TextStyle(color: txtSec, fontSize: 13),
        labelLarge    : TextStyle(color: txtPrimary, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfAlt,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: bord, width: 1.5),
          ),
        ),
      ),
    );
  }
}
