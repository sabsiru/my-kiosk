import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/settlement.dart';
import '../../providers/admin_auth_provider.dart';
import '../../theme/app_colors.dart';

final _dailySettlementProvider = FutureProvider<Settlement>((ref) {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return ref.read(adminServiceProvider).getDailySettlement(today);
});

final _paymentMethodProvider = FutureProvider<Map<String, int>>((ref) {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final weekAgo =
      DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 7)));
  return ref.read(adminServiceProvider).getByPaymentMethod(weekAgo, today);
});

class SettlementScreen extends ConsumerWidget {
  const SettlementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(_dailySettlementProvider);
    final methodAsync = ref.watch(_paymentMethodProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('정산',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _closeSettlement(context, ref),
                icon: const Icon(Icons.lock),
                label: const Text('당일 마감'),
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 24),
          dailyAsync.when(
            data: (s) => Row(
              children: [
                _Card(
                    title: '총 매출',
                    value: '${_formatPrice(s.totalRevenue)}원',
                    color: AppColors.success),
                const SizedBox(width: 16),
                _Card(
                    title: '총 주문',
                    value: '${s.totalOrders}건',
                    color: AppColors.adminAccent),
                const SizedBox(width: 16),
                _Card(
                    title: '취소',
                    value: '${_formatPrice(s.cancelledAmount)}원 (${s.cancelledCount}건)',
                    color: AppColors.error),
                const SizedBox(width: 16),
                _Card(
                    title: '마감 여부',
                    value: s.isClosed ? '마감 완료' : '미마감',
                    color: s.isClosed ? AppColors.success : AppColors.warning),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('정산 로드 실패: $e'),
          ),
          const SizedBox(height: 32),
          const Text('결제수단별 매출 (최근 7일)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          methodAsync.when(
            data: (methods) => Row(
              children: methods.entries.map((e) {
                return Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(_methodLabel(e.key),
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Text('${_formatPrice(e.value)}원',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('결제수단 데이터 로드 실패: $e'),
          ),
        ],
      ),
    );
  }

  String _methodLabel(String key) {
    switch (key) {
      case 'CARD':
        return '카드';
      case 'CASH':
        return '현금';
      case 'KAKAO_PAY':
        return '카카오페이';
      case 'NAVER_PAY':
        return '네이버페이';
      default:
        return key;
    }
  }

  Future<void> _closeSettlement(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('당일 마감'),
        content: const Text('오늘 정산을 마감하시겠습니까? 마감 후 수정할 수 없습니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('마감'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await ref.read(adminServiceProvider).closeSettlement(today);
        ref.invalidate(_dailySettlementProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('오류: $e')));
        }
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

class _Card extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _Card(
      {required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
