class Order {
  final int id;
  final String orderNumber;
  final int? tableId;
  final String status;
  final int totalAmount;
  final List<OrderItem> items;
  final String createdAt;

  Order({
    required this.id,
    required this.orderNumber,
    this.tableId,
    required this.status,
    required this.totalAmount,
    this.items = const [],
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as int,
        orderNumber: json['orderNumber'] as String,
        tableId: json['tableId'] as int?,
        status: json['status'] as String,
        totalAmount: json['totalAmount'] as int,
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['createdAt'] as String,
      );
}

class OrderItem {
  final int id;
  final int menuId;
  final String menuName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final String selectedOptions;

  OrderItem({
    required this.id,
    required this.menuId,
    required this.menuName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.selectedOptions = '',
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as int,
        menuId: json['menuId'] as int,
        menuName: json['menuName'] as String,
        quantity: json['quantity'] as int,
        unitPrice: json['unitPrice'] as int,
        totalPrice: json['totalPrice'] as int,
        selectedOptions: json['selectedOptions'] as String? ?? '',
      );
}
