import '../l10n/app_strings.dart';
import '../models/product.dart';

/// Stock helpers shared by cart, product pages, and catalog.
extension ProductStock on Product {
  bool get canPurchase => inStock && stockQuantity > 0;

  String get availabilityLabel =>
      canPurchase ? AppStrings.stockAvailable(stockQuantity) : AppStrings.outOfStock;
}

int cartQuantityForProduct(List<CartItem> items, int productId, {CartItem? exclude}) {
  return items
      .where((item) => item.product.id == productId && item != exclude)
      .fold(0, (sum, item) => sum + item.quantity);
}

int maxPurchasableQuantity(Product product, List<CartItem> items, {CartItem? exclude}) {
  final reserved = cartQuantityForProduct(items, product.id, exclude: exclude);
  final remaining = product.stockQuantity - reserved;
  return remaining < 0 ? 0 : remaining;
}

bool canAddProductToCart(Product product, List<CartItem> items) =>
    maxPurchasableQuantity(product, items) > 0;

bool canIncreaseCartQuantity(CartItem item, List<CartItem> items) =>
    maxPurchasableQuantity(item.product, items, exclude: item) > 0;
