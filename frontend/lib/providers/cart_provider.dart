import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../providers/toast_provider.dart';
import '../utils/product_stock.dart';

class CartProvider extends ChangeNotifier {
  CartProvider(this._toast);

  final ToastProvider _toast;
  final List<CartItem> _items = [];
  bool _isOpen = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isOpen => _isOpen;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);

  void openCart() {
    _isOpen = true;
    notifyListeners();
  }

  void closeCart() {
    _isOpen = false;
    notifyListeners();
  }

  void toggleCart() {
    _isOpen = !_isOpen;
    notifyListeners();
  }

  void addItem(Product product, {String? color, String? size}) {
    if (!product.canPurchase) {
      _toast.error(AppStrings.outOfStock);
      return;
    }
    if (!canAddProductToCart(product, _items)) {
      _toast.error(AppStrings.stockMaxInCart);
      return;
    }

    final selectedColor = color ?? product.colors.first;
    final selectedSize = size ?? product.sizes.first;
    final index = _items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.color == selectedColor &&
          item.size == selectedSize,
    );

    if (index >= 0) {
      final current = _items[index];
      if (!canIncreaseCartQuantity(current, _items)) {
        _toast.error(AppStrings.stockMaxInCart);
        return;
      }
      _items[index] = current.copyWith(quantity: current.quantity + 1);
    } else {
      _items.add(CartItem(
        product: product,
        quantity: 1,
        color: selectedColor,
        size: selectedSize,
      ));
    }

    _toast.success(AppStrings.addedToCart(product.name));
    _isOpen = true;
    notifyListeners();
  }

  void updateQuantity(CartItem item, int quantity) {
    if (quantity <= 0) {
      removeItem(item);
      return;
    }
    final maxQty = maxPurchasableQuantity(item.product, _items, exclude: item) + item.quantity;
    final nextQty = quantity > maxQty ? maxQty : quantity;
    if (nextQty < quantity) {
      _toast.error(AppStrings.stockInsufficient);
    }
    final index = _items.indexOf(item);
    if (index >= 0) {
      _items[index] = item.copyWith(quantity: nextQty);
      notifyListeners();
    }
  }

  int maxQuantityFor(CartItem item) =>
      maxPurchasableQuantity(item.product, _items, exclude: item) + item.quantity;

  void removeItem(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> toCheckoutItems() =>
      _items.map((item) => item.toJson()).toList();
}
