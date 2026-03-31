import 'package:dio/dio.dart';
import '../models/payment.dart';
import 'api_client.dart';

class PaymentService {
  final Dio _dio = ApiClient.instance;

  Future<Payment> createPayment({
    required int storeId,
    required int orderId,
    required String method,
  }) async {
    final response = await _dio.post('/kiosk/payments',
        data: {
          'orderId': orderId,
          'method': method,
        },
        queryParameters: {'storeId': storeId});
    return Payment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Payment> cancelPayment(int paymentId, {required int storeId}) async {
    final response = await _dio.post('/kiosk/payments/$paymentId/cancel',
        queryParameters: {'storeId': storeId});
    return Payment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Payment> getPaymentStatus(int paymentId,
      {required int storeId}) async {
    final response = await _dio.get('/kiosk/payments/$paymentId/status',
        queryParameters: {'storeId': storeId});
    return Payment.fromJson(response.data as Map<String, dynamic>);
  }
}
