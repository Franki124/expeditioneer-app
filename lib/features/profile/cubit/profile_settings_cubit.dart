import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_settings_state.dart';

class ProfileSettingsCubit extends Cubit<ProfileSettingsState> {
  ProfileSettingsCubit() : super(const ProfileSettingsState()) {
    _load();
  }

  static const _notificationsKey = 'notificationsEnabled';
  static const _soundKey = 'soundEnabled';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    emit(ProfileSettingsState(
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
      soundEnabled: prefs.getBool(_soundKey) ?? true,
    ));
  }

  Future<void> setNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
    emit(state.copyWith(notificationsEnabled: enabled));
  }

  Future<void> setSound(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, enabled);
    emit(state.copyWith(soundEnabled: enabled));
  }
}
