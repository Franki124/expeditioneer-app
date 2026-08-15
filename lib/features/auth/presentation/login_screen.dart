import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/petal_field.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _promptGuestName(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showAppDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.navyPanel2,
        title: Text(
          'What should we call you?',
          style: AppTypography.body(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.body(),
          decoration: const InputDecoration(hintText: 'Display name'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      context.read<AuthCubit>().signInAsGuest(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => current.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        context.read<AuthCubit>().clearError();
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.8),
                  radius: 1.2,
                  colors: [AppColors.navyPanel2, AppColors.navyDeep],
                ),
              ),
            ),
            const PetalField(),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 36, 26, 36),
              child: SafeArea(
                child: FadeSlideIn(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'The Expedition Journal',
                                style: AppTypography.display(fontSize: 30),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.xs8),
                              Text(
                                'find every journal · miss nothing',
                                style: AppTypography.label(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          AppButton(
                            label: 'Continue with Google',
                            onPressed: () =>
                                context.read<AuthCubit>().signInWithGoogle(),
                          ),
                          const SizedBox(height: AppSpacing.sm12),
                          TextButton(
                            onPressed: () => _promptGuestName(context),
                            child: Text(
                              'continue as a guest',
                              style: AppTypography.label(
                                fontSize: 15,
                                color: AppColors.creamDim,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
