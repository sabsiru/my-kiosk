import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_auth_provider.dart';
import '../../theme/app_colors.dart';

final _hqStoresProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminServiceProvider).getHqStores();
});

class HqStoreListScreen extends ConsumerWidget {
  const HqStoreListScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppColors.success;
      case 'SUSPENDED':
        return Colors.orange;
      case 'INACTIVE':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return '운영중';
      case 'SUSPENDED':
        return '해지';
      case 'INACTIVE':
        return '비활성';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(_hqStoresProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('가맹점 관리',
                  style:
                      TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showAddDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('매장 추가'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1B2A)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: storesAsync.when(
              data: (stores) {
                if (stores.isEmpty) {
                  return const Center(
                      child: Text('등록된 매장이 없습니다',
                          style:
                              TextStyle(color: AppColors.textSecondary)));
                }
                return ListView.builder(
                  itemCount: stores.length,
                  itemBuilder: (context, i) {
                    final store = stores[i];
                    final status = store['status'] as String;
                    final color = _statusColor(status);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(Icons.store, color: color),
                        ),
                        title: Text(store['name'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16)),
                        subtitle: Text(
                            '코드: ${store['code']} · DB: ${store['dbName']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(_statusLabel(status),
                                  style: TextStyle(
                                      color: color, fontSize: 12)),
                              backgroundColor: color.withOpacity(0.1),
                            ),
                            const SizedBox(width: 8),
                            if (status == 'ACTIVE') ...[
                              IconButton(
                                onPressed: () => _showEditDialog(
                                    context, ref, store),
                                icon: const Icon(Icons.edit_outlined,
                                    color: AppColors.textSecondary),
                                tooltip: '수정',
                              ),
                              IconButton(
                                onPressed: () => _suspendStore(
                                    context, ref, store),
                                icon: const Icon(Icons.block,
                                    color: Colors.orange),
                                tooltip: '가맹 해지',
                              ),
                            ],
                            if (status == 'SUSPENDED')
                              TextButton.icon(
                                onPressed: () => _reactivateStore(
                                    context, ref, store),
                                icon: const Icon(Icons.refresh,
                                    color: AppColors.success, size: 18),
                                label: const Text('재활성화',
                                    style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('매장 목록 로드 실패: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(
      BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('매장 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: '매장명 (예: 쿠로치쿠 울산삼산점)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                  labelText: '매장 코드 (예: ULSAN_SAMSAN)',
                  border: OutlineInputBorder()),
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
        await ref.read(adminServiceProvider).createHqStore(
              nameController.text,
              codeController.text,
            );
        ref.invalidate(_hqStoresProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }

  Future<void> _showEditDialog(
      BuildContext context, WidgetRef ref, Map<String, dynamic> store) async {
    final nameController =
        TextEditingController(text: store['name'] as String);
    final codeController =
        TextEditingController(text: store['code'] as String);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('매장 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: '매장명', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                  labelText: '매장 코드', border: OutlineInputBorder()),
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
        await ref.read(adminServiceProvider).updateHqStore(
              (store['id'] as num).toInt(),
              nameController.text,
              codeController.text,
              store['status'] as String,
            );
        ref.invalidate(_hqStoresProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }

  Future<void> _suspendStore(
      BuildContext context, WidgetRef ref, Map<String, dynamic> store) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가맹 해지'),
        content: Text(
            '\'${store['name']}\' 매장을 해지하시겠습니까?\n데이터는 보존되며 재활성화할 수 있습니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('해지'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(adminServiceProvider).updateHqStore(
              (store['id'] as num).toInt(),
              store['name'] as String,
              store['code'] as String,
              'SUSPENDED',
            );
        ref.invalidate(_hqStoresProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }

  Future<void> _reactivateStore(
      BuildContext context, WidgetRef ref, Map<String, dynamic> store) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('매장 재활성화'),
        content: Text('\'${store['name']}\' 매장을 다시 활성화하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success),
            child: const Text('활성화'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(adminServiceProvider).updateHqStore(
              (store['id'] as num).toInt(),
              store['name'] as String,
              store['code'] as String,
              'ACTIVE',
            );
        ref.invalidate(_hqStoresProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }
}
