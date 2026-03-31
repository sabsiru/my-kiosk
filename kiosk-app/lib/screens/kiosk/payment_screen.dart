import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/payment_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isProcessing = false;
  String? _selectedMethod;

  final _methods = [
    {'key': 'CARD', 'label': '신용/체크카드', 'icon': Icons.credit_card},
    {'key': 'KAKAO_PAY', 'label': '카카오페이', 'icon': Icons.account_balance_wallet},
    {'key': 'NAVER_PAY', 'label': '네이버페이', 'icon': Icons.payment},
  ];

  @override
  Widget build(BuildContext context) {
    final cartTotal = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: _isProcessing ? null : () => context.go('/admin/kiosk/cart'),
        ),
        title: const Text('결제'),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 4),
                  SizedBox(height: 24),
                  Text('결제 처리 중...',
                      style: TextStyle(fontSize: 20, color: AppColors.textSecondary)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(AppTheme.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 결제 금액
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.paddingLarge),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Text('결제 금액',
                            style: TextStyle(
                                fontSize: 18, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text(
                          '${_formatPrice(cartTotal)}원',
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text('결제 수단 선택',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),

                  // 결제 수단 선택
                  ...(_methods).map((method) {
                    final key = method['key'] as String;
                    final isSelected = _selectedMethod == key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => setState(() => _selectedMethod = key),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.paddingMedium),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(method['icon'] as IconData,
                                  size: 32,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary),
                              const SizedBox(width: 16),
                              Text(method['label'] as String,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal)),
                              const Spacer(),
                              if (isSelected)
                                const Icon(Icons.check_circle,
                                    color: AppColors.primary, size: 28),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed:
                          _selectedMethod == null ? null : _processPayment,
                      child: const Text('결제하기', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      final storeId = ref.read(adminAuthProvider).storeId;
      if (storeId == null) throw Exception('매장 정보가 없습니다.');

      final cartItems = ref.read(cartProvider);
      final orderService = ref.read(orderServiceProvider);
      final paymentService = PaymentService();

      // 1. 주문 생성
      final order = await orderService.createOrder(
        storeId: storeId,
        items: cartItems
            .map((item) => {
                  'menuId': item.menuId,
                  'quantity': item.quantity,
                  'selectedOptions': item.optionsText,
                  'optionAdditionalPrice': item.optionAdditionalPrice,
                })
            .toList(),
      );

      // 2. 결제 처리
      await paymentService.createPayment(
        storeId: storeId,
        orderId: order.id,
        method: _selectedMethod!,
      );

      // 3. 장바구니 초기화
      ref.read(cartProvider.notifier).clear();
      ref.read(currentOrderProvider.notifier).state = order;

      if (mounted) {
        context.go('/admin/kiosk/complete');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('결제 실패: $e'), backgroundColor: AppColors.error),
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
