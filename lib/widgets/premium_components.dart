import 'dart:ui';

import 'package:flutter/material.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final Color? tint;
  final double blur;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.tint,
    this.blur = 12,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = tint ?? Theme.of(context).colorScheme.surface;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                base.withValues(alpha: dark ? .88 : .96),
                base.withValues(alpha: dark ? .68 : .88),
              ],
            ),
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: dark ? .10 : .65),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? .16 : .04),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const MetricPill({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: .20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 7),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(width: 7),
          Text(value, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class AnalyticsItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  const AnalyticsItem({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: accent.withValues(alpha: .13), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: accent, size: 19),
          ),
          const SizedBox(height: 9),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -.3)),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
