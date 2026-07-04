import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/smart_catalog.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/catalog_asset_image.dart';
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
    final hasImage = widget.view.image.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: AppColors.white,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 1,
              maxScale: hasImage ? 3 : 1,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: LayoutBuilder(
                  key: ValueKey(widget.view.id),
                  builder: (context, constraints) {
                    if (!hasImage) {
                      return CatalogViewPlaceholder(
                        viewName: widget.view.name,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                      );
                    }

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CatalogAssetImage(
                          key: _imageKey,
                          source: widget.view.image,
                          fit: BoxFit.contain,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          placeholder: const Center(
                            child: AppLoadingInline(size: 40),
                          ),
                          error: Icon(Icons.directions_car, size: 80, color: AppColors.textMuted.withValues(alpha: 0.4)),
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
          ],
        ),
      ),
    );
  }
}

class CatalogViewPlaceholder extends StatelessWidget {
  const CatalogViewPlaceholder({
    super.key,
    required this.viewName,
    required this.width,
    required this.height,
  });

  final String viewName;
  final double width;
  final double height;

  IconData _iconForView(String name) {
    if (name.contains('عقب')) return Icons.flip_to_back_outlined;
    if (name.contains('راست')) return Icons.arrow_back_ios_new;
    if (name.contains('چپ')) return Icons.arrow_forward_ios;
    if (name.contains('موتور')) return Icons.settings_outlined;
    if (name.contains('کابین') || name.contains('داخل')) return Icons.airline_seat_recline_normal_outlined;
    if (name.contains('ترمز')) return Icons.album_outlined;
    if (name.contains('تعلیق')) return Icons.height_outlined;
    if (name.contains('بیرونی')) return Icons.directions_car_outlined;
    return Icons.image_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width * 0.72, maxHeight: height * 0.72),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: CustomPaint(
                painter: _DashedBorderPainter(color: AppColors.gold.withValues(alpha: 0.45)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(_iconForView(viewName), size: 32, color: AppColors.gold.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        viewName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.catalogViewPlaceholder,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, 12, size.width - 24, size.height - 24),
      const Radius.circular(12),
    );

    final path = Path()..addRRect(r);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}
