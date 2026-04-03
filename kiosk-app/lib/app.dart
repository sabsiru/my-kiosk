import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/admin_auth_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class KioskApp extends ConsumerStatefulWidget {
  const KioskApp({super.key});

  @override
  ConsumerState<KioskApp> createState() => _KioskAppState();
}

class _KioskAppState extends ConsumerState<KioskApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(ref);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(adminAuthProvider);

    if (!auth.isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.kioskTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp.router(
      title: '키오스크',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.kioskTheme,
      routerConfig: _router,
    );
  }
}
