class Settlement {
  final String date;
  final int totalRevenue;
  final int totalOrders;
  final int cardAmount;
  final int cashAmount;
  final int kakaoPayAmount;
  final int naverPayAmount;
  final int cancelledAmount;
  final int cancelledCount;
  final bool isClosed;

  Settlement({
    required this.date,
    required this.totalRevenue,
    required this.totalOrders,
    this.cardAmount = 0,
    this.cashAmount = 0,
    this.kakaoPayAmount = 0,
    this.naverPayAmount = 0,
    this.cancelledAmount = 0,
    this.cancelledCount = 0,
    this.isClosed = false,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) => Settlement(
        date: json['date'] as String,
        totalRevenue: json['totalRevenue'] as int,
        totalOrders: json['totalOrders'] as int,
        cardAmount: json['cardAmount'] as int? ?? 0,
        cashAmount: json['cashAmount'] as int? ?? 0,
        kakaoPayAmount: json['kakaoPayAmount'] as int? ?? 0,
        naverPayAmount: json['naverPayAmount'] as int? ?? 0,
        cancelledAmount: json['cancelledAmount'] as int? ?? 0,
        cancelledCount: json['cancelledCount'] as int? ?? 0,
        isClosed: json['isClosed'] as bool? ?? false,
      );
}
