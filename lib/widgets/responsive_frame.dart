import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'wajz_logo.dart';

/// Below this width we are on a phone (or a narrow browser) and render the app
/// exactly as the mobile design intends — full-bleed, edge to edge.
const double _kFrameBreakpoint = 720;

/// Maximum readable width of the app column on large screens. Wajz is a
/// text-first reading app, so we keep a comfortable single-column measure
/// rather than stretching cards across a desktop monitor.
const double _kPanelMaxWidth = 460;

/// Caps the panel height on very tall windows so it reads as a focused,
/// device-like surface instead of an over-long ribbon.
const double _kPanelMaxHeight = 1040;

/// Wraps the routed app so it looks intentional on desktop/tablet web while
/// staying pixel-identical on phones.
///
/// - Narrow viewports: returns [child] untouched (mobile layout, bottom nav).
/// - Wide viewports: centres the app in a floating, rounded "app panel" on an
///   on-brand navy backdrop, and overrides [MediaQuery] so screens lay out to
///   the panel size (keyboard insets, sizing, etc. stay correct).
class ResponsiveWebFrame extends StatelessWidget {
  const ResponsiveWebFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < _kFrameBreakpoint) return child;

        final height = constraints.maxHeight;
        final vMargin = height >= 760 ? 28.0 : 0.0;
        final brand = context.brand;

        return DecoratedBox(
          decoration: BoxDecoration(gradient: brand.brandGradient),
          child: Stack(
            children: [
              // Soft accent glow, top-trailing — echoes the splash screen.
              Positioned(
                top: -180,
                right: -120,
                child: _GlowOrb(
                  color: brand.accentBright.withValues(alpha: 0.16),
                  size: math.min(width * 0.6, 560),
                ),
              ),
              // Faint brand watermark, bottom-leading.
              Positioned(
                left: -40,
                bottom: -50,
                child: Opacity(
                  opacity: 0.05,
                  child: WajzLogoMark(
                    size: math.min(width * 0.4, 420),
                    lineColor: Colors.white,
                    accentColor: brand.accentBright,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: vMargin,
                    horizontal: WajzSpacing.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _kPanelMaxWidth,
                      maxHeight: _kPanelMaxHeight,
                    ),
                    child: _AppPanel(rounded: vMargin > 0, child: child),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The floating app surface: rounded, bordered, elevated, with [MediaQuery]
/// resized to its own bounds so the app inside behaves as if on a phone.
class _AppPanel extends StatelessWidget {
  const _AppPanel({required this.child, required this.rounded});

  final Widget child;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(rounded ? WajzRadius.xl : 0);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: context.brand.accentBright.withValues(alpha: dark ? 0.14 : 0.20),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 60,
            spreadRadius: -12,
            offset: Offset(0, 30),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                viewInsets: EdgeInsets.zero,
                viewPadding: EdgeInsets.zero,
                padding: EdgeInsets.zero,
              ),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
