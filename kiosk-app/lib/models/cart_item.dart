import 'menu.dart';

class CartItem {
  final int menuId;
  final String menuName;
  final int unitPrice;
  final int quantity;
  final Map<String, List<MenuOptionItem>> selectedOptions;
  final int optionAdditionalPrice;

  CartItem({
    required this.menuId,
    required this.menuName,
    required this.unitPrice,
    this.quantity = 1,
    this.selectedOptions = const {},
    this.optionAdditionalPrice = 0,
  });

  int get totalPrice => (unitPrice + optionAdditionalPrice) * quantity;

  String get optionsText {
    final parts = <String>[];
    for (final items in selectedOptions.values) {
      for (final item in items) {
        parts.add(item.name);
      }
    }
    return parts.join(', ');
  }

  CartItem copyWith({int? quantity}) => CartItem(
        menuId: menuId,
        menuName: menuName,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        selectedOptions: selectedOptions,
        optionAdditionalPrice: optionAdditionalPrice,
      );
}
