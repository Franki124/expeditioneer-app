import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/motion.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';
import '../auth/data/auth_repository.dart';
import '../auth/domain/app_user.dart';
import '../events/cubit/joined_event_cubit.dart';
import '../events/cubit/joined_event_state.dart';
import '../events/data/event_repository.dart';
import '../events/domain/event.dart';
import 'cubit/profile_settings_cubit.dart';
import 'cubit/profile_settings_state.dart';
import 'widgets/stat_tile.dart';
import 'widgets/toggle_row.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileSettingsCubit(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  static const _guestProgressWarning =
      "You're playing as a guest. If you sign out without linking an account first, "
      "you won't be able to get back into this progress — guest sessions can't be recovered.";

  Future<void> _confirmLeaveEvent(BuildContext context, {required bool isGuest}) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.navyPanel2,
        title: Text('Leave this event?', style: AppTypography.body(fontWeight: FontWeight.w700)),
        content: Text(
          isGuest
              ? "You'll need the join code again to rejoin. $_guestProgressWarning"
              : "You'll need the join code again to rejoin.",
          style: AppTypography.body(color: AppColors.creamDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Leave', style: AppTypography.body(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<JoinedEventCubit>().leaveEvent();
    }
  }

  Future<void> _confirmSignOut(BuildContext context, {required bool isGuest}) async {
    if (!isGuest) {
      await context.read<AuthCubit>().signOut();
      return;
    }
    final action = await showAppDialog<_SignOutAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.navyPanel2,
        title: Text('Sign out as a guest?', style: AppTypography.body(fontWeight: FontWeight.w700)),
        content: Text(_guestProgressWarning, style: AppTypography.body(color: AppColors.creamDim)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(_SignOutAction.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(_SignOutAction.signOutAnyway),
            child: Text('Sign out anyway', style: AppTypography.body(color: AppColors.danger)),
          ),
          AppButton(
            label: 'Sign in with Google first',
            expand: false,
            onPressed: () => Navigator.of(dialogContext).pop(_SignOutAction.linkGoogle),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case _SignOutAction.signOutAnyway:
        await context.read<AuthCubit>().signOut();
      case _SignOutAction.linkGoogle:
        await context.read<AuthCubit>().linkGoogleAccount();
      case _SignOutAction.cancel:
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthCubit>().state.user?.uid;
    if (uid == null) return const SizedBox.shrink();

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => current.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage!)),
        );
        context.read<AuthCubit>().clearError();
      },
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: SafeArea(
          child: StreamBuilder<AppUser?>(
            stream: context.read<AuthRepository>().watchUserProfile(uid),
            builder: (context, userSnapshot) {
              final user = userSnapshot.data;
              final isGuest = (user?.authProvider ?? 'anonymous') == 'anonymous';
              return FadeSlideIn(
                child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md20),
                children: [
                  Text('Profile', style: AppTypography.display()),
                  const SizedBox(height: AppSpacing.md20),
                  Row(
                    children: [
                      _Avatar(user: user),
                      const SizedBox(width: AppSpacing.sm12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Wanderer',
                              style: AppTypography.display(fontSize: 20),
                            ),
                            Text(
                              _authProviderLabel(user?.authProvider),
                              style: AppTypography.body(color: AppColors.creamDim, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md20),
                  BlocBuilder<JoinedEventCubit, JoinedEventState>(
                    builder: (context, state) {
                      final eventId = state.joinedEventId;
                      if (eventId == null) {
                        return AppCard(
                          padding: const EdgeInsets.all(AppSpacing.md20),
                          child: Text(
                            "You haven't joined an event yet.",
                            style: AppTypography.body(color: AppColors.creamDim),
                          ),
                        );
                      }
                      return StreamBuilder<Event?>(
                        stream: context.read<EventRepository>().watchEvent(eventId),
                        builder: (context, eventSnapshot) {
                          final event = eventSnapshot.data;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  StatTile(
                                    label: 'Currently joined',
                                    value: event?.name ?? '—',
                                  ),
                                  const SizedBox(width: AppSpacing.sm12),
                                  StatTile(
                                    label: 'Status',
                                    value: event?.isLive ?? false ? 'Live' : 'Ended',
                                  ),
                                ],
                              ),
                              if (event != null) ...[
                                const SizedBox(height: AppSpacing.sm12),
                                TextButton(
                                  onPressed: () => _confirmLeaveEvent(context, isGuest: isGuest),
                                  child: Text(
                                    'leave current event',
                                    style: AppTypography.label(fontSize: 15, color: AppColors.danger),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
                  if (isGuest) ...[
                    const SizedBox(height: AppSpacing.lg32),
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "You're playing as a guest",
                            style: AppTypography.body(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.xs4),
                          Text(
                            'Sign in to save your progress — guest sessions can\'t be recovered '
                            'once you sign out.',
                            style: AppTypography.body(color: AppColors.creamDim, fontSize: 15),
                          ),
                          const SizedBox(height: AppSpacing.sm12),
                          AppButton(
                            label: 'Continue with Google',
                            onPressed: () => context.read<AuthCubit>().linkGoogleAccount(),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg32),
                  Text('Preferences', style: AppTypography.label(fontSize: 15)),
                  const SizedBox(height: AppSpacing.sm12),
                  BlocBuilder<ProfileSettingsCubit, ProfileSettingsState>(
                    builder: (context, state) {
                      final cubit = context.read<ProfileSettingsCubit>();
                      return Column(
                        children: [
                          ToggleRow(
                            label: 'Notifications',
                            value: state.notificationsEnabled,
                            onChanged: cubit.setNotifications,
                          ),
                          ToggleRow(
                            label: 'Sound',
                            value: state.soundEnabled,
                            onChanged: cubit.setSound,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg32),
                  AppButton(
                    label: 'Sign out',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _confirmSignOut(context, isGuest: isGuest),
                  ),
                ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _authProviderLabel(String? authProvider) {
    switch (authProvider) {
      case 'google':
        return 'Signed in with Google';
      case 'apple':
        return 'Signed in with Apple';
      default:
        return 'Guest expeditioneer';
    }
  }
}

enum _SignOutAction { cancel, signOutAnyway, linkGoogle }

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user?.avatarUrl;
    final initial = (user?.displayName.isNotEmpty ?? false) ? user!.displayName[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.goldDim,
      foregroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child: Text(initial, style: AppTypography.display(fontSize: 20, color: AppColors.navyDeep)),
    );
  }
}
