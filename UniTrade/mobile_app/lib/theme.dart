import 'dart:ui';
import 'package:flutter/material.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

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
  
  Color get bgColor => isDark ? const Color(0xFF0D0D0E) : const Color(0xFFFAF8F5);
  Color get surfaceColor => isDark ? const Color(0xFF16161A) : Colors.white;
  Color get surfaceHighlight => isDark ? const Color(0xFF22222A) : const Color(0xFFF5F0EB);
  
  Color get textColor => isDark ? Colors.white : const Color(0xFF1A1A1A);
  Color get textMuted => isDark ? const Color(0xFF8A8A93) : Colors.grey.shade600;
  
  Color get borderColor => isDark ? const Color(0xFF25252A) : Colors.black.withValues(alpha: 0.06);
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
  // New vibrant colors matching Rockart
  final Color primaryLight;
  final Color primaryDark;
  final Color promoGradientStart;
  final Color promoGradientEnd;
  final Color cardShadow;
  final Color successGreen;
  final Color warmGrey;

  const AppColors({
    required this.background,
    required this.primary,
    required this.cardBg,
    required this.textMuted,
    required this.border,
    required this.accent,
    required this.textPrimary,
    required this.glassBg,
    required this.primaryLight,
    required this.primaryDark,
    required this.promoGradientStart,
    required this.promoGradientEnd,
    required this.cardShadow,
    required this.successGreen,
    required this.warmGrey,
  });
}

class AppTheme {
  static const double radiusCard = 24.0;
  static const double radiusButton = 30.0;
  static const Color primaryBase = Color(0xFFFF5500); // Neon Orange

  static const AppColors darkColors = AppColors(
    background: Color(0xFF0D0D0E), // Rockart Pure Dark Background
    primary: primaryBase,
    cardBg: Color(0xFF16161A), // Rockart card surface
    textMuted: Color(0xFF8A8A93),
    border: Color(0xFF25252A),
    accent: Color(0xFFFF5500),
    textPrimary: Colors.white,
    glassBg: Color(0xFF121215),
    primaryLight: Color(0xFFFF884D),
    primaryDark: Color(0xFFCC4400),
    promoGradientStart: Color(0xFFFF5500),
    promoGradientEnd: Color(0xFFB33300),
    cardShadow: Color(0x7F000000),
    successGreen: Color(0xFF00E676),
    warmGrey: Color(0xFF22222A),
  );

  static const AppColors lightColors = AppColors(
    background: Color(0xFFFAF8F5),
    primary: primaryBase,
    cardBg: Colors.white,
    textMuted: Color(0xFF7A736E),
    border: Color(0xFFE5E0DA),
    accent: Color(0xFFFF5500),
    textPrimary: Color(0xFF161412),
    glassBg: Color(0xFFFFFFFF),
    primaryLight: Color(0xFFFFECE3),
    primaryDark: Color(0xFFCC4400),
    promoGradientStart: Color(0xFFFF7733),
    promoGradientEnd: Color(0xFFFF5500),
    cardShadow: Color(0x14000000),
    successGreen: Color(0xFF00E676),
    warmGrey: Color(0xFFF0EBE5),
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
