import 'dart:ui';
import 'package:flutter/material.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class ThemeManager {
  static ValueNotifier<ThemeMode> get themeNotifier => globals_themeNotifier;
  static void toggleTheme() {
    globals_themeNotifier.value = globals_themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

// Rename the global one so it doesn't conflict
final ValueNotifier<ThemeMode> globals_themeNotifier = themeNotifier;

extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  
  Color get bgColor => isDark ? const Color(0xFF0F0F11) : const Color(0xFFF8F9FA);
  Color get surfaceColor => isDark ? const Color(0xFF1E1E22) : Colors.white;
  Color get surfaceHighlight => isDark ? const Color(0xFF2A2A2E) : const Color(0xFFF0F0F0);
  
  Color get textColor => isDark ? Colors.white : const Color(0xFF1A1A1A);
  Color get textMuted => isDark ? Colors.grey.shade500 : Colors.grey.shade600;
  
  Color get borderColor => isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
}

// Friend's Theme definitions
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
  static const Color primaryBase = Color(0xFFFF8A00);

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
    background: Color(0xFFF8F5F1),
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
