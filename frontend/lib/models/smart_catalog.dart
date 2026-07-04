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
  final List<int> productIds;
  final String partNumber;
  final String oem;

  CatalogHotspot({
    required this.id,
    required this.label,
    required this.category,
    required this.x,
    required this.y,
    required this.productId,
    this.productIds = const [],
    this.partNumber = '',
    this.oem = '',
  });

  factory CatalogHotspot.fromJson(Map<String, dynamic> json) {
    final ids = (json['product_ids'] as List? ?? [])
        .map((e) => (e as num).toInt())
        .toList();
    final primary = json['product_id'] as int? ?? (ids.isNotEmpty ? ids.first : 0);
    return CatalogHotspot(
      id: json['id'] as String,
      label: json['label'] as String,
      category: json['category'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      productId: primary,
      productIds: ids.isNotEmpty ? ids : (primary > 0 ? [primary] : []),
      partNumber: json['part_number'] as String? ?? '',
      oem: json['oem'] as String? ?? '',
    );
  }
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
  final List<Product> products;
  final String partNumber;
  final String oemNumber;
  final String material;
  final int weightGrams;
  final String warranty;
  final List<Product> related;

  CatalogHotspotProduct({
    required this.hotspot,
    required this.product,
    this.products = const [],
    this.partNumber = '',
    this.oemNumber = '',
    this.material = '',
    this.weightGrams = 0,
    this.warranty = '',
    this.related = const [],
  });

  List<Product> get allProducts => products.isNotEmpty ? products : [product];

  factory CatalogHotspotProduct.fromJson(Map<String, dynamic> json) {
    final products = (json['products'] as List? ?? [])
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
    final primary = Product.fromJson(json['product'] as Map<String, dynamic>);
    return CatalogHotspotProduct(
      hotspot: CatalogHotspot.fromJson(json['hotspot'] as Map<String, dynamic>),
      product: primary,
      products: products.isNotEmpty ? products : [primary],
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

class AdminCatalogSummary {
  final String id;
  final String name;
  final String subtitle;
  final String year;
  final String brandLogo;
  final String image;
  final int viewCount;
  final int hotspotCount;
  final String createdAt;
  final String updatedAt;

  AdminCatalogSummary({
    required this.id,
    required this.name,
    this.subtitle = '',
    this.year = '',
    this.brandLogo = '',
    this.image = '',
    this.viewCount = 0,
    this.hotspotCount = 0,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory AdminCatalogSummary.fromJson(Map<String, dynamic> json) => AdminCatalogSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        year: json['year'] as String? ?? '',
        brandLogo: json['brand_logo'] as String? ?? '',
        image: json['image'] as String? ?? '',
        viewCount: json['view_count'] as int? ?? 0,
        hotspotCount: json['hotspot_count'] as int? ?? 0,
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );
}

class AdminCatalogViewDetail {
  final String id;
  final String name;
  final String image;
  final List<CatalogHotspot> hotspots;

  AdminCatalogViewDetail({
    required this.id,
    required this.name,
    this.image = '',
    this.hotspots = const [],
  });

  factory AdminCatalogViewDetail.fromJson(Map<String, dynamic> json) => AdminCatalogViewDetail(
        id: json['id'] as String,
        name: json['name'] as String,
        image: json['image'] as String? ?? '',
        hotspots: (json['hotspots'] as List? ?? [])
            .map((e) => CatalogHotspot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AdminCatalogDetail {
  final String id;
  final String name;
  final String subtitle;
  final String year;
  final String brandLogo;
  final String image;
  final List<AdminCatalogViewDetail> views;
  final List<CatalogCategory> categories;

  AdminCatalogDetail({
    required this.id,
    required this.name,
    this.subtitle = '',
    this.year = '',
    this.brandLogo = '',
    this.image = '',
    this.views = const [],
    this.categories = const [],
  });

  factory AdminCatalogDetail.fromJson(Map<String, dynamic> json) => AdminCatalogDetail(
        id: json['id'] as String,
        name: json['name'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        year: json['year'] as String? ?? '',
        brandLogo: json['brand_logo'] as String? ?? '',
        image: json['image'] as String? ?? '',
        views: (json['views'] as List? ?? [])
            .map((e) => AdminCatalogViewDetail.fromJson(e as Map<String, dynamic>))
            .toList(),
        categories: (json['categories'] as List? ?? [])
            .map((e) => CatalogCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
