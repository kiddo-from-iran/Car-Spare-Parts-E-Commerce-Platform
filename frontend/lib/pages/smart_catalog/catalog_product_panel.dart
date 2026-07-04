import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/product.dart';
import '../../models/smart_catalog.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../utils/product_stock.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/product_specs_table.dart';

class CatalogProductPanel extends StatelessWidget {
  const CatalogProductPanel({
    super.key,
    required this.data,
    required this.loading,
    required this.vehicleName,
    this.compact = false,
    this.showSpecsTable = true,
  });

  final CatalogHotspotProduct? data;
  final bool loading;
  final String vehicleName;
  final bool compact;
  final bool showSpecsTable;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const AppLoadingCenter(size: 72);
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
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    final products = item.allProducts;

    return Padding(
      padding: EdgeInsets.all(compact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.hotspot.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (products.length > 1) ...[
            const SizedBox(height: 8),
            Text(
              '${products.length} محصول مرتبط با این نقطه',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          ...products.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (index > 0) ...[
                  const SizedBox(height: 24),
                  Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 24),
                ],
                _CatalogProductBlock(
                  item: item,
                  product: product,
                  vehicleName: vehicleName,
                  showSpecsTable: showSpecsTable,
                  compact: compact,
                  showProductTitle: products.length > 1,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _CatalogProductBlock extends StatelessWidget {
  const _CatalogProductBlock({
    required this.item,
    required this.product,
    required this.vehicleName,
    required this.showSpecsTable,
    required this.compact,
    required this.showProductTitle,
  });

  final CatalogHotspotProduct item;
  final Product product;
  final String vehicleName;
  final bool showSpecsTable;
  final bool compact;
  final bool showProductTitle;

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final cart = context.watch<CartProvider>();
    final inWishlist = wishlist.isWishlisted(product.id);
    final canAdd = canAddProductToCart(product, cart.items);
    final isPhone = AppResponsive.isPhone(context);
    const imageSize = 280.0;
    final imageUrl = _resolveImage(context, product.images.first);

    Widget imageBlock = _ProductImage(
      imageUrl: imageUrl,
      size: isPhone ? double.infinity : imageSize,
      onTap: () => _showZoom(context, imageUrl),
    );

    Widget specsBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'مشخصات فنی',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ProductSpecsTable(
          rows: catalogProductSpecRows(item, product, vehicleName),
          stockIn: product.canPurchase,
        ),
      ],
    );

    Widget addToCartButton = FilledButton.icon(
      onPressed: canAdd ? () => context.read<CartProvider>().addItem(product) : null,
      icon: const Icon(Icons.shopping_cart_outlined, size: 18),
      label: const Text(AppStrings.addToCart),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.textOnGold,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Widget imageColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        imageBlock,
        const SizedBox(height: 12),
        addToCartButton,
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: AppStrings.addToWishlist,
              onPressed: () => wishlist.toggle(product.id),
              icon: Icon(
                inWishlist ? Icons.favorite : Icons.favorite_border,
                color: inWishlist ? AppColors.gold : AppColors.black,
              ),
            ),
            IconButton(
              tooltip: AppStrings.share,
              onPressed: () {},
              icon: const Icon(Icons.share_outlined, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showProductTitle) ...[
          Text(
            product.name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
          ),
          if (product.brand.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              product.brand,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
        ],
        if (product.description.isNotEmpty) ...[
          Text(
            product.description,
            style: TextStyle(color: AppColors.textSecondary, height: 1.6, fontSize: 13),
          ),
          const SizedBox(height: 16),
        ],
        if (showSpecsTable) ...[
          if (isPhone) ...[
            imageColumn,
            const SizedBox(height: 20),
            specsBlock,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: specsBlock),
                const SizedBox(width: 28),
                SizedBox(width: imageSize, child: imageColumn),
              ],
            ),
        ] else ...[
          if (!isPhone)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox(width: imageSize, child: imageColumn),
            )
          else
            imageColumn,
        ],
      ],
    );
  }

  String _resolveImage(BuildContext context, String source) {
    return context.read<ApiService>().resolveMediaUrl(source);
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

class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.imageUrl,
    required this.size,
    required this.onTap,
  });

  final String imageUrl;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isFullWidth = size == double.infinity;
    final height = isFullWidth ? 240.0 : size;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : size,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: AppLoadingInline(size: 36),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<(String, String)> catalogProductSpecRows(
  CatalogHotspotProduct item,
  Product product,
  String vehicleName,
) =>
    [
      (AppStrings.partNumber, item.partNumber),
      (AppStrings.productBrand, product.brand),
      ('خودرو', vehicleName),
      ('موقعیت', item.hotspot.label),
      (AppStrings.manufacturer, product.brand),
      (AppStrings.country, product.manufacturerCountry),
      (AppStrings.material, item.material),
      (AppStrings.weight, '${item.weightGrams} ${AppStrings.grams}'),
      (AppStrings.warranty, item.warranty),
      (AppStrings.availability, product.availabilityLabel),
      (AppStrings.price, AppStrings.formatPrice(product.price)),
      if (product.hasDiscount) ('تخفیف', '${product.discountPercent.toStringAsFixed(0)}٪'),
      ('دسته‌بندی', product.partCategory.isNotEmpty ? product.partCategory : product.category),
    ];
