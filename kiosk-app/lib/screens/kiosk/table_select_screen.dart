import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/table.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/kiosk_table_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';

final _kioskTablesProvider = FutureProvider<List<KioskTable>>((ref) async {
  final auth = ref.read(adminAuthProvider);
  if (auth.storeId == null) return [];
  final dio = ApiClient.instance;
  final response = await dio.get('/kiosk/tables',
      queryParameters: {'storeId': auth.storeId});
  return (response.data as List)
      .map((e) => KioskTable.fromJson(e as Map<String, dynamic>))
      .toList();
});

class TableSelectScreen extends ConsumerWidget {
  const TableSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(_kioskTablesProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.table_bar, size: 56, color: Colors.white70),
            const SizedBox(height: 16),
            const Text(
              '테이블을 선택하세요',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '이 키오스크에서 사용할 테이블 번호를 선택합니다',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
            const SizedBox(height: 48),
            tablesAsync.when(
              data: (tables) {
                if (tables.isEmpty) {
                  return const Text(
                    '등록된 테이블이 없습니다.\n관리자 모드에서 테이블을 추가해주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 16),
                  );
                }
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: tables.map((table) {
                    final isOccupied = table.status == 'OCCUPIED';
                    return _TableCard(
                      table: table,
                      isOccupied: isOccupied,
                      onTap: () {
                        ref.read(kioskSelectedTableProvider.notifier).state =
                            table;
                        context.go('/admin/kiosk');
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(color: Colors.white),
              error: (e, _) => Text(
                '테이블 로드 실패: $e',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
            const SizedBox(height: 48),
            TextButton.icon(
              onPressed: () => context.go('/admin/mode'),
              icon: const Icon(Icons.arrow_back, color: Colors.white54),
              label: const Text('모드 선택으로 돌아가기',
                  style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableCard extends StatefulWidget {
  final KioskTable table;
  final bool isOccupied;
  final VoidCallback onTap;

  const _TableCard({
    required this.table,
    required this.isOccupied,
    required this.onTap,
  });

  @override
  State<_TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<_TableCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: _hovering
                ? AppColors.primary.withOpacity(0.2)
                : const Color(0xFF1A2332),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isOccupied
                  ? AppColors.warning
                  : _hovering
                      ? AppColors.primary
                      : Colors.white.withOpacity(0.1),
              width: _hovering ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.table_bar,
                size: 36,
                color: widget.isOccupied ? AppColors.warning : Colors.white70,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.table.tableNumber}번',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (widget.isOccupied)
                const Text(
                  '사용중',
                  style: TextStyle(fontSize: 12, color: AppColors.warning),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
