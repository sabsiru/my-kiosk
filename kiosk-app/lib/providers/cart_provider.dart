import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CartItem item) {
    final existingIndex = state.indexWhere(
      (e) =>
          e.menuId == item.menuId && e.optionsText == item.optionsText,
    );

    if (existingIndex >= 0) {
      state = [
        ...state.sublist(0, existingIndex),
        state[existingIndex]
            .copyWith(quantity: state[existingIndex].quantity + item.quantity),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [...state, item];
    }
  }

  void removeItem(int index) {
    state = [...state]..removeAt(index);
  }

  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeItem(index);
      return;
    }
    state = [
      ...state.sublist(0, index),
      state[index].copyWith(quantity: quantity),
      ...state.sublist(index + 1),
    ];
  }

  int get totalAmount => state.fold(0, (sum, item) => sum + item.totalPrice);

  int get totalCount => state.fold(0, (sum, item) => sum + item.quantity);

  void clear() {
    state = [];
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

final cartTotalProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.totalPrice);
});

final cartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});
