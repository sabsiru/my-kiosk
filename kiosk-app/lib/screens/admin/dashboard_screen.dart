import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../models/settlement.dart';
import '../../providers/admin_auth_provider.dart';
import '../../theme/app_colors.dart';

class AdminDashboardScreen extends ConsumerWidget {
  final Widget child;

  const AdminDashboardScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(adminAuthProvider);
    final currentPath = GoRouterState.of(context).uri.toString();

    final menuItems = [
      _NavItem(icon: Icons.dashboard, label: '대시보드', path: '/admin/manage'),
      _NavItem(icon: Icons.storefront, label: '영업', path: '/admin/manage/operation'),
      _NavItem(icon: Icons.restaurant_menu, label: '메뉴 관리', path: '/admin/manage/menus'),
      _NavItem(icon: Icons.receipt_long, label: '주문 조회', path: '/admin/manage/orders'),
      _NavItem(icon: Icons.table_bar, label: '테이블 관리', path: '/admin/manage/tables'),
      _NavItem(icon: Icons.calculate, label: '정산', path: '/admin/manage/settlements'),
      _NavItem(icon: Icons.bar_chart, label: '통계', path: '/admin/manage/statistics'),
      _NavItem(icon: Icons.settings, label: '매장 설정', path: '/admin/manage/store'),
    ];

    return Scaffold(
      body: Row(
        children: [
          // 사이드 네비게이션
          Container(
            width: 240,
            color: AppColors.adminPrimary,
            child: Column(
              children: [
                // 헤더
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Icon(Icons.store, size: 40, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        auth.name ?? '관리자',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        auth.role ?? '',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),

                // 메뉴 항목
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: menuItems.map((item) {
                      final isSelected = currentPath == item.path ||
                          (item.path != '/admin/manage' &&
                              currentPath.startsWith(item.path));
                      return ListTile(
                        leading: Icon(item.icon,
                            color:
                                isSelected ? Colors.white : Colors.white60),
                        title: Text(item.label,
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white60,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                        selected: isSelected,
                        selectedTileColor: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        onTap: () => context.go(item.path),
                      );
                    }).toList(),
                  ),
                ),

                // 하단
                ListTile(
                  leading:
                      const Icon(Icons.arrow_back, color: Colors.white60),
                  title: const Text('모드 선택',
                      style: TextStyle(color: Colors.white60)),
                  onTap: () => context.go('/admin/mode'),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.logout, color: Colors.white60),
                  title: const Text('로그아웃',
                      style: TextStyle(color: Colors.white60)),
                  onTap: () {
                    ref.read(adminAuthProvider.notifier).logout();
                    context.go('/admin/login');
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // 메인 콘텐츠
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;

  _NavItem({required this.icon, required this.label, required this.path});
}

// 대시보드 홈 콘텐츠
final _dashboardSettlementProvider = FutureProvider<Settlement>((ref) {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return ref.read(adminServiceProvider).getDailySettlement(today);
});

final _dashboardOrdersProvider = FutureProvider<List<Order>>((ref) {
  return ref.read(adminServiceProvider).getOrders(limit: 10);
});

class DashboardHomeContent extends ConsumerWidget {
  const DashboardHomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementAsync = ref.watch(_dashboardSettlementProvider);
    final ordersAsync = ref.watch(_dashboardOrdersProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('대시보드',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () {
                  ref.invalidate(_dashboardSettlementProvider);
                  ref.invalidate(_dashboardOrdersProvider);
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 24),
          settlementAsync.when(
            data: (s) => Row(
              children: [
                _StatCard(
                    title: '오늘 매출',
                    value: '${_formatPrice(s.totalRevenue)}원',
                    icon: Icons.attach_money,
                    color: AppColors.success),
                const SizedBox(width: 16),
                _StatCard(
                    title: '오늘 주문',
                    value: '${s.totalOrders}건',
                    icon: Icons.receipt,
                    color: AppColors.adminAccent),
                const SizedBox(width: 16),
                _StatCard(
                    title: '취소',
                    value: '${s.cancelledCount}건',
                    icon: Icons.cancel_outlined,
                    color: AppColors.error),
                const SizedBox(width: 16),
                _StatCard(
                    title: '마감 상태',
                    value: s.isClosed ? '마감' : '영업중',
                    icon: s.isClosed ? Icons.lock : Icons.lock_open,
                    color: s.isClosed ? AppColors.textSecondary : AppColors.warning),
              ],
            ),
            loading: () => const SizedBox(
                height: 100, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('정산 데이터 로드 실패: $e'),
          ),
          const SizedBox(height: 32),
          const Text('최근 주문',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
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
                  itemBuilder: (context, i) {
                    final order = orders[i];
                    return Card(
                      child: ListTile(
                        leading: _statusIcon(order.status),
                        title: Text('주문 #${order.orderNumber}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${order.items.map((e) => '${e.menuName} x${e.quantity}').join(', ')}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${_formatPrice(order.totalAmount)}원',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(order.createdAt.substring(11, 16),
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
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

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textSecondary)),
                  ),
                  Icon(icon, color: color, size: 28),
                ],
              ),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
