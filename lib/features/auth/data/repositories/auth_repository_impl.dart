import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/failures/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../models/user_profile_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Stream<UserProfile?> get authStateChanges {
    return _dataSource.authStateChanges.map(
      (user) =>
          user != null ? UserProfileModel.fromFirebaseUser(user) : null,
    );
  }

  @override
  Future<UserProfile> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential =
          await _dataSource.signInWithEmailAndPassword(email, password);
      return UserProfileModel.fromFirebaseUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    }
  }

  @override
  Future<UserProfile> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential =
          await _dataSource.createUserWithEmailAndPassword(email, password);
      return UserProfileModel.fromFirebaseUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    }
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    try {
      final credential = await _dataSource.signInWithGoogle();
      if (credential?.user == null) throw const UserCancelledException();
      return UserProfileModel.fromFirebaseUser(credential!.user!);
    } on UserCancelledException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _dataSource.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    }
  }

  String _mapError(String code) => switch (code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' =>
          'Email ou mot de passe incorrect.',
        'email-already-in-use' => 'Cet email est déjà utilisé.',
        'weak-password' =>
          'Le mot de passe doit contenir au moins 6 caractères.',
        'invalid-email' => 'Adresse email invalide.',
        'network-request-failed' => 'Pas de connexion Internet.',
        _ => 'Une erreur est survenue. Réessaie.',
      };
}
