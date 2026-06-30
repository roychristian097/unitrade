import 'dart:ui';
import 'package:flutter/material.dart';

class ThemeManager {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  static void toggleTheme() {
    themeNotifier.value = themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

class AppColors {
  final Color background;
  final Color primary;
  final Color cardBg;
  final Color textMuted;
  final Color border;
  final Color accent;
  final Color textPrimary;
  final Color glassBg;

  const AppColors({
    required this.background,
    required this.primary,
    required this.cardBg,
    required this.textMuted,
    required this.border,
    required this.accent,
    required this.textPrimary,
    required this.glassBg,
  });
}

class AppTheme {
  static const double radiusCard = 28.0;
  static const double radiusButton = 20.0;
  static const Color primaryBase = Color(0xFFFF8A00); // Oranye terang

  static const AppColors darkColors = AppColors(
    background: Color(0xFF161412),
    primary: primaryBase,
    cardBg: Color(0xFF211D1A),
    textMuted: Color(0xFF998F86),
    border: Color(0xFF38322D),
    accent: Color(0xFFF59E0B),
    textPrimary: Colors.white,
    glassBg: Color(0xFF1E1914),
  );

  static const AppColors lightColors = AppColors(
    background: Color(0xFFF8F5F1), // Off-white / light cream
    primary: primaryBase,
    cardBg: Colors.white,
    textMuted: Color(0xFF7A736E),
    border: Color(0xFFE5E0DA),
    accent: Color(0xFFF59E0B),
    textPrimary: Color(0xFF161412),
    glassBg: Color(0xFFFFFFFF),
  );

  static AppColors colors(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkColors : lightColors;
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkColors.background,
      primaryColor: darkColors.primary,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkColors.textPrimary),
        titleTextStyle: TextStyle(color: darkColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkColors.background,
        selectedItemColor: darkColors.primary,
        unselectedItemColor: darkColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      )
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightColors.background,
      primaryColor: lightColors.primary,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: lightColors.textPrimary),
        titleTextStyle: TextStyle(color: lightColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightColors.primary,
          foregroundColor: Colors.white, // Text inside primary button always white
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightColors.background,
        selectedItemColor: lightColors.primary,
        unselectedItemColor: lightColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      )
    );
  }
}

// Extension to make color access cleaner like `context.colors.primary`
extension ThemeContext on BuildContext {
  AppColors get colors => AppTheme.colors(this);
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = AppTheme.radiusCard,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.glassBg.withValues(alpha: isDark ? 0.65 : 0.8),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: colors.border.withValues(alpha: 0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                spreadRadius: 1,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
