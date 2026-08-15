class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.authProvider,
    this.email,
    this.avatarUrl,
  });

  final String uid;
  final String displayName;
  final String authProvider;
  final String? email;
  final String? avatarUrl;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      displayName: map['displayName'] as String? ?? 'Wanderer',
      authProvider: map['authProvider'] as String? ?? 'anonymous',
      email: map['email'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
    );
  }
}
