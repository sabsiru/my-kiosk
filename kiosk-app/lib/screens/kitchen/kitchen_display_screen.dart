import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/order.dart';
import '../../providers/admin_auth_provider.dart';
import '../../services/kitchen_service.dart';
import '../../services/websocket_service.dart';
import '../../theme/app_colors.dart';

final kitchenServiceProvider = Provider((ref) => KitchenService());

final _kitchenOrdersProvider = FutureProvider<List<Order>>((ref) {
  final storeId = ref.read(adminAuthProvider).storeId;
  if (storeId == null) throw Exception('매장 정보가 없습니다.');
  return ref.read(kitchenServiceProvider).getActiveOrders(storeId: storeId);
});

class KitchenDisplayScreen extends ConsumerStatefulWidget {
  const KitchenDisplayScreen({super.key});

  @override
  ConsumerState<KitchenDisplayScreen> createState() =>
      _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends ConsumerState<KitchenDisplayScreen> {
  final _wsService = WebSocketService();
  StreamSubscription? _kitchenSub;

  @override
  void initState() {
    super.initState();
    _wsService.connectKitchen();
    _kitchenSub = _wsService.kitchenStream.listen((data) {
      ref.invalidate(_kitchenOrdersProvider);
    });
  }

  @override
  void dispose() {
    _kitchenSub?.cancel();
    _wsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(_kitchenOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => context.go('/admin/mode'),
        ),
        title: const Text('주방 디스플레이',
            style: TextStyle(color: Colors.white, fontSize: 24)),
        actions: [
          TextButton.icon(
            onPressed: () => ref.invalidate(_kitchenOrdersProvider),
            icon: const Icon(Icons.refresh, color: Colors.white70),
            label: const Text('새로고침',
                style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          final pendingOrders =
              orders.where((o) => o.status == 'PENDING').toList();
          final preparingOrders =
              orders.where((o) => o.status == 'PREPARING').toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('신규 주문', AppColors.adminAccent),
                      const SizedBox(height: 12),
                      Expanded(
                          child: _buildOrderGrid(pendingOrders, isPending: true)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('조리 중', AppColors.warning),
                      const SizedBox(height: 12),
                      Expanded(
                          child:
                              _buildOrderGrid(preparingOrders, isPending: false)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white54)),
        error: (e, _) => Center(
            child: Text('$e', style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(title,
          style: TextStyle(
              color: color, fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildOrderGrid(List<Order> orders, {required bool isPending}) {
    if (orders.isEmpty) {
      return Center(
        child: Text(isPending ? '신규 주문 없음' : '조리 중인 주문 없음',
            style: const TextStyle(color: Colors.white30, fontSize: 18)),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: orders.length,
      itemBuilder: (context, i) =>
          _OrderCard(order: orders[i], isPending: isPending, onAction: _onAction),
    );
  }

  Future<void> _onAction(Order order, String nextStatus) async {
    final storeId = ref.read(adminAuthProvider).storeId;
    if (storeId == null) return;
    try {
      await ref
          .read(kitchenServiceProvider)
          .updateOrderStatus(order.id, nextStatus, storeId: storeId);
      ref.invalidate(_kitchenOrdersProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    }
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool isPending;
  final Future<void> Function(Order, String) onAction;

  const _OrderCard({
    required this.order,
    required this.isPending,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isPending ? AppColors.adminAccent : AppColors.warning;

    return Card(
      color: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${order.orderNumber}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text(order.createdAt.substring(11, 16),
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
            const Divider(color: Colors.white24, height: 16),
            Expanded(
              child: ListView(
                children: order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(item.menuName,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16)),
                        ),
                        Text('x${item.quantity}',
                            style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () =>
                    onAction(order, isPending ? 'PREPARING' : 'COMPLETED'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isPending ? AppColors.adminAccent : AppColors.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(isPending ? '조리 시작' : '조리 완료',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
