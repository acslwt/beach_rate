import '../entities/user_profile.dart';

abstract class AuthRepository {
  Stream<UserProfile?> get authStateChanges;
  Future<UserProfile> signInWithEmailAndPassword(String email, String password);
  Future<UserProfile> createUserWithEmailAndPassword(String email, String password);
  Future<UserProfile> signInWithGoogle();
  Future<void> signOut();
}
