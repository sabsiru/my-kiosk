import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category.dart';
import '../../models/menu.dart';
import '../../providers/admin_auth_provider.dart';
import '../../theme/app_colors.dart';

final _categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.read(adminServiceProvider).getCategories();
});

final _menusByCategoryProvider =
    FutureProvider.family<List<Menu>, int>((ref, categoryId) {
  return ref.read(adminServiceProvider).getMenusByCategory(categoryId);
});

class MenuManageScreen extends ConsumerStatefulWidget {
  const MenuManageScreen({super.key});

  @override
  ConsumerState<MenuManageScreen> createState() => _MenuManageScreenState();
}

class _MenuManageScreenState extends ConsumerState<MenuManageScreen> {
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(_categoriesProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('메뉴 관리',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showCategoryDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('카테고리 추가'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.adminAccent),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selectedCategoryId == null
                        ? null
                        : () => _showMenuDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('메뉴 추가'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.adminPrimary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 카테고리 탭
          categoriesAsync.when(
            data: (categories) {
              if (categories.isNotEmpty && _selectedCategoryId == null) {
                Future.microtask(
                    () => setState(() => _selectedCategoryId = categories.first.id));
              }
              return SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final selected = cat.id == _selectedCategoryId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onLongPress: () => _showCategoryActionDialog(cat),
                        child: ChoiceChip(
                          label: Text(cat.name),
                          selected: selected,
                          selectedColor: AppColors.adminPrimary,
                          labelStyle: TextStyle(
                              color: selected ? Colors.white : AppColors.textPrimary),
                          onSelected: (_) =>
                              setState(() => _selectedCategoryId = cat.id),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('카테고리 로드 실패: $e'),
          ),
          const SizedBox(height: 16),
          // 메뉴 목록
          Expanded(
            child: _selectedCategoryId == null
                ? const Center(child: Text('카테고리를 선택하세요'))
                : _buildMenuList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    final menusAsync = ref.watch(_menusByCategoryProvider(_selectedCategoryId!));
    return menusAsync.when(
      data: (menus) {
        if (menus.isEmpty) {
          return const Center(
              child: Text('등록된 메뉴가 없습니다',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary)));
        }
        return ListView.builder(
          itemCount: menus.length,
          itemBuilder: (context, index) {
            final menu = menus[index];
            return Card(
              child: ListTile(
                leading: menu.isSoldOut
                    ? const Icon(Icons.block, color: AppColors.error)
                    : const Icon(Icons.fastfood, color: AppColors.primary),
                title: Text(menu.name,
                    style: TextStyle(
                        decoration: menu.isSoldOut
                            ? TextDecoration.lineThrough
                            : null)),
                subtitle: Text('${_formatPrice(menu.price)}원'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _toggleSoldOut(menu.id),
                      child: Text(menu.isSoldOut ? '품절 해제' : '품절 처리',
                          style: TextStyle(
                              color: menu.isSoldOut
                                  ? AppColors.success
                                  : AppColors.error)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.adminAccent),
                      onPressed: () => _showMenuDialog(menu: menu),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: () => _deleteMenu(menu.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('메뉴 로드 실패: $e')),
    );
  }

  void _showCategoryActionDialog(Category category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(category.name),
        content: const Text('작업을 선택하세요'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showCategoryDialog(category: category);
            },
            child: const Text('수정'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('카테고리 삭제'),
                  content: Text('\'${category.name}\' 카테고리를 삭제하시겠습니까?\n해당 카테고리의 메뉴도 확인해주세요.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(c, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  await ref.read(adminServiceProvider).deleteCategory(category.id);
                  if (_selectedCategoryId == category.id) {
                    setState(() => _selectedCategoryId = null);
                  }
                  ref.invalidate(_categoriesProvider);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
                  }
                }
              }
            },
            child: const Text('삭제', style: TextStyle(color: AppColors.error)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategoryDialog({Category? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final orderController =
        TextEditingController(text: '${category?.displayOrder ?? 0}');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? '카테고리 추가' : '카테고리 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: '카테고리명', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: orderController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: '표시 순서', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminPrimary),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final service = ref.read(adminServiceProvider);
        if (category == null) {
          await service.createCategory(
              nameController.text, int.tryParse(orderController.text) ?? 0);
        } else {
          await service.updateCategory(category.id, nameController.text,
              int.tryParse(orderController.text) ?? 0);
        }
        ref.invalidate(_categoriesProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }

  Future<void> _showMenuDialog({Menu? menu}) async {
    final nameController = TextEditingController(text: menu?.name ?? '');
    final descController = TextEditingController(text: menu?.description ?? '');
    final priceController =
        TextEditingController(text: menu != null ? '${menu.price}' : '');
    String? imageUrl = menu?.imageUrl;
    Uint8List? imageBytes;
    String? imageFileName;
    bool isUploading = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(menu == null ? '메뉴 추가' : '메뉴 수정'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                        labelText: '메뉴명', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                        labelText: '설명', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: '가격', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  // 이미지 업로드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        if (imageBytes != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(imageBytes!,
                                height: 120, fit: BoxFit.cover),
                          )
                        else if (imageUrl != null && imageUrl!.isNotEmpty)
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(imageUrl!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isUploading
                                    ? null
                                    : () async {
                                        final result =
                                            await FilePicker.platform.pickFiles(
                                          type: FileType.image,
                                          withData: true,
                                        );
                                        if (result != null &&
                                            result.files.single.bytes != null) {
                                          setState(() {
                                            imageBytes =
                                                result.files.single.bytes;
                                            imageFileName =
                                                result.files.single.name;
                                          });
                                        }
                                      },
                                icon: const Icon(Icons.image),
                                label: const Text('이미지 선택'),
                              ),
                            ),
                            if (imageBytes != null) ...[
                              const SizedBox(width: 8),
                              isUploading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : IconButton(
                                      onPressed: () async {
                                        setState(() => isUploading = true);
                                        try {
                                          final url = await ref
                                              .read(adminServiceProvider)
                                              .uploadImage(imageBytes!,
                                                  imageFileName ?? 'image.jpg');
                                          setState(() {
                                            imageUrl = url;
                                            isUploading = false;
                                          });
                                        } catch (e) {
                                          setState(() => isUploading = false);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        '업로드 실패: $e')));
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.cloud_upload,
                                          color: AppColors.adminAccent),
                                    ),
                            ],
                          ],
                        ),
                        if (imageUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('업로드됨',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.success)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('취소')),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminPrimary),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        // 이미지가 선택됐지만 아직 업로드 안 된 경우 자동 업로드
        if (imageBytes != null && (imageUrl == null || imageUrl == menu?.imageUrl)) {
          imageUrl = await ref
              .read(adminServiceProvider)
              .uploadImage(imageBytes!, imageFileName ?? 'image.jpg');
        }

        final service = ref.read(adminServiceProvider);
        final data = {
          'categoryId': _selectedCategoryId,
          'name': nameController.text,
          'description': descController.text,
          'price': int.tryParse(priceController.text) ?? 0,
          'imageUrl': imageUrl,
        };
        if (menu == null) {
          await service.createMenu(data);
        } else {
          await service.updateMenu(menu.id, data);
        }
        ref.invalidate(_menusByCategoryProvider(_selectedCategoryId!));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }

  Future<void> _toggleSoldOut(int menuId) async {
    try {
      await ref.read(adminServiceProvider).toggleSoldOut(menuId);
      ref.invalidate(_menusByCategoryProvider(_selectedCategoryId!));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    }
  }

  Future<void> _deleteMenu(int menuId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메뉴 삭제'),
        content: const Text('정말 삭제하시겠습니까?'),
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
        await ref.read(adminServiceProvider).deleteMenu(menuId);
        ref.invalidate(_menusByCategoryProvider(_selectedCategoryId!));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
