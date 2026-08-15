import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/utils/connectivity_cubit.dart';
import 'core/widgets/offline_overlay.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/events/cubit/joined_event_cubit.dart';
import 'features/events/data/event_repository.dart';
import 'features/events/data/journal_repository.dart';
import 'features/events/data/participant_repository.dart';
import 'features/onboarding/cubit/onboarding_cubit.dart';
import 'routing/app_router.dart';
import 'theme/app_scroll_behavior.dart';
import 'theme/app_theme.dart';
import 'theme/colors.dart';

/// The design is mobile-first; on web this keeps the layout at a phone-like
/// width instead of stretching it across a wide browser window.
const _webMaxWidth = 480.0;

class ExpeditioneerApp extends StatefulWidget {
  const ExpeditioneerApp({super.key});

  @override
  State<ExpeditioneerApp> createState() => _ExpeditioneerAppState();
}

class _ExpeditioneerAppState extends State<ExpeditioneerApp> {
  late final AuthRepository _authRepository;
  late final EventRepository _eventRepository;
  late final JournalRepository _journalRepository;
  late final ParticipantRepository _participantRepository;
  late final AuthCubit _authCubit;
  late final JoinedEventCubit _joinedEventCubit;
  late final OnboardingCubit _onboardingCubit;
  late final ConnectivityCubit _connectivityCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _eventRepository = EventRepository();
    _journalRepository = JournalRepository();
    _participantRepository = ParticipantRepository();
    _authCubit = AuthCubit(_authRepository);
    _joinedEventCubit = JoinedEventCubit(
      eventRepository: _eventRepository,
      participantRepository: _participantRepository,
      authCubit: _authCubit,
    );
    _onboardingCubit = OnboardingCubit();
    _connectivityCubit = ConnectivityCubit();
    _router = AppRouter.build(_authCubit, _onboardingCubit);
  }

  @override
  void dispose() {
    _authCubit.close();
    _joinedEventCubit.close();
    _onboardingCubit.close();
    _connectivityCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authRepository),
        RepositoryProvider.value(value: _eventRepository),
        RepositoryProvider.value(value: _journalRepository),
        RepositoryProvider.value(value: _participantRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authCubit),
          BlocProvider.value(value: _joinedEventCubit),
          BlocProvider.value(value: _onboardingCubit),
          BlocProvider.value(value: _connectivityCubit),
        ],
        child: MaterialApp.router(
          title: 'Expedition Journal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          scrollBehavior: AppScrollBehavior(),
          routerConfig: _router,
          builder: (context, child) {
            final content = Stack(
              children: [
                ?child,
                const OfflineOverlay(),
              ],
            );
            if (!kIsWeb) return content;
            return ColoredBox(
              color: AppColors.navyDeep,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _webMaxWidth),
                  child: content,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
