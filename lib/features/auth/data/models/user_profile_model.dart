import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.firstName,
    required super.email,
    super.favorites,
    super.visits,
  });

  factory UserProfileModel.fromFirebaseUser(User user) {
    final displayName = user.displayName ?? '';
    final firstName = displayName.isNotEmpty
        ? displayName.split(' ').first
        : user.email?.split('@').first ?? 'Utilisateur';
    return UserProfileModel(firstName: firstName, email: user.email ?? '');
  }
}
