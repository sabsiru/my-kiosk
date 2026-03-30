import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin_auth_provider.dart';


class HqDashboardScreen extends ConsumerWidget {
  final Widget child;

  const HqDashboardScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(adminAuthProvider);
    final currentPath = GoRouterState.of(context).uri.toString();

    final menuItems = [
      _NavItem(icon: Icons.dashboard, label: '본사 대시보드', path: '/hq'),
      _NavItem(icon: Icons.store, label: '가맹점 관리', path: '/hq/stores'),
      _NavItem(icon: Icons.people, label: '계정 관리', path: '/hq/admins'),
    ];

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 260,
            color: const Color(0xFF0D1B2A),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Icon(Icons.corporate_fare,
                          size: 40, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(auth.name ?? '본사 관리자',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const Text('HQ_ADMIN',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: menuItems.map((item) {
                      final isSelected = currentPath == item.path;
                      return ListTile(
                        leading: Icon(item.icon,
                            color:
                                isSelected ? Colors.white : Colors.white60),
                        title: Text(item.label,
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white60,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                        selected: isSelected,
                        selectedTileColor: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        onTap: () => context.go(item.path),
                      );
                    }).toList(),
                  ),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.logout, color: Colors.white60),
                  title: const Text('로그아웃',
                      style: TextStyle(color: Colors.white60)),
                  onTap: () {
                    ref.read(adminAuthProvider.notifier).logout();
                    context.go('/');
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  _NavItem({required this.icon, required this.label, required this.path});
}
