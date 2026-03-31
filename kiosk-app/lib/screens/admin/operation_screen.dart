import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../models/store.dart';
import '../../models/table.dart';
import '../../providers/admin_auth_provider.dart';
import '../../services/websocket_service.dart';
import '../../theme/app_colors.dart';

final _storeProvider = FutureProvider<Store>((ref) {
  return ref.read(adminServiceProvider).getStore();
});

final _tablesProvider = FutureProvider<List<KioskTable>>((ref) {
  return ref.read(adminServiceProvider).getTables();
});

final _selectedTableIdProvider = StateProvider<int?>((ref) => null);

final _tableOrdersProvider = FutureProvider.family<List<Order>, int>((ref, tableId) {
  return ref.read(adminServiceProvider).getOrdersByTable(tableId);
});

class OperationScreen extends ConsumerWidget {
  const OperationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = ref.watch(_storeProvider);

    return storeAsync.when(
      data: (store) => store.isOpen
          ? _OperatingView(store: store)
          : _PreOperatingView(store: store),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('매장 정보 로드 실패: $e')),
    );
  }
}

class _PreOperatingView extends ConsumerWidget {
  final Store store;
  const _PreOperatingView({required this.store});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(_tablesProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('영업 준비',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(adminServiceProvider).openStore();
                  ref.invalidate(_storeProvider);
                  ref.invalidate(_tablesProvider);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('영업 시작', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('영업 시작 전 테이블 배치를 확인하세요',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Expanded(
            child: tablesAsync.when(
              data: (tables) {
                if (tables.isEmpty) {
                  return const Center(
                    child: Text('등록된 테이블이 없습니다.\n테이블 관리에서 추가해주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                  );
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: tables.length,
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    return Card(
                      color: AppColors.surface,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.table_bar,
                                size: 32, color: AppColors.textSecondary),
                            const SizedBox(height: 8),
                            Text('${table.tableNumber}번',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('테이블 로드 실패: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatingView extends ConsumerStatefulWidget {
  final Store store;
  const _OperatingView({required this.store});

  @override
  ConsumerState<_OperatingView> createState() => _OperatingViewState();
}

class _OperatingViewState extends ConsumerState<_OperatingView> {
  Timer? _refreshTimer;
  final _wsService = WebSocketService();
  StreamSubscription? _orderSub;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(_tablesProvider);
    });
    _wsService.connectOrderStatus();
    _orderSub = _wsService.orderStatusStream.listen((_) {
      ref.invalidate(_tablesProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _orderSub?.cancel();
    _wsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final tablesAsync = ref.watch(_tablesProvider);
    final selectedTableId = ref.watch(_selectedTableIdProvider);

    return Row(
      children: [
        // 좌측: 테이블 그리드
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('영업 중',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            ref.invalidate(_tablesProvider);
                            ref.invalidate(_storeProvider);
                          },
                          icon: const Icon(Icons.refresh),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _confirmCloseStore(context, ref),
                          icon: const Icon(Icons.stop, color: AppColors.error),
                          label: const Text('영업 종료',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: tablesAsync.when(
                    data: (tables) => GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: tables.length,
                      itemBuilder: (context, index) {
                        final table = tables[index];
                        final isOccupied = table.status == 'OCCUPIED';
                        final isSelected = selectedTableId == table.id;
                        return GestureDetector(
                          onTap: () {
                            ref.read(_selectedTableIdProvider.notifier).state =
                                table.id;
                          },
                          child: Card(
                            color: isSelected
                                ? AppColors.adminAccent.withOpacity(0.15)
                                : isOccupied
                                    ? AppColors.warning.withOpacity(0.1)
                                    : AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.adminAccent
                                    : isOccupied
                                        ? AppColors.warning
                                        : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.table_bar,
                                      size: 32,
                                      color: isOccupied
                                          ? AppColors.warning
                                          : AppColors.success),
                                  const SizedBox(height: 8),
                                  Text('${table.tableNumber}번',
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    isOccupied ? '사용중' : '비어있음',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isOccupied
                                          ? AppColors.warning
                                          : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 우측: 선택된 테이블 주문 상세
        Container(width: 1, color: AppColors.border),
        Expanded(
          flex: 1,
          child: selectedTableId == null
              ? const Center(
                  child: Text('테이블을 선택하세요',
                      style: TextStyle(
                          fontSize: 16, color: AppColors.textSecondary)),
                )
              : _TableOrderDetail(tableId: selectedTableId),
        ),
      ],
    );
  }

  void _confirmCloseStore(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('영업 종료'),
        content: const Text('영업을 종료하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(adminServiceProvider).closeStore();
              ref.invalidate(_storeProvider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('영업 종료'),
          ),
        ],
      ),
    );
  }
}

class _TableOrderDetail extends ConsumerWidget {
  final int tableId;
  const _TableOrderDetail({required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(_tableOrdersProvider(tableId));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('테이블 주문 상세',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                final activeOrders = orders
                    .where((o) => o.status != 'PAID' && o.status != 'CANCELLED')
                    .toList();
                if (activeOrders.isEmpty) {
                  return const Center(
                    child: Text('활성 주문이 없습니다',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                final totalAmount = activeOrders.fold<int>(
                    0, (sum, o) => sum + o.totalAmount);
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: activeOrders.length,
                        itemBuilder: (context, index) {
                          final order = activeOrders[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
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
                                              fontWeight: FontWeight.w600)),
                                      _OrderStatusBadge(status: order.status),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ...order.items.map((item) => Text(
                                      '${item.menuName} x${item.quantity}  ${_formatPrice(item.totalPrice)}원',
                                      style: const TextStyle(fontSize: 14))),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${_formatPrice(order.totalAmount)}원',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('합계',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('${_formatPrice(totalAmount)}원',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () =>
                            _showPaymentDialog(context, ref, totalAmount),
                        child: const Text('결제하기', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(
      BuildContext context, WidgetRef ref, int totalAmount) {
    String? selectedMethod;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('결제 - ${_formatPrice(totalAmount)}원'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final method in [
                ('CARD', '카드', Icons.credit_card),
                ('CASH', '현금', Icons.money),
                ('KAKAO_PAY', '카카오페이', Icons.account_balance_wallet),
                ('NAVER_PAY', '네이버페이', Icons.payment),
              ])
                RadioListTile<String>(
                  value: method.$1,
                  groupValue: selectedMethod,
                  onChanged: (v) => setState(() => selectedMethod = v),
                  title: Row(
                    children: [
                      Icon(method.$3, size: 20),
                      const SizedBox(width: 8),
                      Text(method.$2),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: selectedMethod == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      try {
                        await ref
                            .read(adminServiceProvider)
                            .checkoutTable(tableId, selectedMethod!);
                        ref.invalidate(_tablesProvider);
                        ref.invalidate(_tableOrdersProvider(tableId));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('결제 완료'),
                                backgroundColor: AppColors.success),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('결제 실패: $e'),
                                backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
              child: const Text('결제'),
            ),
          ],
        ),
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

class _OrderStatusBadge extends StatelessWidget {
  final String status;
  const _OrderStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'PENDING' => ('대기', AppColors.adminAccent),
      'PREPARING' => ('조리중', AppColors.warning),
      'COMPLETED' => ('완료', AppColors.success),
      _ => (status, AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
