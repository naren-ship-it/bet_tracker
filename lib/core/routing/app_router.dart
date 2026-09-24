import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../features/auth/screens/auth_page.dart';
import '../../providers/auth_providers.dart';
import '../../core/constants/app_colors.dart';

// ── Shell (title bar on every screen) ────────────────────────────────────────

class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const _AppTitleBar(),
      body: child,
    );
  }
}

// ── Title bar ─────────────────────────────────────────────────────────────────

class _AppTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppTitleBar();

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context) {
    return DragToMoveArea(
      child: Container(
        height: 40,
        color: AppColors.surface,
        child: Row(
          children: [
            const Spacer(),
            _TitleBarButton(
              icon: Icons.remove,
              onPressed: () => windowManager.minimize(),
            ),
            _TitleBarButton(
              icon: Icons.crop_square,
              onPressed: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
            ),
            _TitleBarButton(
              icon: Icons.close,
              isClose: true,
              onPressed: () => windowManager.close(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBarButton extends StatefulWidget {
  const _TitleBarButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  @override
  State<_TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<_TitleBarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 46,
          height: 40,
          color: _hovered
              ? (widget.isClose
                  ? const Color(0xFFC42B1C)
                  : Colors.white.withOpacity(0.1))
              : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 16,
            color: _hovered && widget.isClose
                ? Colors.white
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ── Home screen ───────────────────────────────────────────────────────────────

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Authentication successful',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 20),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            icon: const Icon(Icons.logout, color: AppColors.textPrimary),
            label: const Text(
              'Logout',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

// ── Router ────────────────────────────────────────────────────────────────────

GoRouter createRouter(AuthProvider authProvider) => GoRouter(
  initialLocation: '/login',
  refreshListenable: authProvider,
  redirect: (context, state) {
    if (!authProvider.isInitialized) return null;

    final isAuth = authProvider.isLoggedIn;
    final isOnAuth = state.matchedLocation == '/login' ||
                     state.matchedLocation == '/signup';

    if (!isAuth && !isOnAuth) return '/login';
    if (isAuth && isOnAuth) return '/home';

    return null;
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(path: '/login',  builder: (_, __) => const LoginPage()),
        GoRoute(path: '/signup', builder: (_, __) => const SignupPage()),
        GoRoute(path: '/home',   builder: (_, __) => const HomePage()),
      ],
    ),
  ],
);