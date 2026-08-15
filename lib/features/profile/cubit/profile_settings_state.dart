import 'package:equatable/equatable.dart';

class ProfileSettingsState extends Equatable {
  const ProfileSettingsState({
    this.notificationsEnabled = true,
    this.soundEnabled = true,
  });

  final bool notificationsEnabled;
  final bool soundEnabled;

  ProfileSettingsState copyWith({bool? notificationsEnabled, bool? soundEnabled}) {
    return ProfileSettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  @override
  List<Object?> get props => [notificationsEnabled, soundEnabled];
}
