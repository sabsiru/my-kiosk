class Payment {
  final int id;
  final int orderId;
  final String method;
  final int amount;
  final String status;
  final String? approvalNumber;
  final String createdAt;

  Payment({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
    required this.status,
    this.approvalNumber,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as int,
        orderId: json['orderId'] as int,
        method: json['method'] as String,
        amount: json['amount'] as int,
        status: json['status'] as String,
        approvalNumber: json['approvalNumber'] as String?,
        createdAt: json['createdAt'] as String,
      );
}
