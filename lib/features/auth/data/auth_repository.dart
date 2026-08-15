import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/app_user.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  bool _googleSignInInitialized = false;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<AppUser?> watchUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists ? AppUser.fromMap(uid, doc.data()!) : null,
        );
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleSignInInitialized = true;
  }

  Future<void> signInWithGoogle() async {
    final User? user;
    if (kIsWeb) {
      // Web's OAuth popup flow is handled entirely by firebase_auth's own
      // web plugin — no google_sign_in web client-ID/meta-tag setup needed.
      final userCredential = await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
      user = userCredential.user;
    } else {
      await _ensureGoogleSignInInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      user = userCredential.user;
    }
    if (user == null) return;
    await _ensureUserDocument(
      user,
      authProvider: 'google',
      displayName: user.displayName ?? 'Wanderer',
      email: user.email,
    );
  }

  /// Upgrades the current anonymous guest to a real Google account in place
  /// (same uid), so every `participants`/`scans`/`nameReservations` doc tied
  /// to that uid stays valid and becomes permanently recoverable via sign-in
  /// instead of being orphaned the moment the guest signs out. Throws
  /// [FirebaseAuthException] with code `credential-already-in-use` if that
  /// Google account is already linked to a different Firebase user — a real,
  /// expected case the caller must handle, not swallow.
  Future<void> linkGoogleAccount() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return;

    final AuthCredential credential;
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      final userCredential = await currentUser.linkWithPopup(provider);
      await _mergeGoogleProfile(userCredential.user ?? currentUser);
      return;
    } else {
      await _ensureGoogleSignInInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      credential = GoogleAuthProvider.credential(idToken: idToken);
    }
    final userCredential = await currentUser.linkWithCredential(credential);
    await _mergeGoogleProfile(userCredential.user ?? currentUser);
  }

  Future<void> _mergeGoogleProfile(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'authProvider': 'google',
      'email': user.email,
      if (user.photoURL != null) 'avatarUrl': user.photoURL,
    }, SetOptions(merge: true));
  }

  Future<void> signInAsGuest(String displayName) async {
    final userCredential = await _firebaseAuth.signInAnonymously();
    final user = userCredential.user;
    if (user == null) return;
    await _ensureUserDocument(
      user,
      authProvider: 'anonymous',
      displayName: displayName,
      email: null,
    );
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (_googleSignInInitialized) {
      await GoogleSignIn.instance.signOut();
    }
  }

  Future<void> _ensureUserDocument(
    User user, {
    required String authProvider,
    required String displayName,
    String? email,
  }) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) return;
    await docRef.set({
      'displayName': displayName,
      'email': email,
      'authProvider': authProvider,
      'avatarUrl': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
