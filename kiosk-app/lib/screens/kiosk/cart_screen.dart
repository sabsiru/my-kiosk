import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/kiosk_order_history_provider.dart';
import '../../providers/kiosk_table_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kiosk/cart_item_widget.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isOrdering = false;

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartTotal = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => context.go('/admin/kiosk/menu'),
        ),
        title: const Text('장바구니'),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: const Text('전체 삭제',
                  style: TextStyle(color: AppColors.error, fontSize: 16)),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: AppColors.textLight),
                  SizedBox(height: 16),
                  Text('장바구니가 비어있습니다',
                      style: TextStyle(
                          fontSize: 20, color: AppColors.textSecondary)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.paddingMedium),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return CartItemWidget(
                        item: item,
                        onIncrement: () => ref
                            .read(cartProvider.notifier)
                            .updateQuantity(index, item.quantity + 1),
                        onDecrement: () => ref
                            .read(cartProvider.notifier)
                            .updateQuantity(index, item.quantity - 1),
                        onRemove: () =>
                            ref.read(cartProvider.notifier).removeItem(index),
                      );
                    },
                  ),
                ),
                // 합계 + 주문 버튼
                Container(
                  padding: const EdgeInsets.all(AppTheme.paddingLarge),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2)),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('총 결제금액',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600)),
                            Text(
                              '${_formatPrice(cartTotal)}원',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isOrdering ? null : _placeOrder,
                            child: _isOrdering
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('주문하기',
                                    style: TextStyle(fontSize: 22)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _isOrdering = true);

    try {
      final storeId = ref.read(adminAuthProvider).storeId;
      if (storeId == null) throw Exception('매장 정보가 없습니다.');

      final cartItems = ref.read(cartProvider);
      final orderService = ref.read(orderServiceProvider);

      final selectedTable = ref.read(kioskSelectedTableProvider);
      final order = await orderService.createOrder(
        storeId: storeId,
        tableId: selectedTable?.id,
        items: cartItems
            .map((item) => {
                  'menuId': item.menuId,
                  'quantity': item.quantity,
                  'selectedOptions': item.optionsText,
                  'optionAdditionalPrice': item.optionAdditionalPrice,
                })
            .toList(),
      );

      ref.read(cartProvider.notifier).clear();
      ref.read(currentOrderProvider.notifier).state = order;
      ref.invalidate(kioskOrderHistoryProvider);

      if (mounted) {
        context.go('/admin/kiosk/complete');
      }
    } catch (e) {
      setState(() => _isOrdering = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('주문 실패: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
