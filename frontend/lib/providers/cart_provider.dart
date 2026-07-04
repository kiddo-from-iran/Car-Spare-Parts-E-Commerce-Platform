import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../providers/toast_provider.dart';

import '../models/product.dart';

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
    if (!product.inStock) return;
    final selectedColor = color ?? product.colors.first;
    final selectedSize = size ?? product.sizes.first;
    final index = _items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.color == selectedColor &&
          item.size == selectedSize,
    );

    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity + 1);
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
    final index = _items.indexOf(item);
    if (index >= 0) {
      _items[index] = item.copyWith(quantity: quantity);
      notifyListeners();
    }
  }

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
