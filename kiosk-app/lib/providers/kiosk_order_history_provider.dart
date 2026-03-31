import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../providers/admin_auth_provider.dart';
import '../providers/kiosk_table_provider.dart';
import '../providers/order_provider.dart';

final kioskOrderHistoryProvider = FutureProvider<List<Order>>((ref) async {
  final table = ref.watch(kioskSelectedTableProvider);
  final auth = ref.read(adminAuthProvider);
  if (table == null || auth.storeId == null) return [];
  final orders = await ref.read(orderServiceProvider).getOrdersByTable(
    storeId: auth.storeId!,
    tableId: table.id,
  );
  return orders.where((o) => o.status != 'PAID' && o.status != 'CANCELLED').toList();
});
