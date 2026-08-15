import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.unknown, this.user, this.errorMessage});

  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, user?.uid, errorMessage];
}
