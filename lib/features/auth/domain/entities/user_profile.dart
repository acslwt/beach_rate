class UserProfile {
  final String uid;
  final String firstName;
  final String email;

  /// Profile photo, when the sign-in provider supplies one (e.g. Google).
  /// `null` for email/password accounts unless set explicitly.
  final String? photoUrl;
  final int favorites;
  final int visits;

  const UserProfile({
    required this.uid,
    required this.firstName,
    required this.email,
    this.photoUrl,
    this.favorites = 0,
    this.visits = 0,
  });

  String get initial => firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';
}
