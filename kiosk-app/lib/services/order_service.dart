import 'package:dio/dio.dart';
import '../models/order.dart';
import 'api_client.dart';

class OrderService {
  final Dio _dio = ApiClient.instance;

  Future<Order> createOrder({
    required int storeId,
    int? tableId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _dio.post('/kiosk/orders',
        data: {
          'tableId': tableId,
          'items': items,
        },
        queryParameters: {'storeId': storeId});
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Order> getOrderByNumber(String orderNumber,
      {required int storeId}) async {
    final response = await _dio.get('/kiosk/orders/$orderNumber',
        queryParameters: {'storeId': storeId});
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Order>> getOrdersByTable({
    required int storeId,
    required int tableId,
  }) async {
    final response = await _dio.get('/kiosk/orders', queryParameters: {
      'storeId': storeId,
      'tableId': tableId,
    });
    return (response.data as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
