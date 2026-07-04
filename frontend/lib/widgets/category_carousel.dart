import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

class CategoryCarousel extends StatefulWidget {
  const CategoryCarousel({
    super.key,
    required this.title,
    required this.items,
    required this.visibleItems,
    this.linkPrefix = '/shop',
    this.queryKey = 'vehicle',
    this.largeItems = false,
  });

  final String title;
  final List<CategoryItem> items;
  /// How many items fit on one screen/page (desktop target).
  final int visibleItems;
  final String linkPrefix;
  final String queryKey;
  /// Larger circles and labels (used for vehicle categories).
  final bool largeItems;

  @override
  State<CategoryCarousel> createState() => _CategoryCarouselState();
}

class _CategoryCarouselState extends State<CategoryCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  int _effectiveVisibleItems(double width) {
    if (width < 600) return widget.visibleItems <= 5 ? 2 : 4;
    if (width < 1024) return widget.visibleItems <= 5 ? 3 : 6;
    return widget.visibleItems;
  }

  int _pageCount(int perPage) =>
      widget.items.isEmpty ? 0 : (widget.items.length / perPage).ceil();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _nextPage(int pageCount) {
    if (_currentPage < pageCount - 1) _goToPage(_currentPage + 1);
  }

  void _prevPage() {
    if (_currentPage > 0) _goToPage(_currentPage - 1);
  }

  double _itemWidth(double screenWidth, int perPage, double padding, double spacing) {
    final available = screenWidth - padding * 2;
    return (available - spacing * (perPage - 1)) / perPage;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final padding = AppResponsive.pagePadding(context).toDouble();
    final perPage = _effectiveVisibleItems(screenWidth);
    final pageCount = _pageCount(perPage);
    final spacing = widget.largeItems ? 28.0 : 20.0;
    final itemWidth = _itemWidth(screenWidth, perPage, padding, spacing);
    final rowHeight = itemWidth + (widget.largeItems ? 64 : 48);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 24),
        Stack(
          children: [
            SizedBox(
              height: rowHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: pageCount,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, pageIndex) {
                  final start = pageIndex * perPage;
                  final pageItems = widget.items.skip(start).take(perPage).toList();
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < perPage; i++) ...[
                          if (i > 0) SizedBox(width: spacing),
                          Expanded(
                            child: i < pageItems.length
                                ? LayoutBuilder(
                                    builder: (context, constraints) => _CategoryCircle(
                                      size: constraints.maxWidth,
                                      name: pageItems[i].name,
                                      imageUrl: pageItems[i].image,
                                      large: widget.largeItems,
                                      onTap: () => context.go(
                                        '${widget.linkPrefix}?${widget.queryKey}=${Uri.encodeComponent(pageItems[i].name)}',
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            if (pageCount > 1) ...[
              PositionedDirectional(
                start: 4,
                top: itemWidth * 0.35,
                child: _NavCircle(
                  icon: Icons.chevron_left,
                  enabled: _currentPage > 0,
                  onTap: _prevPage,
                ),
              ),
              PositionedDirectional(
                end: 4,
                top: itemWidth * 0.35,
                child: _NavCircle(
                  icon: Icons.chevron_right,
                  enabled: _currentPage < pageCount - 1,
                  onTap: () => _nextPage(pageCount),
                ),
              ),
            ],
          ],
        ),
        if (pageCount > 1) ...[
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(pageCount, (i) {
                final active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.gold : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _CategoryCircle extends StatefulWidget {
  const _CategoryCircle({
    required this.size,
    required this.name,
    required this.imageUrl,
    required this.onTap,
    this.large = false,
  });

  final double size;
  final String name;
  final String imageUrl;
  final VoidCallback onTap;
  final bool large;

  @override
  State<_CategoryCircle> createState() => _CategoryCircleState();
}

class _CategoryCircleState extends State<_CategoryCircle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final circleSize = widget.size.clamp(widget.large ? 100.0 : 72.0, widget.large ? 220.0 : 140.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: AppColors.circleBg,
                shape: BoxShape.circle,
                boxShadow: _hovered ? [AppTheme.hoverShadow] : [AppTheme.softShadow],
              ),
              child: ClipOval(
                child: Padding(
                  padding: EdgeInsets.all(widget.large ? 14 : 10),
                  child: _CategoryImage(
                    source: widget.imageUrl,
                    circleSize: circleSize,
                    large: widget.large,
                  ),
                ),
              ),
            ),
            SizedBox(height: widget.large ? 14 : 10),
            Text(
              widget.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: widget.large
                        ? (AppResponsive.isPhone(context) ? 12 : 14)
                        : (AppResponsive.isPhone(context) ? 10 : 11),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({
    required this.source,
    required this.circleSize,
    required this.large,
  });

  final String source;
  final double circleSize;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      large ? Icons.directions_car_outlined : Icons.build_outlined,
      size: circleSize * 0.38,
      color: AppColors.gold,
    );

    if (source.startsWith('assets/')) {
      return Image.asset(source, fit: BoxFit.contain, errorBuilder: (_, __, ___) => fallback);
    }

    return CachedNetworkImage(
      imageUrl: source,
      fit: BoxFit.contain,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}

class _NavCircle extends StatelessWidget {
  const _NavCircle({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: enabled ? 3 : 0,
      color: enabled ? AppColors.white : AppColors.surfaceMuted,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 24,
            color: enabled ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
