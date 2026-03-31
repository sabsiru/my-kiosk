import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/store.dart';
import '../../providers/admin_auth_provider.dart';
import '../../theme/app_colors.dart';

final _storeProvider = FutureProvider<Store>((ref) {
  return ref.read(adminServiceProvider).getStore();
});

class StoreSettingsScreen extends ConsumerStatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  ConsumerState<StoreSettingsScreen> createState() =>
      _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends ConsumerState<StoreSettingsScreen> {
  final _nameController = TextEditingController();
  final _openTimeController = TextEditingController();
  final _closeTimeController = TextEditingController();
  bool _isOpen = true;
  bool _hideAdminButton = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    super.dispose();
  }

  void _initFields(Store store) {
    if (!_initialized) {
      _nameController.text = store.name;
      _openTimeController.text = store.openTime;
      _closeTimeController.text = store.closeTime;
      _isOpen = store.isOpen;
      _hideAdminButton = store.hideAdminButton;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeAsync = ref.watch(_storeProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('매장 설정',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: storeAsync.when(
              data: (store) {
                _initFields(store);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: '매장명',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _openTimeController,
                                decoration: const InputDecoration(
                                  labelText: '영업 시작',
                                  border: OutlineInputBorder(),
                                  hintText: '09:00',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _closeTimeController,
                                decoration: const InputDecoration(
                                  labelText: '영업 종료',
                                  border: OutlineInputBorder(),
                                  hintText: '22:00',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('영업 중'),
                          value: _isOpen,
                          onChanged: (v) => setState(() => _isOpen = v),
                        ),
                        SwitchListTile(
                          title: const Text('키오스크 관리자 버튼 숨김'),
                          subtitle: const Text('OFF: 키오스크에 설정 버튼 표시, ON: 롱프레스로만 접근'),
                          value: _hideAdminButton,
                          onChanged: (v) => setState(() => _hideAdminButton = v),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => _save(),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.adminPrimary),
                          child: const Text('저장'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('매장 정보 로드 실패: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    try {
      await ref.read(adminServiceProvider).updateStore({
        'name': _nameController.text,
        'openTime': _openTimeController.text,
        'closeTime': _closeTimeController.text,
        'isOpen': _isOpen,
        'hideAdminButton': _hideAdminButton,
      });
      _initialized = false;
      ref.invalidate(_storeProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('저장되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    }
  }
}
