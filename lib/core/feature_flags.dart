/// App-wide switches for features that are built but not offered yet.
///
/// TODO: move these to a Firestore config doc the admin console can toggle.
class FeatureFlags {
  FeatureFlags._();

  /// Google sign-in and guest-to-Google linking. Off while the app is
  /// guest-only; the auth code behind it stays in place.
  static const googleSignInEnabled = false;
}
