import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../utils/product_stock.dart';
import 'catalog_asset_image.dart';
import 'luxury_animations.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final p = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: AppCurves.luxurySoft,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hovered ? AppColors.gold : AppColors.border),
            boxShadow: _hovered ? [AppTheme.hoverShadow] : [AppTheme.softShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => context.go('/product/${p.id}'),
                        child: ColoredBox(
                          color: AppColors.surfaceMuted,
                          child: CatalogAssetImage(
                            source: p.images.first,
                            fit: BoxFit.contain,
                            placeholder: Container(color: AppColors.surfaceMuted),
                          ),
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
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${p.discountPercent.toInt()}%',
                            style: const TextStyle(
                              color: AppColors.textOnGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
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
                            color: AppColors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppStrings.newBadge,
                            style: const TextStyle(color: AppColors.gold, fontSize: 11),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AnimatedSlide(
                        offset: _hovered ? Offset.zero : const Offset(0, 1),
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: AnimatedOpacity(
                          opacity: _hovered ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: IgnorePointer(
                            ignoring: !_hovered,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.55),
                                  ],
                                ),
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: p.canPurchase
                                      ? () => cart.addItem(p, color: p.colors.first, size: p.sizes.first)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    elevation: 0,
                                  ),
                                  child: const Text(AppStrings.addToCart, style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p.brand.isNotEmpty)
                        Text(
                          p.brand,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                      ),
                      if (p.compatibleVehicles.isNotEmpty)
                        Text(
                          p.compatibleVehicles.first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                        ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: AppColors.rating),
                          const SizedBox(width: 2),
                          Text('${p.rating}', style: Theme.of(context).textTheme.labelSmall),
                          const Spacer(),
                          Text(
                            p.availabilityLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: p.canPurchase ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              AppStrings.formatPrice(p.price),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gold,
                                  ),
                              overflow: TextOverflow.ellipsis,
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
                    ],
                  ),
                ),
              ),
            ],
          ),
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
        childAspectRatio: AppResponsive.isPhone(context) ? 0.62 : 0.72,
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
