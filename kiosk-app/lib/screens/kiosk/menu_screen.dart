import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/cart_item.dart';
import '../../models/category.dart';
import '../../models/menu.dart';
import '../../providers/menu_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kiosk/menu_card.dart';
import '../../widgets/kiosk/category_tab.dart';
import '../../widgets/kiosk/option_selector.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final cartCount = ref.watch(cartCountProvider);
    final cartTotal = ref.watch(cartTotalProvider);

    return Scaffold(
      body: Column(
        children: [
          // 상단 헤더
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingLarge,
                vertical: AppTheme.paddingMedium),
            color: AppColors.surface,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 28),
                  onPressed: () => context.go('/admin/kiosk'),
                ),
                const SizedBox(width: 8),
                Text('메뉴 선택',
                    style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.go('/admin/kiosk/orders'),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('주문내역',
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),

          // 카테고리 탭
          categoriesAsync.when(
            data: (categories) {
              if (categories.isNotEmpty &&
                  selectedCategory == null) {
                Future.microtask(() {
                  ref.read(selectedCategoryProvider.notifier).state = -1;
                });
              }
              final allCategories = [
                Category(id: -1, name: '전체'),
                ...categories,
              ];
              return CategoryTabBar(
                categories: allCategories,
                selectedId: selectedCategory,
                onSelected: (id) {
                  ref.read(selectedCategoryProvider.notifier).state = id;
                },
              );
            },
            loading: () =>
                const SizedBox(height: 56, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SizedBox(
                height: 56,
                child: Center(child: Text('카테고리 로드 실패: $e'))),
          ),

          // 메뉴 그리드
          Expanded(
            child: selectedCategory == null
                ? const Center(child: Text('카테고리를 선택하세요'))
                : selectedCategory == -1
                    ? const _AllMenuGrid()
                    : _MenuGrid(categoryId: selectedCategory),
          ),

          // 하단 장바구니 바
          if (cartCount > 0)
            GestureDetector(
              onTap: () => context.go('/admin/kiosk/cart'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingLarge,
                    vertical: AppTheme.paddingMedium),
                color: AppColors.primary,
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_cart,
                              color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            '$cartCount개 담김',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        '${_formatPrice(cartTotal)}원',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

class _MenuGrid extends ConsumerWidget {
  final int categoryId;
  const _MenuGrid({required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menusAsync = ref.watch(menusByCategoryProvider(categoryId));

    return menusAsync.when(
      data: (menus) {
        if (menus.isEmpty) {
          return const Center(
              child: Text('등록된 메뉴가 없습니다',
                  style: TextStyle(fontSize: 18, color: AppColors.textSecondary)));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: menus.length,
          itemBuilder: (context, index) {
            final menu = menus[index];
            return MenuCard(
              menu: menu,
              onTap: menu.isSoldOut
                  ? null
                  : () => _showOptionSheet(context, ref, menu),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('메뉴 로드 실패: $e')),
    );
  }

  void _showOptionSheet(BuildContext context, WidgetRef ref, Menu menu) async {
    try {
      final detail = await ref.read(menuDetailProvider(menu.id).future);
      if (!context.mounted) return;

      if (detail.options.isEmpty) {
        ref.read(cartProvider.notifier).addItem(CartItem(
              menuId: menu.id,
              menuName: menu.name,
              unitPrice: menu.price,
            ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${menu.name} 추가됨'),
              duration: const Duration(seconds: 1)),
        );
      } else {
        _showOptionsDialog(context, ref, detail);
      }
    } catch (_) {
      if (!context.mounted) return;
      ref.read(cartProvider.notifier).addItem(CartItem(
            menuId: menu.id,
            menuName: menu.name,
            unitPrice: menu.price,
          ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${menu.name} 추가됨'),
            duration: const Duration(seconds: 1)),
      );
    }
  }

  void _showOptionsDialog(
      BuildContext context, WidgetRef ref, MenuDetail detail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => OptionSelector(
        menuDetail: detail,
        onConfirm: (cartItem) {
          ref.read(cartProvider.notifier).addItem(cartItem);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${detail.name} 추가됨'),
                duration: const Duration(seconds: 1)),
          );
        },
      ),
    );
  }
}

class _AllMenuGrid extends ConsumerWidget {
  const _AllMenuGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMenusAsync = ref.watch(allMenusProvider);

    return allMenusAsync.when(
      data: (menus) {
        if (menus.isEmpty) {
          return const Center(
              child: Text('등록된 메뉴가 없습니다',
                  style: TextStyle(fontSize: 18, color: AppColors.textSecondary)));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: menus.length,
          itemBuilder: (context, index) {
            final menu = menus[index];
            return MenuCard(
              menu: menu,
              onTap: menu.isSoldOut
                  ? null
                  : () => _showOptionSheet(context, ref, menu),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('메뉴 로드 실패: $e')),
    );
  }

  void _showOptionSheet(BuildContext context, WidgetRef ref, Menu menu) async {
    try {
      final detail = await ref.read(menuDetailProvider(menu.id).future);
      if (!context.mounted) return;

      if (detail.options.isEmpty) {
        ref.read(cartProvider.notifier).addItem(CartItem(
              menuId: menu.id,
              menuName: menu.name,
              unitPrice: menu.price,
            ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${menu.name} 추가됨'),
              duration: const Duration(seconds: 1)),
        );
      } else {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) => OptionSelector(
            menuDetail: detail,
            onConfirm: (cartItem) {
              ref.read(cartProvider.notifier).addItem(cartItem);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${detail.name} 추가됨'),
                    duration: const Duration(seconds: 1)),
              );
            },
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ref.read(cartProvider.notifier).addItem(CartItem(
            menuId: menu.id,
            menuName: menu.name,
            unitPrice: menu.price,
          ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${menu.name} 추가됨'),
            duration: const Duration(seconds: 1)),
      );
    }
  }
}
