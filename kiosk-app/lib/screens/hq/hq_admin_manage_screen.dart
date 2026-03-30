import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_auth_provider.dart';
import '../../theme/app_colors.dart';

final _hqAdminsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminServiceProvider).getHqAdmins();
});

final _hqStoresForAdminProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminServiceProvider).getHqStores();
});

class HqAdminManageScreen extends ConsumerWidget {
  const HqAdminManageScreen({super.key});

  String _roleLabel(String role) {
    switch (role) {
      case 'HQ_ADMIN':
        return '본사 관리자';
      case 'STORE_OWNER':
        return '가맹점주';
      case 'STORE_MANAGER':
        return '매장 매니저';
      default:
        return role;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'HQ_ADMIN':
        return const Color(0xFF6C63FF);
      case 'STORE_OWNER':
        return AppColors.success;
      case 'STORE_MANAGER':
        return Colors.orange;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(_hqAdminsProvider);
    final storesAsync = ref.watch(_hqStoresForAdminProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('계정 관리',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context, ref, storesAsync),
                icon: const Icon(Icons.person_add),
                label: const Text('계정 추가'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1B2A)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: adminsAsync.when(
              data: (admins) {
                if (admins.isEmpty) {
                  return const Center(
                      child: Text('등록된 계정이 없습니다',
                          style: TextStyle(color: AppColors.textSecondary)));
                }
                return ListView.builder(
                  itemCount: admins.length,
                  itemBuilder: (context, i) {
                    final admin = admins[i];
                    final role = admin['role'] as String;
                    final color = _roleColor(role);
                    final storeId = admin['storeId'];
                    final storeName = storesAsync.whenOrNull(
                      data: (stores) {
                        if (storeId == null) return null;
                        final store = stores.where(
                            (s) => (s['id'] as num).toInt() == (storeId as num).toInt());
                        return store.isNotEmpty ? store.first['name'] as String : null;
                      },
                    );

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(Icons.person, color: color),
                        ),
                        title: Text(admin['name'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        subtitle: Text(
                          '아이디: ${admin['username']}${storeName != null ? ' · 매장: $storeName' : ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(_roleLabel(role),
                                  style: TextStyle(color: color, fontSize: 12)),
                              backgroundColor: color.withOpacity(0.1),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _showEditDialog(
                                  context, ref, admin, storesAsync),
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppColors.textSecondary),
                              tooltip: '수정',
                            ),
                            if (role != 'HQ_ADMIN')
                              IconButton(
                                onPressed: () =>
                                    _deleteAdmin(context, ref, admin),
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.error),
                                tooltip: '삭제',
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('계정 목록 로드 실패: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref,
      AsyncValue<List<Map<String, dynamic>>> storesAsync) async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    String selectedRole = 'STORE_OWNER';
    int? selectedStoreId;

    final stores = storesAsync.valueOrNull ?? [];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('계정 추가'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                      labelText: '아이디', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: '비밀번호', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: '이름', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                      labelText: '역할', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                        value: 'STORE_OWNER', child: Text('가맹점주')),
                    DropdownMenuItem(
                        value: 'STORE_MANAGER', child: Text('매장 매니저')),
                    DropdownMenuItem(
                        value: 'HQ_ADMIN', child: Text('본사 관리자')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedRole = v ?? selectedRole),
                ),
                if (selectedRole != 'HQ_ADMIN') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedStoreId,
                    decoration: const InputDecoration(
                        labelText: '소속 매장', border: OutlineInputBorder()),
                    items: stores
                        .map((s) => DropdownMenuItem<int>(
                              value: (s['id'] as num).toInt(),
                              child: Text(s['name'] as String),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedStoreId = v),
                  ),
                ],
              ],
            ),
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
      ),
    );

    if (result == true) {
      try {
        await ref.read(adminServiceProvider).createHqAdmin(
              username: usernameController.text,
              password: passwordController.text,
              name: nameController.text,
              role: selectedRole,
              storeId: selectedRole == 'HQ_ADMIN' ? null : selectedStoreId,
            );
        ref.invalidate(_hqAdminsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref,
      Map<String, dynamic> admin,
      AsyncValue<List<Map<String, dynamic>>> storesAsync) async {
    final nameController =
        TextEditingController(text: admin['name'] as String);
    final passwordController = TextEditingController();
    String selectedRole = admin['role'] as String;
    int? selectedStoreId = (admin['storeId'] as num?)?.toInt();

    final stores = storesAsync.valueOrNull ?? [];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('계정 수정 (${admin['username']})'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: '이름', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: '비밀번호 (변경 시에만 입력)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                      labelText: '역할', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                        value: 'STORE_OWNER', child: Text('가맹점주')),
                    DropdownMenuItem(
                        value: 'STORE_MANAGER', child: Text('매장 매니저')),
                    DropdownMenuItem(
                        value: 'HQ_ADMIN', child: Text('본사 관리자')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedRole = v ?? selectedRole),
                ),
                if (selectedRole != 'HQ_ADMIN') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedStoreId,
                    decoration: const InputDecoration(
                        labelText: '소속 매장', border: OutlineInputBorder()),
                    items: stores
                        .map((s) => DropdownMenuItem<int>(
                              value: (s['id'] as num).toInt(),
                              child: Text(s['name'] as String),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedStoreId = v),
                  ),
                ],
              ],
            ),
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
      ),
    );

    if (result == true) {
      try {
        await ref.read(adminServiceProvider).updateHqAdmin(
              (admin['id'] as num).toInt(),
              name: nameController.text,
              role: selectedRole,
              storeId: selectedRole == 'HQ_ADMIN' ? null : selectedStoreId,
              password: passwordController.text.isEmpty
                  ? null
                  : passwordController.text,
            );
        ref.invalidate(_hqAdminsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }

  Future<void> _deleteAdmin(
      BuildContext context, WidgetRef ref, Map<String, dynamic> admin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 삭제'),
        content: Text('\'${admin['name']}\' 계정을 삭제하시겠습니까?'),
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
        await ref
            .read(adminServiceProvider)
            .deleteHqAdmin((admin['id'] as num).toInt());
        ref.invalidate(_hqAdminsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }
}
