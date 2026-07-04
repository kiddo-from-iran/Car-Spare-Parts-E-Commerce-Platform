import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../widgets/product_card.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.productId});

  final int productId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? _product;
  List<Product> _related = [];
  int _selectedImage = 0;
  String? _selectedColor;
  String? _selectedSize;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final api = context.read<ApiService>();
      final product = await api.getProduct(widget.productId);
      final related = await api.getRelatedProducts(widget.productId);
      if (mounted) {
        setState(() {
          _product = product;
          _related = related;
          _selectedColor = product.colors.first;
          _selectedSize = product.sizes.first;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addToCart() {
    final product = _product;
    if (product == null) return;
    context.read<CartProvider>().addItem(
          product,
          color: _selectedColor,
          size: _selectedSize,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final product = _product;
    if (product == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.productNotFound),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: () => context.go('/shop'), child: const Text(AppStrings.backToShop)),
          ],
        ),
      );
    }

    final isMobile = AppResponsive.widthOf(context) < 900;
    final padding = AppResponsive.pagePadding(context);
    final wishlist = context.watch<WishlistProvider>();

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => context.go('/shop'),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text(AppStrings.backToShop),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ImageGallery(
                  product: product,
                  selectedIndex: _selectedImage,
                  onSelect: (i) => setState(() => _selectedImage = i),
                ),
                const SizedBox(height: 32),
                _ProductInfo(
                  product: product,
                  selectedColor: _selectedColor!,
                  selectedSize: _selectedSize!,
                  isWishlisted: wishlist.isWishlisted(product.id),
                  onColorChanged: (c) => setState(() => _selectedColor = c),
                  onSizeChanged: (s) => setState(() => _selectedSize = s),
                  onAddToCart: _addToCart,
                  onToggleWishlist: () => wishlist.toggle(product.id),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _ImageGallery(
                    product: product,
                    selectedIndex: _selectedImage,
                    onSelect: (i) => setState(() => _selectedImage = i),
                  ),
                ),
                const SizedBox(width: 64),
                Expanded(
                  flex: 2,
                  child: _ProductInfo(
                    product: product,
                    selectedColor: _selectedColor!,
                    selectedSize: _selectedSize!,
                    isWishlisted: wishlist.isWishlisted(product.id),
                    onColorChanged: (c) => setState(() => _selectedColor = c),
                    onSizeChanged: (s) => setState(() => _selectedSize = s),
                    onAddToCart: _addToCart,
                    onToggleWishlist: () => wishlist.toggle(product.id),
                  ),
                ),
              ],
            ),
          if (_related.isNotEmpty) ...[
            const SizedBox(height: 80),
            Text(
              AppStrings.youMayAlsoLike,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1,
                  ),
            ),
            const SizedBox(height: 32),
            ProductGrid(products: _related),
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({
    required this.product,
    required this.selectedIndex,
    required this.onSelect,
  });

  final Product product;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 5,
          child: CachedNetworkImage(
            imageUrl: product.images[selectedIndex],
            fit: BoxFit.cover,
          ),
        ),
        if (product.images.length > 1) ...[
          const SizedBox(height: 16),
          Row(
            children: List.generate(product.images.length, (i) {
              final selected = i == selectedIndex;
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: GestureDetector(
                  onTap: () => onSelect(i),
                  child: Container(
                    width: 72,
                    height: 90,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected ? AppColors.textPrimary : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: product.images[i],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({
    required this.product,
    required this.selectedColor,
    required this.selectedSize,
    required this.isWishlisted,
    required this.onColorChanged,
    required this.onSizeChanged,
    required this.onAddToCart,
    required this.onToggleWishlist,
  });

  final Product product;
  final String selectedColor;
  final String selectedSize;
  final bool isWishlisted;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String> onSizeChanged;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleWishlist;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.category.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.5,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ),
            IconButton(
              icon: Icon(
                isWishlisted ? Icons.favorite : Icons.favorite_border,
                color: isWishlisted ? Colors.red.shade300 : null,
              ),
              onPressed: onToggleWishlist,
            ),
          ],
        ),
        const SizedBox(height: 12),
          Text(
            AppStrings.formatPrice(product.price),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 24),
        Text(
          product.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.7,
              ),
        ),
        const SizedBox(height: 32),
        if (product.colors.length > 1) ...[
          Text(AppStrings.color, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.colors.map((c) {
              final selected = c == selectedColor;
              return ChoiceChip(
                label: Text(c),
                selected: selected,
                onSelected: (_) => onColorChanged(c),
                selectedColor: AppColors.creamDark,
                side: BorderSide(color: selected ? AppColors.textPrimary : AppColors.border),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (product.sizes.length > 1) ...[
          Text(AppStrings.size, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.sizes.map((s) {
              final selected = s == selectedSize;
              return ChoiceChip(
                label: Text(s),
                selected: selected,
                onSelected: (_) => onSizeChanged(s),
                selectedColor: AppColors.creamDark,
                side: BorderSide(color: selected ? AppColors.textPrimary : AppColors.border),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: product.inStock ? onAddToCart : null,
            child: Text(product.inStock ? AppStrings.addToCart : AppStrings.outOfStock),
          ),
        ),
      ],
    );
  }
}
