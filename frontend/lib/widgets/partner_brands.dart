import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/search_suggestion.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

class PartnerBrandsSection extends StatefulWidget {
  const PartnerBrandsSection({super.key, required this.brands});

  final List<PartnerBrand> brands;

  @override
  State<PartnerBrandsSection> createState() => _PartnerBrandsSectionState();
}

class _PartnerBrandsSectionState extends State<PartnerBrandsSection> {
  final _scrollController = ScrollController();
  Timer? _autoScroll;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  void _startAutoScroll() {
    _autoScroll?.cancel();
    _autoScroll = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted || _paused || !_scrollController.hasClients) return;
      final half = _scrollController.position.maxScrollExtent / 2;
      if (half <= 0) return;
      final next = _scrollController.offset + 1.2;
      _scrollController.jumpTo(next >= half ? 0 : next);
    });
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      (_scrollController.offset + delta).clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.brands.isEmpty) return const SizedBox.shrink();

    final padding = AppResponsive.pagePadding(context);
    final isMobile = AppResponsive.isPhone(context);
    final items = [...widget.brands, ...widget.brands];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Text(
              AppStrings.partnerBrandsTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 28),
          MouseRegion(
            onEnter: (_) => setState(() => _paused = true),
            onExit: (_) => setState(() => _paused = false),
            child: SizedBox(
              height: isMobile ? 100 : 120,
              child: Stack(
                children: [
                  ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => SizedBox(width: isMobile ? 16 : 24),
                    itemBuilder: (context, index) => _BrandLogoCard(brand: items[index], compact: isMobile),
                  ),
                  if (!isMobile) ...[
                    PositionedDirectional(
                      start: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _NavBtn(icon: Icons.chevron_right, onTap: () => _scrollBy(-220)),
                      ),
                    ),
                    PositionedDirectional(
                      end: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _NavBtn(icon: Icons.chevron_left, onTap: () => _scrollBy(220)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLogoCard extends StatefulWidget {
  const _BrandLogoCard({required this.brand, required this.compact});
  final PartnerBrand brand;
  final bool compact;

  @override
  State<_BrandLogoCard> createState() => _BrandLogoCardState();
}

class _BrandLogoCardState extends State<_BrandLogoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.compact ? 120.0 : 160.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: w,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hovered ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border),
          boxShadow: _hovered ? [AppTheme.softShadow] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: widget.brand.logo,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => Icon(Icons.business, color: AppColors.textMuted, size: 32),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.brand.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: widget.compact ? 10 : 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: AppColors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 22, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
