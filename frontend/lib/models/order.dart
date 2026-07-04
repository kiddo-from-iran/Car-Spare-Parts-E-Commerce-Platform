class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final String color;
  final String size;
  final double unitPrice;
  final double lineTotal;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.color,
    required this.size,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      color: json['color'] as String,
      size: json['size'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      lineTotal: (json['line_total'] as num).toDouble(),
    );
  }
}

class Order {
  final int id;
  final String orderNumber;
  final int userId;
  final String userName;
  final String userPhone;
  final String? userEmail;
  final String status;
  final String statusLabel;
  final double subtotal;
  final String? discountCode;
  final double discountAmount;
  final String shippingMethod;
  final double shippingCost;
  final double total;
  final String phone;
  final String firstName;
  final String lastName;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String createdAt;
  final String updatedAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.userEmail,
    required this.status,
    required this.statusLabel,
    required this.subtotal,
    this.discountCode,
    required this.discountAmount,
    required this.shippingMethod,
    required this.shippingCost,
    required this.total,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  String get shippingLabel => shippingMethod == 'tipax' ? 'تیپاکس' : 'پست';

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String,
      userPhone: json['user_phone'] as String? ?? '',
      userEmail: json['user_email'] as String?,
      status: json['status'] as String,
      statusLabel: json['status_label'] as String,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? (json['total'] as num).toDouble(),
      discountCode: json['discount_code'] as String?,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      shippingMethod: json['shipping_method'] as String? ?? 'post',
      shippingCost: (json['shipping_cost'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num).toDouble(),
      phone: json['phone'] as String? ?? json['user_phone'] as String? ?? '',
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zip_code'] as String,
      country: json['country'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      items: (json['items'] as List)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OrderStatusOption {
  final String value;
  final String label;

  OrderStatusOption({required this.value, required this.label});

  factory OrderStatusOption.fromJson(Map<String, dynamic> json) {
    return OrderStatusOption(
      value: json['value'] as String,
      label: json['label'] as String,
    );
  }
}

class MonthlyRevenue {
  final int year;
  final int month;
  final String monthLabel;
  final int orderCount;
  final double revenue;

  MonthlyRevenue({
    required this.year,
    required this.month,
    required this.monthLabel,
    required this.orderCount,
    required this.revenue,
  });

  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenue(
      year: json['year'] as int,
      month: json['month'] as int,
      monthLabel: json['month_label'] as String,
      orderCount: json['order_count'] as int,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}

class RevenueSummary {
  final List<MonthlyRevenue> months;
  final double totalRevenue;
  final int totalOrders;

  RevenueSummary({
    required this.months,
    required this.totalRevenue,
    required this.totalOrders,
  });

  factory RevenueSummary.fromJson(Map<String, dynamic> json) {
    return RevenueSummary(
      months: (json['months'] as List)
          .map((e) => MonthlyRevenue.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      totalOrders: json['total_orders'] as int,
    );
  }
}

class DiscountValidation {
  final bool valid;
  final String code;
  final double discountAmount;
  final String message;

  DiscountValidation({
    required this.valid,
    required this.code,
    required this.discountAmount,
    required this.message,
  });

  factory DiscountValidation.fromJson(Map<String, dynamic> json) {
    return DiscountValidation(
      valid: json['valid'] as bool,
      code: json['code'] as String,
      discountAmount: (json['discount_amount'] as num).toDouble(),
      message: json['message'] as String,
    );
  }
}
