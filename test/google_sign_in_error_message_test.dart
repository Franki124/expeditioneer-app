import 'package:expeditioneer_journal/features/auth/cubit/auth_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  const fallback = 'fallback';

  String? message(Object error) => googleSignInErrorMessage(error, fallback: fallback);

  test('user closing the picker stays silent', () {
    expect(message(FirebaseAuthException(code: 'popup-closed-by-user')), isNull);
    expect(message(FirebaseAuthException(code: 'cancelled-popup-request')), isNull);
    expect(
      message(const GoogleSignInException(code: GoogleSignInExceptionCode.canceled)),
      isNull,
    );
  });

  test('unauthorized web domain is shown, not swallowed', () {
    expect(message(FirebaseAuthException(code: 'unauthorized-domain')),
        contains('not set up'));
  });

  test('blocked popup tells the guest to allow pop-ups', () {
    expect(message(FirebaseAuthException(code: 'popup-blocked')), contains('pop-ups'));
  });

  test('Android misconfiguration reported as canceled is shown', () {
    expect(
      message(const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: '[16] Account reauth failed.',
      )),
      contains('not set up'),
    );
    expect(
      message(const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError)),
      contains('not set up'),
    );
  });

  test('anything else falls back to the generic message', () {
    expect(message(FirebaseAuthException(code: 'internal-error')), fallback);
    expect(message(Exception('boom')), fallback);
  });
}
