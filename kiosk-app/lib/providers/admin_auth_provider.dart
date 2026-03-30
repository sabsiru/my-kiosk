import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';

class AdminAuthState {
  final bool isAuthenticated;
  final String? token;
  final String? username;
  final String? name;
  final String? role;
  final int? storeId;

  AdminAuthState({
    this.isAuthenticated = false,
    this.token,
    this.username,
    this.name,
    this.role,
    this.storeId,
  });

  bool get isHqAdmin => role == 'HQ_ADMIN';
  bool get isStoreOwner => role == 'STORE_OWNER';
  bool get isStoreManager => role == 'STORE_MANAGER';
}

class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  final AdminService _adminService;

  AdminAuthNotifier(this._adminService) : super(AdminAuthState());

  Future<bool> login(String username, String password) async {
    try {
      final result = await _adminService.login(username, password);
      final token = result['token'] as String;
      ApiClient.setAuthToken(token);
      state = AdminAuthState(
        isAuthenticated: true,
        token: token,
        username: username,
        name: result['name'] as String?,
        role: result['role'] as String?,
        storeId: result['storeId'] as int?,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    ApiClient.clearAuthToken();
    state = AdminAuthState();
  }
}

final adminServiceProvider = Provider((ref) => AdminService());

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  return AdminAuthNotifier(ref.read(adminServiceProvider));
});
