import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'providers/auth_providers.dart';
import 'features/auth/screens/auth_page.dart';
// Source - https://stackoverflow.com/a/71355167
// Posted by slatieee, modified by community. See post 'Timeline' for change history
// Retrieved 2026-09-23, License - CC BY-SA 4.0

import 'package:window_manager/window_manager.dart';


// ── Router ────────────────────────────────────────────────────────────────────

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const _HomePage(),
    ),
  ],
);

// ── Entry point ───────────────────────────────────────────────────────────────

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WindowManager.instance.ensureInitialized();
  WindowManager.instance.setTitleBarStyle(TitleBarStyle.hidden);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const BetTrackerApp(),
    ),
  );
}

// ── Root app ──────────────────────────────────────────────────────────────────

class BetTrackerApp extends StatelessWidget {
  const BetTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(          // ← MaterialApp.router, not MaterialApp
      routerConfig: _router,            // ← plug in GoRouter here
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
    );
  }
}

// ── Temporary home screen (replace with your real one) ────────────────────────

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Bet Tracker',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textPrimary),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Authentication successful',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 20),
        ),
      ),
    );
  }
}