import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import '../../theme/app_colors.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 메뉴 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.menuName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                if (item.optionsText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(item.optionsText,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textSecondary)),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${_formatPrice(item.totalPrice)}원',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
          // 수량 조절
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  onPressed: onDecrement,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: onIncrement,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textLight),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
