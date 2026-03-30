import 'package:dio/dio.dart';
import '../models/category.dart';
import '../models/menu.dart';
import 'api_client.dart';

class MenuService {
  final Dio _dio = ApiClient.instance;

  Future<List<Category>> getCategories({required int storeId}) async {
    final response = await _dio.get('/kiosk/categories',
        queryParameters: {'storeId': storeId});
    return (response.data as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Menu>> getMenusByCategory(int categoryId,
      {required int storeId}) async {
    final response = await _dio.get('/kiosk/categories/$categoryId/menus',
        queryParameters: {'storeId': storeId});
    return (response.data as List)
        .map((e) => Menu.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MenuDetail> getMenuDetail(int menuId, {required int storeId}) async {
    final response = await _dio.get('/kiosk/menus/$menuId',
        queryParameters: {'storeId': storeId});
    return MenuDetail.fromJson(response.data as Map<String, dynamic>);
  }
}
