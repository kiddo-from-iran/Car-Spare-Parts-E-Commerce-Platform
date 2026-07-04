import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/product_stock.dart';

/// Striped key/value table for product specifications (shop + smart catalog).
class ProductSpecsTable extends StatelessWidget {
  const ProductSpecsTable({
    super.key,
    required this.rows,
    this.stockIn = true,
    this.priceHighlight = true,
  });

  final List<(String label, String value)> rows;
  final bool stockIn;
  final bool priceHighlight;

  factory ProductSpecsTable.fromProduct(Product product) {
    return ProductSpecsTable(
      rows: productSpecRows(product),
      stockIn: product.canPurchase,
    );
  }

  static List<(String, String)> productSpecRows(Product product) {
    final rows = <(String, String)>[];
    final usedSpecKeys = <String>{};

    void add(String label, String? value) {
      final v = value?.trim() ?? '';
      if (v.isEmpty || v == '—') return;
      rows.add((label, v));
    }

    final partNumber = product.specs['کد فنی'] ??
        product.specs['شماره فنی'] ??
        product.specs['part_number'] ??
        product.specs['Part Number'];
    if (partNumber != null) usedSpecKeys.addAll(['کد فنی', 'شماره فنی', 'part_number', 'Part Number']);
    add(AppStrings.partNumber, partNumber);

    add(AppStrings.productBrand, product.brand.isNotEmpty ? product.brand : null);

    if (product.compatibleVehicles.isNotEmpty) {
      add('خودرو', product.compatibleVehicles.join('، '));
    }

    add('موقعیت', product.specs['موقعیت']);
    if (product.specs.containsKey('موقعیت')) usedSpecKeys.add('موقعیت');

    add(AppStrings.manufacturer, product.brand.isNotEmpty ? product.brand : product.specs['سازنده']);
    if (product.specs.containsKey('سازنده')) usedSpecKeys.add('سازنده');

    add(
      AppStrings.country,
      product.manufacturerCountry.isNotEmpty ? product.manufacturerCountry : product.specs['کشور سازنده'],
    );
    usedSpecKeys.add('کشور سازنده');

    add(AppStrings.material, product.specs['جنس'] ?? product.specs[AppStrings.material]);
    usedSpecKeys.addAll(['جنس', AppStrings.material]);

    final weight = product.specs['وزن'] ?? product.specs[AppStrings.weight];
    if (weight != null) {
      add(AppStrings.weight, weight.contains(AppStrings.grams) ? weight : '$weight ${AppStrings.grams}');
      usedSpecKeys.addAll(['وزن', AppStrings.weight]);
    }

    add(AppStrings.warranty, product.specs['گارانتی'] ?? product.specs[AppStrings.warranty]);
    usedSpecKeys.addAll(['گارانتی', AppStrings.warranty]);

    add('دسته‌بندی', product.partCategory.isNotEmpty ? product.partCategory : product.category);

    for (final entry in product.specs.entries) {
      if (usedSpecKeys.contains(entry.key)) continue;
      if (entry.key == 'برند') continue;
      add(entry.key, entry.value);
    }

    add(AppStrings.availability, product.availabilityLabel);
    add(AppStrings.price, AppStrings.formatPrice(product.price));
    if (product.hasDiscount) {
      add('تخفیف', '${product.discountPercent.toStringAsFixed(0)}٪');
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: i.isEven ? AppColors.white : AppColors.surfaceMuted,
                border: i < rows.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.border))
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      rows[i].$1,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: _valueColor(rows[i].$1),
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

  Color _valueColor(String label) {
    if (label == AppStrings.availability) return stockIn ? AppColors.success : AppColors.error;
    if (label == AppStrings.price && priceHighlight) return AppColors.gold;
    return AppColors.textPrimary;
  }
}
