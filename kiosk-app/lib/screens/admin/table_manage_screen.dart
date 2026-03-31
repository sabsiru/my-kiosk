import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/table.dart';
import '../../providers/admin_auth_provider.dart';
import '../../theme/app_colors.dart';

final _tablesProvider = FutureProvider<List<KioskTable>>((ref) {
  return ref.read(adminServiceProvider).getTables();
});

class TableManageScreen extends ConsumerWidget {
  const TableManageScreen({super.key});

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
              const Text('테이블 관리',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showAddDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('테이블 추가'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminPrimary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: tablesAsync.when(
              data: (tables) {
                if (tables.isEmpty) {
                  return const Center(
                      child: Text('등록된 테이블이 없습니다',
                          style: TextStyle(color: AppColors.textSecondary)));
                }
                return GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: tables.length,
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    return Card(
                      color: _statusColor(table.status),
                      child: InkWell(
                        onTap: () => _showEditDialog(context, ref, table),
                        onLongPress: () => _deleteTable(context, ref, table.id),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${table.tableNumber}번',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(_statusText(table.status),
                                  style: const TextStyle(fontSize: 14)),
                              if (table.deviceId != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(table.deviceId!,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('테이블 로드 실패: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return AppColors.success.withOpacity(0.1);
      case 'OCCUPIED':
        return AppColors.warning.withOpacity(0.1);
      default:
        return AppColors.background;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'AVAILABLE':
        return '사용 가능';
      case 'OCCUPIED':
        return '사용 중';
      case 'RESERVED':
        return '예약됨';
      default:
        return status;
    }
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final numberController = TextEditingController();
    final deviceController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테이블 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: '테이블 번호', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: deviceController,
              decoration: const InputDecoration(
                  labelText: '디바이스 ID (선택)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await ref.read(adminServiceProvider).createTable(
              int.tryParse(numberController.text) ?? 0,
              deviceController.text.isEmpty ? null : deviceController.text,
            );
        ref.invalidate(_tablesProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, KioskTable table) async {
    final numberController = TextEditingController(text: '${table.tableNumber}');
    final deviceController = TextEditingController(text: table.deviceId ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테이블 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: '테이블 번호', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: deviceController,
              decoration: const InputDecoration(
                  labelText: '디바이스 ID (선택)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await ref.read(adminServiceProvider).updateTable(
              table.id,
              int.tryParse(numberController.text) ?? table.tableNumber,
              deviceController.text.isEmpty ? null : deviceController.text,
            );
        ref.invalidate(_tablesProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }

  Future<void> _deleteTable(
      BuildContext context, WidgetRef ref, int tableId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테이블 삭제'),
        content: const Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(adminServiceProvider).deleteTable(tableId);
        ref.invalidate(_tablesProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }
}
