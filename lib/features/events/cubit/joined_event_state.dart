import 'package:equatable/equatable.dart';

enum JoinCodeStatus { idle, validating, unknownCode, notActivated, closed, nameTaken, success, error }

class JoinedEventState extends Equatable {
  const JoinedEventState({
    this.joinedEventId,
    this.joinCodeStatus = JoinCodeStatus.idle,
  });

  final String? joinedEventId;
  final JoinCodeStatus joinCodeStatus;

  JoinedEventState copyWith({String? joinedEventId, JoinCodeStatus? joinCodeStatus}) {
    return JoinedEventState(
      joinedEventId: joinedEventId ?? this.joinedEventId,
      joinCodeStatus: joinCodeStatus ?? this.joinCodeStatus,
    );
  }

  @override
  List<Object?> get props => [joinedEventId, joinCodeStatus];
}
