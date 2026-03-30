import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin_auth_provider.dart';
import '../../theme/app_colors.dart';

class ModeSelectScreen extends ConsumerWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(adminAuthProvider);

    return Scaffold(
      backgroundColor: AppColors.adminPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store, size: 48, color: Colors.white70),
            const SizedBox(height: 12),
            Text(
              auth.name ?? '관리자',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '모드를 선택하세요',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModeCard(
                  icon: Icons.dashboard,
                  label: '관리자 모드',
                  sublabel: '매장 관리',
                  color: AppColors.adminAccent,
                  onTap: () => context.go('/admin/manage'),
                ),
                const SizedBox(width: 24),
                _ModeCard(
                  icon: Icons.touch_app,
                  label: '키오스크 모드',
                  sublabel: '주문 접수',
                  color: AppColors.primary,
                  onTap: () => context.go('/admin/kiosk/table-select'),
                ),
                const SizedBox(width: 24),
                _ModeCard(
                  icon: Icons.restaurant,
                  label: '주방 디스플레이',
                  sublabel: '조리 현황',
                  color: AppColors.warning,
                  onTap: () => context.go('/admin/kitchen'),
                ),
              ],
            ),
            const SizedBox(height: 48),
            TextButton.icon(
              onPressed: () {
                ref.read(adminAuthProvider.notifier).logout();
                context.go('/');
              },
              icon: const Icon(Icons.logout, color: Colors.white54),
              label: const Text('로그아웃',
                  style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
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
          width: 200,
          height: 220,
          decoration: BoxDecoration(
            color: _hovering
                ? widget.color.withOpacity(0.15)
                : const Color(0xFF1A2332),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovering
                  ? widget.color
                  : Colors.white.withOpacity(0.1),
              width: _hovering ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 56, color: widget.color),
              const SizedBox(height: 16),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.sublabel,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
