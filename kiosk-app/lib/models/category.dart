class Category {
  final int id;
  final String name;
  final int displayOrder;

  Category({required this.id, required this.name, this.displayOrder = 0});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: json['name'] as String,
        displayOrder: json['displayOrder'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'displayOrder': displayOrder,
      };
}
