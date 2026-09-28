import 'package:go_router/go_router.dart';
import 'package:bet_tracker/main.dart';
import '../../screens/auth_page.dart';
import '../../providers/auth_providers.dart';

// ── Router ────────────────────────────────────────────────────────────────────

GoRouter createRouter(AuthProvider authProvider) => GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        if (!authProvider.isInitialized) return null;

        final isAuth = authProvider.isLoggedIn;
        final isOnAuth =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup';

        if (!isAuth && !isOnAuth) return '/login';
        if (isAuth && isOnAuth) return '/home';

        return null;
      },
      routes: [
        // ── Auth routes (no app bar — AuthPage has its own _AuthTopBar) ──
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginPage(),
        ),
        GoRoute(
          path: '/signup',
          builder: (_, __) => const SignupPage(),
        ),

        // ── App routes (AppHomePage has its own CustomAppBar + footer) ────
        GoRoute(
          path: '/home',
          builder: (_, __) => const AppHomePage(),
        ),
      ],
    );