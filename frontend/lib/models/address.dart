class UserAddress {
  final int id;
  final String label;
  final String firstName;
  final String lastName;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  UserAddress({
    required this.id,
    required this.label,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.isDefault,
    this.latitude,
    this.longitude,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get summary => address;

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'] as int,
      label: json['label'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      address: json['address'] as String,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      zipCode: json['zip_code'] as String? ?? '',
      country: json['country'] as String? ?? 'ایران',
      isDefault: json['is_default'] as bool,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'is_default': isDefault,
      };
}
