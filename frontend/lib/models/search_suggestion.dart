class SearchSuggestion {
  final int id;
  final String name;
  final double price;
  final String brand;
  final String category;
  final String image;

  SearchSuggestion({
    required this.id,
    required this.name,
    required this.price,
    this.brand = '',
    this.category = '',
    this.image = '',
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) => SearchSuggestion(
        id: json['id'] as int,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        brand: json['brand'] as String? ?? '',
        category: json['category'] as String? ?? '',
        image: json['image'] as String? ?? '',
      );
}

class PartnerBrand {
  final String id;
  final String name;
  final String logo;

  PartnerBrand({required this.id, required this.name, required this.logo});

  factory PartnerBrand.fromJson(Map<String, dynamic> json) => PartnerBrand(
        id: json['id'] as String,
        name: json['name'] as String,
        logo: json['logo'] as String,
      );
}
