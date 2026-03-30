import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../providers/admin_auth_provider.dart';
import '../../theme/app_colors.dart';

final _selectedStatusFilter = StateProvider<String?>((ref) => null);

final _ordersProvider = FutureProvider<List<Order>>((ref) {
  final status = ref.watch(_selectedStatusFilter);
  return ref.read(adminServiceProvider).getOrders(status: status);
});

class OrderManageScreen extends ConsumerWidget {
  const OrderManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(_ordersProvider);
    final selectedStatus = ref.watch(_selectedStatusFilter);

    final filters = [
      {'key': null, 'label': '전체'},
      {'key': 'PENDING', 'label': '대기'},
      {'key': 'PREPARING', 'label': '조리중'},
      {'key': 'COMPLETED', 'label': '완료'},
      {'key': 'PAID', 'label': '결제완료'},
      {'key': 'CANCELLED', 'label': '취소'},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('주문 조회',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: filters.map((f) {
              final key = f['key'] as String?;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f['label'] as String),
                  selected: selectedStatus == key,
                  onSelected: (_) =>
                      ref.read(_selectedStatusFilter.notifier).state = key,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(
                      child: Text('주문이 없습니다',
                          style: TextStyle(color: AppColors.textSecondary)));
                }
                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      child: ExpansionTile(
                        leading: _statusIcon(order.status),
                        title: Text('주문 #${order.orderNumber}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${_formatPrice(order.totalAmount)}원 · ${order.createdAt.substring(0, 16)}'),
                        trailing: _buildStatusLabel(order.status),
                        children: order.items
                            .map((item) => ListTile(
                                  dense: true,
                                  title: Text(
                                      '${item.menuName} x${item.quantity}'),
                                  trailing: Text(
                                      '${_formatPrice(item.totalPrice)}원'),
                                ))
                            .toList(),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('주문 로드 실패: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIcon(String status) {
    switch (status) {
      case 'PAID':
        return const Icon(Icons.payment, color: AppColors.adminAccent);
      case 'PREPARING':
        return const Icon(Icons.restaurant, color: AppColors.warning);
      case 'COMPLETED':
        return const Icon(Icons.check_circle, color: AppColors.success);
      case 'CANCELLED':
        return const Icon(Icons.cancel, color: AppColors.error);
      default:
        return const Icon(Icons.pending, color: AppColors.textSecondary);
    }
  }

  Widget _buildStatusLabel(String status) {
    final (label, color) = switch (status) {
      'PENDING' => ('대기', AppColors.adminAccent),
      'PREPARING' => ('조리중', AppColors.warning),
      'COMPLETED' => ('완료', AppColors.success),
      'PAID' => ('결제완료', AppColors.adminAccent),
      'CANCELLED' => ('취소', AppColors.error),
      _ => (status, AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
