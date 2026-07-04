import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/smart_catalog.dart';
import '../../providers/cart_provider.dart';
import '../../providers/toast_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';

class CatalogProductPanel extends StatelessWidget {
  const CatalogProductPanel({
    super.key,
    required this.data,
    required this.loading,
    required this.vehicleName,
    this.compact = false,
  });

  final CatalogHotspotProduct? data;
  final bool loading;
  final String vehicleName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold));
    }

    final item = data;
    if (item == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_outlined, size: 48, color: AppColors.gold.withValues(alpha: 0.6)),
              const SizedBox(height: 12),
              Text(
                AppStrings.catalogClickHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    final product = item.product;
    final wishlist = context.watch<WishlistProvider>();
    final inWishlist = wishlist.isWishlisted(product.id);

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.hotspot.label,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showZoom(context, product.images.first),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: CachedNetworkImage(
                  imageUrl: product.images.first,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => ColoredBox(
                    color: AppColors.catalogPanel,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoTable(
            rows: [
              (AppStrings.partNumber, item.partNumber),
              (AppStrings.productBrand, product.brand),
              ('خودرو', vehicleName),
              ('موقعیت', item.hotspot.label),
              (AppStrings.manufacturer, product.brand),
              (AppStrings.country, product.manufacturerCountry),
              (AppStrings.material, item.material),
              (AppStrings.weight, '${item.weightGrams} ${AppStrings.grams}'),
              (AppStrings.warranty, item.warranty),
              (AppStrings.availability, product.inStock ? AppStrings.inStock : AppStrings.outOfStock),
              (AppStrings.price, AppStrings.formatPrice(product.price)),
              if (product.hasDiscount) ('تخفیف', '${product.discountPercent.toStringAsFixed(0)}٪'),
              ('دسته‌بندی', product.partCategory.isNotEmpty ? product.partCategory : product.category),
            ],
            stockIn: product.inStock,
            priceHighlight: true,
          ),
          if (product.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              product.description,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), height: 1.6, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: product.inStock
                ? () {
                    context.read<CartProvider>().addItem(product);
                    context.read<ToastProvider>().show(AppStrings.addToCart);
                  }
                : null,
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text(AppStrings.addToCart),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/product/${product.id}'),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text(AppStrings.viewProduct),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: AppStrings.addToWishlist,
                onPressed: () => wishlist.toggle(product.id),
                icon: Icon(inWishlist ? Icons.favorite : Icons.favorite_border, color: inWishlist ? Colors.redAccent : Colors.white70),
              ),
              IconButton(
                tooltip: AppStrings.share,
                onPressed: () {},
                icon: Icon(Icons.share_outlined, color: Colors.white.withValues(alpha: 0.7)),
              ),
            ],
          ),
          if (item.related.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              AppStrings.relatedProducts,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: compact ? 260 : 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: item.related.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => SizedBox(
                  width: 180,
                  child: ProductCard(product: item.related[index]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showZoom(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTable extends StatelessWidget {
  const _InfoTable({
    required this.rows,
    this.stockIn = true,
    this.priceHighlight = false,
  });

  final List<(String, String)> rows;
  final bool stockIn;
  final bool priceHighlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.catalogPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)))
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      rows[i].$1,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: _valueColor(rows[i].$1, stockIn),
                        fontSize: rows[i].$1 == AppStrings.price ? 15 : 13,
                        fontWeight: rows[i].$1 == AppStrings.price || rows[i].$1 == AppStrings.availability
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _valueColor(String label, bool stockIn) {
    if (label == AppStrings.availability) return stockIn ? AppColors.success : Colors.redAccent;
    if (label == AppStrings.price && priceHighlight) return AppColors.gold;
    return Colors.white.withValues(alpha: 0.92);
  }
}
