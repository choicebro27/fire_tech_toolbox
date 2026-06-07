// lib/theme/widgets.dart
// Shared UI components — colours resolved via BuildContext so they adapt
// to light / dark / auto theme switching.
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Section card with optional title
class TechCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsets? padding;

  const TechCard({super.key, this.title, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 3, height: 14,
                    color: AppColors.accent,
                    margin: const EdgeInsets.only(right: 8),
                  ),
                  Text(title!,
                    style: TextStyle(
                      color: context.appTextSec,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Divider(height: 1, thickness: 1, color: context.appBorder),
          ],
          Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Result/output display row
class ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool large;

  const ResultRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
          style: TextStyle(
            color: context.appTextSec,
            fontSize: large ? 14 : 13,
          ),
        ),
        Text(value,
          style: TextStyle(
            color: valueColor ?? context.appText,
            fontSize: large ? 20 : 14,
            fontWeight: large ? FontWeight.w800 : FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

/// Info/compliance callout box
class InfoBox extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;

  const InfoBox({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
              style: TextStyle(
                color: c.withValues(alpha: 0.9),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glowing accent badge
class AccentBadge extends StatelessWidget {
  final String text;
  const AccentBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(text,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
