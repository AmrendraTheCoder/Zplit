import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

/// Available app themes.
enum AppThemeMode {
  midnight('Midnight', 'Dark premium theme'),
  arctic('Arctic', 'Clean light theme'),
  emerald('Emerald', 'Nature-inspired green');

  final String label;
  final String description;
  const AppThemeMode(this.label, this.description);

  Color get previewColor => switch (this) {
        AppThemeMode.midnight => const Color(0xFF0D1117),
        AppThemeMode.arctic => const Color(0xFFF0F4F8),
        AppThemeMode.emerald => const Color(0xFF064E3B),
      };

  Color get accentColor => switch (this) {
        AppThemeMode.midnight => AppColors.primary,
        AppThemeMode.arctic => const Color(0xFF3B82F6),
        AppThemeMode.emerald => const Color(0xFF10B981),
      };

  Brightness get brightness => switch (this) {
        AppThemeMode.midnight => Brightness.dark,
        AppThemeMode.arctic => Brightness.light,
        AppThemeMode.emerald => Brightness.dark,
      };
}

/// Manages theme state and persistence.
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  static const _key = 'zplit_theme';

  ThemeNotifier() : super(AppThemeMode.midnight) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    if (name != null) {
      try {
        state = AppThemeMode.values.firstWhere((t) => t.name == name);
      } catch (_) {
        // Invalid stored value — keep default
      }
    }
  }

  Future<void> setTheme(AppThemeMode theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, theme.name);
  }
}

/// Global theme provider.
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});
