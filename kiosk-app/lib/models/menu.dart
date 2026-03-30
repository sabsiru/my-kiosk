class Menu {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final int price;
  final String? imageUrl;
  final bool isSoldOut;
  final int displayOrder;

  Menu({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description = '',
    required this.price,
    this.imageUrl,
    this.isSoldOut = false,
    this.displayOrder = 0,
  });

  factory Menu.fromJson(Map<String, dynamic> json) => Menu(
        id: json['id'] as int,
        categoryId: json['categoryId'] as int,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        price: json['price'] as int,
        imageUrl: json['imageUrl'] as String?,
        isSoldOut: json['isSoldOut'] as bool? ?? false,
        displayOrder: json['displayOrder'] as int? ?? 0,
      );
}

class MenuDetail {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final int price;
  final String? imageUrl;
  final bool isSoldOut;
  final List<MenuOption> options;

  MenuDetail({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description = '',
    required this.price,
    this.imageUrl,
    this.isSoldOut = false,
    this.options = const [],
  });

  factory MenuDetail.fromJson(Map<String, dynamic> json) => MenuDetail(
        id: json['id'] as int,
        categoryId: json['categoryId'] as int,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        price: json['price'] as int,
        imageUrl: json['imageUrl'] as String?,
        isSoldOut: json['isSoldOut'] as bool? ?? false,
        options: (json['options'] as List<dynamic>?)
                ?.map((e) => MenuOption.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class MenuOption {
  final int id;
  final String name;
  final bool isRequired;
  final int maxSelection;
  final List<MenuOptionItem> items;

  MenuOption({
    required this.id,
    required this.name,
    this.isRequired = false,
    this.maxSelection = 1,
    this.items = const [],
  });

  factory MenuOption.fromJson(Map<String, dynamic> json) => MenuOption(
        id: json['id'] as int,
        name: json['name'] as String,
        isRequired: json['isRequired'] as bool? ?? false,
        maxSelection: json['maxSelection'] as int? ?? 1,
        items: (json['items'] as List<dynamic>?)
                ?.map(
                    (e) => MenuOptionItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class MenuOptionItem {
  final int id;
  final String name;
  final int additionalPrice;

  MenuOptionItem({
    required this.id,
    required this.name,
    this.additionalPrice = 0,
  });

  factory MenuOptionItem.fromJson(Map<String, dynamic> json) => MenuOptionItem(
        id: json['id'] as int,
        name: json['name'] as String,
        additionalPrice: json['additionalPrice'] as int? ?? 0,
      );
}
