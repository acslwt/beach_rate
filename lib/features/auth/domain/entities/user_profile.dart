class UserProfile {
  final String firstName;
  final String email;
  final int favorites;
  final int visits;

  const UserProfile({
    required this.firstName,
    required this.email,
    this.favorites = 0,
    this.visits = 0,
  });

  String get initial => firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';
}
