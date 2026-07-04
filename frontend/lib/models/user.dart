class AppUser {
  final int id;
  final String phone;
  final String? email;
  final String fullName;
  final String role;

  AppUser({
    required this.id,
    required this.phone,
    this.email,
    required this.fullName,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'email': email,
        'full_name': fullName,
        'role': role,
      };
}
