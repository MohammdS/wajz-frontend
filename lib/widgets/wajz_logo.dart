import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';

/// The Wajz brand mark shared with the launcher and browser icons.
class WajzLogoMark extends StatelessWidget {
  const WajzLogoMark({super.key, this.size = 40});

  /// Overall size of the square mark.
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/icon/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
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
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
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
    this.color,
    this.subColor,
    this.showLatin = true,
  });

  final double markSize;
  final double fontSize;
  final Color? color;
  final Color? subColor;
  final bool showLatin;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WajzLogoMark(size: markSize),
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
