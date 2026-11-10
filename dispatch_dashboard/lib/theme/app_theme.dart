import 'package:flutter/material.dart';

/// Global controller managing light/dark theme mode across the application.
class AppThemeController {
  AppThemeController._();

  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool get isDark => themeModeNotifier.value == ThemeMode.dark;

  static void toggleTheme() {
    themeModeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
  }

  static void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }
}

/// Central design tokens for the HIWONET-RESPONSE console.
///
/// Brand accents are fixed, while foundational surfaces and text colors
/// dynamically adapt to the active [ThemeMode] (Light vs. Dark).
/// In Dark Mode, surfaces turn deep dark/black while typography maintains
/// brilliant high-contrast legibility.
class AppColors {
  AppColors._();

  // Core brand constants
  static const Color brandRed = Color(0xFFFF1E56);
  static const Color brandRedDark = Color(0xFFCC1443);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  // Dynamic theme-reactive tokens
  static Color get ink =>
      AppThemeController.isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);

  static Color get inkSoft =>
      AppThemeController.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

  static Color get border =>
      AppThemeController.isDark ? const Color(0xFF283446) : const Color(0xFFE2E8F0);

  static Color get surface =>
      AppThemeController.isDark ? const Color(0xFF121722) : const Color(0xFFFFFFFF);

  static Color get canvas =>
      AppThemeController.isDark ? const Color(0xFF0A0D14) : const Color(0xFFFAF7F2);

  static Color get chipBg =>
      AppThemeController.isDark ? const Color(0xFF1A2232) : const Color(0xFFF1F5F9);
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  AppRadius._();
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 16;
}

ThemeData buildAppTheme({bool isDark = false}) {
  final brightness = isDark ? Brightness.dark : Brightness.light;
  final surface = isDark ? const Color(0xFF121722) : const Color(0xFFFFFFFF);
  final canvas = isDark ? const Color(0xFF0A0D14) : const Color(0xFFFAF7F2);
  final ink = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
  final inkSoft = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);
  final border = isDark ? const Color(0xFF283446) : const Color(0xFFE2E8F0);
  final card = isDark ? const Color(0xFF121722) : const Color(0xFFFFFFFF);
  final inputFill = isDark ? const Color(0xFF0E131F) : Colors.white;

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brandRed,
      brightness: brightness,
      primary: AppColors.brandRed,
      surface: surface,
      onSurface: ink,
      outline: border,
    ),
    scaffoldBackgroundColor: canvas,
    canvasColor: canvas,
    cardColor: card,
    fontFamily: 'Segoe UI',
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: ink,
      displayColor: ink,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandRed,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.brandRed, width: 1.5),
      ),
      labelStyle: TextStyle(color: inkSoft, fontSize: 13),
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
        fontSize: 13,
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: inkSoft, fontSize: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: border),
      ),
    ),
    dataTableTheme: DataTableThemeData(
      headingTextStyle: TextStyle(
        color: ink,
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
      ),
      dataTextStyle: TextStyle(
        color: ink,
        fontSize: 13,
      ),
      headingRowColor: WidgetStateProperty.all(
        isDark ? const Color(0xFF161E2E) : const Color(0xFFF1F5F9),
      ),
      dividerThickness: 1,
    ),
    dividerTheme: DividerThemeData(
      color: border,
      thickness: 1,
    ),
  );
}

/// Interactive toggle button for switching between Light and Dark mode.
class ThemeToggleButton extends StatelessWidget {
  final bool compact;
  final Color? color;

  const ThemeToggleButton({
    super.key,
    this.compact = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeModeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        final tooltip = isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode';
        final icon = isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined;
        final iconColor = color ?? (isDark ? const Color(0xFFFDE047) : AppColors.inkSoft);

        if (compact) {
          return Tooltip(
            message: tooltip,
            child: InkWell(
              onTap: AppThemeController.toggleTheme,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              hoverColor: AppColors.chipBg,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ),
          );
        }

        return Tooltip(
          message: tooltip,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: InkWell(
              onTap: AppThemeController.toggleTheme,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              hoverColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: iconColor),
                    const SizedBox(width: 6),
                    Text(
                      isDark ? 'Light' : 'Dark',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
