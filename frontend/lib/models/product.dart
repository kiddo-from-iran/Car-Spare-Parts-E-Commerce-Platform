class Product {
  final int id;
  final String name;
  final double price;
  final double originalPrice;
  final double discountPercent;
  final String description;
  final String category;
  final String partCategory;
  final String brand;
  final String manufacturerCountry;
  final List<String> compatibleVehicles;
  final List<String> colors;
  final List<String> sizes;
  final List<String> images;
  final Map<String, String> specs;
  final int popularity;
  final int views;
  final double rating;
  final int reviewCount;
  final int stockQuantity;
  final String createdAt;
  final bool isNew;
  final bool inStock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice = 0,
    this.discountPercent = 0,
    required this.description,
    required this.category,
    this.partCategory = '',
    this.brand = '',
    this.manufacturerCountry = '',
    this.compatibleVehicles = const [],
    required this.colors,
    required this.sizes,
    required this.images,
    this.specs = const {},
    required this.popularity,
    this.views = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.stockQuantity = 0,
    required this.createdAt,
    required this.isNew,
    required this.inStock,
  });

  bool get hasDiscount => discountPercent > 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? (json['price'] as num).toDouble(),
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String,
      category: json['category'] as String,
      partCategory: json['part_category'] as String? ?? json['category'] as String,
      brand: json['brand'] as String? ?? '',
      manufacturerCountry: json['manufacturer_country'] as String? ?? '',
      compatibleVehicles: List<String>.from(json['compatible_vehicles'] as List? ?? []),
      colors: List<String>.from(json['colors'] as List),
      sizes: List<String>.from(json['sizes'] as List),
      images: List<String>.from(json['images'] as List),
      specs: Map<String, String>.from(json['specs'] as Map? ?? {}),
      popularity: json['popularity'] as int,
      views: json['views'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      createdAt: json['created_at'] as String,
      isNew: json['is_new'] as bool,
      inStock: json['in_stock'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'original_price': originalPrice,
        'discount_percent': discountPercent,
        'description': description,
        'category': category,
        'part_category': partCategory,
        'brand': brand,
        'manufacturer_country': manufacturerCountry,
        'compatible_vehicles': compatibleVehicles,
        'colors': colors,
        'sizes': sizes,
        'images': images,
        'specs': specs,
        'popularity': popularity,
        'views': views,
        'rating': rating,
        'review_count': reviewCount,
        'stock_quantity': stockQuantity,
        'is_new': isNew,
        'in_stock': inStock,
      };
}

class CartItem {
  final Product product;
  final int quantity;
  final String color;
  final String size;

  CartItem({
    required this.product,
    required this.quantity,
    required this.color,
    required this.size,
  });

  double get lineTotal => product.price * quantity;

  CartItem copyWith({int? quantity, String? color, String? size}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      color: color ?? this.color,
      size: size ?? this.size,
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': product.id,
        'quantity': quantity,
        'color': color,
        'size': size,
      };
}

class CategoryItem {
  final String id;
  final String name;
  final String image;

  CategoryItem({required this.id, required this.name, required this.image});

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        image: json['image'] as String,
      );
}

class MegaMenuCategory {
  final String id;
  final String name;
  final String icon;
  final List<MegaMenuSubcategory> subcategories;

  MegaMenuCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.subcategories,
  });

  factory MegaMenuCategory.fromJson(Map<String, dynamic> json) => MegaMenuCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        subcategories: (json['subcategories'] as List)
            .map((e) => MegaMenuSubcategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MegaMenuSubcategory {
  final String name;
  final String slug;
  final List<String> items;

  MegaMenuSubcategory({required this.name, required this.slug, required this.items});

  factory MegaMenuSubcategory.fromJson(Map<String, dynamic> json) => MegaMenuSubcategory(
        name: json['name'] as String,
        slug: json['slug'] as String,
        items: List<String>.from(json['items'] as List),
      );
}
