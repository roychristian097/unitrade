import 'package:flutter/material.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

extension ThemeColors on BuildContext {
  bool get isDark => themeNotifier.value == ThemeMode.dark;
  
  Color get bgColor => isDark ? const Color(0xFF0F0F11) : const Color(0xFFF8F9FA);
  Color get surfaceColor => isDark ? const Color(0xFF1E1E22) : Colors.white;
  Color get surfaceHighlight => isDark ? const Color(0xFF2A2A2E) : const Color(0xFFF0F0F0);
  
  Color get textColor => isDark ? Colors.white : const Color(0xFF1A1A1A);
  Color get textMuted => isDark ? Colors.grey.shade500 : Colors.grey.shade600;
  
  Color get borderColor => isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
}
