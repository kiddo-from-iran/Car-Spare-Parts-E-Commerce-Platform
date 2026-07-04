import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/smart_catalog.dart';
import '../../theme/app_theme.dart';
import 'catalog_hotspot_marker.dart';

class CatalogDiagram extends StatefulWidget {
  const CatalogDiagram({
    super.key,
    required this.view,
    required this.hotspots,
    required this.allHotspots,
    required this.selectedHotspotId,
    required this.highlightedHotspotId,
    required this.categoryFilter,
    required this.onHotspotTap,
    required this.onHotspotHover,
  });

  final CatalogView view;
  final List<CatalogHotspot> hotspots;
  final List<CatalogHotspot> allHotspots;
  final String? selectedHotspotId;
  final String? highlightedHotspotId;
  final String? categoryFilter;
  final ValueChanged<CatalogHotspot> onHotspotTap;
  final ValueChanged<CatalogHotspot?> onHotspotHover;

  @override
  State<CatalogDiagram> createState() => _CatalogDiagramState();
}

class _CatalogDiagramState extends State<CatalogDiagram> {
  String? _hoveredId;
  final _imageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final visibleIds = widget.hotspots.map((h) => h.id).toSet();
    final displayHotspots = widget.allHotspots;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: AppColors.catalogDark,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 1,
              maxScale: 3,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: LayoutBuilder(
                  key: ValueKey(widget.view.id),
                  builder: (context, constraints) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CachedNetworkImage(
                          key: _imageKey,
                          imageUrl: widget.view.image,
                          fit: BoxFit.contain,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                          ),
                          errorWidget: (_, __, ___) => const Icon(Icons.directions_car, size: 80, color: Colors.white24),
                        ),
                        ...displayHotspots.map((hotspot) {
                          final active = widget.selectedHotspotId == hotspot.id;
                          final highlighted = widget.highlightedHotspotId == hotspot.id;
                          final dimmed = widget.categoryFilter != null && !visibleIds.contains(hotspot.id);
                          final hovered = _hoveredId == hotspot.id;

                          return Positioned(
                            left: hotspot.x * constraints.maxWidth - 22,
                            top: hotspot.y * constraints.maxHeight - 22,
                            child: Opacity(
                              opacity: dimmed ? 0.25 : 1,
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  CatalogHotspotMarker(
                                    active: active,
                                    highlighted: highlighted,
                                    label: hotspot.label,
                                    onTap: () => widget.onHotspotTap(hotspot),
                                    onHover: (v) {
                                      setState(() => _hoveredId = v ? hotspot.id : null);
                                      widget.onHotspotHover(v ? hotspot : null);
                                    },
                                  ),
                                  if (hovered || active)
                                    Positioned(
                                      bottom: 36,
                                      child: AnimatedOpacity(
                                        opacity: hovered || active ? 1 : 0,
                                        duration: const Duration(milliseconds: 180),
                                        child: CatalogHotspotTooltip(label: hotspot.label),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_outlined, size: 16, color: AppColors.gold.withValues(alpha: 0.9)),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.catalogClickHint,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
