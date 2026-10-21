import 'package:flutter/material.dart';

/// Bảng màu thương hiệu: xanh buýt Sài Gòn + cam ấm.
class Brand {
  static const green = Color(0xFF00A86B);
  static const greenDeep = Color(0xFF00704A);
  static const teal = Color(0xFF00897B);
  static const amber = Color(0xFFFFA726);
  static const coral = Color(0xFFFF6B4A);
  static const ink = Color(0xFF0F1B17);
  static const night = Color(0xFF0B1411);

  /// Màu số tuyến (ổn định theo số hiệu).
  static const routePalette = [
    Color(0xFF00A86B), Color(0xFF1E88E5), Color(0xFFE53935), Color(0xFF8E24AA), Color(0xFFFB8C00),
    Color(0xFF00897B), Color(0xFF3949AB), Color(0xFFD81B60), Color(0xFF6D4C41), Color(0xFF43A047),
  ];
  static Color routeColor(String ref) {
    final n = int.tryParse(ref.replaceAll(RegExp(r'\D'), ''));
    final i = n ?? ref.codeUnits.fold<int>(0, (a, b) => a + b);
    return routePalette[i % routePalette.length];
  }
}

class AppTheme {
  static const font = 'BeVietnamPro';

  static ThemeData _base(Brightness b) {
    final dark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: Brand.green,
      brightness: b,
      primary: dark ? const Color(0xFF3DDC97) : Brand.greenDeep,
      secondary: dark ? const Color(0xFF7FD6C8) : Brand.teal,
      tertiary: Brand.amber,
      onTertiary: Brand.ink,
      surface: dark ? Brand.night : const Color(0xFFF6F8F7),
      surfaceContainerLowest: dark ? const Color(0xFF0E1814) : Colors.white,
      surfaceContainerLow: dark ? const Color(0xFF13201B) : Colors.white,
      surfaceContainer: dark ? const Color(0xFF172620) : const Color(0xFFEFF3F1),
      surfaceContainerHigh: dark ? const Color(0xFF1C2D26) : const Color(0xFFE8EEEB),
      surfaceContainerHighest: dark ? const Color(0xFF22352D) : const Color(0xFFDFE7E3),
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: font, brightness: b);
    final tt = base.textTheme.apply(fontFamily: font, bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    return base.copyWith(
      textTheme: tt.copyWith(
        headlineMedium: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headlineSmall: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        titleLarge: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: font, fontSize: 12, fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500)),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontFamily: font, fontWeight: FontWeight.w700, fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerHigh,
        labelStyle: TextStyle(fontFamily: font, fontWeight: FontWeight.w600, color: scheme.onSurface, fontSize: 13),
      ),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: scheme.surfaceContainerLow, showDragHandle: true),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      }),
    );
  }

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);
}
