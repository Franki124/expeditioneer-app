import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
    } catch (e, stackTrace) {
      _reportGoogleError(e, stackTrace,
          fallback: 'Google sign-in failed. Please try again.');
    }
  }

  Future<void> linkGoogleAccount() async {
    try {
      await _repository.linkGoogleAccount();
    } on FirebaseAuthException catch (e, stackTrace) {
      if (e.code == 'credential-already-in-use') {
        _emitError('That Google account is already linked to a different profile.');
        return;
      }
      _reportGoogleError(e, stackTrace,
          fallback: 'Could not link your Google account. Please try again.');
    } catch (e, stackTrace) {
      _reportGoogleError(e, stackTrace,
          fallback: 'Could not link your Google account. Please try again.');
    }
  }

  /// Turns a Google sign-in failure into a message the guest can act on.
  /// Only a genuine "user closed the picker" stays silent; everything else
  /// (including config problems that surface as `canceled` on Android) is
  /// logged and shown, so a broken setup never looks like a dead button.
  void _reportGoogleError(Object error, StackTrace stackTrace, {required String fallback}) {
    debugPrint('Google sign-in error: $error\n$stackTrace');
    final message = googleSignInErrorMessage(error, fallback: fallback);
    if (message != null) _emitError(message);
  }

  void _emitError(String message) {
    emit(AuthState(status: state.status, user: state.user, errorMessage: message));
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

/// Returns the message to show for a Google sign-in [error], or `null` when
/// the user simply backed out and nothing should be shown.
@visibleForTesting
String? googleSignInErrorMessage(Object error, {required String fallback}) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'user-cancelled':
        return null;
      case 'popup-blocked':
        return 'Your browser blocked the Google sign-in window. '
            'Allow pop-ups for this site and try again.';
      case 'unauthorized-domain':
      case 'operation-not-allowed':
        return 'Google sign-in is not set up for this version of the app yet. '
            'Continue as a guest for now.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      case 'web-storage-unsupported':
        return 'This browser blocks the storage Google sign-in needs. '
            'Try another browser or continue as a guest.';
    }
    return fallback;
  }
  if (error is GoogleSignInException) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        // Android reports a missing SHA-1 / OAuth client as a cancellation
        // ("[16] Account reauth failed."), which used to be swallowed.
        final description = error.description ?? '';
        if (description.contains('[16]') || description.contains('reauth')) {
          return 'Google sign-in is not set up for this version of the app yet. '
              'Continue as a guest for now.';
        }
        return null;
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google sign-in is not set up for this version of the app yet. '
            'Continue as a guest for now.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google sign-in could not open on this device. '
            'Continue as a guest for now.';
      default:
        return fallback;
    }
  }
  return fallback;
}
