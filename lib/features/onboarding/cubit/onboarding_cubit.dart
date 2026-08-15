import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `null` while the persisted flag is still loading, then `true`/`false`.
/// The router redirect waits for `null` to resolve before deciding whether
/// to send a freshly-logged-in user to onboarding or straight to home.
class OnboardingCubit extends Cubit<bool?> {
  OnboardingCubit() : super(null) {
    _load();
  }

  static const _prefsKey = 'onboardingSeen';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    emit(prefs.getBool(_prefsKey) ?? false);
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    emit(true);
  }
}
