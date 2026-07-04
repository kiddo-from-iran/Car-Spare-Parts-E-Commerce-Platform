import '../models/product.dart';

class CatalogVehicleSummary {
  final String id;
  final String name;
  final String subtitle;
  final String year;
  final String brandLogo;
  final String image;

  CatalogVehicleSummary({
    required this.id,
    required this.name,
    this.subtitle = '',
    this.year = '',
    this.brandLogo = '',
    required this.image,
  });

  factory CatalogVehicleSummary.fromJson(Map<String, dynamic> json) => CatalogVehicleSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        year: json['year'] as String? ?? '',
        brandLogo: json['brand_logo'] as String? ?? '',
        image: json['image'] as String,
      );
}

class CatalogView {
  final String id;
  final String name;
  final String image;

  CatalogView({required this.id, required this.name, required this.image});

  factory CatalogView.fromJson(Map<String, dynamic> json) => CatalogView(
        id: json['id'] as String,
        name: json['name'] as String,
        image: json['image'] as String,
      );
}

class CatalogCategory {
  final String id;
  final String name;
  final String icon;

  CatalogCategory({required this.id, required this.name, required this.icon});

  factory CatalogCategory.fromJson(Map<String, dynamic> json) => CatalogCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
      );
}

class CatalogHotspot {
  final String id;
  final String label;
  final String category;
  final double x;
  final double y;
  final int productId;
  final String partNumber;
  final String oem;

  CatalogHotspot({
    required this.id,
    required this.label,
    required this.category,
    required this.x,
    required this.y,
    required this.productId,
    this.partNumber = '',
    this.oem = '',
  });

  factory CatalogHotspot.fromJson(Map<String, dynamic> json) => CatalogHotspot(
        id: json['id'] as String,
        label: json['label'] as String,
        category: json['category'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        productId: json['product_id'] as int,
        partNumber: json['part_number'] as String? ?? '',
        oem: json['oem'] as String? ?? '',
      );
}

class CatalogVehicleDetail {
  final String id;
  final String name;
  final String subtitle;
  final String year;
  final String brandLogo;
  final String image;
  final List<CatalogView> views;
  final List<CatalogCategory> categories;

  CatalogVehicleDetail({
    required this.id,
    required this.name,
    this.subtitle = '',
    this.year = '',
    this.brandLogo = '',
    required this.image,
    required this.views,
    this.categories = const [],
  });

  factory CatalogVehicleDetail.fromJson(Map<String, dynamic> json) => CatalogVehicleDetail(
        id: json['id'] as String,
        name: json['name'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        year: json['year'] as String? ?? '',
        brandLogo: json['brand_logo'] as String? ?? '',
        image: json['image'] as String,
        views: (json['views'] as List).map((e) => CatalogView.fromJson(e as Map<String, dynamic>)).toList(),
        categories: (json['categories'] as List? ?? [])
            .map((e) => CatalogCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CatalogHotspotProduct {
  final CatalogHotspot hotspot;
  final Product product;
  final String partNumber;
  final String oemNumber;
  final String material;
  final int weightGrams;
  final String warranty;
  final List<Product> related;

  CatalogHotspotProduct({
    required this.hotspot,
    required this.product,
    this.partNumber = '',
    this.oemNumber = '',
    this.material = '',
    this.weightGrams = 0,
    this.warranty = '',
    this.related = const [],
  });

  factory CatalogHotspotProduct.fromJson(Map<String, dynamic> json) => CatalogHotspotProduct(
        hotspot: CatalogHotspot.fromJson(json['hotspot'] as Map<String, dynamic>),
        product: Product.fromJson(json['product'] as Map<String, dynamic>),
        partNumber: json['part_number'] as String? ?? '',
        oemNumber: json['oem_number'] as String? ?? '',
        material: json['material'] as String? ?? '',
        weightGrams: json['weight_grams'] as int? ?? 0,
        warranty: json['warranty'] as String? ?? '',
        related: (json['related'] as List? ?? [])
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class HotspotSearchResult {
  final CatalogHotspot hotspot;
  final String viewId;

  HotspotSearchResult({required this.hotspot, required this.viewId});

  factory HotspotSearchResult.fromJson(Map<String, dynamic> json) => HotspotSearchResult(
        hotspot: CatalogHotspot.fromJson(json),
        viewId: json['view_id'] as String,
      );
}
