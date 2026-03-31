import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_auth_provider.dart';
import '../../theme/app_colors.dart';

final _hqSummaryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminServiceProvider).getHqStatisticsSummary();
});

class HqHomeContent extends ConsumerWidget {
  const HqHomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(_hqSummaryProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('본사 대시보드',
                  style:
                      TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () {
                  ref.invalidate(_hqSummaryProvider);
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${DateFormat('yyyy-MM-dd').format(DateTime.now())} 기준',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          const Text('전 매장 매출 현황',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Expanded(
            child: summaryAsync.when(
              data: (summaries) {
                if (summaries.isEmpty) {
                  return const Center(child: Text('매장 데이터가 없습니다'));
                }
                final totalRevenue = summaries.fold<int>(
                    0, (sum, s) => sum + (s['totalRevenue'] as int));
                final totalOrders = summaries.fold<int>(
                    0, (sum, s) => sum + (s['totalOrders'] as int));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 통합 요약 카드
                    Row(
                      children: [
                        _SummaryCard(
                            title: '전체 매출',
                            value: '${_formatPrice(totalRevenue)}원',
                            icon: Icons.attach_money,
                            color: AppColors.success),
                        const SizedBox(width: 16),
                        _SummaryCard(
                            title: '전체 주문',
                            value: '${totalOrders}건',
                            icon: Icons.receipt,
                            color: AppColors.adminAccent),
                        const SizedBox(width: 16),
                        _SummaryCard(
                            title: '운영 매장',
                            value: '${summaries.length}개',
                            icon: Icons.store,
                            color: AppColors.adminPrimary),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('매장별 매출',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: summaries.length,
                        itemBuilder: (context, i) {
                          final s = summaries[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.adminPrimary.withOpacity(0.1),
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                              title: Text(s['storeName'] as String,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  '주문 ${s['totalOrders']}건 · ${(s['isClosed'] as bool) ? '마감' : '영업중'}'),
                              trailing: Text(
                                  '${_formatPrice(s['totalRevenue'] as int)}원',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('데이터 로드 실패: $e')),
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
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
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
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
