import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState()) {
    _subscription = _repository.authStateChanges().listen(_onAuthChanged);
  }

  final AuthRepository _repository;
  late final StreamSubscription<User?> _subscription;

  void _onAuthChanged(User? user) {
    emit(AuthState(
      status: user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated,
      user: user,
    ));
  }

  Future<void> signInWithGoogle() async {
    try {
      await _repository.signInWithGoogle();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      emit(AuthState(
        status: state.status,
        user: state.user,
        errorMessage: 'Google sign-in failed. Please try again.',
      ));
    } catch (_) {
      emit(AuthState(
        status: state.status,
        user: state.user,
        errorMessage: 'Google sign-in failed. Please try again.',
      ));
    }
  }

  Future<void> linkGoogleAccount() async {
    try {
      await _repository.linkGoogleAccount();
    } on FirebaseAuthException catch (e) {
      emit(AuthState(
        status: state.status,
        user: state.user,
        errorMessage: e.code == 'credential-already-in-use'
            ? 'That Google account is already linked to a different profile.'
            : 'Could not link your Google account. Please try again.',
      ));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      emit(AuthState(
        status: state.status,
        user: state.user,
        errorMessage: 'Could not link your Google account. Please try again.',
      ));
    } catch (_) {
      emit(AuthState(
        status: state.status,
        user: state.user,
        errorMessage: 'Could not link your Google account. Please try again.',
      ));
    }
  }

  Future<void> signInAsGuest(String displayName) async {
    try {
      await _repository.signInAsGuest(displayName);
    } catch (_) {
      emit(AuthState(
        status: state.status,
        user: state.user,
        errorMessage: 'Could not continue as guest. Please try again.',
      ));
    }
  }

  Future<void> signOut() => _repository.signOut();

  void clearError() {
    emit(AuthState(status: state.status, user: state.user));
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
