import 'package:dio/dio.dart';
import '../models/order.dart';
import 'api_client.dart';

class KitchenService {
  final Dio _dio = ApiClient.instance;

  Future<List<Order>> getActiveOrders({required int storeId}) async {
    final response = await _dio.get('/kitchen/orders',
        queryParameters: {'storeId': storeId});
    return (response.data as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateOrderStatus(int orderId, String status,
      {required int storeId}) async {
    await _dio.put('/kitchen/orders/$orderId/status',
        data: {'status': status},
        queryParameters: {'storeId': storeId});
  }
}
