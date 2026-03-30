import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin_auth_provider.dart';

class HqLoginScreen extends ConsumerStatefulWidget {
  const HqLoginScreen({super.key});

  @override
  ConsumerState<HqLoginScreen> createState() => _HqLoginScreenState();
}

class _HqLoginScreenState extends ConsumerState<HqLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.business, size: 64, color: Color(0xFF6C63FF)),
                const SizedBox(height: 16),
                const Text('본사 관리자 로그인',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: '아이디',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child:
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('로그인',
                            style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('돌아가기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await ref.read(adminAuthProvider.notifier).login(
          _usernameController.text,
          _passwordController.text,
        );

    setState(() => _isLoading = false);

    if (success && mounted) {
      final auth = ref.read(adminAuthProvider);
      if (auth.isHqAdmin) {
        context.go('/hq');
      } else {
        ref.read(adminAuthProvider.notifier).logout();
        setState(() => _error = '본사 관리자 계정이 아닙니다');
      }
    } else {
      setState(() => _error = '아이디 또는 비밀번호가 잘못되었습니다');
    }
  }
}
