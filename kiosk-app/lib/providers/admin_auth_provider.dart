import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';

class AdminAuthState {
  final bool isAuthenticated;
  final bool isInitialized;
  final String? token;
  final String? username;
  final String? name;
  final String? role;
  final int? storeId;

  AdminAuthState({
    this.isAuthenticated = false,
    this.isInitialized = false,
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
  final Completer<void> _initCompleter = Completer<void>();

  Future<void> get initialized => _initCompleter.future;

  AdminAuthNotifier(this._adminService) : super(AdminAuthState()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        state = AdminAuthState(isInitialized: true);
        return;
      }

      ApiClient.setAuthToken(token);
      try {
        final me = await _adminService.getMe();
        state = AdminAuthState(
          isAuthenticated: true,
          isInitialized: true,
          token: token,
          username: me['username'] as String?,
          name: me['name'] as String?,
          role: me['role'] as String?,
          storeId: me['storeId'] as int?,
        );
      } catch (_) {
        await prefs.remove('auth_token');
        ApiClient.clearAuthToken();
        state = AdminAuthState(isInitialized: true);
      }
    } finally {
      if (!_initCompleter.isCompleted) _initCompleter.complete();
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final result = await _adminService.login(username, password);
      final token = result['token'] as String;
      ApiClient.setAuthToken(token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      state = AdminAuthState(
        isAuthenticated: true,
        isInitialized: true,
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

  Future<void> logout() async {
    ApiClient.clearAuthToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    state = AdminAuthState(isInitialized: true);
  }
}

final adminServiceProvider = Provider((ref) => AdminService());

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  return AdminAuthNotifier(ref.read(adminServiceProvider));
});
