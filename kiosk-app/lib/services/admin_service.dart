import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/category.dart';
import '../models/menu.dart';
import '../models/order.dart';
import '../models/table.dart';
import '../models/settlement.dart';
import '../models/statistics.dart';
import '../models/store.dart';
import 'api_client.dart';

class AdminService {
  final Dio _dio = ApiClient.instance;

  // 인증
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _dio.post('/admin/login', data: {
      'username': username,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/admin/me');
    return response.data as Map<String, dynamic>;
  }

  // 카테고리/메뉴 조회 (키오스크 API 재사용)
  Future<List<Category>> getCategories() async {
    final response = await _dio.get('/admin/categories');
    return (response.data as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Menu>> getMenusByCategory(int categoryId) async {
    final response = await _dio.get('/admin/categories/$categoryId/menus');
    return (response.data as List)
        .map((e) => Menu.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // 카테고리 관리
  Future<Category> createCategory(String name, int displayOrder) async {
    final response = await _dio.post('/admin/categories', data: {
      'name': name,
      'displayOrder': displayOrder,
    });
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Category> updateCategory(int id, String name, int displayOrder) async {
    final response = await _dio.put('/admin/categories/$id', data: {
      'name': name,
      'displayOrder': displayOrder,
    });
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int id) async {
    await _dio.delete('/admin/categories/$id');
  }

  // 메뉴
  Future<Menu> createMenu(Map<String, dynamic> data) async {
    final response = await _dio.post('/admin/menus', data: data);
    return Menu.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Menu> updateMenu(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/admin/menus/$id', data: data);
    return Menu.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteMenu(int id) async {
    await _dio.delete('/admin/menus/$id');
  }

  Future<Map<String, dynamic>> toggleSoldOut(int id) async {
    final response = await _dio.put('/admin/menus/$id/sold-out');
    return response.data as Map<String, dynamic>;
  }

  // 주문
  Future<List<Order>> getOrders({
    String? status,
    String? from,
    String? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{'limit': limit, 'offset': offset};
    if (status != null) params['status'] = status;
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;

    final response =
        await _dio.get('/admin/orders', queryParameters: params);
    return (response.data as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateOrderStatus(int id, String status) async {
    await _dio.put('/admin/orders/$id/status', data: {'status': status});
  }

  Future<void> cancelOrder(int id) async {
    await _dio.put('/admin/orders/$id/cancel');
  }

  // 테이블
  Future<List<KioskTable>> getTables() async {
    final response = await _dio.get('/admin/tables');
    return (response.data as List)
        .map((e) => KioskTable.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KioskTable> createTable(int tableNumber, String? deviceId) async {
    final response = await _dio.post('/admin/tables', data: {
      'tableNumber': tableNumber,
      'deviceId': deviceId,
    });
    return KioskTable.fromJson(response.data as Map<String, dynamic>);
  }

  Future<KioskTable> updateTable(int id, int tableNumber, String? deviceId) async {
    final response = await _dio.put('/admin/tables/$id', data: {
      'tableNumber': tableNumber,
      'deviceId': deviceId,
    });
    return KioskTable.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTable(int id) async {
    await _dio.delete('/admin/tables/$id');
  }

  // 정산
  Future<Settlement> getDailySettlement(String date) async {
    final response = await _dio
        .get('/admin/settlements/daily', queryParameters: {'date': date});
    return Settlement.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Settlement>> getPeriodSettlement(String from, String to) async {
    final response = await _dio.get('/admin/settlements/period',
        queryParameters: {'from': from, 'to': to});
    return (response.data as List)
        .map((e) => Settlement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, int>> getByPaymentMethod(String from, String to) async {
    final response = await _dio.get('/admin/settlements/by-payment-method',
        queryParameters: {'from': from, 'to': to});
    return (response.data as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as int));
  }

  Future<void> closeSettlement(String date) async {
    await _dio
        .post('/admin/settlements/close', queryParameters: {'date': date});
  }

  // 통계
  Future<List<MenuSales>> getMenuSales(String from, String to) async {
    final response = await _dio.get('/admin/statistics/menu-sales',
        queryParameters: {'from': from, 'to': to});
    return (response.data as List)
        .map((e) => MenuSales.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RevenueStat>> getRevenueTrend(String from, String to) async {
    final response = await _dio.get('/admin/statistics/revenue',
        queryParameters: {'from': from, 'to': to});
    return (response.data as List)
        .map((e) => RevenueStat.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<HourlyStat>> getHourlyStats(String date) async {
    final response = await _dio
        .get('/admin/statistics/hourly', queryParameters: {'date': date});
    return (response.data as List)
        .map((e) => HourlyStat.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CategorySales>> getCategorySales(String from, String to) async {
    final response = await _dio.get('/admin/statistics/category-sales',
        queryParameters: {'from': from, 'to': to});
    return (response.data as List)
        .map((e) => CategorySales.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // === 본사 API ===

  Future<List<Map<String, dynamic>>> getHqStores() async {
    final response = await _dio.get('/hq/stores');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createHqStore(String name, String code) async {
    final response = await _dio.post('/hq/stores', data: {
      'name': name,
      'code': code,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateHqStore(
      int id, String name, String code, String status) async {
    final response = await _dio.put('/hq/stores/$id', data: {
      'name': name,
      'code': code,
      'status': status,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteHqStore(int id) async {
    await _dio.delete('/hq/stores/$id');
  }

  Future<List<Map<String, dynamic>>> getHqStatisticsSummary({String? date}) async {
    final params = <String, dynamic>{};
    if (date != null) params['date'] = date;
    final response = await _dio.get('/hq/statistics/summary', queryParameters: params);
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // === 본사 관리자 계정 관리 ===

  Future<List<Map<String, dynamic>>> getHqAdmins({int? storeId}) async {
    final params = <String, dynamic>{};
    if (storeId != null) params['storeId'] = storeId;
    final response = await _dio.get('/hq/admins', queryParameters: params);
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createHqAdmin({
    required String username,
    required String password,
    required String name,
    required String role,
    int? storeId,
  }) async {
    final response = await _dio.post('/hq/admins', data: {
      'username': username,
      'password': password,
      'name': name,
      'role': role,
      'storeId': storeId,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateHqAdmin(int id, {
    required String name,
    required String role,
    int? storeId,
    String? password,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'role': role,
      'storeId': storeId,
    };
    if (password != null && password.isNotEmpty) data['password'] = password;
    final response = await _dio.put('/hq/admins/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteHqAdmin(int id) async {
    await _dio.delete('/hq/admins/$id');
  }

  // 매장 설정
  Future<Store> getStore() async {
    final response = await _dio.get('/admin/store');
    return Store.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Store> updateStore(Map<String, dynamic> data) async {
    final response = await _dio.put('/admin/store', data: data);
    return Store.fromJson(response.data as Map<String, dynamic>);
  }

  // 영업 시작/종료
  Future<Store> openStore() async {
    final response = await _dio.post('/admin/store/open');
    return Store.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Store> closeStore() async {
    final response = await _dio.post('/admin/store/close');
    return Store.fromJson(response.data as Map<String, dynamic>);
  }

  // 테이블 결제
  Future<Map<String, dynamic>> checkoutTable(int tableId, String method) async {
    final response = await _dio.post('/admin/tables/$tableId/checkout', data: {
      'method': method,
    });
    return response.data as Map<String, dynamic>;
  }

  // 테이블별 주문 조회
  Future<List<Order>> getOrdersByTable(int tableId) async {
    final response = await _dio.get('/admin/orders', queryParameters: {
      'tableId': tableId,
    });
    return (response.data as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // 이미지 업로드
  Future<String> uploadImage(Uint8List bytes, String filename) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _dio.post('/admin/upload/image', data: formData);
    return response.data['url'] as String;
  }
}
