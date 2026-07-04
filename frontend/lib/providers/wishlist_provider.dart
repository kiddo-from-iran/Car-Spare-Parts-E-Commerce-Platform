import 'package:flutter/material.dart';

class WishlistProvider extends ChangeNotifier {
  final Set<int> _ids = {};

  Set<int> get ids => Set.unmodifiable(_ids);

  bool isWishlisted(int productId) => _ids.contains(productId);

  void toggle(int productId) {
    if (_ids.contains(productId)) {
      _ids.remove(productId);
    } else {
      _ids.add(productId);
    }
    notifyListeners();
  }
}
