import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/menu.dart';
import '../services/menu_service.dart';
import 'admin_auth_provider.dart';

final menuServiceProvider = Provider((ref) => MenuService());

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  final storeId = ref.read(adminAuthProvider).storeId;
  if (storeId == null) throw Exception('매장 정보가 없습니다. 로그인이 필요합니다.');
  return ref.read(menuServiceProvider).getCategories(storeId: storeId);
});

final selectedCategoryProvider = StateProvider<int?>((ref) => null);

final menusByCategoryProvider =
    FutureProvider.family<List<Menu>, int>((ref, categoryId) {
  final storeId = ref.read(adminAuthProvider).storeId;
  if (storeId == null) throw Exception('매장 정보가 없습니다. 로그인이 필요합니다.');
  return ref
      .read(menuServiceProvider)
      .getMenusByCategory(categoryId, storeId: storeId);
});

final allMenusProvider = FutureProvider<List<Menu>>((ref) async {
  final storeId = ref.read(adminAuthProvider).storeId;
  if (storeId == null) throw Exception('매장 정보가 없습니다. 로그인이 필요합니다.');
  final categories = await ref.read(menuServiceProvider).getCategories(storeId: storeId);
  final allMenus = <Menu>[];
  for (final cat in categories) {
    final menus = await ref.read(menuServiceProvider).getMenusByCategory(cat.id, storeId: storeId);
    allMenus.addAll(menus);
  }
  return allMenus;
});

final menuDetailProvider =
    FutureProvider.family<MenuDetail, int>((ref, menuId) {
  final storeId = ref.read(adminAuthProvider).storeId;
  if (storeId == null) throw Exception('매장 정보가 없습니다. 로그인이 필요합니다.');
  return ref.read(menuServiceProvider).getMenuDetail(menuId, storeId: storeId);
});
