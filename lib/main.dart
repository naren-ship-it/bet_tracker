import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_widgets/app_bar.dart';
import 'app_widgets/app_footer.dart';
import 'core/constants/app_colors.dart';
import 'core/routing/app_router.dart';
import 'providers/auth_providers.dart';
import 'screens/home_screen.dart';
import 'screens/player_management_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/team_management_screen.dart';
import 'screens/tournament_betting_screen.dart';
import 'screens/tournament_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hide the native title bar so _AuthTopBar takes over
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    titleBarStyle: TitleBarStyle.hidden,
    title: 'Bet Tracker',
    minimumSize: Size(800, 600),
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final authProvider = AuthProvider();
  final router = createRouter(authProvider);

  runApp(
    ChangeNotifierProvider.value(
      value: authProvider,
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
        textTheme: GoogleFonts.manropeTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      builder: (context, child) {
        return Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (!auth.isInitialized) {
              return const Scaffold(
                backgroundColor: Color(0xFF030E1C),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
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

// ── Home shell (app bar + module screens + floating footer nav) ───────────────

class AppHomePage extends StatefulWidget {
  const AppHomePage({super.key});

  @override
  State<AppHomePage> createState() => _AppHomePageState();
}

class _AppHomePageState extends State<AppHomePage> {
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
        onProfileTap: () {},
        onLogoutTap: () async {
          await context.read<AuthProvider>().logout();
          if (context.mounted) {
            context.go('/login');
          }
        },
      ),
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