import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Wajz design system — واجِز, "concise."
///
/// Modern Arab identity: smart, minimal, fast, credible. Deep navy for trust,
/// a fresh teal accent for clarity, calm neutral surfaces, strong geometric
/// typography. Arabic-inspired geometry is used lightly, never decoratively
/// (PRD 17: calm, credible, text-first).
abstract final class WajzColors {
  // Brand core
  static const navy = Color(0xFF0C2A4A); // trust / primary dark
  static const navyDeep = Color(0xFF08203A);
  static const teal = Color(0xFF0FA388); // fresh accent / primary action
  static const tealBright = Color(0xFF2DCCAE); // on-navy + dark mode
  static const amber = Color(0xFFC98A2E); // "developing" only
  static const danger = Color(0xFFD24B3A);

  // Light ("mist") surfaces
  static const lightBackground = Color(0xFFF5F7FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFEFF2F7);
  static const lightBorder = Color(0xFFE2E7EE);
  static const lightTextPrimary = Color(0xFF16202E);
  static const lightTextSecondary = Color(0xFF5E6B7B);

  // Dark ("midnight") surfaces
  static const darkBackground = Color(0xFF071728);
  static const darkSurface = Color(0xFF0E2742);
  static const darkSurfaceAlt = Color(0xFF12304F);
  static const darkBorder = Color(0xFF21405E);
  static const darkTextPrimary = Color(0xFFE8EDF3);
  static const darkTextSecondary = Color(0xFF93A4B8);

  /// Confidence label tones (PRD 12.7) — calm, never alarming.
  static Color confidenceColor(String label, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (label) {
      case 'confirmed_by_multiple_sources':
        return dark ? const Color(0xFF36C9A6) : const Color(0xFF0E8E76);
      case 'developing':
        return dark ? const Color(0xFFE0A85A) : amber;
      case 'single_source':
        return dark ? darkTextSecondary : lightTextSecondary;
      case 'opinion_analysis':
        return dark ? const Color(0xFF9BB0E6) : const Color(0xFF4B63A8);
      case 'correction_or_update':
        return dark ? const Color(0xFF6FB6D9) : const Color(0xFF2C7BA6);
      case 'low_confidence':
        return dark ? const Color(0xFFE08C7E) : danger;
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
  static const xxl = 48.0;
}

abstract final class WajzRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

/// Reusable brand gradients — restrained, never flashy.
abstract final class WajzGradients {
  static const navy = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF143A63), WajzColors.navyDeep],
  );

  static const teal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [WajzColors.tealBright, WajzColors.teal],
  );
}

/// A selectable colour theme. The neutral light surfaces and body text stay
/// shared across themes (calm, text-first — PRD 17); each palette swaps the
/// brand gradient, the accent, and the dark-mode surfaces so the app takes on a
/// distinct identity without losing legibility.
class WajzPalette {
  const WajzPalette({
    required this.id,
    required this.brandTop,
    required this.brandDeep,
    required this.accent,
    required this.accentBright,
    required this.darkBackground,
    required this.darkSurface,
    required this.darkSurfaceAlt,
    required this.darkBorder,
    this.onBrand = const Color(0xFFEAF1F8),
    this.onBrandMuted = const Color(0xFFB7C6D6),
    this.onBrandFaint = const Color(0xFF93A4B8),
    this.modeLock,
  });

  /// Stable key used for persistence and localized names.
  final String id;

  /// Forces the app into a fixed brightness when set (e.g. the white theme is
  /// always light, the black theme always dark). Null = follow the system.
  final ThemeMode? modeLock;

  /// Brand gradient start (lighter) and end (deep base).
  final Color brandTop;
  final Color brandDeep;

  /// Accent used as the primary action colour in light / dark mode.
  final Color accent;
  final Color accentBright;

  // Dark-mode neutrals, tinted to match the palette.
  final Color darkBackground;
  final Color darkSurface;
  final Color darkSurfaceAlt;
  final Color darkBorder;

  // Text/icon colours that sit on the brand gradient. Default to light tones
  // (for dark brand surfaces); a light/white palette overrides them with ink.
  final Color onBrand;
  final Color onBrandMuted;
  final Color onBrandFaint;
}

/// The four built-in themes shown in Profile › Appearance. The first entry is
/// the default (the original Wajz navy + teal).
const List<WajzPalette> wajzPalettes = [
  // "Onyx" — soft charcoal (not pure black) so it reads calm, not harsh.
  // Locked to dark mode.
  WajzPalette(
    id: 'black',
    brandTop: Color(0xFF2A2A2F),
    brandDeep: Color(0xFF18181C),
    accent: Color(0xFF0FA388),
    accentBright: Color(0xFF29BFA4),
    darkBackground: Color(0xFF131316),
    darkSurface: Color(0xFF1C1C21),
    darkSurfaceAlt: Color(0xFF26262C),
    darkBorder: Color(0xFF33333A),
    onBrand: Color(0xFFE4E8EE),
    onBrandMuted: Color(0xFF9BA2AD),
    onBrandFaint: Color(0xFF6B7178),
    modeLock: ThemeMode.dark,
  ),
  WajzPalette(
    id: 'royal_violet',
    brandTop: Color(0xFF332C73),
    brandDeep: Color(0xFF161232),
    accent: Color(0xFF6C4AE0),
    accentBright: Color(0xFF9D86FF),
    darkBackground: Color(0xFF0F0B26),
    darkSurface: Color(0xFF1B1640),
    darkSurfaceAlt: Color(0xFF241E52),
    darkBorder: Color(0xFF362D6B),
  ),
  WajzPalette(
    id: 'emerald',
    brandTop: Color(0xFF14463A),
    brandDeep: Color(0xFF07271D),
    accent: Color(0xFF0E9E6E),
    accentBright: Color(0xFF34D399),
    darkBackground: Color(0xFF06160F),
    darkSurface: Color(0xFF0C2A1E),
    darkSurfaceAlt: Color(0xFF103627),
    darkBorder: Color(0xFF1E4C39),
  ),
  WajzPalette(
    id: 'amber_dusk',
    brandTop: Color(0xFF4A3522),
    brandDeep: Color(0xFF241708),
    accent: Color(0xFFB9791C),
    accentBright: Color(0xFFF2B24A),
    darkBackground: Color(0xFF1A1206),
    darkSurface: Color(0xFF2A1F10),
    darkSurfaceAlt: Color(0xFF352815),
    darkBorder: Color(0xFF4A3A1E),
  ),
  // "Pearl" — soft warm-paper brand surfaces with calm slate text (not stark
  // black-on-white) and a gentle teal accent. Locked to light mode.
  WajzPalette(
    id: 'pearl',
    brandTop: Color(0xFFFCFDFE),
    brandDeep: Color(0xFFEBEFF4),
    accent: Color(0xFF0E9A82),
    accentBright: Color(0xFF13A88B),
    darkBackground: Color(0xFF0E1318),
    darkSurface: Color(0xFF181E25),
    darkSurfaceAlt: Color(0xFF202833),
    darkBorder: Color(0xFF313B47),
    onBrand: Color(0xFF2A3744),
    onBrandMuted: Color(0xFF616D7A),
    onBrandFaint: Color(0xFF8C97A4),
    modeLock: ThemeMode.light,
  ),
];

/// Looks up a palette by [id], falling back to the default.
WajzPalette wajzPaletteById(String? id) => wajzPalettes.firstWhere(
  (p) => p.id == id,
  orElse: () => wajzPalettes.first,
);

/// Theme-aware brand colours/gradients. Widgets read these via [context.brand]
/// so brand surfaces (hero, sidebar, splash, logo tile) follow the chosen theme.
class WajzBrand extends ThemeExtension<WajzBrand> {
  const WajzBrand({
    required this.brandGradient,
    required this.accentGradient,
    required this.accent,
    required this.accentBright,
    required this.brandTop,
    required this.brandDeep,
    required this.onBrand,
    required this.onBrandMuted,
    required this.onBrandFaint,
  });

  final LinearGradient brandGradient;
  final LinearGradient accentGradient;
  final Color accent;
  final Color accentBright;
  final Color brandTop;
  final Color brandDeep;

  /// Text colours that read well on the dark brand gradient (palette-agnostic).
  final Color onBrand;
  final Color onBrandMuted;
  final Color onBrandFaint;

  factory WajzBrand.of(WajzPalette p) => WajzBrand(
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [p.brandTop, p.brandDeep],
    ),
    accentGradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [p.accentBright, p.accent],
    ),
    accent: p.accent,
    accentBright: p.accentBright,
    brandTop: p.brandTop,
    brandDeep: p.brandDeep,
    onBrand: p.onBrand,
    onBrandMuted: p.onBrandMuted,
    onBrandFaint: p.onBrandFaint,
  );

  @override
  WajzBrand copyWith({
    LinearGradient? brandGradient,
    LinearGradient? accentGradient,
    Color? accent,
    Color? accentBright,
    Color? brandTop,
    Color? brandDeep,
    Color? onBrand,
    Color? onBrandMuted,
    Color? onBrandFaint,
  }) => WajzBrand(
    brandGradient: brandGradient ?? this.brandGradient,
    accentGradient: accentGradient ?? this.accentGradient,
    accent: accent ?? this.accent,
    accentBright: accentBright ?? this.accentBright,
    brandTop: brandTop ?? this.brandTop,
    brandDeep: brandDeep ?? this.brandDeep,
    onBrand: onBrand ?? this.onBrand,
    onBrandMuted: onBrandMuted ?? this.onBrandMuted,
    onBrandFaint: onBrandFaint ?? this.onBrandFaint,
  );

  @override
  WajzBrand lerp(ThemeExtension<WajzBrand>? other, double t) {
    if (other is! WajzBrand) return this;
    return WajzBrand(
      brandGradient: LinearGradient.lerp(brandGradient, other.brandGradient, t)!,
      accentGradient:
          LinearGradient.lerp(accentGradient, other.accentGradient, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentBright: Color.lerp(accentBright, other.accentBright, t)!,
      brandTop: Color.lerp(brandTop, other.brandTop, t)!,
      brandDeep: Color.lerp(brandDeep, other.brandDeep, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      onBrandMuted: Color.lerp(onBrandMuted, other.onBrandMuted, t)!,
      onBrandFaint: Color.lerp(onBrandFaint, other.onBrandFaint, t)!,
    );
  }
}

extension WajzBrandX on BuildContext {
  /// The active theme's brand colours. Falls back to the default palette.
  WajzBrand get brand =>
      Theme.of(this).extension<WajzBrand>() ?? WajzBrand.of(wajzPalettes.first);
}

/// Soft, cool brand shadow for elevated surfaces (used sparingly).
List<BoxShadow> wajzCardShadow(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return const [
      BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 6)),
    ];
  }
  return const [
    BoxShadow(color: Color(0x0F0C2A4A), blurRadius: 16, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x080C2A4A), blurRadius: 2, offset: Offset(0, 1)),
  ];
}

/// Display font (branding / headlines): Tajawal for Arabic, Space Grotesk for
/// Latin — both modern and geometric.
TextStyle wajzDisplayFont(Locale locale, {TextStyle? textStyle}) {
  return locale.languageCode == 'ar'
      ? GoogleFonts.tajawal(textStyle: textStyle)
      : GoogleFonts.spaceGrotesk(textStyle: textStyle);
}

ThemeData appTheme(
  Brightness brightness,
  Locale locale, {
  WajzPalette? palette,
}) {
  palette ??= wajzPalettes.first;
  final dark = brightness == Brightness.dark;
  final arabic = locale.languageCode == 'ar';

  final accent = dark ? palette.accentBright : palette.accent;
  final onAccent = dark ? palette.brandDeep : Colors.white;
  final surface = dark ? palette.darkSurface : WajzColors.lightSurface;
  final scaffoldBg = dark ? palette.darkBackground : WajzColors.lightBackground;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: accent,
    onPrimary: onAccent,
    primaryContainer: Color.alphaBlend(
      (dark ? palette.accentBright : palette.accent).withValues(alpha: 0.16),
      surface,
    ),
    onPrimaryContainer: dark ? palette.accentBright : palette.accent,
    secondary: accent,
    onSecondary: onAccent,
    secondaryContainer: Color.alphaBlend(
      accent.withValues(alpha: 0.12),
      surface,
    ),
    onSecondaryContainer: dark ? palette.accentBright : palette.brandDeep,
    error: WajzColors.danger,
    onError: Colors.white,
    surface: surface,
    surfaceContainerHighest:
        dark ? palette.darkSurfaceAlt : WajzColors.lightSurfaceAlt,
    onSurface: dark ? WajzColors.darkTextPrimary : WajzColors.lightTextPrimary,
    onSurfaceVariant:
        dark ? WajzColors.darkTextSecondary : WajzColors.lightTextSecondary,
    outline: dark ? palette.darkBorder : WajzColors.lightBorder,
    outlineVariant: dark ? palette.darkBorder : WajzColors.lightBorder,
  );

  // Body / UI font: IBM Plex Sans Arabic for Arabic, Inter for Latin.
  final base = ThemeData(brightness: brightness).textTheme;
  final bodyTheme = (arabic
          ? GoogleFonts.ibmPlexSansArabicTextTheme(base)
          : GoogleFonts.interTextTheme(base))
      .apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
  );

  // Display font for the large/branding slots.
  TextStyle display(TextStyle? s, {double? height}) =>
      wajzDisplayFont(locale, textStyle: s).copyWith(
        fontWeight: FontWeight.w700,
        height: height,
        letterSpacing: arabic ? 0 : -0.2,
      );

  final textTheme = bodyTheme.copyWith(
    displayLarge: display(bodyTheme.displayLarge, height: 1.05),
    displayMedium: display(bodyTheme.displayMedium, height: 1.08),
    displaySmall: display(bodyTheme.displaySmall, height: 1.1),
    headlineLarge: display(bodyTheme.headlineLarge, height: 1.15),
    headlineMedium: display(bodyTheme.headlineMedium, height: 1.2),
    headlineSmall: display(bodyTheme.headlineSmall, height: 1.25),
    titleLarge: display(bodyTheme.titleLarge, height: 1.3),
    titleMedium: bodyTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.35,
    ),
    titleSmall: bodyTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
    bodyLarge: bodyTheme.bodyLarge?.copyWith(height: 1.55),
    bodyMedium: bodyTheme.bodyMedium?.copyWith(height: 1.55),
    bodySmall: bodyTheme.bodySmall?.copyWith(height: 1.45),
    labelLarge: bodyTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: arabic ? 0 : 0.2,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldBg,
    extensions: [WajzBrand.of(palette)],
    textTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: scaffoldBg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle:
          dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      titleTextStyle: wajzDisplayFont(
        locale,
        textStyle: textTheme.titleLarge,
      ).copyWith(fontWeight: FontWeight.w700, fontSize: 23),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WajzRadius.lg),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scaffoldBg,
      side: BorderSide(color: colorScheme.outlineVariant),
      labelStyle: textTheme.labelMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WajzRadius.pill),
      ),
      showCheckmark: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colorScheme.primary.withValues(alpha: 0.14),
      height: 70,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelSmall?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WajzRadius.md),
        ),
        textStyle: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: arabic ? 0 : 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.outlineVariant),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WajzRadius.md),
        ),
        textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? WajzColors.darkSurfaceAlt : WajzColors.lightSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: WajzSpacing.md,
        vertical: WajzSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WajzRadius.md),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WajzRadius.md),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WajzRadius.md),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: WajzColors.navy,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WajzRadius.sm),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.outlineVariant,
    ),
  );
}

final lightTheme = appTheme(Brightness.light, const Locale('en'));
final darkTheme = appTheme(Brightness.dark, const Locale('en'));
