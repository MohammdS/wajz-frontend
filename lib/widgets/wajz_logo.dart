import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';

/// The Wajz brand mark: three "headline lines" condensing into one short,
/// highlighted line — the visual of واجِز, "concise." Long story in, clear
/// summary out. Minimal, geometric, recognisable at any size.
class WajzLogoMark extends StatelessWidget {
  const WajzLogoMark({
    super.key,
    this.size = 40,
    this.tile = false,
    this.lineColor,
    this.accentColor,
  });

  /// Overall size of the square mark (including the tile, if shown).
  final double size;

  /// Draw the mark inside a navy "app-icon" squircle.
  final bool tile;

  /// Color of the two neutral lines (defaults sensibly for tile / surface).
  final Color? lineColor;

  /// Color of the short summary line (defaults to teal accent).
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    if (tile) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: brand.brandGradient,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: brand.accentBright.withValues(alpha: 0.22)),
        ),
        child: Center(
          child: CustomPaint(
            size: Size.square(size * 0.62),
            painter: _LinesPainter(
              lineColor: lineColor ?? brand.onBrand,
              accentColor: accentColor ?? brand.accentBright,
            ),
          ),
        ),
      );
    }
    return CustomPaint(
      size: Size.square(size),
      painter: _LinesPainter(
        lineColor: lineColor ?? theme.colorScheme.onSurface,
        accentColor: accentColor ?? theme.colorScheme.primary,
      ),
    );
  }
}

/// The Arabic + Latin wordmark, stacked.
class WajzWordmark extends StatelessWidget {
  const WajzWordmark({
    super.key,
    this.fontSize = 34,
    this.color,
    this.subColor,
    this.showLatin = true,
    this.center = false,
  });

  final double fontSize;
  final Color? color;
  final Color? subColor;
  final bool showLatin;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final main = color ?? theme.colorScheme.onSurface;
    final sub = subColor ?? theme.colorScheme.primary;
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'واجِز',
          textDirection: TextDirection.rtl,
          style: GoogleFonts.tajawal(
            textStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: main,
              height: 1.0,
            ),
          ),
        ),
        if (showLatin) ...[
          const SizedBox(height: 3),
          Text(
            'Wajz',
            style: GoogleFonts.spaceGrotesk(
              textStyle: TextStyle(
                fontSize: fontSize * 0.40,
                fontWeight: FontWeight.w600,
                letterSpacing: fontSize * 0.06,
                color: sub,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Mark + wordmark lockup.
class WajzLogo extends StatelessWidget {
  const WajzLogo({
    super.key,
    this.markSize = 44,
    this.fontSize = 30,
    this.tile = true,
    this.color,
    this.subColor,
    this.showLatin = true,
  });

  final double markSize;
  final double fontSize;
  final bool tile;
  final Color? color;
  final Color? subColor;
  final bool showLatin;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WajzLogoMark(size: markSize, tile: tile),
        const SizedBox(width: WajzSpacing.sm + 2),
        WajzWordmark(
          fontSize: fontSize,
          color: color,
          subColor: subColor,
          showLatin: showLatin,
        ),
      ],
    );
  }
}

class _LinesPainter extends CustomPainter {
  _LinesPainter({required this.lineColor, required this.accentColor});

  final Color lineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final x0 = s * 0.16;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.13;

    void line(double y, double len, Color c) {
      paint.color = c;
      canvas.drawLine(Offset(x0, y * s), Offset((x0 + len * s), y * s), paint);
    }

    line(0.26, 0.68, lineColor);
    line(0.50, 0.50, lineColor);
    line(0.74, 0.32, accentColor);
  }

  @override
  bool shouldRepaint(_LinesPainter old) =>
      old.lineColor != lineColor || old.accentColor != accentColor;
}
