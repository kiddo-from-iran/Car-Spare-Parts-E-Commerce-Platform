class TicketMessage {
  final int id;
  final int userId;
  final String userName;
  final String message;
  final bool isAdmin;
  final String createdAt;

  TicketMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.isAdmin,
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String,
      message: json['message'] as String,
      isAdmin: json['is_admin'] as bool,
      createdAt: json['created_at'] as String,
    );
  }
}

class Ticket {
  final int id;
  final int orderId;
  final String orderNumber;
  final int userId;
  final String userName;
  final String subject;
  final String status;
  final String createdAt;
  final String updatedAt;
  final List<TicketMessage> messages;

  Ticket({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.userId,
    required this.userName,
    required this.subject,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      orderNumber: json['order_number'] as String,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String,
      subject: json['subject'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      messages: json['messages'] != null
          ? (json['messages'] as List)
              .map((e) => TicketMessage.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
