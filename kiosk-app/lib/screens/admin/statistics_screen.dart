import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/statistics.dart';
import '../../providers/admin_auth_provider.dart';
import '../../theme/app_colors.dart';

final _periodProvider = StateProvider<int>((ref) => 7);

final _menuSalesProvider = FutureProvider<List<MenuSales>>((ref) {
  final days = ref.watch(_periodProvider);
  final to = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final from = DateFormat('yyyy-MM-dd')
      .format(DateTime.now().subtract(Duration(days: days)));
  return ref.read(adminServiceProvider).getMenuSales(from, to);
});

final _revenueProvider = FutureProvider<List<RevenueStat>>((ref) {
  final days = ref.watch(_periodProvider);
  final to = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final from = DateFormat('yyyy-MM-dd')
      .format(DateTime.now().subtract(Duration(days: days)));
  return ref.read(adminServiceProvider).getRevenueTrend(from, to);
});

final _categorySalesProvider = FutureProvider<List<CategorySales>>((ref) {
  final days = ref.watch(_periodProvider);
  final to = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final from = DateFormat('yyyy-MM-dd')
      .format(DateTime.now().subtract(Duration(days: days)));
  return ref.read(adminServiceProvider).getCategorySales(from, to);
});

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_periodProvider);
    final menuSalesAsync = ref.watch(_menuSalesProvider);
    final revenueAsync = ref.watch(_revenueProvider);
    final categorySalesAsync = ref.watch(_categorySalesProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('통계',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [7, 30, 90].map((d) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${d}일'),
                  selected: period == d,
                  onSelected: (_) =>
                      ref.read(_periodProvider.notifier).state = d,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 메뉴별 판매량
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('메뉴별 판매량',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          Expanded(
                            child: menuSalesAsync.when(
                              data: (sales) {
                                if (sales.isEmpty) {
                                  return const Center(
                                      child: Text('데이터 없음'));
                                }
                                return ListView.builder(
                                  itemCount: sales.length,
                                  itemBuilder: (context, i) {
                                    final s = sales[i];
                                    final maxQty = sales.first.totalQuantity;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 120,
                                            child: Text(s.menuName,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                          Expanded(
                                            child: LinearProgressIndicator(
                                              value: maxQty > 0
                                                  ? s.totalQuantity /
                                                      maxQty
                                                  : 0,
                                              backgroundColor:
                                                  AppColors.border,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('${s.totalQuantity}개',
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(
                                  child: CircularProgressIndicator()),
                              error: (e, _) => Text('$e'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 카테고리별 매출 + 매출 추이
                Expanded(
                  child: Column(
                    children: [
                      // 카테고리별
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('카테고리별 매출',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: categorySalesAsync.when(
                                    data: (sales) {
                                      if (sales.isEmpty) {
                                        return const Center(
                                            child: Text('데이터 없음'));
                                      }
                                      return ListView.builder(
                                        itemCount: sales.length,
                                        itemBuilder: (context, i) {
                                          final s = sales[i];
                                          return ListTile(
                                            dense: true,
                                            title: Text(s.categoryName),
                                            trailing: Text(
                                                '${_formatPrice(s.totalRevenue)}원 (${s.percentage.toStringAsFixed(1)}%)',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          );
                                        },
                                      );
                                    },
                                    loading: () => const Center(
                                        child:
                                            CircularProgressIndicator()),
                                    error: (e, _) => Text('$e'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 매출 추이
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('매출 추이',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: revenueAsync.when(
                                    data: (stats) {
                                      if (stats.isEmpty) {
                                        return const Center(
                                            child: Text('데이터 없음'));
                                      }
                                      return ListView.builder(
                                        itemCount: stats.length,
                                        itemBuilder: (context, i) {
                                          final s = stats[i];
                                          return ListTile(
                                            dense: true,
                                            title: Text(s.date),
                                            trailing: Text(
                                                '${_formatPrice(s.totalRevenue)}원 / ${s.totalOrders}건',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          );
                                        },
                                      );
                                    },
                                    loading: () => const Center(
                                        child:
                                            CircularProgressIndicator()),
                                    error: (e, _) => Text('$e'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
