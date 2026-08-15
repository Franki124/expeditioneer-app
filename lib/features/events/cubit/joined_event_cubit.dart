import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../data/event_repository.dart';
import '../data/participant_repository.dart';
import 'joined_event_state.dart';

class JoinedEventCubit extends Cubit<JoinedEventState> {
  JoinedEventCubit({
    required this._eventRepository,
    required this._participantRepository,
    required AuthCubit authCubit,
  }) : super(const JoinedEventState()) {
    _authSubscription = authCubit.stream.listen((state) => _onUidChanged(state.user?.uid));
    _onUidChanged(authCubit.state.user?.uid);
  }

  final EventRepository _eventRepository;
  final ParticipantRepository _participantRepository;
  late final StreamSubscription<AuthState> _authSubscription;

  // The "joined event" pointer is per signed-in user, not per device — two
  // different accounts on the same install must not inherit each other's
  // joined-event state.
  String? _currentUid;

  static String _prefsKeyFor(String uid) => 'joinedEventId_$uid';

  Future<void> _onUidChanged(String? uid) async {
    if (uid == _currentUid) return;
    _currentUid = uid;

    if (uid == null) {
      emit(const JoinedEventState());
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (_currentUid != uid) return; // a newer uid change landed while awaiting
    emit(JoinedEventState(joinedEventId: prefs.getString(_prefsKeyFor(uid))));
  }

  Future<void> submitJoinCode(
    String rawCode, {
    required String uid,
    required String displayName,
  }) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty || state.joinedEventId != null) return;

    emit(state.copyWith(joinCodeStatus: JoinCodeStatus.validating));
    final event = await _eventRepository.getEventByJoinCode(code);

    if (event == null) {
      emit(state.copyWith(joinCodeStatus: JoinCodeStatus.unknownCode));
      return;
    }

    switch (event.status) {
      case 'draft':
        emit(state.copyWith(joinCodeStatus: JoinCodeStatus.notActivated));
        return;
      case 'closed':
      case 'archived':
        emit(state.copyWith(joinCodeStatus: JoinCodeStatus.closed));
        return;
      case 'live':
        try {
          await _participantRepository.joinEvent(
            eventId: event.id,
            uid: uid,
            displayName: displayName,
          );
        } on DisplayNameTakenException {
          emit(state.copyWith(joinCodeStatus: JoinCodeStatus.nameTaken));
          return;
        } catch (_) {
          emit(state.copyWith(joinCodeStatus: JoinCodeStatus.error));
          return;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKeyFor(uid), event.id);
        emit(JoinedEventState(joinedEventId: event.id, joinCodeStatus: JoinCodeStatus.success));
        return;
    }
  }

  void resetJoinCodeStatus() {
    emit(state.copyWith(joinCodeStatus: JoinCodeStatus.idle));
  }

  Future<void> leaveEvent() async {
    final uid = _currentUid;
    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyFor(uid));
    }
    emit(const JoinedEventState());
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
