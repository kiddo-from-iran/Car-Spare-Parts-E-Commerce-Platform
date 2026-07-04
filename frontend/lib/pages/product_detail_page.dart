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
import '../utils/product_stock.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/product_card.dart';
import '../widgets/product_specs_table.dart';

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
      return const AppLoadingCenter();
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
          _SpecsSection(product: product),
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

class _SpecsSection extends StatelessWidget {
  const _SpecsSection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'مشخصات فنی',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ProductSpecsTable.fromProduct(product),
        const SizedBox(height: 32),
      ],
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

  static const _mainHeight = 420.0;
  static const _thumbSize = 72.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: _mainHeight,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: product.images[selectedIndex],
                  fit: BoxFit.contain,
                  height: _mainHeight - 32,
                  width: double.infinity,
                ),
              ),
            ),
          ),
        ),
        if (product.images.length > 1) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: _thumbSize + 4,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: product.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _ThumbTile(
                url: product.images[i],
                selected: i == selectedIndex,
                onTap: () => onSelect(i),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ThumbTile extends StatefulWidget {
  const _ThumbTile({required this.url, required this.selected, required this.onTap});

  final String url;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ThumbTile> createState() => _ThumbTileState();
}

class _ThumbTileState extends State<_ThumbTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.selected
        ? AppColors.gold
        : _hovered
            ? AppColors.gold.withValues(alpha: 0.6)
            : AppColors.border;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: _ImageGallery._thumbSize,
          height: _ImageGallery._thumbSize,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: widget.selected ? 2 : 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: CachedNetworkImage(
                imageUrl: widget.url,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
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
    final cart = context.watch<CartProvider>();
    final remaining = maxPurchasableQuantity(product, cart.items);
    final canAdd = remaining > 0;

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
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          product.availabilityLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: canAdd ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
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
            onPressed: canAdd ? onAddToCart : null,
            child: Text(canAdd ? AppStrings.addToCart : AppStrings.outOfStock),
          ),
        ),
      ],
    );
  }
}
