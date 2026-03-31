class MenuSales {
  final int menuId;
  final String menuName;
  final String categoryName;
  final int totalQuantity;
  final int totalRevenue;

  MenuSales({
    required this.menuId,
    required this.menuName,
    required this.categoryName,
    required this.totalQuantity,
    required this.totalRevenue,
  });

  factory MenuSales.fromJson(Map<String, dynamic> json) => MenuSales(
        menuId: json['menuId'] as int,
        menuName: json['menuName'] as String,
        categoryName: json['categoryName'] as String,
        totalQuantity: json['totalQuantity'] as int,
        totalRevenue: json['totalRevenue'] as int,
      );
}

class RevenueStat {
  final String date;
  final int totalRevenue;
  final int totalOrders;

  RevenueStat({
    required this.date,
    required this.totalRevenue,
    required this.totalOrders,
  });

  factory RevenueStat.fromJson(Map<String, dynamic> json) => RevenueStat(
        date: json['date'] as String,
        totalRevenue: json['totalRevenue'] as int,
        totalOrders: json['totalOrders'] as int,
      );
}

class HourlyStat {
  final int hour;
  final int orderCount;
  final int revenue;

  HourlyStat({
    required this.hour,
    required this.orderCount,
    required this.revenue,
  });

  factory HourlyStat.fromJson(Map<String, dynamic> json) => HourlyStat(
        hour: json['hour'] as int,
        orderCount: json['orderCount'] as int,
        revenue: json['revenue'] as int,
      );
}

class CategorySales {
  final int categoryId;
  final String categoryName;
  final int totalRevenue;
  final double percentage;

  CategorySales({
    required this.categoryId,
    required this.categoryName,
    required this.totalRevenue,
    required this.percentage,
  });

  factory CategorySales.fromJson(Map<String, dynamic> json) => CategorySales(
        categoryId: json['categoryId'] as int,
        categoryName: json['categoryName'] as String,
        totalRevenue: json['totalRevenue'] as int,
        percentage: (json['percentage'] as num).toDouble(),
      );
}
