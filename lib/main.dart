import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'core/constants/app_colors.dart';
import 'providers/auth_providers.dart';
import 'core/routing/app_router.dart'; // ← use the single router
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(titleBarStyle: TitleBarStyle.hidden);
  await windowManager.waitUntilReadyToShow(windowOptions);
  await windowManager.show();

  final authProvider = AuthProvider();           // ← create once
  final router = createRouter(authProvider);     // ← pass into router

  runApp(
    ChangeNotifierProvider.value(
      value: authProvider,                       // ← reuse same instance
      child: BetTrackerApp(router: router),
    ),
  );
}

class BetTrackerApp extends StatelessWidget {
  const BetTrackerApp({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'Bet Tracker',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        fontFamily: 'Inter',
      ),
      // Splash while token check runs
      builder: (context, child) {
        return Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (!auth.isInitialized) {
              return const Scaffold(
                backgroundColor: Color(0xFF030E1C),
                body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2563EB),
                  ),
                ),
              );
            }
            return child!;
          },
        );
      },
    );
  }
}