import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/address.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/smart_catalog.dart';
import '../models/search_suggestion.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import '../utils/dev_log.dart';

class ApiService {
  ApiService({this.baseUrl = 'http://localhost:8000'});

  final String baseUrl;
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> _handle(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return json.decode(response.body);
    }
    final body = response.body.isNotEmpty ? json.decode(response.body) : {};
    final detail = body is Map ? (body['detail'] ?? 'خطای سرور') : 'خطای سرور';
    throw Exception(detail.toString());
  }

  Map<String, dynamic> _handleOtpResponse(Map<String, dynamic> result, String purpose) {
    final devOtp = result['dev_otp'];
    if (devOtp != null) {
      DevLog.otp(
        phone: result['phone']?.toString() ?? '',
        code: devOtp.toString(),
        purpose: purpose,
      );
    }
    return result;
  }

  // Auth
  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers,
      body: json.encode({'phone': phone, 'password': password}),
    );
    return (await _handle(response)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerSendOtp({
    required String phone,
    required String password,
    required String fullName,
    String? email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register/send-otp'),
      headers: _headers,
      body: json.encode({
        'phone': phone,
        'password': password,
        'full_name': fullName,
        if (email != null && email.isNotEmpty) 'email': email,
      }),
    );
    return _handleOtpResponse((await _handle(response)) as Map<String, dynamic>, 'register');
  }

  Future<Map<String, dynamic>> registerVerify(String phone, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register/verify'),
      headers: _headers,
      body: json.encode({'phone': phone, 'code': code}),
    );
    return (await _handle(response)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> forgotPasswordSendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/forgot-password/send-otp'),
      headers: _headers,
      body: json.encode({'phone': phone}),
    );
    return _handleOtpResponse((await _handle(response)) as Map<String, dynamic>, 'reset');
  }

  Future<void> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/forgot-password/reset'),
      headers: _headers,
      body: json.encode({'phone': phone, 'code': code, 'new_password': newPassword}),
    );
    await _handle(response);
  }

  Future<AppUser> updateProfile({String? fullName, String? email}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: _headers,
      body: json.encode({
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
      }),
    );
    return AppUser.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  Future<List<UserAddress>> getAddresses() async {
    final response = await http.get(Uri.parse('$baseUrl/api/auth/addresses'), headers: _headers);
    final list = (await _handle(response)) as List;
    return list.map((e) => UserAddress.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UserAddress> createAddress(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/addresses'),
      headers: _headers,
      body: json.encode(data),
    );
    return UserAddress.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  Future<UserAddress> updateAddress(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/auth/addresses/$id'),
      headers: _headers,
      body: json.encode(data),
    );
    return UserAddress.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  Future<void> deleteAddress(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/auth/addresses/$id'),
      headers: _headers,
    );
    await _handle(response);
  }

  Future<DiscountValidation> validateDiscount(String code, double subtotal) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/discount/validate'),
      headers: _headers,
      body: json.encode({'code': code, 'subtotal': subtotal}),
    );
    return DiscountValidation.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  Future<AppUser> getMe() async {
    final response = await http.get(Uri.parse('$baseUrl/api/auth/me'), headers: _headers);
    return AppUser.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  // Catalog
  Future<List<Product>> getProducts({
    String? category,
    String? partCategory,
    String? vehicle,
    String? brand,
    String? country,
    double? minPrice,
    double? maxPrice,
    String? color,
    String? search,
    String? sort,
    bool featured = false,
    bool inStockOnly = false,
    bool outOfStockOnly = false,
    bool hasDiscount = false,
    int? page,
    int? pageSize,
  }) async {
    final params = <String, String>{};
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (partCategory != null && partCategory.isNotEmpty) params['part_category'] = partCategory;
    if (vehicle != null && vehicle.isNotEmpty) params['vehicle'] = vehicle;
    if (brand != null && brand.isNotEmpty) params['brand'] = brand;
    if (country != null && country.isNotEmpty) params['country'] = country;
    if (minPrice != null) params['min_price'] = minPrice.toString();
    if (maxPrice != null) params['max_price'] = maxPrice.toString();
    if (color != null && color.isNotEmpty) params['color'] = color;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (sort != null && sort.isNotEmpty) params['sort'] = sort;
    if (featured) params['featured'] = 'true';
    if (inStockOnly) params['in_stock_only'] = 'true';
    if (outOfStockOnly) params['out_of_stock_only'] = 'true';
    if (hasDiscount) params['has_discount'] = 'true';
    if (page != null) params['page'] = page.toString();
    if (pageSize != null) params['page_size'] = pageSize.toString();

    final uri = Uri.parse('$baseUrl/api/products').replace(queryParameters: params);
    final response = await http.get(uri);
    final list = (await _handle(response)) as List;
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> getProductsCount({
    String? category,
    String? partCategory,
    String? vehicle,
    String? brand,
    String? country,
    double? minPrice,
    double? maxPrice,
    String? search,
    bool inStockOnly = false,
    bool outOfStockOnly = false,
    bool hasDiscount = false,
  }) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (partCategory != null) params['part_category'] = partCategory;
    if (vehicle != null) params['vehicle'] = vehicle;
    if (brand != null) params['brand'] = brand;
    if (country != null) params['country'] = country;
    if (minPrice != null) params['min_price'] = minPrice.toString();
    if (maxPrice != null) params['max_price'] = maxPrice.toString();
    if (search != null) params['search'] = search;
    if (inStockOnly) params['in_stock_only'] = 'true';
    if (outOfStockOnly) params['out_of_stock_only'] = 'true';
    if (hasDiscount) params['has_discount'] = 'true';
    final uri = Uri.parse('$baseUrl/api/products/count').replace(queryParameters: params);
    final response = await http.get(uri);
    final result = (await _handle(response)) as Map<String, dynamic>;
    return result['count'] as int;
  }

  Future<Product> getProduct(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/api/products/$id'));
    return Product.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  Future<List<Product>> getRelatedProducts(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/api/products/$id/related'));
    final list = (await _handle(response)) as List;
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<String>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/api/categories'));
    return List<String>.from((await _handle(response)) as List);
  }

  Future<List<String>> getFooterCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/api/footer-categories'));
    return List<String>.from((await _handle(response)) as List);
  }

  Future<List<String>> getColors() async {
    final response = await http.get(Uri.parse('$baseUrl/api/colors'));
    return List<String>.from((await _handle(response)) as List);
  }

  Future<List<MegaMenuCategory>> getMegaMenu() async {
    final response = await http.get(Uri.parse('$baseUrl/api/mega-menu'));
    final list = (await _handle(response)) as List;
    return list.map((e) => MegaMenuCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CategoryItem>> getVehicleCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/api/vehicle-categories'));
    final list = (await _handle(response)) as List;
    return list.map((e) => CategoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CategoryItem>> getPartCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/api/part-categories'));
    final list = (await _handle(response)) as List;
    return list.map((e) => CategoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<String>> getBrands() async {
    final response = await http.get(Uri.parse('$baseUrl/api/brands'));
    return List<String>.from((await _handle(response)) as List);
  }

  Future<List<String>> getManufacturerCountries() async {
    final response = await http.get(Uri.parse('$baseUrl/api/manufacturer-countries'));
    return List<String>.from((await _handle(response)) as List);
  }

  Future<List<SearchSuggestion>> searchSuggest(String query, {int limit = 8}) async {
    if (query.trim().length < 2) return [];
    final uri = Uri.parse('$baseUrl/api/search/suggest').replace(
      queryParameters: {'q': query.trim(), 'limit': limit.toString()},
    );
    final response = await http.get(uri);
    final list = (await _handle(response)) as List;
    return list.map((e) => SearchSuggestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PartnerBrand>> getPartnerBrands() async {
    final response = await http.get(Uri.parse('$baseUrl/api/partner-brands'));
    final list = (await _handle(response)) as List;
    return list.map((e) => PartnerBrand.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    final response = await http.get(Uri.parse('$baseUrl/api/admin/stats'), headers: _headers);
    return (await _handle(response)) as Map<String, dynamic>;
  }

  Future<List<OrderStatusOption>> getOrderStatuses() async {
    final response = await http.get(Uri.parse('$baseUrl/api/order-statuses'));
    final list = (await _handle(response)) as List;
    return list.map((e) => OrderStatusOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Orders
  Future<Map<String, dynamic>> checkout(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/orders/checkout'),
      headers: _headers,
      body: json.encode(data),
    );
    return (await _handle(response)) as Map<String, dynamic>;
  }

  Future<List<Order>> getMyOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/api/orders/my'), headers: _headers);
    final list = (await _handle(response)) as List;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> getMyOrder(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/api/orders/my/$id'), headers: _headers);
    return Order.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  Future<List<Order>> getAdminOrders({String? filter, String? status}) async {
    final params = <String, String>{};
    if (filter != null) params['filter'] = filter;
    if (status != null) params['status'] = status;
    final uri = Uri.parse('$baseUrl/api/admin/orders').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);
    final list = (await _handle(response)) as List;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> updateOrderStatus(int orderId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/admin/orders/$orderId/status'),
      headers: _headers,
      body: json.encode({'status': status}),
    );
    return Order.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  Future<void> deleteOrder(int orderId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/admin/orders/$orderId'),
      headers: _headers,
    );
    await _handle(response);
  }

  Future<RevenueSummary> getRevenueSummary({int months = 6}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/orders/revenue/summary?months=$months'),
      headers: _headers,
    );
    return RevenueSummary.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  // Products admin
  Future<List<Product>> getAdminProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/api/admin/products'), headers: _headers);
    final list = (await _handle(response)) as List;
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Product> createProduct(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/products'),
      headers: _headers,
      body: json.encode(data),
    );
    return Product.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/admin/products/$id'),
      headers: _headers,
      body: json.encode(data),
    );
    return Product.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  Future<void> deleteProduct(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/admin/products/$id'),
      headers: _headers,
    );
    await _handle(response);
  }

  // Tickets
  Future<Ticket> createTicket(int orderId, String subject, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tickets'),
      headers: _headers,
      body: json.encode({'order_id': orderId, 'subject': subject, 'message': message}),
    );
    return Ticket.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  Future<List<Ticket>> getMyTickets() async {
    final response = await http.get(Uri.parse('$baseUrl/api/tickets/my'), headers: _headers);
    final list = (await _handle(response)) as List;
    return list.map((e) => Ticket.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Ticket> getMyTicket(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/api/tickets/my/$id'), headers: _headers);
    return Ticket.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  Future<Ticket> replyToTicket(int id, String message, {bool admin = false}) async {
    final path = admin ? '/api/admin/tickets/$id/messages' : '/api/tickets/my/$id/messages';
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: json.encode({'message': message}),
    );
    return Ticket.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  Future<List<Ticket>> getAdminTickets({String? status}) async {
    final uri = Uri.parse('$baseUrl/api/admin/tickets').replace(
      queryParameters: status != null ? {'status': status} : {},
    );
    final response = await http.get(uri, headers: _headers);
    final list = (await _handle(response)) as List;
    return list.map((e) => Ticket.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Ticket> getAdminTicket(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/api/admin/tickets/$id'), headers: _headers);
    return Ticket.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  Future<Ticket> closeTicket(int id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/admin/tickets/$id/close'),
      headers: _headers,
    );
    return Ticket.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  Future<List<CatalogCategory>> getCatalogCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/api/smart-catalog/categories'));
    final list = (await _handle(response)) as List;
    return list.map((e) => CatalogCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CatalogVehicleSummary>> getCatalogVehicles({String? search}) async {
    final uri = Uri.parse('$baseUrl/api/smart-catalog/vehicles').replace(
      queryParameters: search != null && search.isNotEmpty ? {'search': search} : {},
    );
    final response = await http.get(uri);
    final list = (await _handle(response)) as List;
    return list.map((e) => CatalogVehicleSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CatalogVehicleDetail> getCatalogVehicle(String vehicleId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/smart-catalog/vehicles/$vehicleId'));
    return CatalogVehicleDetail.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  Future<List<CatalogHotspot>> getCatalogHotspots(
    String vehicleId,
    String viewId, {
    String? category,
  }) async {
    final uri = Uri.parse('$baseUrl/api/smart-catalog/vehicles/$vehicleId/views/$viewId/hotspots')
        .replace(queryParameters: category != null ? {'category': category} : {});
    final response = await http.get(uri);
    final list = (await _handle(response)) as List;
    return list.map((e) => CatalogHotspot.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<HotspotSearchResult>> searchCatalogHotspots(String vehicleId, String query) async {
    final uri = Uri.parse('$baseUrl/api/smart-catalog/vehicles/$vehicleId/search-hotspots')
        .replace(queryParameters: {'q': query});
    final response = await http.get(uri);
    final list = (await _handle(response)) as List;
    return list.map((e) => HotspotSearchResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CatalogHotspotProduct> getHotspotProduct(
    String vehicleId,
    String hotspotId,
    String viewId,
  ) async {
    final uri = Uri.parse('$baseUrl/api/smart-catalog/hotspots/$vehicleId/$hotspotId/product')
        .replace(queryParameters: {'view_id': viewId});
    final response = await http.get(uri);
    return CatalogHotspotProduct.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  // Admin catalogs
  Future<List<AdminCatalogSummary>> getAdminCatalogs() async {
    final response = await http.get(Uri.parse('$baseUrl/api/admin/catalogs'), headers: _headers);
    final list = (await _handle(response)) as List;
    return list.map((e) => AdminCatalogSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AdminCatalogDetail> getAdminCatalog(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/api/admin/catalogs/$id'), headers: _headers);
    return AdminCatalogDetail.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  Future<AdminCatalogDetail> saveAdminCatalog(Map<String, dynamic> data, {String? id}) async {
    final uri = id != null
        ? Uri.parse('$baseUrl/api/admin/catalogs/$id')
        : Uri.parse('$baseUrl/api/admin/catalogs');
    final response = id != null
        ? await http.put(uri, headers: _headers, body: json.encode(data))
        : await http.post(uri, headers: _headers, body: json.encode(data));
    return AdminCatalogDetail.fromJson((await _handle(response)) as Map<String, dynamic>);
  }

  Future<void> deleteAdminCatalog(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/admin/catalogs/$id'), headers: _headers);
    await _handle(response);
  }

  MediaType? _imageMediaType(String filename) {
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'gif' => MediaType('image', 'gif'),
      _ => null,
    };
  }

  Future<String> uploadCatalogImage(List<int> bytes, String filename) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/admin/catalogs/upload-image'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: _imageMediaType(filename),
    ));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final result = (await _handle(response)) as Map<String, dynamic>;
    return result['url'] as String;
  }

  String resolveMediaUrl(String source) {
    if (source.startsWith('http://') || source.startsWith('https://')) return source;
    if (source.startsWith('/')) return '$baseUrl$source';
    return source;
  }
}
