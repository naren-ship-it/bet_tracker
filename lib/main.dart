import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'providers/auth_providers.dart';
import 'screens/auth_page.dart';
import 'app_widgets/app_bar.dart';
import 'app_widgets/app_footer.dart';

import 'screens/home_screen.dart';
import 'screens/tournament_management_screen.dart';
import 'screens/team_management_screen.dart';
import 'screens/player_management_screen.dart';
import 'screens/tournament_betting_screen.dart';
import 'screens/settings_screen.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(960, 600),
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

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
    return MaterialApp.router(
      routerConfig: _router,
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

// ── Home shell (app bar + module screens + floating footer nav) ────────────────

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  AppModule _currentModule = AppModule.home;

  static const _moduleOrder = [
    AppModule.home,
    AppModule.tournamentManagement,
    AppModule.teamManagement,
    AppModule.playerManagement,
    AppModule.tournamentBetting,
    AppModule.settings,
  ];

  static const _screens = [
    HomeScreen(),
    TournamentManagementScreen(),
    TeamManagementScreen(),
    PlayerManagementScreen(),
    TournamentBettingScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _moduleOrder.indexOf(_currentModule);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        onProfileTap: () {
          // TODO: navigate to profile view
        },
        onLogoutTap: () async {
          await context.read<AuthProvider>().logout();
          if (context.mounted) context.go('/login');
        },
      ),
      // No bottomNavigationBar — CustomAppFooter floats itself via Stack below.
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: currentIndex,
              children: _screens,
            ),
          ),
          CustomAppFooter(
            currentModule: _currentModule,
            onModuleSelected: (module) {
              setState(() => _currentModule = module);
            },
          ),
        ],
      ),
    );
  }
}