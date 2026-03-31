import 'package:flutter/material.dart';
import '../../models/menu.dart';
import '../../theme/app_colors.dart';

class MenuCard extends StatelessWidget {
  final Menu menu;
  final VoidCallback? onTap;

  const MenuCard({super.key, required this.menu, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 이미지 영역
                Expanded(
                  flex: 3,
                  child: Container(
                    color: AppColors.background,
                    child: menu.imageUrl != null
                        ? Image.network(menu.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _placeholderIcon())
                        : _placeholderIcon(),
                  ),
                ),
                // 이름 + 가격
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          menu.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatPrice(menu.price)}원',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // 품절 오버레이
            if (menu.isSoldOut)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.7),
                  child: const Center(
                    child: Text(
                      '품절',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.soldOut),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return const Center(
      child: Icon(Icons.fastfood, size: 48, color: AppColors.textLight),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
