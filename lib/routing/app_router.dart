import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/cubit/auth_cubit.dart';
import '../features/auth/cubit/auth_state.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/journal/journal_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/onboarding/cubit/onboarding_cubit.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/scan/scan_screen.dart';
import '../theme/breakpoints.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'route_paths.dart';
import 'router_refresh_stream.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static GoRouter build(AuthCubit authCubit, OnboardingCubit onboardingCubit) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: RoutePaths.login,
      refreshListenable: GoRouterRefreshStream([authCubit.stream, onboardingCubit.stream]),
      redirect: (context, state) {
        final authState = authCubit.state;
        final loggingIn = state.matchedLocation == RoutePaths.login;

        // Auth state hasn't resolved yet — stay put (no splash screen yet).
        if (authState.status == AuthStatus.unknown) return null;

        final loggedIn = authState.status == AuthStatus.authenticated;
        if (!loggedIn) return loggingIn ? null : RoutePaths.login;
        if (loggedIn && loggingIn) {
          // Onboarding-seen flag hasn't loaded from prefs yet — stay put
          // rather than flashing onboarding before we know it was seen.
          final onboardingSeen = onboardingCubit.state;
          if (onboardingSeen == null) return null;
          return onboardingSeen ? RoutePaths.home : RoutePaths.onboarding;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: RoutePaths.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: RoutePaths.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: RoutePaths.scan,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ScanScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              _AppShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RoutePaths.home,
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RoutePaths.journal,
                  builder: (context, state) => const JournalScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RoutePaths.leaderboard,
                  builder: (context, state) => const LeaderboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RoutePaths.profile,
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isDesktop = kIsWeb && MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: AppColors.navyPanel,
              minWidth: 88,
              labelType: NavigationRailLabelType.all,
              indicatorColor: AppColors.gold.withValues(alpha: 0.18),
              selectedLabelTextStyle: AppTypography.body(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
              unselectedLabelTextStyle: AppTypography.body(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.creamDim,
              ),
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined, color: AppColors.creamDim),
                  selectedIcon: Icon(Icons.home_outlined, color: AppColors.gold),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.menu_book_outlined, color: AppColors.creamDim),
                  selectedIcon: Icon(Icons.menu_book_outlined, color: AppColors.gold),
                  label: Text('Journals'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.leaderboard_outlined, color: AppColors.creamDim),
                  selectedIcon: Icon(Icons.leaderboard_outlined, color: AppColors.gold),
                  label: Text('Leaderboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline, color: AppColors.creamDim),
                  selectedIcon: Icon(Icons.person_outline, color: AppColors.gold),
                  label: Text('Profile'),
                ),
              ],
            ),
            const VerticalDivider(width: 1, color: AppColors.navyDeep),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.navyPanel,
        indicatorColor: AppColors.gold.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.body(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected) ? AppColors.gold : AppColors.creamDim,
          ),
        ),
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.creamDim),
            selectedIcon: Icon(Icons.home_outlined, color: AppColors.gold),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined, color: AppColors.creamDim),
            selectedIcon: Icon(Icons.menu_book_outlined, color: AppColors.gold),
            label: 'Journals',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined, color: AppColors.creamDim),
            selectedIcon: Icon(Icons.leaderboard_outlined, color: AppColors.gold),
            label: 'Leaderboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: AppColors.creamDim),
            selectedIcon: Icon(Icons.person_outline, color: AppColors.gold),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
