import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_auth_provider.dart';
import '../screens/dev_entry_screen.dart';
import '../screens/kiosk/home_screen.dart';
import '../screens/kiosk/menu_screen.dart';
import '../screens/kiosk/cart_screen.dart';
import '../screens/kiosk/payment_screen.dart';
import '../screens/kiosk/complete_screen.dart';
import '../screens/kiosk/order_history_screen.dart';
import '../screens/admin/login_screen.dart';
import '../screens/admin/mode_select_screen.dart';
import '../screens/admin/dashboard_screen.dart';
import '../screens/admin/menu_manage_screen.dart';
import '../screens/admin/order_manage_screen.dart';
import '../screens/admin/table_manage_screen.dart';
import '../screens/admin/settlement_screen.dart';
import '../screens/admin/statistics_screen.dart';
import '../screens/admin/store_settings_screen.dart';
import '../screens/admin/operation_screen.dart';
import '../screens/kiosk/table_select_screen.dart';
import '../screens/hq/hq_login_screen.dart';
import '../screens/hq/hq_dashboard_screen.dart';
import '../screens/hq/hq_home_content.dart';
import '../screens/hq/hq_store_list_screen.dart';
import '../screens/hq/hq_admin_manage_screen.dart';
import '../screens/kitchen/kitchen_display_screen.dart';

GoRouter createAppRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final auth = ref.read(adminAuthProvider);
      final path = state.uri.toString();

      // /admin/* 경로는 로그인 필요 (login 제외)
      if (path.startsWith('/admin') && path != '/admin/login') {
        if (!auth.isAuthenticated) {
          return '/admin/login';
        }
      }

      // /hq/* 경로는 HQ 로그인 필요 (login 제외)
      if (path.startsWith('/hq') && path != '/hq/login') {
        if (!auth.isAuthenticated || !auth.isHqAdmin) {
          return '/hq/login';
        }
      }

      return null;
    },
    routes: [
      // 개발용 진입점 (본사 관리 / 가맹점 관리)
      GoRoute(path: '/', builder: (_, __) => const DevEntryScreen()),

      // 가맹점 관리자 로그인
      GoRoute(
          path: '/admin/login',
          builder: (_, __) => const AdminLoginScreen()),

      // 모드 선택 (로그인 후)
      GoRoute(
          path: '/admin/mode',
          builder: (_, __) => const ModeSelectScreen()),

      // 키오스크 모드 (로그인 후 접근)
      GoRoute(
          path: '/admin/kiosk/table-select',
          builder: (_, __) => const TableSelectScreen()),
      GoRoute(path: '/admin/kiosk', builder: (_, __) => const HomeScreen()),
      GoRoute(
          path: '/admin/kiosk/menu', builder: (_, __) => const MenuScreen()),
      GoRoute(
          path: '/admin/kiosk/cart', builder: (_, __) => const CartScreen()),
      GoRoute(
          path: '/admin/kiosk/orders',
          builder: (_, __) => const OrderHistoryScreen()),
      GoRoute(
          path: '/admin/kiosk/payment',
          builder: (_, __) => const PaymentScreen()),
      GoRoute(
          path: '/admin/kiosk/complete',
          builder: (_, __) => const CompleteScreen()),

      // 주방 디스플레이 모드 (로그인 후 접근)
      GoRoute(
          path: '/admin/kitchen',
          builder: (_, __) => const KitchenDisplayScreen()),

      // 매장 관리자 화면 (쉘 라우트로 사이드바 공유)
      ShellRoute(
        builder: (context, state, child) =>
            AdminDashboardScreen(child: child),
        routes: [
          GoRoute(
              path: '/admin/manage',
              builder: (_, __) => const DashboardHomeContent()),
          GoRoute(
              path: '/admin/manage/operation',
              builder: (_, __) => const OperationScreen()),
          GoRoute(
              path: '/admin/manage/menus',
              builder: (_, __) => const MenuManageScreen()),
          GoRoute(
              path: '/admin/manage/orders',
              builder: (_, __) => const OrderManageScreen()),
          GoRoute(
              path: '/admin/manage/tables',
              builder: (_, __) => const TableManageScreen()),
          GoRoute(
              path: '/admin/manage/settlements',
              builder: (_, __) => const SettlementScreen()),
          GoRoute(
              path: '/admin/manage/statistics',
              builder: (_, __) => const StatisticsScreen()),
          GoRoute(
              path: '/admin/manage/store',
              builder: (_, __) => const StoreSettingsScreen()),
        ],
      ),

      // 본사 로그인
      GoRoute(
          path: '/hq/login',
          builder: (_, __) => const HqLoginScreen()),

      // 본사 관리자 화면
      ShellRoute(
        builder: (context, state, child) =>
            HqDashboardScreen(child: child),
        routes: [
          GoRoute(
              path: '/hq',
              builder: (_, __) => const HqHomeContent()),
          GoRoute(
              path: '/hq/stores',
              builder: (_, __) => const HqStoreListScreen()),
          GoRoute(
              path: '/hq/admins',
              builder: (_, __) => const HqAdminManageScreen()),
        ],
      ),
    ],
  );
}
