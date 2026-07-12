import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogleUseCase {
  final AuthRepository _repository;
  const SignInWithGoogleUseCase(this._repository);

  Future<UserProfile> call() => _repository.signInWithGoogle();
}
