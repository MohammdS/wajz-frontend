import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A faint dot grid — a calm, modern "data" texture used behind brand
/// surfaces (hero headers, splash). Kept very low-contrast so text stays clean.
class WajzDotsPainter extends CustomPainter {
  WajzDotsPainter({
    required this.color,
    this.gap = 26,
    this.radius = 1.1,
    this.opacity = 0.10,
  });

  final Color color;
  final double gap;
  final double radius;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: opacity);
    for (var y = gap; y < size.height; y += gap) {
      for (var x = gap; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(WajzDotsPainter old) =>
      old.color != color || old.opacity != opacity || old.gap != gap;
}

/// A sleek navy brand panel: deep gradient, a faint dot grid, and a soft teal
/// glow. The hero surface for the briefing header, login, and splash.
class WajzHeroPanel extends StatelessWidget {
  const WajzHeroPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(WajzSpacing.lg),
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(WajzRadius.xl);
    final brand = context.brand;
    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: brand.brandGradient,
          border: Border.all(
            color: brand.onBrand.withValues(alpha: 0.08),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: WajzDotsPainter(color: Colors.white, opacity: 0.06),
              ),
            ),
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      brand.accentBright.withValues(alpha: 0.22),
                      brand.accentBright.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
