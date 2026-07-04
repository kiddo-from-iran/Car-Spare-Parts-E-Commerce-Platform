import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import 'luxury_animations.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({super.key, required this.product, this.showQuickView = true});

  final Product product;
  final bool showQuickView;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final cart = context.read<CartProvider>();
    final isWishlisted = wishlist.isWishlisted(widget.product.id);
    final p = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: AppCurves.luxurySoft,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hovered ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
          boxShadow: _hovered ? [AppTheme.hoverShadow] : [AppTheme.softShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: GestureDetector(
                      onTap: () => context.go('/product/${p.id}'),
                      child: CachedNetworkImage(
                        imageUrl: p.images.first,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.surfaceMuted),
                      ),
                    ),
                  ),
                  if (p.hasDiscount)
                    PositionedDirectional(
                      top: 10,
                      start: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.discount,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${p.discountPercent.toInt()}%',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  if (p.isNew && p.inStock)
                    PositionedDirectional(
                      top: 10,
                      end: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(AppStrings.newBadge, style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    ),
                  PositionedDirectional(
                    bottom: 8,
                    end: 8,
                    child: IconButton(
                      icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border,
                          color: isWishlisted ? AppColors.discount : AppColors.textPrimary, size: 20),
                      style: IconButton.styleFrom(backgroundColor: AppColors.white, minimumSize: const Size(36, 36)),
                      onPressed: () => wishlist.toggle(p.id),
                    ),
                  ),
                  if (_hovered && widget.showQuickView)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.04),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Center(
                          child: OutlinedButton(
                            onPressed: () => context.go('/product/${p.id}'),
                            style: OutlinedButton.styleFrom(backgroundColor: AppColors.white),
                            child: const Text(AppStrings.quickView),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.brand.isNotEmpty)
                      Text(p.brand, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textMuted)),
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, height: 1.4),
                    ),
                    if (p.compatibleVehicles.isNotEmpty)
                      Text(
                        p.compatibleVehicles.first,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.accent, fontSize: 10),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: AppColors.rating),
                        const SizedBox(width: 2),
                        Text('${p.rating}', style: Theme.of(context).textTheme.labelSmall),
                        const Spacer(),
                        Text(
                          p.inStock ? AppStrings.inStock : AppStrings.outOfStock,
                          style: TextStyle(
                            fontSize: 10,
                            color: p.inStock ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          AppStrings.formatPrice(p.price),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                        ),
                        if (p.hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            AppStrings.formatPrice(p.originalPrice),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.textMuted,
                                ),
                          ),
                        ],
                      ],
                    ),
                    if (_hovered) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: p.inStock
                              ? () => cart.addItem(p, color: p.colors.first, size: p.sizes.first)
                              : null,
                          style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Text(AppStrings.addToCart, style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products, this.animate = false});

  final List<Product> products;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final columns = AppResponsive.productGridColumns(context);
    final spacing = AppResponsive.isPhone(context) ? 12.0 : 20.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: AppResponsive.isPhone(context) ? 0.58 : 0.62,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final card = ProductCard(product: products[index]);
        if (!animate) return card;
        return StaggeredFadeIn(index: index, child: card);
      },
    );
  }
}
