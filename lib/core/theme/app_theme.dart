import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Wajz design system (PRD 17): calm, minimal, text-first.
/// Primary deep navy / muted teal, neutral backgrounds, muted amber accents,
/// red reserved for urgent confirmed alerts only.
abstract final class WajzColors {
  static const navy = Color(0xFF1C3A52);
  static const teal = Color(0xFF2F6D6A);
  static const amber = Color(0xFFB8862E);
  static const danger = Color(0xFFB3402E);

  static const lightBackground = Color(0xFFF7F6F3);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE6E3DC);
  static const lightTextPrimary = Color(0xFF1C2730);
  static const lightTextSecondary = Color(0xFF5C6A75);

  static const darkBackground = Color(0xFF101820);
  static const darkSurface = Color(0xFF1A2530);
  static const darkBorder = Color(0xFF2B3947);
  static const darkTextPrimary = Color(0xFFE8EAEC);
  static const darkTextSecondary = Color(0xFF9AA7B2);

  /// Confidence label tones (PRD 12.7) - calm, never alarming.
  static Color confidenceColor(String label, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (label) {
      case 'confirmed_by_multiple_sources':
        return dark ? const Color(0xFF6CA88F) : const Color(0xFF2E6B4F);
      case 'developing':
        return dark ? const Color(0xFFD0A75C) : amber;
      case 'single_source':
        return dark ? darkTextSecondary : lightTextSecondary;
      case 'opinion_analysis':
        return dark ? const Color(0xFF9B8FC4) : const Color(0xFF5E5187);
      case 'correction_or_update':
        return dark ? const Color(0xFF7FA8C9) : const Color(0xFF31618A);
      case 'low_confidence':
        return dark ? const Color(0xFFC98A7E) : danger;
      default:
        return dark ? darkTextSecondary : lightTextSecondary;
    }
  }
}

abstract final class WajzSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

ThemeData _build(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: dark ? const Color(0xFF7FB0AD) : WajzColors.teal,
    onPrimary: dark ? WajzColors.darkBackground : Colors.white,
    secondary: WajzColors.amber,
    onSecondary: Colors.white,
    error: WajzColors.danger,
    onError: Colors.white,
    surface: dark ? WajzColors.darkSurface : WajzColors.lightSurface,
    onSurface: dark ? WajzColors.darkTextPrimary : WajzColors.lightTextPrimary,
    onSurfaceVariant: dark ? WajzColors.darkTextSecondary : WajzColors.lightTextSecondary,
    outlineVariant: dark ? WajzColors.darkBorder : WajzColors.lightBorder,
  );

  final textTheme = GoogleFonts.interTextTheme(
    ThemeData(brightness: brightness).textTheme,
  ).apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: dark ? WajzColors.darkBackground : WajzColors.lightBackground,
    textTheme: textTheme.copyWith(
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.5),
      bodySmall: textTheme.bodySmall?.copyWith(height: 1.45),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? WajzColors.darkBackground : WajzColors.lightBackground,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(color: colorScheme.outlineVariant, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: dark ? WajzColors.darkBackground : WajzColors.lightBackground,
      side: BorderSide(color: colorScheme.outlineVariant),
      labelStyle: textTheme.labelMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

final lightTheme = _build(Brightness.light);
final darkTheme = _build(Brightness.dark);
