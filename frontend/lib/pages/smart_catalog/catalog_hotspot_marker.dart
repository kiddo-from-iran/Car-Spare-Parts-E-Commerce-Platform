import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class CatalogHotspotMarker extends StatefulWidget {
  const CatalogHotspotMarker({
    super.key,
    required this.active,
    required this.highlighted,
    required this.onTap,
    required this.onHover,
    required this.label,
  });

  final bool active;
  final bool highlighted;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;
  final String label;

  @override
  State<CatalogHotspotMarker> createState() => _CatalogHotspotMarkerState();
}

class _CatalogHotspotMarkerState extends State<CatalogHotspotMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.active || widget.highlighted ? 1.15 : 1.0;

    return MouseRegion(
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    final t = _pulse.value;
                    final opacity = widget.active || widget.highlighted ? 0.45 : 0.25;
                    return Transform.scale(
                      scale: 1 + t * 0.8,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold.withValues(alpha: opacity * (1 - t)),
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: widget.active || widget.highlighted ? AppColors.gold : AppColors.gold.withValues(alpha: 0.85),
                      width: widget.active ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.35),
                        blurRadius: widget.active ? 12 : 6,
                        spreadRadius: widget.active ? 2 : 0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CatalogHotspotTooltip extends StatelessWidget {
  const CatalogHotspotTooltip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gold),
        ),
      ),
    );
  }
}
