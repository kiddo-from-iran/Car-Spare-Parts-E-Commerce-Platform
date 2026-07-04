import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import 'luxury_animations.dart';

class FeatureCards extends StatelessWidget {
  const FeatureCards({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = AppResponsive.pagePadding(context);
    final isMobile = AppResponsive.widthOf(context) < 768;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 48),
      child: Column(
        children: [
          Text(
            AppStrings.storeFeaturesTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 32),
          if (isMobile)
            Column(
              children: AppStrings.features
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _FeatureCard(title: f.$1, subtitle: f.$2, icon: f.$3),
                      ))
                  .toList(),
            )
          else
            Row(
              children: AppStrings.features.asMap().entries.map((entry) {
                final (title, subtitle, icon) = entry.value;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: entry.key == 0 ? 0 : 12,
                      end: entry.key == AppStrings.features.length - 1 ? 0 : 12,
                    ),
                    child: StaggeredFadeIn(
                      index: entry.key,
                      child: _FeatureCard(title: title, subtitle: subtitle, icon: icon),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? AppColors.gold.withValues(alpha: 0.3) : AppColors.border,
          ),
          boxShadow: _hovered ? [AppTheme.hoverShadow] : [AppTheme.softShadow],
        ),
        transform: _hovered ? (Matrix4.identity()..translate(0.0, -4.0)) : Matrix4.identity(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, size: 32, color: AppColors.gold),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
