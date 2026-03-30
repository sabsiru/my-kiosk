import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/store.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/kiosk_table_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';

final _kioskStoreProvider = FutureProvider<Store>((ref) async {
  final auth = ref.read(adminAuthProvider);
  if (auth.storeId == null) throw Exception('매장 정보 없음');
  final dio = ApiClient.instance;
  final response = await dio.get('/kiosk/store',
      queryParameters: {'storeId': auth.storeId});
  return Store.fromJson(response.data as Map<String, dynamic>);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTable = ref.watch(kioskSelectedTableProvider);
    final storeAsync = ref.watch(_kioskStoreProvider);
    final hideAdminButton = storeAsync.valueOrNull?.hideAdminButton ?? true;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: GestureDetector(
        onTap: () => context.go('/admin/kiosk/menu'),
        onLongPressStart: (details) {
          if (details.globalPosition.dx < 100 &&
              details.globalPosition.dy < 100) {
            _showAdminAuthDialog(context, ref);
          }
        },
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selectedTable != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '테이블 ${selectedTable.tableNumber}번',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (selectedTable != null) const SizedBox(height: 24),
                  const Icon(
                    Icons.restaurant_menu,
                    size: 120,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '주문하기',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '화면을 터치하여 주문을 시작하세요',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white70,
                          fontSize: 20,
                        ),
                  ),
                  const SizedBox(height: 60),
                  const Icon(
                    Icons.touch_app,
                    size: 48,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
            // 관리자 버튼 (숨김 설정에 따라 표시)
            if (!hideAdminButton)
              Positioned(
                right: 16,
                bottom: 16,
                child: GestureDetector(
                  onTap: () => _showAdminAuthDialog(context, ref),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings,
                        color: Colors.white54, size: 24),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAdminAuthDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: AppColors.adminPrimary),
              SizedBox(width: 8),
              Text('관리자 인증'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('관리자 비밀번호를 입력하세요',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  errorText: error,
                ),
                onSubmitted: (_) async {
                  final success = await _verifyAdmin(ref, controller.text);
                  if (success && dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    if (context.mounted) context.go('/admin/mode');
                  } else {
                    setState(() => error = '비밀번호가 잘못되었습니다');
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminPrimary,
              ),
              onPressed: () async {
                final success = await _verifyAdmin(ref, controller.text);
                if (success && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  if (context.mounted) context.go('/admin/mode');
                } else {
                  setState(() => error = '비밀번호가 잘못되었습니다');
                }
              },
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _verifyAdmin(WidgetRef ref, String password) async {
    try {
      final auth = ref.read(adminAuthProvider);
      if (auth.username == null) return false;
      final adminService = ref.read(adminServiceProvider);
      final result = await adminService.login(auth.username!, password);
      return result['token'] != null;
    } catch (_) {
      return false;
    }
  }
}
