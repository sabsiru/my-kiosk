import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static const String _baseUrl = 'ws://localhost:8081';

  WebSocketChannel? _syncChannel;
  WebSocketChannel? _kitchenChannel;
  WebSocketChannel? _orderStatusChannel;

  final _syncController = StreamController<Map<String, dynamic>>.broadcast();
  final _kitchenController = StreamController<Map<String, dynamic>>.broadcast();
  final _orderStatusController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get syncStream => _syncController.stream;
  Stream<Map<String, dynamic>> get kitchenStream => _kitchenController.stream;
  Stream<Map<String, dynamic>> get orderStatusStream =>
      _orderStatusController.stream;

  void connectSync() {
    _syncChannel?.sink.close();
    _syncChannel = WebSocketChannel.connect(Uri.parse('$_baseUrl/ws/sync'));
    _syncChannel!.stream.listen(
      (data) {
        final decoded = jsonDecode(data as String) as Map<String, dynamic>;
        _syncController.add(decoded);
      },
      onDone: () => _reconnect('sync'),
      onError: (_) => _reconnect('sync'),
    );
  }

  void connectKitchen() {
    _kitchenChannel?.sink.close();
    _kitchenChannel =
        WebSocketChannel.connect(Uri.parse('$_baseUrl/ws/kitchen'));
    _kitchenChannel!.stream.listen(
      (data) {
        final decoded = jsonDecode(data as String) as Map<String, dynamic>;
        _kitchenController.add(decoded);
      },
      onDone: () => _reconnect('kitchen'),
      onError: (_) => _reconnect('kitchen'),
    );
  }

  void connectOrderStatus() {
    _orderStatusChannel?.sink.close();
    _orderStatusChannel =
        WebSocketChannel.connect(Uri.parse('$_baseUrl/ws/order-status'));
    _orderStatusChannel!.stream.listen(
      (data) {
        final decoded = jsonDecode(data as String) as Map<String, dynamic>;
        _orderStatusController.add(decoded);
      },
      onDone: () => _reconnect('order-status'),
      onError: (_) => _reconnect('order-status'),
    );
  }

  void _reconnect(String type) {
    Future.delayed(const Duration(seconds: 3), () {
      switch (type) {
        case 'sync':
          connectSync();
          break;
        case 'kitchen':
          connectKitchen();
          break;
        case 'order-status':
          connectOrderStatus();
          break;
      }
    });
  }

  void dispose() {
    _syncChannel?.sink.close();
    _kitchenChannel?.sink.close();
    _orderStatusChannel?.sink.close();
    _syncController.close();
    _kitchenController.close();
    _orderStatusController.close();
  }
}
