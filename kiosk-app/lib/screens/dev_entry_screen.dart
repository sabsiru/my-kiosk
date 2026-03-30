import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DevEntryScreen extends StatelessWidget {
  const DevEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'KIOSK DEV',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '진입점을 선택하세요',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _EntryCard(
                  icon: Icons.business,
                  label: '본사 관리',
                  sublabel: 'HQ Admin',
                  color: const Color(0xFF6C63FF),
                  onTap: () => context.go('/hq/login'),
                ),
                const SizedBox(width: 24),
                _EntryCard(
                  icon: Icons.store,
                  label: '가맹점 관리',
                  sublabel: 'Store Admin',
                  color: const Color(0xFF00BFA6),
                  onTap: () => context.go('/admin/login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _EntryCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
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
          width: 180,
          height: 200,
          decoration: BoxDecoration(
            color: _hovering
                ? widget.color.withOpacity( 0.15)
                : const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovering
                  ? widget.color
                  : Colors.white.withOpacity( 0.1),
              width: _hovering ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 48, color: widget.color),
              const SizedBox(height: 16),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.sublabel,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
